package com.hgengine.android

import java.nio.ByteBuffer

/** JNI bindings to libhgengine (melonDS core + BPS patcher). Methods returning String? yield null on success or an error message. */
object NativeBridge {
    const val SCREEN_WIDTH = 256
    const val SCREEN_HEIGHT = 192
    const val SAMPLE_RATE = 48000

    // DS button bits (see emulator.h).
    const val BTN_A = 1 shl 0
    const val BTN_B = 1 shl 1
    const val BTN_SELECT = 1 shl 2
    const val BTN_START = 1 shl 3
    const val BTN_RIGHT = 1 shl 4
    const val BTN_LEFT = 1 shl 5
    const val BTN_UP = 1 shl 6
    const val BTN_DOWN = 1 shl 7
    const val BTN_R = 1 shl 8
    const val BTN_L = 1 shl 9
    const val BTN_X = 1 shl 10
    const val BTN_Y = 1 shl 11

    init {
        System.loadLibrary("hgengine")
    }

    external fun setDataDirectory(dir: String)
    external fun applyBpsPatch(sourcePath: String, patchPath: String, outPath: String): String?
    external fun boot(romPath: String, savePath: String, useJit: Boolean): String?
    external fun shutdown()

    /** Runs one frame; [framebuffer] must be a direct buffer of 256x384 RGBA pixels. */
    external fun runFrame(framebuffer: ByteBuffer)

    /** Fills [buffer] with interleaved stereo samples and returns the number of frames written. */
    external fun readAudio(buffer: ShortArray): Int
    external fun setButtons(mask: Int)
    external fun touch(down: Boolean, x: Int, y: Int)
    external fun saveState(path: String): String?
    external fun loadState(path: String): String?
    external fun flushSave()
}
