package com.hussainhacko.cleancut.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Regression: timeline thumbnails used the nearest sync frame, so a video with
 * sparse keyframes (e.g. a screen recording, one keyframe at 0) showed frame 0
 * in every tile (found on the emulator, Phase 4 test).
 */
class ThumbnailTimingTest {
    private val tolerance = ThumbnailTiming.SYNC_TOLERANCE_US

    @Test
    fun `a keyframe close to the target is good enough`() {
        assertFalse(ThumbnailTiming.needsExactFrame(targetUs = 4_000_000, closestSyncUs = 4_000_000))
        assertFalse(ThumbnailTiming.needsExactFrame(4_000_000, 4_000_000 - tolerance))
        // Normal 1 s GOP: the following keyframe is also within tolerance.
        assertFalse(ThumbnailTiming.needsExactFrame(4_000_000, 4_000_000 + tolerance))
    }

    @Test
    fun `a distant keyframe needs the exact frame`() {
        assertTrue(ThumbnailTiming.needsExactFrame(4_000_000, 4_000_000 - tolerance - 1))
        assertTrue(ThumbnailTiming.needsExactFrame(4_000_000, 4_000_000 + tolerance + 1))
        // Screen recording: only one keyframe, at 0.
        assertTrue(ThumbnailTiming.needsExactFrame(10_000_000, 0))
    }

    @Test
    fun `unknown keyframes fall back to the fast sync frame`() {
        assertFalse(ThumbnailTiming.needsExactFrame(10_000_000, null))
        assertFalse(ThumbnailTiming.needsExactFrame(10_000_000, -1))
    }

    @Test
    fun `video thumbnails cached by the old sync-only extractor are not reused`() {
        val key = CacheKeys.thumbnail("u", 1_000_000, 120, isImage = false)
        assertNotEquals(CacheKeys.legacySyncOnlyThumbnail("u", 1_000_000, 120), key)
        // Stills were always exact; their cache stays valid.
        assertEquals(
            CacheKeys.legacySyncOnlyThumbnail("u", 0, 120, isImage = true),
            CacheKeys.thumbnail("u", 0, 120, isImage = true),
        )
    }
}
