// Host-side smoke tests for the native layer (run on the build machine, not on Android).
//
//   ./hge_tests                      run the built-in tests
//   ./hge_tests bps SRC PATCH TARGET  apply PATCH to SRC and compare with TARGET

#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

#include "bps.h"
#include "emulator.h"

namespace
{

int failures = 0;

#define CHECK(cond)                                                       \
    do                                                                    \
    {                                                                     \
        if (!(cond))                                                      \
        {                                                                 \
            std::fprintf(stderr, "%s:%d: CHECK failed: %s\n", __FILE__, __LINE__, #cond); \
            failures++;                                                   \
        }                                                                 \
    } while (0)

bool ReadAll(const char* path, std::vector<uint8_t>& out)
{
    FILE* f = std::fopen(path, "rb");
    if (!f)
        return false;
    std::fseek(f, 0, SEEK_END);
    out.resize(std::ftell(f));
    std::fseek(f, 0, SEEK_SET);
    bool ok = std::fread(out.data(), 1, out.size(), f) == out.size();
    std::fclose(f);
    return ok;
}

void WriteAll(const std::string& path, const std::vector<uint8_t>& data)
{
    FILE* f = std::fopen(path.c_str(), "wb");
    std::fwrite(data.data(), 1, data.size(), f);
    std::fclose(f);
}

void Put32(std::vector<uint8_t>& v, size_t off, uint32_t x)
{
    for (int i = 0; i < 4; i++)
        v[off + i] = (x >> (8 * i)) & 0xFF;
}

uint16_t Crc16(const uint8_t* data, size_t len)
{
    uint16_t crc = 0xFFFF;
    for (size_t i = 0; i < len; i++)
    {
        crc ^= data[i];
        for (int k = 0; k < 8; k++)
            crc = (crc & 1) ? (crc >> 1) ^ 0xA001 : crc >> 1;
    }
    return crc;
}

// A minimal homebrew DS ROM. The ARM9 program powers on the LCDs, puts engine A
// in VRAM display mode and fills VRAM bank A with pure red; the ARM7 just spins.
std::vector<uint8_t> MakeTestRom()
{
    static const uint32_t arm9[] = {
        0xE59F0038, 0xE59F1038, 0xE5801000, 0xE3A00301, 0xE3A01802, 0xE5801000, 0xE59F0028,
        0xE3A01080, 0xE5C01000, 0xE3A0051A, 0xE59F101C, 0xE3A02A06, 0xE4801004, 0xE2522001,
        0x1AFFFFFC, 0xEAFFFFFE, 0x04000304, 0x0000820F, 0x04000240, 0x001F001F,
    };
    static const uint32_t arm7[] = {0xEAFFFFFE};

    std::vector<uint8_t> rom(0x20000, 0);
    std::memcpy(&rom[0x00], "HGE TEST", 8);
    std::memcpy(&rom[0x0C], "####", 4);
    Put32(rom, 0x20, 0x8000);       // ARM9 ROM offset (past the secure area)
    Put32(rom, 0x24, 0x02000000);   // ARM9 entry
    Put32(rom, 0x28, 0x02000000);   // ARM9 load address
    Put32(rom, 0x2C, sizeof(arm9));
    Put32(rom, 0x30, 0xA000);       // ARM7 ROM offset
    Put32(rom, 0x34, 0x037F8000);   // ARM7 entry
    Put32(rom, 0x38, 0x037F8000);   // ARM7 load address
    Put32(rom, 0x3C, sizeof(arm7));
    Put32(rom, 0x80, 0xA000 + sizeof(arm7));
    Put32(rom, 0x84, 0x4000);
    for (size_t i = 0; i < sizeof(arm9) / 4; i++)
        Put32(rom, 0x8000 + i * 4, arm9[i]);
    Put32(rom, 0xA000, arm7[0]);
    uint16_t crc = Crc16(rom.data(), 0x15E);
    rom[0x15E] = crc & 0xFF;
    rom[0x15F] = crc >> 8;
    return rom;
}

void TestCrc()
{
    const char* s = "123456789";
    CHECK(hge::Crc32(reinterpret_cast<const uint8_t*>(s), 9) == 0xCBF43926u);
}

void TestBpsRejectsGarbage()
{
    std::vector<uint8_t> src(16, 1), patch(32, 0), out;
    std::string error;
    CHECK(!hge::ApplyBps(src, patch, out, error));
    CHECK(!error.empty());
}

void TestEmulator(const std::string& dir)
{
    const std::string romPath = dir + "/test.nds";
    const std::string savPath = dir + "/test.sav";
    const std::string statePath = dir + "/test.mln";
    WriteAll(romPath, MakeTestRom());
    hge::SetLocalDirectory(dir);

    for (bool jit : {false, true})
    {
        hge::Emulator emu;
        std::string error;
        bool booted = emu.Boot(romPath, savPath, jit, error);
        if (!booted)
            std::fprintf(stderr, "boot failed (jit=%d): %s\n", jit, error.c_str());
        CHECK(booted);
        if (!booted)
            continue;

        std::vector<uint32_t> fb(256 * 384, 0);
        int audioFrames = 0;
        std::vector<int16_t> audio(4096);
        for (int i = 0; i < 30; i++)
        {
            emu.RunFrame(fb.data());
            audioFrames += emu.ReadAudio(audio.data(), 2048);
        }

        const uint32_t top = fb[128 + 96 * 256];
        std::printf("jit=%d top pixel RGBA=%08X bottom pixel=%08X audio frames=%d\n",
                    jit, top, fb[256 * 192 + 128 + 96 * 256], audioFrames);
        CHECK((top & 0xFF) >= 0xF0);          // red
        CHECK(((top >> 8) & 0xFF) == 0);      // no green
        CHECK(((top >> 16) & 0xFF) == 0);     // no blue
        CHECK((top >> 24) == 0xFF);           // opaque
        CHECK(audioFrames > 0);

        emu.SetButtons(hge::BtnA | hge::BtnStart);
        emu.Touch(10, 20);
        emu.RunFrame(fb.data());
        emu.ReleaseTouch();
        emu.SetButtons(0);

        CHECK(emu.SaveState(statePath, error));
        emu.RunFrame(fb.data());
        CHECK(emu.LoadState(statePath, error));
        emu.RunFrame(fb.data());
        CHECK((fb[128 + 96 * 256] & 0xFF) >= 0xF0);

        CHECK(!emu.LoadState(dir + "/missing.mln", error));
        emu.Shutdown();
        CHECK(!emu.IsRunning());
    }
}

}

int main(int argc, char** argv)
{
    if (argc == 5 && std::strcmp(argv[1], "bps") == 0)
    {
        std::vector<uint8_t> src, patch, expected, out;
        if (!ReadAll(argv[2], src) || !ReadAll(argv[3], patch) || !ReadAll(argv[4], expected))
        {
            std::fprintf(stderr, "couldn't read inputs\n");
            return 2;
        }
        std::string error;
        if (!hge::ApplyBps(src, patch, out, error))
        {
            std::fprintf(stderr, "apply failed: %s\n", error.c_str());
            return 1;
        }
        if (out != expected)
        {
            std::fprintf(stderr, "output differs from expected target\n");
            return 1;
        }
        std::printf("bps ok (%zu bytes)\n", out.size());
        return 0;
    }

    const std::string dir = argc > 1 ? argv[1] : ".";
    TestCrc();
    TestBpsRejectsGarbage();
    TestEmulator(dir);

    if (failures)
    {
        std::fprintf(stderr, "%d check(s) failed\n", failures);
        return 1;
    }
    std::printf("all tests passed\n");
    return 0;
}
