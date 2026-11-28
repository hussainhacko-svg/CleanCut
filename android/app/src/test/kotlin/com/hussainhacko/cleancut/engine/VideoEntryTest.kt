package com.hussainhacko.cleancut.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Media3 1.11.1 (and 1.12.0-rc01) never starts a video that follows another item in a
 * sequence of a multi-sequence composition, so the preview restarts inside it: these are the
 * times where that must happen.
 */
class VideoEntryTest {
    private fun video(durationUs: Long, uri: String, transitionOut: TransitionSpec? = null) = ClipSpec(
        uri = uri,
        kind = SpecMediaKind.VIDEO,
        sourceDurationUs = durationUs,
        sourceInUs = 0,
        sourceOutUs = durationUs,
        speed = 1.0,
        keepPitch = true,
        speedSteps = emptyList(),
        style = styleSpec(),
        transitionOut = transitionOut,
        muted = false,
    )

    private fun image(durationUs: Long, uri: String, transitionOut: TransitionSpec? = null) = ClipSpec(
        uri = uri,
        kind = SpecMediaKind.IMAGE,
        sourceDurationUs = durationUs,
        sourceInUs = 0,
        sourceOutUs = durationUs,
        speed = 1.0,
        keepPitch = true,
        speedSteps = emptyList(),
        style = styleSpec(),
        transitionOut = transitionOut,
        muted = false,
    )

    private fun plan(clips: List<ClipSpec>, overlays: List<OverlayTrackSpec> = emptyList()) = CompositionPlan.of(
        CompositionSpec(
            clips = clips,
            canvasWidth = 1080,
            canvasHeight = 1920,
            frameRate = 30,
            background = backgroundSpec(),
            overlayTracks = overlays,
        ),
    )

    private val dissolve = TransitionSpec(SpecTransitionType.DISSOLVE, 500_000)

    @Test
    fun `a single sequence needs no restarts`() {
        val p = plan(listOf(image(3_000_000, "content://still"), video(5_000_000, "content://v")))
        assertEquals(emptyList<Long>(), p.videoEntryTimesUs)
    }

    @Test
    fun `the B lane video of a transition is an entry`() {
        // Still [0, 3 s] dissolves (0.5 s) into a video: lane 1 = gap, then the video at 2.5 s.
        val p = plan(listOf(image(3_000_000, "content://still", dissolve), video(5_000_000, "content://v")))
        assertEquals(listOf(2_500_000L), p.videoEntryTimesUs)
        assertEquals(2_500_000L, p.nextVideoEntryAfterUs(0))
        assertNull(p.nextVideoEntryAfterUs(2_500_000))
    }

    @Test
    fun `a video that is first in its lane is not an entry, a later one is`() {
        // Lane 0 = v1 then v3; lane 1 = gap then v2.
        val p = plan(
            listOf(
                video(3_000_000, "content://v1", dissolve),
                video(3_000_000, "content://v2", dissolve),
                video(3_000_000, "content://v3"),
            ),
        )
        assertEquals(listOf(2_500_000L, 5_000_000L), p.videoEntryTimesUs)
    }

    @Test
    fun `overlay videos after a gap or another clip are entries, stills and a first video are not`() {
        val p = plan(
            listOf(video(10_000_000, "content://main")),
            listOf(
                // Starts at 0: first item of its sequence.
                OverlayTrackSpec(listOf(PlacedClipSpec(0, video(2_000_000, "content://o1")))),
                // Gap, still, then a video straight after the still.
                OverlayTrackSpec(
                    listOf(
                        PlacedClipSpec(1_000_000, image(1_000_000, "content://s")),
                        PlacedClipSpec(2_000_000, video(1_000_000, "content://o2")),
                    ),
                ),
                // Gap then a video.
                OverlayTrackSpec(listOf(PlacedClipSpec(4_000_000, video(1_000_000, "content://o3")))),
            ),
        )
        // The main video is the first item of its sequence (then a gap), so no entry for it.
        assertEquals(listOf(2_000_000L, 4_000_000L), p.videoEntryTimesUs)
        assertEquals(4_000_000L, p.nextVideoEntryAfterUs(2_000_000))
    }

    @Test
    fun `a video after the main track's first clip is an entry once overlays make it multi-sequence`() {
        val p = plan(
            listOf(image(2_000_000, "content://still"), video(3_000_000, "content://v")),
            listOf(OverlayTrackSpec(listOf(PlacedClipSpec(0, image(1_000_000, "content://o"))))),
        )
        assertEquals(listOf(2_000_000L), p.videoEntryTimesUs)
    }

    @Test
    fun `the restart lands inside the video and never before the playhead`() {
        // Rounded up to whole ms so the new player starts in the video, not 0.4 ms before it
        // (which would leave it stuck and restart again forever).
        assertEquals(2_751L, PreviewPlayer.videoEntryRestartMs(entryUs = 2_750_400, positionMs = 2_700))
        assertEquals(2_750L, PreviewPlayer.videoEntryRestartMs(entryUs = 2_750_000, positionMs = 2_740))
        // Already past it (e.g. the tick came late): restart where the playhead is.
        assertEquals(3_100L, PreviewPlayer.videoEntryRestartMs(entryUs = 2_750_000, positionMs = 3_100))
    }

    @Test
    fun `item boundaries are where any sequence switches items, excluding 0 and the end`() {
        val p = plan(
            listOf(video(5_000_000, "content://main")),
            listOf(
                OverlayTrackSpec(listOf(PlacedClipSpec(3_000_000, image(1_400_000, "content://g")))),
                OverlayTrackSpec(listOf(PlacedClipSpec(0, image(2_000_000, "content://r")))),
            ),
        )
        // Green: gap|still at 3.0, still|gap at 4.4. Red: still|gap at 2.0. Main: video|nothing
        // (the main video ends exactly at the composition end, 5.0).
        assertEquals(listOf(2_000_000L, 3_000_000L, 4_400_000L), p.itemBoundariesUs)
        assertEquals(emptyList<Long>(), plan(listOf(video(5_000_000, "content://v"))).itemBoundariesUs)
    }

    @Test
    fun `a paused start on a layer's last frame before a switch moves two frames back`() {
        val p = plan(
            listOf(video(5_000_000, "content://main")),
            listOf(OverlayTrackSpec(listOf(PlacedClipSpec(3_000_000, image(1_400_000, "content://g"))))),
        )
        // 30 fps: one frame is 33 333 µs. 4 384 ms is the still's last frame before 4.4 s.
        assertEquals(4_333L, p.safePausedStartMs(4_384))
        assertEquals(4_333L, p.safePausedStartMs(4_399))
        // The trim release's "last frame" seek, rounded down to whole ms (seen on device).
        assertEquals(4_333L, p.safePausedStartMs(4_366))
        // Not right before a switch: unchanged (including exactly on it, and at the very end).
        assertEquals(4_300L, p.safePausedStartMs(4_300))
        assertEquals(4_400L, p.safePausedStartMs(4_400))
        assertEquals(2_000L, p.safePausedStartMs(2_000))
        assertEquals(4_999L, p.safePausedStartMs(4_999))
    }
}
