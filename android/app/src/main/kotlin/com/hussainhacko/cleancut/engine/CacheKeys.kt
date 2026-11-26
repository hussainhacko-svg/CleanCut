package com.hussainhacko.cleancut.engine

import java.security.MessageDigest

/** File names for the thumbnail and waveform disk caches. */
object CacheKeys {
    /** Thumbnail times are bucketed so near-identical requests share a file. */
    const val THUMB_BUCKET_US = 10_000L

    /** Rounds [timeUs] to the nearest bucket (never negative). */
    fun bucketUs(timeUs: Long): Long =
        ((timeUs.coerceAtLeast(0) + THUMB_BUCKET_US / 2) / THUMB_BUCKET_US) * THUMB_BUCKET_US

    /** Cache file name of a frame; stills ignore the time. */
    fun thumbnail(uri: String, timeUs: Long, heightPx: Int, isImage: Boolean): String {
        val time = if (isImage) 0 else bucketUs(timeUs)
        return "${sha1("thumb|$uri|$heightPx|$time")}.jpg"
    }

    /** Cache file name of a waveform. */
    fun waveform(uri: String, peaksPerSecond: Int): String =
        "${sha1("wave|$uri|$peaksPerSecond")}.wave"

    private fun sha1(text: String): String =
        MessageDigest.getInstance("SHA-1")
            .digest(text.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
}
