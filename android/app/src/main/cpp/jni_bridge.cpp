// JNI entry points for com.hgengine.android.NativeBridge.

#include <jni.h>

#include <cstdio>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "bps.h"
#include "emulator.h"

namespace
{

std::mutex g_lock;
std::unique_ptr<hge::Emulator> g_emu;

std::string ToString(JNIEnv* env, jstring s)
{
    if (!s)
        return {};
    const char* chars = env->GetStringUTFChars(s, nullptr);
    std::string out(chars);
    env->ReleaseStringUTFChars(s, chars);
    return out;
}

jstring Result(JNIEnv* env, bool ok, const std::string& error)
{
    return ok ? nullptr : env->NewStringUTF(error.c_str());
}

bool ReadAll(const std::string& path, std::vector<uint8_t>& out)
{
    FILE* f = std::fopen(path.c_str(), "rb");
    if (!f)
        return false;
    std::fseek(f, 0, SEEK_END);
    long len = std::ftell(f);
    std::fseek(f, 0, SEEK_SET);
    out.resize(len > 0 ? static_cast<size_t>(len) : 0);
    bool ok = len >= 0 && std::fread(out.data(), 1, out.size(), f) == out.size();
    std::fclose(f);
    return ok;
}

}

#define JNI_FN(name) Java_com_hgengine_android_NativeBridge_##name

extern "C" {

JNIEXPORT void JNICALL JNI_FN(setDataDirectory)(JNIEnv* env, jobject, jstring dir)
{
    hge::SetLocalDirectory(ToString(env, dir));
}

// Returns null on success, or an error message.
JNIEXPORT jstring JNICALL JNI_FN(applyBpsPatch)(JNIEnv* env, jobject, jstring sourcePath, jstring patchPath, jstring outPath)
{
    std::vector<uint8_t> source, patch, target;
    std::string error;
    if (!ReadAll(ToString(env, sourcePath), source))
        return env->NewStringUTF("Couldn't read the selected ROM.");
    if (!ReadAll(ToString(env, patchPath), patch))
        return env->NewStringUTF("Couldn't read the hg-engine patch.");
    if (!hge::ApplyBps(source, patch, target, error))
        return env->NewStringUTF(error.c_str());

    source.clear();
    source.shrink_to_fit();

    const std::string out = ToString(env, outPath);
    FILE* f = std::fopen(out.c_str(), "wb");
    if (!f)
        return env->NewStringUTF("Couldn't write the patched ROM.");
    bool ok = std::fwrite(target.data(), 1, target.size(), f) == target.size();
    ok = (std::fclose(f) == 0) && ok;
    return ok ? nullptr : env->NewStringUTF("Couldn't write the patched ROM.");
}

JNIEXPORT jstring JNICALL JNI_FN(boot)(JNIEnv* env, jobject, jstring romPath, jstring savePath, jboolean useJit)
{
    std::lock_guard<std::mutex> lock(g_lock);
    if (!g_emu)
        g_emu = std::make_unique<hge::Emulator>();
    std::string error;
    bool ok = g_emu->Boot(ToString(env, romPath), ToString(env, savePath), useJit, error);
    return Result(env, ok, error);
}

JNIEXPORT void JNICALL JNI_FN(shutdown)(JNIEnv*, jobject)
{
    std::lock_guard<std::mutex> lock(g_lock);
    g_emu.reset();
}

JNIEXPORT void JNICALL JNI_FN(runFrame)(JNIEnv* env, jobject, jobject framebuffer)
{
    std::lock_guard<std::mutex> lock(g_lock);
    if (!g_emu)
        return;
    auto* pixels = static_cast<uint32_t*>(env->GetDirectBufferAddress(framebuffer));
    if (pixels && env->GetDirectBufferCapacity(framebuffer) >= hge::kScreenWidth * hge::kScreenHeight * 2 * 4)
        g_emu->RunFrame(pixels);
}

JNIEXPORT jint JNICALL JNI_FN(readAudio)(JNIEnv* env, jobject, jshortArray buffer)
{
    std::lock_guard<std::mutex> lock(g_lock);
    if (!g_emu)
        return 0;
    jsize len = env->GetArrayLength(buffer);
    jshort* samples = env->GetShortArrayElements(buffer, nullptr);
    int frames = g_emu->ReadAudio(samples, len / 2);
    env->ReleaseShortArrayElements(buffer, samples, 0);
    return frames;
}

JNIEXPORT void JNICALL JNI_FN(setButtons)(JNIEnv*, jobject, jint mask)
{
    std::lock_guard<std::mutex> lock(g_lock);
    if (g_emu)
        g_emu->SetButtons(static_cast<uint32_t>(mask));
}

JNIEXPORT void JNICALL JNI_FN(touch)(JNIEnv*, jobject, jboolean down, jint x, jint y)
{
    std::lock_guard<std::mutex> lock(g_lock);
    if (!g_emu)
        return;
    if (down)
        g_emu->Touch(x, y);
    else
        g_emu->ReleaseTouch();
}

JNIEXPORT jstring JNICALL JNI_FN(saveState)(JNIEnv* env, jobject, jstring path)
{
    std::lock_guard<std::mutex> lock(g_lock);
    std::string error = "The game isn't running.";
    bool ok = g_emu && g_emu->SaveState(ToString(env, path), error);
    return Result(env, ok, error);
}

JNIEXPORT jstring JNICALL JNI_FN(loadState)(JNIEnv* env, jobject, jstring path)
{
    std::lock_guard<std::mutex> lock(g_lock);
    std::string error = "The game isn't running.";
    bool ok = g_emu && g_emu->LoadState(ToString(env, path), error);
    return Result(env, ok, error);
}

JNIEXPORT void JNICALL JNI_FN(flushSave)(JNIEnv*, jobject)
{
    std::lock_guard<std::mutex> lock(g_lock);
    if (g_emu)
        g_emu->FlushSave();
}

}
