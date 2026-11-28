package com.hussainhacko.cleancut.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class OverlayPlanTest {
    private fun video(
        durationUs: Long,
        uri: String,
        muted: Boolean = false,
        transitionOut: TransitionSpec? = null,
        style: ClipStyleSpec = styleSpec(),
    ) = ClipSpec(
        uri = uri,
        kind = SpecMediaKind.VIDEO,
        sourceDurationUs = durationUs,
        sourceInUs = 0,
        sourceOutUs = durationUs,
        speed = 1.0,
        keepPitch = true,
        speedSteps = emptyList(),
        style = style,
        transitionOut = transitionOut,
        muted = muted,
    )

    private fun image(
        durationUs: Long,
        uri: String,
        style: ClipStyleSpec = styleSpec(),
    ) = ClipSpec(
        uri = uri,
        kind = SpecMediaKind.IMAGE,
        sourceDurationUs = durationUs,
        sourceInUs = 0,
        sourceOutUs = durationUs,
        speed = 1.0,
        keepPitch = true,
        speedSteps = emptyList(),
        style = style,
        muted = false,
    )

    @Test
    fun `overlay tracks trigger multi-sequence mode and extend total duration when longer than main`() {
        val spec = CompositionSpec(
            clips = listOf(video(4_000_000, "content://main")),
            canvasWidth = 1080,
            canvasHeight = 1920,
            frameRate = 30,
            background = backgroundSpec(),
            overlayTracks = listOf(
                OverlayTrackSpec(
                    listOf(PlacedClipSpec(3_000_000, image(3_000_000, "content://ov"))),
                ),
            ),
        )
        val plan = CompositionPlan.of(spec)
        assertTrue(plan.hasOverlays)
        assertTrue(plan.isMultiSequence)
        assertEquals(4_000_000L, plan.mainDurationUs)
        assertEquals(6_000_000L, plan.durationUs)

        // Overlay track segments pad leading gap [0..3s] then clip [3s..6s].
        assertEquals(
            listOf(
                LaneSegment.Gap(0L, 3_000_000L),
                LaneSegment.Clip(0, 3_000_000L, 6_000_000L),
            ),
            plan.overlayTracks.single().segments(plan.durationUs),
        )
        // Main track pads trailing gap [4s..6s].
        assertEquals(
            listOf(
                LaneSegment.Clip(0, 0L, 4_000_000L),
                LaneSegment.Gap(4_000_000L, 6_000_000L),
            ),
            plan.mainSingleSegments(),
        )
    }

    @Test
    fun `isSequenceActiveAt orders overlays frontmost above main and A-B transition lanes`() {
        val spec = CompositionSpec(
            clips = listOf(
                video(4_000_000, "content://a", transitionOut = TransitionSpec(SpecTransitionType.DISSOLVE, 1_000_000)),
                video(4_000_000, "content://b"),
            ),
            canvasWidth = 1080,
            canvasHeight = 1920,
            frameRate = 30,
            background = backgroundSpec(),
            overlayTracks = listOf(
                OverlayTrackSpec(listOf(PlacedClipSpec(2_000_000, image(2_000_000, "content://top")))),
            ),
        )
        val plan = CompositionPlan.of(spec)
        // Sequence 0 = overlay [2s..4s], sequence 1 = main lane 0 [0..4s], sequence 2 = main lane 1 [3s..7s].
        assertFalse(plan.isSequenceActiveAt(0, 1_000_000L))
        assertTrue(plan.isSequenceActiveAt(1, 1_000_000L))
        assertFalse(plan.isSequenceActiveAt(2, 1_000_000L))

        // Inside [3s..4s], overlay AND both A/B transition lanes are active.
        assertTrue(plan.isSequenceActiveAt(0, 3_500_000L))
        assertTrue(plan.isSequenceActiveAt(1, 3_500_000L))
        assertTrue(plan.isSequenceActiveAt(2, 3_500_000L))

        // After 4s, only main lane 1 is active.
        assertFalse(plan.isSequenceActiveAt(0, 5_000_000L))
        assertFalse(plan.isSequenceActiveAt(1, 5_000_000L))
        assertTrue(plan.isSequenceActiveAt(2, 5_000_000L))
    }

    @Test
    fun `the lowest showing overlay paints the canvas background once the main track ends`() {
        // Main [0..4s]; track 0 (front) [3s..8s]; track 1 (back) [5s..6s].
        val spec = CompositionSpec(
            clips = listOf(video(4_000_000, "content://main")),
            canvasWidth = 1080,
            canvasHeight = 1920,
            frameRate = 30,
            background = backgroundSpec(),
            overlayTracks = listOf(
                OverlayTrackSpec(listOf(PlacedClipSpec(3_000_000, image(5_000_000, "content://front")))),
                OverlayTrackSpec(listOf(PlacedClipSpec(5_000_000, image(1_000_000, "content://back")))),
            ),
        )
        val plan = CompositionPlan.of(spec)
        // Over the main clip: overlays stay transparent layers.
        assertFalse(plan.overlayDrawsBackgroundAt(0, 3_500_000L))
        // Main ended, nothing below the front overlay: it paints the background.
        assertTrue(plan.overlayDrawsBackgroundAt(0, 4_500_000L))
        // The back overlay is showing: it paints the background, the front one stays transparent.
        assertFalse(plan.overlayDrawsBackgroundAt(0, 5_500_000L))
        assertTrue(plan.overlayDrawsBackgroundAt(1, 5_500_000L))
        // Very end of the composition (held last frame).
        assertTrue(plan.overlayDrawsBackgroundAt(0, 8_000_000L))
    }

    @Test
    fun `overlays paint the background when the main track is empty`() {
        val spec = CompositionSpec(
            clips = emptyList(),
            canvasWidth = 1080,
            canvasHeight = 1920,
            frameRate = 30,
            background = backgroundSpec(),
            overlayTracks = listOf(
                OverlayTrackSpec(listOf(PlacedClipSpec(0, image(2_000_000, "content://only")))),
            ),
        )
        val plan = CompositionPlan.of(spec)
        assertFalse(plan.isMainActiveAt(1_000_000L))
        assertTrue(plan.overlayDrawsBackgroundAt(0, 1_000_000L))
    }

    @Test
    fun `muted video overlays do not require an audio track`() {
        val spec = CompositionSpec(
            clips = listOf(video(4_000_000, "content://main")),
            canvasWidth = 1080,
            canvasHeight = 1920,
            frameRate = 30,
            background = backgroundSpec(),
            overlayTracks = listOf(
                OverlayTrackSpec(listOf(PlacedClipSpec(0, video(2_000_000, "content://ov", muted = true)))),
            ),
        )
        val plan = CompositionPlan.of(spec)
        assertFalse(plan.overlayTracks.single().hasAudio)
        assertTrue(plan.hasVideo)
    }

    @Test
    fun `structureKey ignores overlay style changes for live swaps, but changes on timing or mute`() {
        fun build(startUs: Long = 1_000_000L, opacity: Double = 1.0, muted: Boolean = true) =
            CompositionPlan.of(
                CompositionSpec(
                    clips = listOf(video(5_000_000, "content://main")),
                    canvasWidth = 1080,
                    canvasHeight = 1920,
                    frameRate = 30,
                    background = backgroundSpec(),
                    overlayTracks = listOf(
                        OverlayTrackSpec(
                            listOf(
                                PlacedClipSpec(
                                    startUs,
                                    video(
                                        2_000_000,
                                        "content://ov",
                                        muted = muted,
                                        style = styleSpec(
                                            samples = listOf(
                                                TransformSampleSpec(0, 0.0, 0.0, 0.5, 0.0, opacity, 0.0),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ),
                ),
            )

        assertEquals(build(opacity = 1.0).structureKey, build(opacity = 0.4).structureKey)
        assertNotEquals(build(startUs = 1_000_000L).structureKey, build(startUs = 2_000_000L).structureKey)
        assertNotEquals(build(muted = true).structureKey, build(muted = false).structureKey)
    }
}
