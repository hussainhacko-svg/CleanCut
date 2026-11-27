package com.hussainhacko.cleancut.engine

import android.content.Context
import android.util.Log
import java.security.MessageDigest
import java.util.concurrent.ConcurrentHashMap

/**
 * Process-wide cache of the bundled `.cube` LUTs (`assets/luts/<id>.cube`), shared by
 * [ClipRenderEffect] (preview + export) and [FilterPreviewGenerator] (thumbnails).
 *
 * Loading reads and parses a text file, so call [get] off the GL thread first (see
 * `EngineHost.setComposition`); the GL thread then only uploads the parsed table.
 */
object LutLibrary {
    /** A parsed LUT plus a hash of its asset text, so cached thumbnails follow LUT edits. */
    class Entry(val lut: CubeLut, val contentHash: String)

    private const val TAG = "CleanCutFilters"
    private val SAFE_ID = Regex("^[a-z0-9_]+$")

    private val loaded = ConcurrentHashMap<String, Entry>()
    private val failed: MutableSet<String> = ConcurrentHashMap.newKeySet()

    /** The LUT [id], loading it on first use; null when the id is unsafe, missing or invalid. */
    fun get(context: Context, id: String): Entry? {
        loaded[id]?.let { return it }
        if (id in failed) return null
        if (!SAFE_ID.matches(id)) {
            failed += id
            return null
        }
        val entry = runCatching {
            val text = context.assets.open("luts/$id.cube").bufferedReader().use { it.readText() }
            Entry(CubeLut.parse(text), sha1(text))
        }.onFailure { Log.w(TAG, "LUT asset luts/$id.cube could not be loaded", it) }.getOrNull()
        if (entry == null) {
            failed += id
            return null
        }
        return loaded.putIfAbsent(id, entry) ?: entry
    }

    private fun sha1(text: String): String =
        MessageDigest.getInstance("SHA-1")
            .digest(text.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
}
