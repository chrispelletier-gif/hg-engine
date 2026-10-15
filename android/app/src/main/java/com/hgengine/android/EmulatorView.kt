package com.hgengine.android

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.view.MotionEvent
import android.view.SurfaceHolder
import android.view.SurfaceView
import kotlin.math.atan2
import kotlin.math.hypot

/**
 * Draws both DS screens plus the touch controls, and turns touches into DS
 * buttons / stylus input. Rendering happens on the emulation thread via [render].
 */
@SuppressLint("ViewConstructor")
class EmulatorView(context: Context, private val input: InputState, private val onMenu: () -> Unit) :
    SurfaceView(context), SurfaceHolder.Callback {

    @Volatile
    private var layout: ScreenLayout? = null

    @Volatile
    var showControls = true

    private val topSrc = Rect(0, 0, NativeBridge.SCREEN_WIDTH, NativeBridge.SCREEN_HEIGHT)
    private val bottomSrc = Rect(0, NativeBridge.SCREEN_HEIGHT, NativeBridge.SCREEN_WIDTH, NativeBridge.SCREEN_HEIGHT * 2)
    private val screenPaint = Paint().apply { isFilterBitmap = true }
    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(70, 255, 255, 255) }
    private val pressedPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(140, 255, 255, 255) }
    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.argb(150, 255, 255, 255)
        style = Paint.Style.STROKE
        strokeWidth = 2f * resources.displayMetrics.density
    }
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.argb(200, 255, 255, 255)
        textAlign = Paint.Align.CENTER
        isFakeBoldText = true
    }

    /** Pointer id that is currently acting as the DS stylus, or -1. */
    private var stylusPointer = -1
    private var menuPointer = -1

    init {
        holder.addCallback(this)
        isFocusable = true
    }

    override fun surfaceCreated(holder: SurfaceHolder) {}

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        layout = ScreenLayout(width, height)
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        layout = null
    }

    /** Called from the emulation thread with the latest 256x384 frame. */
    fun render(frame: Bitmap) {
        val l = layout ?: return
        val canvas = try {
            holder.lockHardwareCanvas() // GPU-scaled; minSdk 26
        } catch (e: IllegalStateException) {
            null
        } ?: return
        try {
            canvas.drawColor(Color.BLACK)
            canvas.drawBitmap(frame, topSrc, l.topScreen, screenPaint)
            canvas.drawBitmap(frame, bottomSrc, l.bottomScreen, screenPaint)
            if (showControls) drawControls(canvas, l)
        } finally {
            holder.unlockCanvasAndPost(canvas)
        }
    }

    private fun drawControls(canvas: android.graphics.Canvas, l: ScreenLayout) {
        val pressed = input.buttons

        // D-pad: a ring with four arrow segments.
        val c = l.dpadCenter
        val r = l.dpadRadius
        canvas.drawCircle(c.x, c.y, r, fillPaint)
        canvas.drawCircle(c.x, c.y, r, strokePaint)
        textPaint.textSize = r * 0.32f
        val dirs = listOf(
            Triple(NativeBridge.BTN_UP, 0f, -1f), Triple(NativeBridge.BTN_DOWN, 0f, 1f),
            Triple(NativeBridge.BTN_LEFT, -1f, 0f), Triple(NativeBridge.BTN_RIGHT, 1f, 0f),
        )
        val arrows = mapOf(NativeBridge.BTN_UP to "▲", NativeBridge.BTN_DOWN to "▼", NativeBridge.BTN_LEFT to "◀", NativeBridge.BTN_RIGHT to "▶")
        for ((mask, dx, dy) in dirs) {
            val x = c.x + dx * r * 0.62f
            val y = c.y + dy * r * 0.62f
            if (pressed and mask != 0) canvas.drawCircle(x, y, r * 0.3f, pressedPaint)
            canvas.drawText(arrows.getValue(mask), x, y + textPaint.textSize * 0.35f, textPaint)
        }

        for (b in l.buttons + l.menuButton) {
            val paint = if (b.mask != 0 && pressed and b.mask != 0) pressedPaint else fillPaint
            val bounds = b.bounds
            if (b.pill) {
                val radius = bounds.height() / 2
                canvas.drawRoundRect(bounds, radius, radius, paint)
                canvas.drawRoundRect(bounds, radius, radius, strokePaint)
                textPaint.textSize = bounds.height() * (if (b.label.length > 3) 0.38f else 0.5f)
            } else {
                canvas.drawCircle(b.center.x, b.center.y, b.radius, paint)
                canvas.drawCircle(b.center.x, b.center.y, b.radius, strokePaint)
                textPaint.textSize = b.radius * 0.9f
            }
            canvas.drawText(b.label, bounds.centerX(), bounds.centerY() + textPaint.textSize * 0.35f, textPaint)
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent): Boolean {
        val l = layout ?: return true
        val action = event.actionMasked
        val actionIndex = event.actionIndex

        if (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_POINTER_DOWN) {
            val id = event.getPointerId(actionIndex)
            val x = event.getX(actionIndex)
            val y = event.getY(actionIndex)
            if (showControls && l.menuButton.hit(x, y, 0f)) {
                menuPointer = id
            } else if (stylusPointer == -1 && l.bottomScreen.contains(x, y) && !(showControls && hitsControl(l, x, y))) {
                stylusPointer = id
            }
        }

        val lifted = if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_POINTER_UP) event.getPointerId(actionIndex) else -1
        if (action == MotionEvent.ACTION_CANCEL) {
            stylusPointer = -1
            menuPointer = -1
            input.setTouch(false, 0, 0)
            input.setTouchButtons(0)
            return true
        }

        var mask = 0
        var stylusSeen = false
        for (i in 0 until event.pointerCount) {
            val id = event.getPointerId(i)
            if (id == lifted) continue
            val x = event.getX(i)
            val y = event.getY(i)
            when (id) {
                stylusPointer -> {
                    stylusSeen = true
                    val sx = ((x - l.bottomScreen.left) / l.bottomScreen.width() * NativeBridge.SCREEN_WIDTH).toInt()
                    val sy = ((y - l.bottomScreen.top) / l.bottomScreen.height() * NativeBridge.SCREEN_HEIGHT).toInt()
                    input.setTouch(true, sx.coerceIn(0, NativeBridge.SCREEN_WIDTH - 1), sy.coerceIn(0, NativeBridge.SCREEN_HEIGHT - 1))
                }
                menuPointer -> {}
                else -> {
                    if (showControls) mask = mask or controlsAt(l, x, y)
                }
            }
        }
        if (!stylusSeen && stylusPointer != -1) {
            stylusPointer = -1
            input.setTouch(false, 0, 0)
        }
        if (lifted != -1 && lifted == menuPointer) {
            menuPointer = -1
            if (l.menuButton.hit(event.getX(actionIndex), event.getY(actionIndex), l.menuButton.radius)) onMenu()
        }
        input.setTouchButtons(mask)
        return true
    }

    private fun hitsControl(l: ScreenLayout, x: Float, y: Float) = controlsAt(l, x, y) != 0

    /** Buttons under a finger at (x, y). The D-pad supports diagonals and sliding. */
    private fun controlsAt(l: ScreenLayout, x: Float, y: Float): Int {
        var mask = 0
        val dx = x - l.dpadCenter.x
        val dy = y - l.dpadCenter.y
        val dist = hypot(dx, dy)
        if (dist <= l.dpadRadius * 1.25f && dist > l.dpadRadius * 0.15f) {
            // Split the circle into 8 sectors; diagonals press two directions.
            val angle = Math.toDegrees(atan2(dy.toDouble(), dx.toDouble())) // 0 = right, 90 = down
            val sector = (((angle + 360 + 22.5) % 360) / 45).toInt()
            mask = mask or when (sector) {
                0 -> NativeBridge.BTN_RIGHT
                1 -> NativeBridge.BTN_RIGHT or NativeBridge.BTN_DOWN
                2 -> NativeBridge.BTN_DOWN
                3 -> NativeBridge.BTN_DOWN or NativeBridge.BTN_LEFT
                4 -> NativeBridge.BTN_LEFT
                5 -> NativeBridge.BTN_LEFT or NativeBridge.BTN_UP
                6 -> NativeBridge.BTN_UP
                else -> NativeBridge.BTN_UP or NativeBridge.BTN_RIGHT
            }
        }
        for (b in l.buttons) {
            if (b.hit(x, y, b.radius * 0.25f)) mask = mask or b.mask
        }
        return mask
    }
}
