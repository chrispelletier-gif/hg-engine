// melonDS frontend hooks (see melonDS/src/Platform.h) for the Android app.
// Only what a single-player retail game needs is implemented; wireless,
// camera, microphone and DSi-only features are stubbed out.

#include <chrono>
#include <condition_variable>
#include <cstdarg>
#include <cstdio>
#include <mutex>
#include <string>
#include <thread>

#include <dlfcn.h>
#include <unistd.h>

#ifdef __ANDROID__
#include <android/log.h>
#endif

#include "Platform.h"
#include "emulator.h"

namespace
{
std::string LocalDir = ".";
}

void hge::SetLocalDirectory(const std::string& dir)
{
    LocalDir = dir;
}

namespace melonDS::Platform
{

void SignalStop(StopReason, void*) {}

// ---- Files -----------------------------------------------------------------

static const char* ModeString(FileMode mode)
{
    if (mode & Append)
        return (mode & Read) ? "a+b" : "ab";
    if ((mode & ReadWrite) == ReadWrite)
        return (mode & Preserve) ? "r+b" : "w+b";
    if (mode & Write)
        return (mode & Preserve) ? "r+b" : "wb";
    return "rb";
}

FileHandle* OpenFile(const std::string& path, FileMode mode)
{
    if ((mode & (Read | Write)) == None)
        return nullptr;
    if ((mode & Write) && (mode & Preserve) && !(mode & NoCreate) && access(path.c_str(), F_OK) != 0)
    {
        // "r+" won't create the file, so create it first.
        if (FILE* f = std::fopen(path.c_str(), "wb"))
            std::fclose(f);
    }
    if ((mode & NoCreate) && access(path.c_str(), F_OK) != 0)
        return nullptr;
    return reinterpret_cast<FileHandle*>(std::fopen(path.c_str(), ModeString(mode)));
}

std::string GetLocalFilePath(const std::string& filename)
{
    if (!filename.empty() && filename[0] == '/')
        return filename;
    return LocalDir + "/" + filename;
}

FileHandle* OpenLocalFile(const std::string& path, FileMode mode)
{
    return OpenFile(GetLocalFilePath(path), mode);
}

bool FileExists(const std::string& name)
{
    return access(name.c_str(), F_OK) == 0;
}

bool LocalFileExists(const std::string& name)
{
    return FileExists(GetLocalFilePath(name));
}

bool CheckFileWritable(const std::string& filepath)
{
    return !FileExists(filepath) || access(filepath.c_str(), W_OK) == 0;
}

bool CheckLocalFileWritable(const std::string& filepath)
{
    return CheckFileWritable(GetLocalFilePath(filepath));
}

static FILE* F(FileHandle* file)
{
    return reinterpret_cast<FILE*>(file);
}

bool CloseFile(FileHandle* file) { return std::fclose(F(file)) == 0; }
bool IsEndOfFile(FileHandle* file) { return std::feof(F(file)) != 0; }
bool FileReadLine(char* str, int count, FileHandle* file) { return std::fgets(str, count, F(file)) != nullptr; }
u64 FilePosition(FileHandle* file) { return static_cast<u64>(std::ftell(F(file))); }
void FileRewind(FileHandle* file) { std::rewind(F(file)); }
u64 FileRead(void* data, u64 size, u64 count, FileHandle* file) { return std::fread(data, size, count, F(file)); }
bool FileFlush(FileHandle* file) { return std::fflush(F(file)) == 0; }
u64 FileWrite(const void* data, u64 size, u64 count, FileHandle* file) { return std::fwrite(data, size, count, F(file)); }

bool FileSeek(FileHandle* file, s64 offset, FileSeekOrigin origin)
{
    int whence = origin == FileSeekOrigin::Start ? SEEK_SET : origin == FileSeekOrigin::Current ? SEEK_CUR : SEEK_END;
    return std::fseek(F(file), static_cast<long>(offset), whence) == 0;
}

u64 FileWriteFormatted(FileHandle* file, const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    int ret = std::vfprintf(F(file), fmt, args);
    va_end(args);
    return ret < 0 ? 0 : static_cast<u64>(ret);
}

u64 FileLength(FileHandle* file)
{
    long pos = std::ftell(F(file));
    std::fseek(F(file), 0, SEEK_END);
    long len = std::ftell(F(file));
    std::fseek(F(file), pos, SEEK_SET);
    return static_cast<u64>(len);
}

// ---- Logging ---------------------------------------------------------------

void Log(LogLevel level, const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
#ifdef __ANDROID__
    int prio = level == Debug ? ANDROID_LOG_DEBUG : level == Info ? ANDROID_LOG_INFO
             : level == Warn ? ANDROID_LOG_WARN : ANDROID_LOG_ERROR;
    __android_log_vprint(prio, "melonDS", fmt, args);
#else
    if (level != Debug)
        std::vfprintf(stderr, fmt, args);
#endif
    va_end(args);
}

// ---- Threading -------------------------------------------------------------

struct Thread
{
    std::thread thread;
};

Thread* Thread_Create(std::function<void()> func)
{
    return new Thread{std::thread(std::move(func))};
}

void Thread_Free(Thread* thread)
{
    if (thread->thread.joinable())
        thread->thread.detach();
    delete thread;
}

void Thread_Wait(Thread* thread)
{
    if (thread->thread.joinable())
        thread->thread.join();
}

struct Semaphore
{
    std::mutex lock;
    std::condition_variable cond;
    int count = 0;
};

Semaphore* Semaphore_Create() { return new Semaphore(); }
void Semaphore_Free(Semaphore* sema) { delete sema; }

void Semaphore_Reset(Semaphore* sema)
{
    std::lock_guard<std::mutex> lock(sema->lock);
    sema->count = 0;
}

void Semaphore_Wait(Semaphore* sema)
{
    std::unique_lock<std::mutex> lock(sema->lock);
    sema->cond.wait(lock, [sema] { return sema->count > 0; });
    sema->count--;
}

bool Semaphore_TryWait(Semaphore* sema, int timeout_ms)
{
    std::unique_lock<std::mutex> lock(sema->lock);
    if (timeout_ms <= 0)
    {
        if (sema->count == 0)
            return false;
    }
    else if (!sema->cond.wait_for(lock, std::chrono::milliseconds(timeout_ms), [sema] { return sema->count > 0; }))
    {
        return false;
    }
    sema->count--;
    return true;
}

void Semaphore_Post(Semaphore* sema, int count)
{
    {
        std::lock_guard<std::mutex> lock(sema->lock);
        sema->count += count;
    }
    sema->cond.notify_all();
}

struct Mutex
{
    std::mutex mutex;
};

Mutex* Mutex_Create() { return new Mutex(); }
void Mutex_Free(Mutex* mutex) { delete mutex; }
void Mutex_Lock(Mutex* mutex) { mutex->mutex.lock(); }
void Mutex_Unlock(Mutex* mutex) { mutex->mutex.unlock(); }
bool Mutex_TryLock(Mutex* mutex) { return mutex->mutex.try_lock(); }

void Sleep(u64 usecs)
{
    std::this_thread::sleep_for(std::chrono::microseconds(usecs));
}

u64 GetUSCount()
{
    using namespace std::chrono;
    return duration_cast<microseconds>(steady_clock::now().time_since_epoch()).count();
}

u64 GetMSCount()
{
    return GetUSCount() / 1000;
}

// ---- Persistence -----------------------------------------------------------

void WriteNDSSave(const u8* savedata, u32 savelen, u32, u32, void* userdata)
{
    if (userdata)
        static_cast<hge::Emulator*>(userdata)->OnSaveWritten(savedata, savelen);
}

void WriteGBASave(const u8*, u32, u32, u32, void*) {}
void WriteFirmware(const Firmware&, u32, u32, void*) {}
void WriteDateTime(int, int, int, int, int, int, void*) {}

// ---- Local multiplayer / Wi-Fi (not supported) ----------------------------

void MP_Begin(void*) {}
void MP_End(void*) {}
int MP_SendPacket(u8*, int len, u64, void*) { return len; }
int MP_RecvPacket(u8*, u64*, void*) { return 0; }
int MP_SendCmd(u8*, int len, u64, void*) { return len; }
int MP_SendReply(u8*, int len, u64, u16, void*) { return len; }
int MP_SendAck(u8*, int len, u64, void*) { return len; }
int MP_RecvHostPacket(u8*, u64*, void*) { return 0; }
u16 MP_RecvReplies(u8*, u64, u16, void*) { return 0; }
int Net_SendPacket(u8*, int len, void*) { return len; }
int Net_RecvPacket(u8*, void*) { return 0; }

// ---- Camera / microphone / add-ons (not supported) ------------------------

void Camera_Start(int, void*) {}
void Camera_Stop(int, void*) {}
void Camera_CaptureFrame(int, u32*, int, int, bool, void*) {}
void Mic_Start(void*) {}
void Mic_Stop(void*) {}
int Mic_ReadInput(s16*, int, void*) { return 0; }

AACDecoder* AAC_Init() { return nullptr; }
void AAC_DeInit(AACDecoder*) {}
bool AAC_Configure(AACDecoder*, int, int) { return false; }
bool AAC_DecodeFrame(AACDecoder*, const void*, int, void*, int) { return false; }

bool Addon_KeyDown(KeyType, void*) { return false; }
void Addon_RumbleStart(u32, void*) {}
void Addon_RumbleStop(void*) {}
float Addon_MotionQuery(MotionQueryType, void*) { return 0.0f; }

// ---- Dynamic libraries (the ARM64 JIT loads libandroid for shared memory) --

DynamicLibrary* DynamicLibrary_Load(const char* lib)
{
    return reinterpret_cast<DynamicLibrary*>(dlopen(lib, RTLD_NOW | RTLD_LOCAL));
}

void DynamicLibrary_Unload(DynamicLibrary* lib)
{
    if (lib)
        dlclose(lib);
}

void* DynamicLibrary_LoadFunction(DynamicLibrary* lib, const char* name)
{
    return lib ? dlsym(lib, name) : nullptr;
}

}
