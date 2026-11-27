package com.hussainhacko.cleancut.engine

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import java.io.File
import kotlin.coroutines.coroutineContext

/**
 * Generates small LUT-graded JPEG preview thumbnails for the Filters panel on
 * [Dispatchers.IO], cached in `cacheDir/filter_previews`.
 *
 * Uses the same bundled `.cube` LUTs (via [LutLibrary]) as
 * [ClipRenderEffect] so thumbnails match the real-time preview and export.
 */
class FilterPreviewGenerator(
    private val context: Context,
    private val thumbnails: ThumbnailExtractor,
) {
    private val dir = File(context.cacheDir, "filter_previews")

    suspend fun generate(
        uri: String,
        timeUs: Long,
        heightPx: Int,
        filterIds: List<String>,
    ): Map<String, String?> = withContext(Dispatchers.IO) {
        require(heightPx in 16..512) { "heightPx must be in 16..512" }
        if (filterIds.isEmpty()) return@withContext emptyMap()
        dir.mkdirs()

        // Ids whose LUT is missing or invalid get no file and map to null.
        val targets = filterIds.mapNotNull { id ->
            LutLibrary.get(context, id)?.let { entry ->
                id to (entry to File(dir, CacheKeys.filterPreview(uri, timeUs, heightPx, id, entry.contentHash)))
            }
        }.toMap()
        fun result(path: (File) -> String?) = filterIds.associateWith { id -> targets[id]?.second?.let(path) }
        if (targets.values.all { it.second.isFile }) {
            return@withContext result { it.path }
        }

        val basePath = thumbnails.extract(uri, listOf(timeUs), heightPx).firstOrNull()
            ?: return@withContext result { null }

        val source = BitmapFactory.decodeFile(basePath)
            ?: return@withContext result { null }

        try {
            val w = source.width
            val h = source.height
            val pixels = IntArray(w * h)
            source.getPixels(pixels, 0, w, 0, 0, w, h)
            val graded = IntArray(pixels.size)

            for ((entry, file) in targets.values) {
                coroutineContext.ensureActive()
                if (file.isFile) continue
                for (i in pixels.indices) {
                    graded[i] = entry.lut.applyToArgb(pixels[i])
                }
                val outBitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                outBitmap.setPixels(graded, 0, w, 0, 0, w, h)
                write(outBitmap, file)
            }
            result { if (it.isFile) it.path else null }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, "Could not generate filter previews for $uri", e)
            result { if (it.isFile) it.path else null }
        } finally {
            source.recycle()
        }
    }

    private fun write(bitmap: Bitmap, file: File) {
        val tmp = File.createTempFile("fprev", ".tmp", dir)
        try {
            tmp.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, it) }
            if (!tmp.renameTo(file)) tmp.delete()
        } finally {
            if (tmp.exists()) tmp.delete()
            bitmap.recycle()
        }
    }

    private companion object {
        const val TAG = "CleanCutFilters"
        const val JPEG_QUALITY = 82
    }
}
