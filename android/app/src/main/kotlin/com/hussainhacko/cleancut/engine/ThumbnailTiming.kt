package com.hussainhacko.cleancut.engine

/**
 * Chooses between a fast sync-frame grab and an exact (decoded) frame for a
 * timeline thumbnail. Pure Kotlin so it can be unit-tested on the JVM.
 *
 * A sync (key) frame decodes on its own, so grabbing the nearest one is fast,
 * but in videos with sparse keyframes (screen recordings, some exports) it
 * can be many seconds away and every tile shows the same picture. Decoding
 * the exact frame costs one decode per frame since the previous keyframe, so
 * it is only used when that keyframe is too far away to look right.
 */
object ThumbnailTiming {
    /** A keyframe at most this far before the target is shown instead (µs). */
    const val SYNC_TOLERANCE_US = 500_000L

    /**
     * Whether the frame at [targetUs] must be decoded exactly, given the time of
     * the sync frame at or before it ([previousSyncUs]; null or negative when
     * unknown, in which case the fast sync frame is used).
     */
    fun needsExactFrame(targetUs: Long, previousSyncUs: Long?): Boolean {
        if (previousSyncUs == null || previousSyncUs < 0) return false
        return targetUs - previousSyncUs > SYNC_TOLERANCE_US
    }
}
