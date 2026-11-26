package com.hussainhacko.cleancut.media

import android.app.Activity
import android.content.ClipData
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.media.ExifInterface
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.ext.SdkExtensions
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Log
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Opens the system Photo Picker (or the document picker on devices without it),
 * persists read access to the picked URIs and reads their metadata.
 *
 * Media is never copied: callers keep the content URI.
 */
class MediaPicker(private val activity: Activity) : MediaPickerHostApi {
    private var pending: CompletableDeferred<List<Uri>>? = null

    override suspend fun pickVisualMedia(allowMultiple: Boolean): List<PickedMedia> {
        check(pending == null) { "A media picker is already open" }
        val result = CompletableDeferred<List<Uri>>()
        pending = result
        try {
            @Suppress("DEPRECATION") // FlutterActivity has no ActivityResult registry.
            activity.startActivityForResult(buildIntent(allowMultiple), REQUEST_CODE)
        } catch (e: Exception) {
            pending = null
            throw e
        }
        val uris = result.await()
        return withContext(Dispatchers.IO) {
            uris.mapNotNull { uri ->
                persistReadPermission(activity.contentResolver, uri)
                readMetadata(activity, uri)
            }
        }
    }

    /** Forward from the activity; returns true when the result was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val deferred = pending ?: return true
        pending = null
        deferred.complete(if (resultCode == Activity.RESULT_OK) urisOf(data) else emptyList())
        return true
    }

    /** Cancels an open request, e.g. when the activity is destroyed. */
    fun dispose() {
        pending?.complete(emptyList())
        pending = null
    }

    private fun buildIntent(allowMultiple: Boolean): Intent =
        if (isPhotoPickerAvailable()) {
            // No type: the picker shows both images and videos.
            Intent(MediaStore.ACTION_PICK_IMAGES).apply {
                if (allowMultiple) {
                    putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, MediaStore.getPickImagesMaxLimit())
                }
            }
        } else {
            Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
                putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("video/*", "image/*"))
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, allowMultiple)
                addFlags(
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
                )
            }
        }

    companion object {
        private const val TAG = "CleanCutMediaPicker"
        private const val REQUEST_CODE = 0xC1C7

        /** Photo Picker exists on API 33+, and on API 30–32 via SDK extension 2. */
        fun isPhotoPickerAvailable(): Boolean =
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
                    SdkExtensions.getExtensionVersion(Build.VERSION_CODES.R) >= 2)

        internal fun urisOf(data: Intent?): List<Uri> {
            if (data == null) return emptyList()
            val clip: ClipData? = data.clipData
            if (clip != null) return List(clip.itemCount) { clip.getItemAt(it).uri }
            return listOfNotNull(data.data)
        }

        private fun persistReadPermission(resolver: ContentResolver, uri: Uri) {
            try {
                resolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } catch (e: SecurityException) {
                // Still readable for this session; the editor reports it later if lost.
                Log.w(TAG, "Could not persist access to $uri", e)
            }
        }

        private fun readMetadata(context: Context, uri: Uri): PickedMedia? = try {
            val mime = context.contentResolver.getType(uri).orEmpty()
            val name = displayName(context.contentResolver, uri)
            when {
                mime.startsWith("video/") -> readVideo(context, uri, name)
                mime.startsWith("image/") -> readImage(context.contentResolver, uri, name)
                else -> null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not read metadata of $uri", e)
            null
        }

        private fun readVideo(context: Context, uri: Uri, name: String?): PickedMedia? {
            val retriever = MediaMetadataRetriever()
            try {
                retriever.setDataSource(context, uri)
                fun key(k: Int) = retriever.extractMetadata(k)?.toLongOrNull()
                val durationMs = key(MediaMetadataRetriever.METADATA_KEY_DURATION) ?: return null
                if (durationMs <= 0) return null
                return PickedMedia(
                    uri = uri.toString(),
                    kind = PickedMediaKind.VIDEO,
                    durationUs = durationMs * 1000,
                    width = key(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH) ?: 0,
                    height = key(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT) ?: 0,
                    rotationDegrees = key(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION) ?: 0,
                    displayName = name,
                )
            } finally {
                retriever.release()
            }
        }

        private fun readImage(resolver: ContentResolver, uri: Uri, name: String?): PickedMedia? {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            // With inJustDecodeBounds, decodeStream always returns null; only the
            // stream itself being null means the file can't be read.
            val stream = resolver.openInputStream(uri) ?: return null
            stream.use { BitmapFactory.decodeStream(it, null, bounds) }
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
            // Unreadable EXIF (some PNG/WebP streams) means "no rotation", not
            // "drop the photo".
            val rotation = runCatching { exifRotation(resolver, uri) }.getOrDefault(0)
            return PickedMedia(
                uri = uri.toString(),
                kind = PickedMediaKind.IMAGE,
                width = bounds.outWidth.toLong(),
                height = bounds.outHeight.toLong(),
                rotationDegrees = rotation.toLong(),
                displayName = name,
            )
        }

        private fun exifRotation(resolver: ContentResolver, uri: Uri): Int =
            resolver.openInputStream(uri)?.use { stream ->
                when (
                    ExifInterface(stream).getAttributeInt(
                        ExifInterface.TAG_ORIENTATION,
                        ExifInterface.ORIENTATION_NORMAL,
                    )
                ) {
                    // Mirrored orientations keep their rotation; the mirror is ignored for now.
                    ExifInterface.ORIENTATION_ROTATE_90, ExifInterface.ORIENTATION_TRANSPOSE -> 90
                    ExifInterface.ORIENTATION_ROTATE_180, ExifInterface.ORIENTATION_FLIP_VERTICAL -> 180
                    ExifInterface.ORIENTATION_ROTATE_270, ExifInterface.ORIENTATION_TRANSVERSE -> 270
                    else -> 0
                }
            } ?: 0

        private fun displayName(resolver: ContentResolver, uri: Uri): String? =
            resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { c -> if (c.moveToFirst()) c.getString(0) else null }
    }
}
