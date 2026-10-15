package com.hgengine.android

import android.app.Activity
import android.app.AlertDialog
import android.os.Build
import android.os.Bundle
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.widget.Toast

/** Fullscreen gameplay: hosts [EmulatorView], maps keyboard/gamepad input and shows the pause menu. */
class GameActivity : Activity() {
    private lateinit var files: GameFiles
    private lateinit var view: EmulatorView
    private val input = InputState()
    private var emulator: EmulatorThread? = null
    private var menuOpen = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        files = GameFiles(this)
        if (!files.gameRom.exists()) {
            finish()
            return
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        view = EmulatorView(this, input) { showMenu() }
        setContentView(view)
        view.requestFocus()

        emulator = EmulatorThread(files, view, input) { error ->
            runOnUiThread {
                AlertDialog.Builder(this)
                    .setTitle(R.string.error_title)
                    .setMessage(error)
                    .setPositiveButton(android.R.string.ok) { _, _ -> finish() }
                    .setCancelable(false)
                    .show()
            }
        }.also { it.start() }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideSystemBars()
    }

    @Suppress("DEPRECATION")
    private fun hideSystemBars() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.let {
                it.hide(WindowInsets.Type.systemBars())
                it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                or View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION)
        }
    }

    override fun onPause() {
        super.onPause()
        input.clear()
        emulator?.let {
            it.setPaused(true)
            it.post { NativeBridge.flushSave() }
        }
    }

    override fun onResume() {
        super.onResume()
        if (!menuOpen) emulator?.setPaused(false)
    }

    override fun onDestroy() {
        super.onDestroy()
        emulator?.let {
            it.quit()
            it.join(3000)
        }
        emulator = null
    }

    // ---- Pause menu ---------------------------------------------------------

    private fun showMenu() {
        val emu = emulator ?: return
        if (menuOpen) return
        menuOpen = true
        emu.setPaused(true)
        input.clear()

        val items = arrayOf(
            getString(R.string.menu_resume),
            getString(R.string.menu_save_state),
            getString(R.string.menu_load_state),
            getString(if (emu.fastForward) R.string.menu_fast_forward_off else R.string.menu_fast_forward_on),
            getString(if (view.showControls) R.string.menu_hide_controls else R.string.menu_show_controls),
            getString(R.string.menu_quit),
        )
        AlertDialog.Builder(this)
            .setItems(items) { _, which ->
                when (which) {
                    1 -> { pickSlot(save = true); return@setItems }
                    2 -> { pickSlot(save = false); return@setItems }
                    3 -> emu.fastForward = !emu.fastForward
                    4 -> view.showControls = !view.showControls
                    5 -> { finish(); return@setItems }
                }
                closeMenu()
            }
            .setOnCancelListener { closeMenu() }
            .show()
    }

    private fun closeMenu() {
        menuOpen = false
        emulator?.setPaused(false)
    }

    private fun pickSlot(save: Boolean) {
        val slots = Array(3) { i ->
            val f = files.stateFile(i + 1)
            if (f.exists()) getString(R.string.slot_used, i + 1, java.text.DateFormat.getDateTimeInstance().format(f.lastModified()))
            else getString(R.string.slot_empty, i + 1)
        }
        AlertDialog.Builder(this)
            .setTitle(if (save) R.string.menu_save_state else R.string.menu_load_state)
            .setItems(slots) { _, which ->
                val path = files.stateFile(which + 1).path
                emulator?.post {
                    val error = if (save) NativeBridge.saveState(path) else NativeBridge.loadState(path)
                    runOnUiThread {
                        val msg = error ?: getString(if (save) R.string.state_saved else R.string.state_loaded, which + 1)
                        Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()
                    }
                }
                closeMenu()
            }
            .setOnCancelListener { closeMenu() }
            .show()
    }

    // ---- Keyboard / gamepad -------------------------------------------------

    private fun buttonFor(keyCode: Int): Int = when (keyCode) {
        KeyEvent.KEYCODE_BUTTON_A, KeyEvent.KEYCODE_X -> NativeBridge.BTN_A
        KeyEvent.KEYCODE_BUTTON_B, KeyEvent.KEYCODE_Z -> NativeBridge.BTN_B
        KeyEvent.KEYCODE_BUTTON_X, KeyEvent.KEYCODE_S -> NativeBridge.BTN_X
        KeyEvent.KEYCODE_BUTTON_Y, KeyEvent.KEYCODE_A -> NativeBridge.BTN_Y
        KeyEvent.KEYCODE_BUTTON_L1, KeyEvent.KEYCODE_Q -> NativeBridge.BTN_L
        KeyEvent.KEYCODE_BUTTON_R1, KeyEvent.KEYCODE_W -> NativeBridge.BTN_R
        KeyEvent.KEYCODE_BUTTON_START, KeyEvent.KEYCODE_ENTER -> NativeBridge.BTN_START
        KeyEvent.KEYCODE_BUTTON_SELECT, KeyEvent.KEYCODE_SHIFT_RIGHT, KeyEvent.KEYCODE_DEL -> NativeBridge.BTN_SELECT
        KeyEvent.KEYCODE_DPAD_UP -> NativeBridge.BTN_UP
        KeyEvent.KEYCODE_DPAD_DOWN -> NativeBridge.BTN_DOWN
        KeyEvent.KEYCODE_DPAD_LEFT -> NativeBridge.BTN_LEFT
        KeyEvent.KEYCODE_DPAD_RIGHT -> NativeBridge.BTN_RIGHT
        else -> 0
    }

    private fun isMenuKey(keyCode: Int) = keyCode == KeyEvent.KEYCODE_BACK ||
        keyCode == KeyEvent.KEYCODE_BUTTON_MODE || keyCode == KeyEvent.KEYCODE_ESCAPE ||
        keyCode == KeyEvent.KEYCODE_MENU

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        if (isMenuKey(keyCode)) {
            if (event.repeatCount == 0) showMenu()
            return true
        }
        val mask = buttonFor(keyCode)
        if (mask == 0) return super.onKeyDown(keyCode, event)
        if (event.isFromSource(InputDevice.SOURCE_GAMEPAD)) view.showControls = false
        input.setKey(mask, true)
        return true
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean {
        if (isMenuKey(keyCode)) return true
        val mask = buttonFor(keyCode)
        if (mask == 0) return super.onKeyUp(keyCode, event)
        input.setKey(mask, false)
        return true
    }

    override fun onGenericMotionEvent(event: MotionEvent): Boolean {
        if (!event.isFromSource(InputDevice.SOURCE_JOYSTICK) || event.actionMasked != MotionEvent.ACTION_MOVE) {
            return super.onGenericMotionEvent(event)
        }
        val x = event.getAxisValue(MotionEvent.AXIS_X) + event.getAxisValue(MotionEvent.AXIS_HAT_X)
        val y = event.getAxisValue(MotionEvent.AXIS_Y) + event.getAxisValue(MotionEvent.AXIS_HAT_Y)
        var mask = 0
        if (x < -STICK_DEADZONE) mask = mask or NativeBridge.BTN_LEFT
        if (x > STICK_DEADZONE) mask = mask or NativeBridge.BTN_RIGHT
        if (y < -STICK_DEADZONE) mask = mask or NativeBridge.BTN_UP
        if (y > STICK_DEADZONE) mask = mask or NativeBridge.BTN_DOWN
        if (mask != 0) view.showControls = false
        input.setStickButtons(mask)
        return true
    }

    companion object {
        private const val STICK_DEADZONE = 0.5f
    }
}
