package com.hgengine.android

import android.content.Context
import android.net.Uri
import java.io.File
import java.io.IOException
import java.util.zip.CRC32

/**
 * Where the game's files live inside the app's private storage, and how they get there.
 *
 * Two ways to provide the game:
 *  - Patch mode: the APK bundles `assets/hg-engine.bps`. The player picks a clean
 *    HeartGold ROM once; it's kept as base.nds so app updates can re-patch automatically.
 *  - Prebuilt mode: the player picks an already-built hg-engine ROM (test.nds).
 */
class GameFiles(private val context: Context) {
    val dir: File = context.filesDir
    val baseRom = File(dir, "base.nds")
    val gameRom = File(dir, "game.nds")
    val save = File(dir, "game.sav")

    private val prefs = context.getSharedPreferences("hgengine", Context.MODE_PRIVATE)

    fun stateFile(slot: Int) = File(dir, "state$slot.mln")

    var useJit: Boolean
        get() = prefs.getBoolean("jit", true)
        set(value) = prefs.edit().putBoolean("jit", value).apply()

    /** CRC of the patch game.nds was built from, or "prebuilt". */
    private var gameSource: String?
        get() = prefs.getString("gameSource", null)
        set(value) = prefs.edit().putString("gameSource", value).apply()

    val hasBundledPatch: Boolean by lazy {
        context.assets.list("")?.contains(PATCH_ASSET) == true
    }

    val isPrebuilt: Boolean get() = gameSource == PREBUILT && gameRom.exists()

    /** Copies the bundled patch to a cache file and returns it with its CRC32. */
    private fun extractPatch(): Pair<File, String> {
        val out = File(context.cacheDir, PATCH_ASSET)
        val crc = CRC32()
        context.assets.open(PATCH_ASSET).use { input ->
            out.outputStream().use { output ->
                val buf = ByteArray(1 shl 16)
                while (true) {
                    val n = input.read(buf)
                    if (n < 0) break
                    crc.update(buf, 0, n)
                    output.write(buf, 0, n)
                }
            }
        }
        return out to "%08x".format(crc.value)
    }

    /** True when the game is ready to play without any further setup. */
    fun isReady(): Boolean {
        if (!gameRom.exists()) return false
        if (isPrebuilt) return true
        return hasBundledPatch && gameSource == bundledPatchId
    }

    private val bundledPatchId: String? by lazy {
        if (!hasBundledPatch) null else extractPatch().second
    }

    /** True when the bundled patch changed (app update) and we still have the base ROM to re-apply it. */
    fun needsRepatch(): Boolean =
        hasBundledPatch && !isPrebuilt && baseRom.exists() && gameSource != bundledPatchId

    /** Builds game.nds from base.nds and the bundled patch. Returns an error message or null. Slow: call off the UI thread. */
    fun applyBundledPatch(): String? {
        val (patch, id) = try {
            extractPatch()
        } catch (e: IOException) {
            return "Couldn't read the bundled patch: ${e.message}"
        }
        val tmp = File(dir, "game.nds.tmp")
        val error = NativeBridge.applyBpsPatch(baseRom.path, patch.path, tmp.path)
        patch.delete()
        if (error != null) {
            tmp.delete()
            return error
        }
        if (!tmp.renameTo(gameRom)) return "Couldn't save the patched game."
        gameSource = id
        return null
    }

    /** Copies a user-picked ROM into place. Returns an error message or null. */
    fun importRom(uri: Uri, prebuilt: Boolean): String? {
        val dest = if (prebuilt) gameRom else baseRom
        val tmp = File(dir, dest.name + ".tmp")
        try {
            val stream = context.contentResolver.openInputStream(uri)
                ?: return "Couldn't open the selected file."
            stream.use { input -> tmp.outputStream().use { input.copyTo(it, 1 shl 16) } }
        } catch (e: IOException) {
            tmp.delete()
            return "Couldn't copy the selected file: ${e.message}"
        }
        if (!looksLikeHeartGold(tmp, usaOnly = !prebuilt)) {
            tmp.delete()
            return if (prebuilt) "That doesn't look like a HeartGold-based DS ROM."
            else "That doesn't look like an English Pokémon HeartGold ROM (game code IPKE)."
        }
        if (!tmp.renameTo(dest)) return "Couldn't save the selected file."
        if (prebuilt) gameSource = PREBUILT else gameSource = null
        return null
    }

    fun importSave(uri: Uri): String? {
        val tmp = File(dir, "game.sav.tmp")
        try {
            val stream = context.contentResolver.openInputStream(uri) ?: return "Couldn't open the save file."
            stream.use { input -> tmp.outputStream().use { input.copyTo(it) } }
        } catch (e: IOException) {
            tmp.delete()
            return "Couldn't import the save: ${e.message}"
        }
        if (tmp.length() == 0L) {
            tmp.delete()
            return "The save file is empty."
        }
        return if (tmp.renameTo(save)) null else "Couldn't replace the save file."
    }

    fun exportSave(uri: Uri): String? {
        if (!save.exists()) return "There's no save file yet."
        return try {
            val stream = context.contentResolver.openOutputStream(uri, "wt") ?: return "Couldn't create the file."
            stream.use { output -> save.inputStream().use { it.copyTo(output) } }
            null
        } catch (e: IOException) {
            "Couldn't export the save: ${e.message}"
        }
    }

    private fun looksLikeHeartGold(file: File, usaOnly: Boolean): Boolean {
        if (file.length() < 0x200) return false
        val header = ByteArray(0x10)
        file.inputStream().use { if (it.read(header) != header.size) return false }
        // hg-engine keeps HeartGold's game code (IPKE = English/USA).
        val code = String(header, 0x0C, 4, Charsets.US_ASCII)
        return if (usaOnly) code == "IPKE" else code.startsWith("IPK")
    }

    companion object {
        const val PATCH_ASSET = "hg-engine.bps"
        private const val PREBUILT = "prebuilt"
    }
}
