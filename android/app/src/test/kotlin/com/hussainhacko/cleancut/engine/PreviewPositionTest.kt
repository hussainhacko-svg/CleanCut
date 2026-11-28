package com.hussainhacko.cleancut.engine

import androidx.media3.common.C
import org.junit.Assert.assertEquals
import org.junit.Test

class PreviewPositionTest {
    @Test
    fun `position past the end is reported as the end`() {
        // CompositionPlayer keeps advancing a few hundred ms after the last frame.
        assertEquals(6_038_000L, PreviewPlayer.reportedPositionUs(6_503, 6_038, ended = false))
        assertEquals(6_038_000L, PreviewPlayer.reportedPositionUs(6_503, 6_038, ended = true))
    }

    @Test
    fun `ended reports exactly the duration`() {
        assertEquals(9_038_000L, PreviewPlayer.reportedPositionUs(9_030, 9_038, ended = true))
    }

    @Test
    fun `positions inside the timeline pass through`() {
        assertEquals(1_234_000L, PreviewPlayer.reportedPositionUs(1_234, 6_038, ended = false))
        assertEquals(0L, PreviewPlayer.reportedPositionUs(-5, 6_038, ended = false))
    }

    @Test
    fun `unknown duration does not clamp`() {
        assertEquals(1_234_000L, PreviewPlayer.reportedPositionUs(1_234, C.TIME_UNSET, ended = false))
        assertEquals(1_234_000L, PreviewPlayer.reportedPositionUs(1_234, C.TIME_UNSET, ended = true))
    }

    @Test
    fun `a multi-input preview counts as finished within one frame of the end`() {
        assertEquals(false, PreviewPlayer.reachedEnd(5_000, 10_000))
        assertEquals(false, PreviewPlayer.reachedEnd(9_959, 10_000))
        assertEquals(true, PreviewPlayer.reachedEnd(9_960, 10_000))
        assertEquals(true, PreviewPlayer.reachedEnd(10_400, 10_000))
        assertEquals(false, PreviewPlayer.reachedEnd(10_400, C.TIME_UNSET))
        assertEquals(false, PreviewPlayer.reachedEnd(0, 0))
    }
}
