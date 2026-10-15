package com.hgengine.android

import android.graphics.Bitmap
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * Runs the emulator: boots the game, then loops frame -> draw -> audio at the
 * DS's native ~59.83 fps. All native calls happen on this thread; other threads
 * talk to it through [InputState] and [post].
 */
class EmulatorThread(
    private val files: GameFiles,
    private val view: EmulatorView,
    private val input: InputState,
    private val onBootError: (String) -> Unit,
) : Thread("hge-emulator") {

    @Volatile private var running = true
    @Volatile private var paused = false
    @Volatile var fastForward = false

    private val wakeLock = Object()
    private val tasks = ConcurrentLinkedQueue<() -> Unit>()

    /** Runs [task] on the emulation thread between frames (even while paused). */
    fun post(task: () -> Unit) {
        tasks.add(task)
        wake()
    }

    fun setPaused(value: Boolean) {
        paused = value
        wake()
    }

    fun quit() {
        running = false
        wake()
    }

    private fun wake() = synchronized(wakeLock) { wakeLock.notifyAll() }

    override fun run() {
        val error = NativeBridge.boot(files.gameRom.path, files.save.path, files.useJit)
        if (error != null) {
            onBootError(error)
            return
        }

        val framebuffer = ByteBuffer
            .allocateDirect(NativeBridge.SCREEN_WIDTH * NativeBridge.SCREEN_HEIGHT * 2 * 4)
            .order(ByteOrder.nativeOrder())
        val frame = Bitmap.createBitmap(NativeBridge.SCREEN_WIDTH, NativeBridge.SCREEN_HEIGHT * 2, Bitmap.Config.ARGB_8888)
        val audio = createAudioTrack()
        val samples = ShortArray(4096)

        var nextFrame = System.nanoTime()
        var lastButtons = -1
        var lastTouch = -1L

        try {
            audio.play()
            while (running) {
                while (true) {
                    val task = tasks.poll() ?: break
                    task()
                }

                if (paused) {
                    synchronized(wakeLock) {
                        if (paused && running && tasks.isEmpty()) wakeLock.wait(500)
                    }
                    nextFrame = System.nanoTime()
                    continue
                }

                val buttons = input.buttons
                if (buttons != lastButtons) {
                    NativeBridge.setButtons(buttons)
                    lastButtons = buttons
                }
                val touch = input.touchSnapshot()
                if (touch != lastTouch) {
                    NativeBridge.touch(InputState.isDown(touch), InputState.xOf(touch), InputState.yOf(touch))
                    lastTouch = touch
                }

                NativeBridge.runFrame(framebuffer)
                framebuffer.rewind()
                frame.copyPixelsFromBuffer(framebuffer)
                framebuffer.rewind()
                view.render(frame)

                val audioFrames = NativeBridge.readAudio(samples)
                if (!fastForward && audioFrames > 0) {
                    audio.write(samples, 0, audioFrames * 2, AudioTrack.WRITE_BLOCKING)
                }

                if (fastForward) {
                    nextFrame = System.nanoTime()
                } else {
                    nextFrame += FRAME_NANOS
                    val wait = nextFrame - System.nanoTime()
                    when {
                        wait > 0 -> Thread.sleep(wait / 1_000_000, (wait % 1_000_000).toInt())
                        wait < -FRAME_NANOS * 4 -> nextFrame = System.nanoTime() // fell behind; don't try to catch up
                    }
                }
            }
        } finally {
            audio.stop()
            audio.release()
            NativeBridge.shutdown() // flushes the save file
        }
    }

    private fun createAudioTrack(): AudioTrack {
        val format = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(NativeBridge.SAMPLE_RATE)
            .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
            .build()
        val minBytes = AudioTrack.getMinBufferSize(
            NativeBridge.SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO, AudioFormat.ENCODING_PCM_16BIT
        )
        return AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(format)
            // A few frames of headroom (~800 stereo frames per video frame).
            .setBufferSizeInBytes(maxOf(minBytes * 2, 800 * 4 * 4))
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)
            .build()
    }

    companion object {
        /** The DS refreshes at 33513982 Hz / (6 * 355 * 263) ≈ 59.8261 Hz. */
        private const val FRAME_NANOS = 16_715_282L
    }
}
