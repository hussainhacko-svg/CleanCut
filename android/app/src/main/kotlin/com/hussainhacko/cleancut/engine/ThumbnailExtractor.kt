package com.hussainhacko.cleancut.engine

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.util.Log
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import java.io.File
import kotlin.coroutines.coroutineContext

/**
 * Extracts frames as small JPEGs into `cacheDir/thumbs`, off the main thread.
 * Cached files are reused across sessions.
 */
class ThumbnailExtractor(private val context: Context) {
    private val dir = File(context.cacheDir, "thumbs")

    suspend fun extract(uri: String, timesUs: List<Long>, heightPx: Int): List<String?> =
        withContext(Dispatchers.IO) {
            require(heightPx in 16..1080) { "heightPx must be in 16..1080" }
            dir.mkdirs()
            val parsed = Uri.parse(uri)
            val isImage = runCatching { context.contentResolver.getType(parsed) }
                .getOrNull()?.startsWith("image/") == true
            val files = timesUs.map { File(dir, CacheKeys.thumbnail(uri, it, heightPx, isImage)) }
            if (files.all { it.isFile }) return@withContext files.map { it.path }

            if (isImage) {
                val file = files.firstOrNull() ?: return@withContext emptyList()
                try {
                    if (!file.isFile) decodeImage(parsed, heightPx)?.let { write(it, file) }
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    // Revoked access, a deleted file or unreadable EXIF: no frame.
                    Log.w(TAG, "Could not read image $uri", e)
                }
                return@withContext files.map { if (it.isFile) it.path else null }
            }

            val retriever = MediaMetadataRetriever()
            val keyframes = KeyframeIndex.open(context, parsed)
            try {
                retriever.setDataSource(context, parsed)
                files.mapIndexed { i, file ->
                    coroutineContext.ensureActive()
                    if (!file.isFile) {
                        // The nearest sync frame is fast and usually close enough; when
                        // the keyframe before the target is far away, decode exactly.
                        val exact = ThumbnailTiming.needsExactFrame(
                            timesUs[i],
                            keyframes?.previousSyncUs(timesUs[i]),
                        )
                        val option = if (exact) {
                            MediaMetadataRetriever.OPTION_CLOSEST
                        } else {
                            MediaMetadataRetriever.OPTION_CLOSEST_SYNC
                        }
                        retriever.getScaledFrameAtTime(
                            timesUs[i],
                            option,
                            heightPx * MAX_ASPECT,
                            heightPx,
                        )?.let { write(it, file) }
                    }
                    if (file.isFile) file.path else null
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // Includes IOException from writing the cache file.
                Log.w(TAG, "Could not read frames of $uri", e)
                files.map { if (it.isFile) it.path else null }
            } finally {
                keyframes?.close()
                retriever.release()
            }
        }

    /** Sync-frame times of a video's first video track, read from its index (no decoding). */
    private class KeyframeIndex private constructor(private val extractor: MediaExtractor) {
        /** Time of the sync frame at or before [timeUs], or null when unknown. */
        fun previousSyncUs(timeUs: Long): Long? {
            extractor.seekTo(timeUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
            return extractor.sampleTime.takeIf { it >= 0 }
        }

        fun close() = extractor.release()

        companion object {
            /** Null when the file can't be indexed; callers then use sync frames. */
            fun open(context: Context, uri: Uri): KeyframeIndex? {
                val extractor = MediaExtractor()
                return try {
                    extractor.setDataSource(context, uri, null)
                    val track = (0 until extractor.trackCount).firstOrNull {
                        extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("video/") == true
                    }
                    if (track == null) {
                        extractor.release()
                        null
                    } else {
                        extractor.selectTrack(track)
                        KeyframeIndex(extractor)
                    }
                } catch (e: CancellationException) {
                    extractor.release()
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, "No keyframe index for $uri", e)
                    extractor.release()
                    null
                }
            }
        }
    }

    private fun decodeImage(uri: Uri, heightPx: Int): Bitmap? {
        val resolver = context.contentResolver
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        resolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
        if (bounds.outHeight <= 0) return null
        var sample = 1
        while (bounds.outHeight / (sample * 2) >= heightPx) sample *= 2
        val decoded = resolver.openInputStream(uri)?.use {
            BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = sample })
        } ?: return null
        // Unreadable EXIF means "no rotation", not "no thumbnail".
        val degrees = runCatching { exifDegrees(uri) }.getOrDefault(0)
        val matrix = Matrix().apply {
            postRotate(degrees.toFloat())
            val rotatedHeight = if (degrees % 180 == 0) decoded.height else decoded.width
            val scale = heightPx.toFloat() / rotatedHeight
            postScale(scale, scale)
        }
        val result = Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, matrix, true)
        // createBitmap usually returns a new bitmap; free the full-size decode.
        if (result !== decoded) decoded.recycle()
        return result
    }

    private fun exifDegrees(uri: Uri): Int =
        context.contentResolver.openInputStream(uri)?.use {
            when (ExifInterface(it).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)) {
                ExifInterface.ORIENTATION_ROTATE_90, ExifInterface.ORIENTATION_TRANSPOSE -> 90
                ExifInterface.ORIENTATION_ROTATE_180, ExifInterface.ORIENTATION_FLIP_VERTICAL -> 180
                ExifInterface.ORIENTATION_ROTATE_270, ExifInterface.ORIENTATION_TRANSVERSE -> 270
                else -> 0
            }
        } ?: 0

    private fun write(bitmap: Bitmap, file: File) {
        // A unique temp file per write: concurrent requests for the same frame
        // can't truncate each other, and a half-written file is never cached.
        val tmp = File.createTempFile("thumb", ".tmp", dir)
        try {
            tmp.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, it) }
            if (!tmp.renameTo(file)) tmp.delete()
        } finally {
            if (tmp.exists()) tmp.delete()
            bitmap.recycle()
        }
    }

    private companion object {
        const val TAG = "CleanCutThumbs"
        const val JPEG_QUALITY = 80

        /** Widest frame kept at full height (wider ones are width-limited). */
        const val MAX_ASPECT = 3
    }
}
