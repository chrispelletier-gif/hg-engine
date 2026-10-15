package com.hgengine.android

import android.graphics.PointF
import android.graphics.RectF
import kotlin.math.min

/** A circular on-screen control. */
data class TouchButton(val label: String, val mask: Int, val center: PointF, val radius: Float, val pill: Boolean = false) {
    val bounds: RectF
        get() = if (pill) RectF(center.x - radius * 1.6f, center.y - radius * 0.7f, center.x + radius * 1.6f, center.y + radius * 0.7f)
        else RectF(center.x - radius, center.y - radius, center.x + radius, center.y + radius)

    fun hit(x: Float, y: Float, slop: Float): Boolean {
        val b = bounds
        return x >= b.left - slop && x <= b.right + slop && y >= b.top - slop && y <= b.bottom + slop
    }
}

/**
 * Positions of both DS screens and the touch controls for a given surface size.
 * Portrait stacks the screens with controls underneath (overlapping the bottom
 * screen when space is short); landscape puts the screens side by side with the
 * controls floating over the edges.
 */
class ScreenLayout(val width: Int, val height: Int) {
    val topScreen = RectF()
    val bottomScreen = RectF()
    val dpadCenter = PointF()
    var dpadRadius = 0f
    val buttons = mutableListOf<TouchButton>()
    lateinit var menuButton: TouchButton
        private set

    init {
        val w = width.toFloat()
        val h = height.toFloat()
        val aspect = NativeBridge.SCREEN_WIDTH.toFloat() / NativeBridge.SCREEN_HEIGHT
        val controlSize = min(w, h) * 0.13f // radius of the face-button cluster unit

        if (h >= w) {
            // Portrait: screens stacked at the top, controls in the remaining space.
            val screenW = min(w, h * 0.62f / 2 * aspect)
            val screenH = screenW / aspect
            val left = (w - screenW) / 2
            topScreen.set(left, 0f, left + screenW, screenH)
            bottomScreen.set(left, screenH, left + screenW, screenH * 2)

            val spare = h - screenH * 2
            val clusterY = if (spare > controlSize * 4.5f) screenH * 2 + spare * 0.45f else h - controlSize * 2.4f
            placeControls(w, h, clusterY, controlSize, shoulderY = clusterY - controlSize * 2.5f)
        } else {
            // Landscape: screens side by side, as large as the height allows.
            val screenH = min(h, w / 2 / aspect)
            val screenW = screenH * aspect
            val left = (w - screenW * 2) / 2
            val top = (h - screenH) / 2
            topScreen.set(left, top, left + screenW, top + screenH)
            bottomScreen.set(left + screenW, top, left + screenW * 2, top + screenH)
            placeControls(w, h, h * 0.62f, controlSize * 0.9f, shoulderY = controlSize * 0.9f)
        }
    }

    private fun placeControls(w: Float, h: Float, clusterY: Float, unit: Float, shoulderY: Float) {
        val margin = unit * 0.35f
        dpadRadius = unit * 1.45f
        dpadCenter.set(margin + dpadRadius, clusterY)

        val faceR = unit * 0.5f
        val faceCx = w - margin - unit * 1.45f
        buttons += TouchButton("X", NativeBridge.BTN_X, PointF(faceCx, clusterY - unit * 0.95f), faceR)
        buttons += TouchButton("B", NativeBridge.BTN_B, PointF(faceCx, clusterY + unit * 0.95f), faceR)
        buttons += TouchButton("Y", NativeBridge.BTN_Y, PointF(faceCx - unit * 0.95f, clusterY), faceR)
        buttons += TouchButton("A", NativeBridge.BTN_A, PointF(faceCx + unit * 0.95f, clusterY), faceR)

        val shoulderR = unit * 0.42f
        val sy = shoulderY.coerceIn(shoulderR, h - shoulderR)
        buttons += TouchButton("L", NativeBridge.BTN_L, PointF(margin + shoulderR * 1.6f, sy), shoulderR, pill = true)
        buttons += TouchButton("R", NativeBridge.BTN_R, PointF(w - margin - shoulderR * 1.6f, sy), shoulderR, pill = true)

        val smallR = unit * 0.3f
        val bottomY = min(h - smallR * 1.4f, clusterY + unit * 1.9f)
        buttons += TouchButton("SELECT", NativeBridge.BTN_SELECT, PointF(w / 2 - smallR * 4.2f, bottomY), smallR, pill = true)
        buttons += TouchButton("START", NativeBridge.BTN_START, PointF(w / 2 + smallR * 4.2f, bottomY), smallR, pill = true)
        menuButton = TouchButton("MENU", 0, PointF(w / 2, bottomY), smallR, pill = true)
    }
}
