#pragma once

#include <cstdint>
#include <memory>
#include <mutex>
#include <string>

namespace melonDS
{
class NDS;
}

namespace hge
{

// DS button bits, matching melonDS's key mask layout.
enum Button : uint32_t
{
    BtnA = 1 << 0,
    BtnB = 1 << 1,
    BtnSelect = 1 << 2,
    BtnStart = 1 << 3,
    BtnRight = 1 << 4,
    BtnLeft = 1 << 5,
    BtnUp = 1 << 6,
    BtnDown = 1 << 7,
    BtnR = 1 << 8,
    BtnL = 1 << 9,
    BtnX = 1 << 10,
    BtnY = 1 << 11,
};

constexpr int kScreenWidth = 256;
constexpr int kScreenHeight = 192;
constexpr int kAudioSampleRate = 48000;

// Directory melonDS uses for its own auxiliary files.
void SetLocalDirectory(const std::string& dir);

// Thin wrapper around a melonDS NDS instance that owns the ROM, the save file
// and the frame/audio plumbing the Android frontend needs.
class Emulator
{
public:
    Emulator();
    ~Emulator();

    bool Boot(const std::string& romPath, const std::string& savePath, bool useJit, std::string& error);
    void Shutdown();
    bool IsRunning() const;

    // Runs one emulated frame and writes both screens (top then bottom,
    // 256x384) as RGBA8888 into `rgba`.
    void RunFrame(uint32_t* rgba);

    // Returns the number of interleaved stereo frames written to `out`.
    int ReadAudio(int16_t* out, int maxFrames);

    void SetButtons(uint32_t pressedMask);
    void Touch(int x, int y);
    void ReleaseTouch();

    bool SaveState(const std::string& path, std::string& error);
    bool LoadState(const std::string& path, std::string& error);

    // Called by melonDS whenever the cartridge save memory changes.
    void OnSaveWritten(const uint8_t* data, uint32_t len);
    void FlushSave();

private:
    std::unique_ptr<melonDS::NDS> nds;
    std::string savePath;

    std::mutex saveLock;
    std::unique_ptr<uint8_t[]> pendingSave;
    uint32_t pendingSaveLen = 0;
    bool saveDirty = false;
    uint64_t lastSaveWriteMs = 0;
};

}
