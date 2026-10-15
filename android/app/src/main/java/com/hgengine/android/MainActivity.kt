package com.hgengine.android

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.graphics.Typeface
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.CheckBox
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import kotlin.concurrent.thread

/** Setup screen: get a playable game.nds in place, manage saves, then launch [GameActivity]. */
class MainActivity : Activity() {
    private lateinit var files: GameFiles
    private lateinit var status: TextView
    private lateinit var progress: ProgressBar
    private lateinit var playButton: Button
    private lateinit var pickBaseButton: Button
    private lateinit var pickPrebuiltButton: Button
    private lateinit var saveButtons: LinearLayout
    private var busy = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        files = GameFiles(this)
        NativeBridge.setDataDirectory(files.dir.path)
        setContentView(buildUi())
    }

    override fun onResume() {
        super.onResume()
        refresh()
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    private fun buildUi(): View {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(32), dp(24), dp(24))
        }
        root.addView(TextView(this).apply {
            text = getString(R.string.app_name)
            textSize = 30f
            typeface = Typeface.DEFAULT_BOLD
        })
        root.addView(TextView(this).apply {
            text = getString(R.string.tagline)
            setPadding(0, dp(4), 0, dp(24))
        })

        status = TextView(this).apply { textSize = 16f }
        root.addView(status)
        progress = ProgressBar(this).apply { isIndeterminate = true; visibility = View.GONE }
        root.addView(progress)

        playButton = button(R.string.play) {
            startActivity(Intent(this, GameActivity::class.java))
        }.also { root.addView(it, fullWidth(dp(24))) }

        pickBaseButton = button(R.string.pick_base_rom) { pickFile(REQUEST_BASE_ROM) }
            .also { root.addView(it, fullWidth(dp(12))) }
        pickPrebuiltButton = button(R.string.pick_prebuilt_rom) { pickFile(REQUEST_PREBUILT_ROM) }
            .also { root.addView(it, fullWidth(dp(12))) }

        saveButtons = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        saveButtons.addView(button(R.string.import_save) { confirmImportSave() },
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        saveButtons.addView(button(R.string.export_save) { exportSave() },
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        root.addView(saveButtons, fullWidth(dp(24)))

        root.addView(CheckBox(this).apply {
            text = getString(R.string.use_jit)
            isChecked = files.useJit
            setOnCheckedChangeListener { _, checked -> files.useJit = checked }
        }, fullWidth(dp(12)))

        root.addView(TextView(this).apply {
            text = getString(R.string.legal_notice)
            textSize = 12f
            alpha = 0.7f
            gravity = Gravity.START
        }, fullWidth(dp(24)))

        return ScrollView(this).apply { addView(root) }
    }

    private fun fullWidth(topMargin: Int) = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
    ).apply { this.topMargin = topMargin }

    private fun button(textRes: Int, onClick: () -> Unit) = Button(this).apply {
        text = getString(textRes)
        setOnClickListener { if (!busy) onClick() }
    }

    private fun refresh() {
        if (busy) return
        setBusy(true, getString(R.string.checking))
        thread(name = "hge-setup") {
            val ready = files.isReady()
            val repatch = !ready && files.needsRepatch()
            runOnUiThread {
                setBusy(false, null)
                if (repatch) runPatch(updating = true) else showState(ready)
            }
        }
    }

    private fun showState(ready: Boolean) {
        playButton.visibility = if (ready) View.VISIBLE else View.GONE
        pickBaseButton.visibility = if (files.hasBundledPatch) View.VISIBLE else View.GONE
        saveButtons.visibility = if (ready) View.VISIBLE else View.GONE
        pickPrebuiltButton.text = getString(
            if (files.hasBundledPatch) R.string.pick_prebuilt_rom_alt else R.string.pick_prebuilt_rom
        )
        status.text = when {
            ready && files.isPrebuilt -> getString(R.string.status_ready_prebuilt)
            ready -> getString(R.string.status_ready)
            files.hasBundledPatch -> getString(R.string.status_need_base)
            else -> getString(R.string.status_need_prebuilt)
        }
    }

    private fun setBusy(isBusy: Boolean, message: String?) {
        busy = isBusy
        progress.visibility = if (isBusy) View.VISIBLE else View.GONE
        if (message != null) status.text = message
        if (isBusy) {
            playButton.visibility = View.GONE
            saveButtons.visibility = View.GONE
        }
        for (b in listOf(pickBaseButton, pickPrebuiltButton)) b.isEnabled = !isBusy
    }

    private fun runPatch(updating: Boolean) {
        setBusy(true, getString(if (updating) R.string.status_updating else R.string.status_patching))
        thread(name = "hge-patch") {
            val error = files.applyBundledPatch()
            runOnUiThread {
                setBusy(false, null)
                if (error != null) showError(error)
                refresh()
            }
        }
    }

    private fun pickFile(request: Int) {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
        }
        startActivityForResult(intent, request)
    }

    private fun confirmImportSave() {
        AlertDialog.Builder(this)
            .setTitle(R.string.import_save)
            .setMessage(R.string.import_save_warning)
            .setPositiveButton(R.string.import_save) { _, _ -> pickFile(REQUEST_IMPORT_SAVE) }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun exportSave() {
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/octet-stream"
            putExtra(Intent.EXTRA_TITLE, "hg-engine.sav")
        }
        startActivityForResult(intent, REQUEST_EXPORT_SAVE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val uri: Uri = data?.data ?: return
        if (resultCode != RESULT_OK) return

        setBusy(true, getString(R.string.status_copying))
        thread(name = "hge-import") {
            val error = when (requestCode) {
                REQUEST_BASE_ROM -> files.importRom(uri, prebuilt = false)
                REQUEST_PREBUILT_ROM -> files.importRom(uri, prebuilt = true)
                REQUEST_IMPORT_SAVE -> files.importSave(uri)
                REQUEST_EXPORT_SAVE -> files.exportSave(uri)
                else -> null
            }
            runOnUiThread {
                setBusy(false, null)
                when {
                    error != null -> { showError(error); refresh() }
                    requestCode == REQUEST_BASE_ROM -> runPatch(updating = false)
                    requestCode == REQUEST_EXPORT_SAVE -> { status.text = getString(R.string.save_exported); showState(true) }
                    requestCode == REQUEST_IMPORT_SAVE -> { refresh(); status.text = getString(R.string.save_imported) }
                    else -> refresh()
                }
            }
        }
    }

    private fun showError(message: String) {
        AlertDialog.Builder(this)
            .setTitle(R.string.error_title)
            .setMessage(message)
            .setPositiveButton(android.R.string.ok, null)
            .show()
    }

    companion object {
        private const val REQUEST_BASE_ROM = 1
        private const val REQUEST_PREBUILT_ROM = 2
        private const val REQUEST_IMPORT_SAVE = 3
        private const val REQUEST_EXPORT_SAVE = 4
    }
}
