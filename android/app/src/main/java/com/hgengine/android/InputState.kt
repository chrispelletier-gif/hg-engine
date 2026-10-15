package com.hgengine.android

import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/**
 * Input shared between the UI thread (touch, keys, gamepad) and the emulation
 * thread, which pushes it into the core once per frame.
 */
class InputState {
    private val touchButtons = AtomicInteger(0)
    private val keyButtons = AtomicInteger(0)
    private val stickButtons = AtomicInteger(0)

    /** Packed DS touchscreen state: bit 32 = pressed, bits 16..31 = x, bits 0..15 = y. */
    private val touchPoint = AtomicLong(0)

    val buttons: Int get() = touchButtons.get() or keyButtons.get() or stickButtons.get()

    fun setTouchButtons(mask: Int) = touchButtons.set(mask)
    fun setStickButtons(mask: Int) = stickButtons.set(mask)

    fun setKey(mask: Int, down: Boolean) {
        while (true) {
            val old = keyButtons.get()
            val new = if (down) old or mask else old and mask.inv()
            if (keyButtons.compareAndSet(old, new)) return
        }
    }

    fun setTouch(down: Boolean, x: Int, y: Int) {
        touchPoint.set(if (down) (1L shl 32) or (x.toLong() shl 16) or y.toLong() else 0L)
    }

    /** Reads the touch state atomically; decode with [isDown], [xOf], [yOf]. */
    fun touchSnapshot(): Long = touchPoint.get()

    companion object {
        fun isDown(touch: Long) = touch and (1L shl 32) != 0L
        fun xOf(touch: Long) = ((touch shr 16) and 0xFFFF).toInt()
        fun yOf(touch: Long) = (touch and 0xFFFF).toInt()
    }

    fun clear() {
        touchButtons.set(0)
        keyButtons.set(0)
        stickButtons.set(0)
        touchPoint.set(0)
    }
}
