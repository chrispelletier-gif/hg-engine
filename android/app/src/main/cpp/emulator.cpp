#include "emulator.h"

#include <cstdio>
#include <ctime>
#include <vector>

#include "Args.h"
#include "GPU_Soft.h"
#include "NDS.h"
#include "NDSCart.h"
#include "Platform.h"
#include "Savestate.h"

namespace hge
{

namespace
{

// How long the save memory has to stay unchanged before it's written to disk.
// The game writes its save in many small chunks; this coalesces them.
constexpr uint64_t kSaveDebounceMs = 1000;

bool ReadFile(const std::string& path, std::vector<uint8_t>& out)
{
    FILE* f = std::fopen(path.c_str(), "rb");
    if (!f)
        return false;
    std::fseek(f, 0, SEEK_END);
    long len = std::ftell(f);
    std::fseek(f, 0, SEEK_SET);
    if (len < 0)
    {
        std::fclose(f);
        return false;
    }
    out.resize(static_cast<size_t>(len));
    bool ok = len == 0 || std::fread(out.data(), 1, out.size(), f) == out.size();
    std::fclose(f);
    return ok;
}

bool WriteFileAtomic(const std::string& path, const uint8_t* data, size_t len)
{
    const std::string tmp = path + ".tmp";
    FILE* f = std::fopen(tmp.c_str(), "wb");
    if (!f)
        return false;
    bool ok = std::fwrite(data, 1, len, f) == len;
    ok = (std::fclose(f) == 0) && ok;
    if (!ok)
    {
        std::remove(tmp.c_str());
        return false;
    }
    return std::rename(tmp.c_str(), path.c_str()) == 0;
}

}

Emulator::Emulator() = default;

Emulator::~Emulator()
{
    Shutdown();
}

bool Emulator::Boot(const std::string& romPath, const std::string& savPath, bool useJit, std::string& error)
{
    Shutdown();

    std::vector<uint8_t> rom;
    if (!ReadFile(romPath, rom) || rom.empty())
    {
        error = "Couldn't read the game ROM.";
        return false;
    }

    savePath = savPath;
    std::vector<uint8_t> save;
    ReadFile(savePath, save); // a missing save just means a new game

    melonDS::NDSArgs args;
    if (!useJit)
        args.JIT = std::nullopt;
    args.OutputSampleRate = kAudioSampleRate;
    args.Interpolation = melonDS::AudioInterpolation::Cubic;

    nds = std::make_unique<melonDS::NDS>(std::move(args), this);
    nds->SetRenderer(std::make_unique<melonDS::SoftRenderer>(*nds));

    melonDS::NDSCart::NDSCartArgs cartArgs;
    if (!save.empty())
    {
        cartArgs.SRAM = std::make_unique<uint8_t[]>(save.size());
        std::copy(save.begin(), save.end(), cartArgs.SRAM.get());
        cartArgs.SRAMLength = static_cast<uint32_t>(save.size());
    }

    auto cart = melonDS::NDSCart::ParseROM(rom.data(), static_cast<uint32_t>(rom.size()), this, std::move(cartArgs));
    if (!cart)
    {
        error = "This file isn't a valid DS ROM.";
        nds.reset();
        return false;
    }

    nds->SetNDSCart(std::move(cart));
    nds->Reset();
    // Built-in FreeBIOS and generated firmware can't boot the DS menu, so boot the cart directly.
    nds->SetupDirectBoot("game.nds");

    // HeartGold uses the RTC for day/night and events, so start from the device clock.
    std::time_t now = std::time(nullptr);
    std::tm local{};
    localtime_r(&now, &local);
    nds->RTC.SetDateTime(local.tm_year + 1900, local.tm_mon + 1, local.tm_mday,
                         local.tm_hour, local.tm_min, local.tm_sec);

    nds->Start();
    return true;
}

void Emulator::Shutdown()
{
    if (!nds)
        return;
    FlushSave();
    nds->Stop();
    nds.reset();
}

bool Emulator::IsRunning() const
{
    return nds != nullptr;
}

void Emulator::RunFrame(uint32_t* rgba)
{
    if (!nds)
        return;

    nds->RunFrame();

    void* top = nullptr;
    void* bottom = nullptr;
    if (nds->GPU.GetFramebuffers(&top, &bottom) && top && bottom)
    {
        // melonDS outputs BGRA; Android bitmaps want RGBA.
        const uint32_t* src[2] = {static_cast<const uint32_t*>(top), static_cast<const uint32_t*>(bottom)};
        for (int s = 0; s < 2; s++)
        {
            uint32_t* dst = rgba + s * kScreenWidth * kScreenHeight;
            for (int i = 0; i < kScreenWidth * kScreenHeight; i++)
            {
                uint32_t p = src[s][i];
                dst[i] = 0xFF000000u | (p & 0x0000FF00u) | ((p >> 16) & 0xFFu) | ((p & 0xFFu) << 16);
            }
        }
    }

    bool writeNow = false;
    {
        std::lock_guard<std::mutex> lock(saveLock);
        writeNow = saveDirty && melonDS::Platform::GetMSCount() - lastSaveWriteMs >= kSaveDebounceMs;
    }
    if (writeNow)
        FlushSave();
}

int Emulator::ReadAudio(int16_t* out, int maxFrames)
{
    if (!nds)
        return 0;
    return nds->SPU.ReadOutput(out, maxFrames);
}

void Emulator::SetButtons(uint32_t pressedMask)
{
    if (nds)
        nds->SetKeyMask(~pressedMask & 0xFFF); // melonDS keys are active-low
}

void Emulator::Touch(int x, int y)
{
    if (!nds)
        return;
    x = x < 0 ? 0 : (x >= kScreenWidth ? kScreenWidth - 1 : x);
    y = y < 0 ? 0 : (y >= kScreenHeight ? kScreenHeight - 1 : y);
    nds->TouchScreen(static_cast<uint16_t>(x), static_cast<uint16_t>(y));
}

void Emulator::ReleaseTouch()
{
    if (nds)
        nds->ReleaseScreen();
}

bool Emulator::SaveState(const std::string& path, std::string& error)
{
    if (!nds)
    {
        error = "The game isn't running.";
        return false;
    }
    melonDS::Savestate state;
    if (state.Error || !nds->DoSavestate(&state) || state.Error)
    {
        error = "Couldn't capture the emulator state.";
        return false;
    }
    if (!WriteFileAtomic(path, static_cast<const uint8_t*>(state.Buffer()), state.Length()))
    {
        error = "Couldn't write the state file.";
        return false;
    }
    return true;
}

bool Emulator::LoadState(const std::string& path, std::string& error)
{
    if (!nds)
    {
        error = "The game isn't running.";
        return false;
    }
    std::vector<uint8_t> data;
    if (!ReadFile(path, data) || data.empty())
    {
        error = "No saved state in this slot.";
        return false;
    }

    // Keep a backup so a bad state file doesn't leave the emulator half-loaded.
    melonDS::Savestate backup;
    if (backup.Error || !nds->DoSavestate(&backup) || backup.Error)
    {
        error = "Couldn't back up the current state.";
        return false;
    }

    melonDS::Savestate state(data.data(), static_cast<uint32_t>(data.size()), false);
    if (!nds->DoSavestate(&state) || state.Error)
    {
        melonDS::Savestate restore(backup.Buffer(), backup.Length(), false);
        nds->DoSavestate(&restore);
        error = "This state file is incompatible or corrupt.";
        return false;
    }
    return true;
}

void Emulator::OnSaveWritten(const uint8_t* data, uint32_t len)
{
    std::lock_guard<std::mutex> lock(saveLock);
    if (pendingSaveLen != len)
    {
        pendingSave = std::make_unique<uint8_t[]>(len);
        pendingSaveLen = len;
    }
    std::copy(data, data + len, pendingSave.get());
    saveDirty = true;
    lastSaveWriteMs = melonDS::Platform::GetMSCount();
}

void Emulator::FlushSave()
{
    std::lock_guard<std::mutex> lock(saveLock);
    if (!saveDirty || savePath.empty())
        return;
    if (WriteFileAtomic(savePath, pendingSave.get(), pendingSaveLen))
        saveDirty = false;
    else
        melonDS::Platform::Log(melonDS::Platform::LogLevel::Error, "Failed to write save file %s\n", savePath.c_str());
}

}
