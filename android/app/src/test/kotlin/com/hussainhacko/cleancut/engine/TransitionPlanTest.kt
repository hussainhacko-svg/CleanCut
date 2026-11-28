package com.hussainhacko.cleancut.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class TransitionPlanTest {
    private fun video(
        durationUs: Long,
        uri: String,
        transitionOut: TransitionSpec? = null,
    ) = ClipSpec(
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
    )

    private fun spec(vararg clips: ClipSpec) =
        CompositionSpec(clips.toList(), 1080, 1920, 30, backgroundSpec())

    @Test
    fun `overlapping transitions shorten duration and shift clip starts`() {
        val plan = CompositionPlan.of(
            spec(
                video(4_000_000, "a", TransitionSpec(SpecTransitionType.DISSOLVE, 1_000_000)),
                video(4_000_000, "b", TransitionSpec(SpecTransitionType.SLIDE_LEFT, 500_000)),
                video(4_000_000, "c"),
            ),
        )
        assertTrue(plan.hasTransitions)
        assertEquals(listOf(0L, 3_000_000L, 6_500_000L), plan.timelineStartsUs)
        assertEquals(10_500_000L, plan.durationUs)
    }

    @Test
    fun `overlap caps at half the shorter neighbor so transitions never collide`() {
        val plan = CompositionPlan.of(
            spec(
                video(4_000_000, "a", TransitionSpec(SpecTransitionType.WIPE_LEFT, 2_000_000)),
                video(1_000_000, "b", TransitionSpec(SpecTransitionType.ZOOM_IN, 2_000_000)),
                video(4_000_000, "c"),
            ),
        )
        assertEquals(500_000L, plan.overlapAfter(0))
        assertEquals(500_000L, plan.overlapAfter(1))
        assertEquals(listOf(0L, 3_500_000L, 4_000_000L), plan.timelineStartsUs)
        assertEquals(8_000_000L, plan.durationUs)
        // Lane 0 has a [0..4s] and c [4s..8s] with no zero-length gap between them.
        assertEquals(
            listOf(
                LaneSegment.Clip(0, 0L, 4_000_000L),
                LaneSegment.Clip(2, 4_000_000L, 8_000_000L),
            ),
            plan.laneSegments(0),
        )
    }

    @Test
    fun `overlap below the minimum plays as a hard cut like Dart`() {
        val plan = CompositionPlan.of(
            spec(
                video(4_000_000, "a", TransitionSpec(SpecTransitionType.DISSOLVE, 500_000)),
                // Half of 0.15 s is 75 ms, below the 0.1 s minimum.
                video(150_000, "b"),
            ),
        )
        assertEquals(0L, plan.overlapAfter(0))
        assertFalse(plan.hasTransitions)
        assertEquals(4_150_000L, plan.durationUs)
    }

    @Test
    fun `laneSegments and isLaneActiveAt cover full composition duration cleanly`() {
        val plan = CompositionPlan.of(
            spec(
                video(4_000_000, "a", TransitionSpec(SpecTransitionType.DISSOLVE, 1_000_000)),
                video(4_000_000, "b"),
            ),
        )
        // Total duration = 7s; a = [0..4s], b = [3s..7s].
        assertEquals(
            listOf(
                LaneSegment.Clip(0, 0L, 4_000_000L),
                LaneSegment.Gap(4_000_000L, 7_000_000L),
            ),
            plan.laneSegments(0),
        )
        assertEquals(
            listOf(
                LaneSegment.Gap(0L, 3_000_000L),
                LaneSegment.Clip(1, 3_000_000L, 7_000_000L),
            ),
            plan.laneSegments(1),
        )
        // Only lane 0 active before overlap.
        assertTrue(plan.isLaneActiveAt(0, 1_000_000L))
        assertFalse(plan.isLaneActiveAt(1, 1_000_000L))
        // Both lanes active inside [3s, 4s).
        assertTrue(plan.isLaneActiveAt(0, 3_500_000L))
        assertTrue(plan.isLaneActiveAt(1, 3_500_000L))
        // Only lane 1 active after 4s and at the very end (7s).
        assertFalse(plan.isLaneActiveAt(0, 4_000_000L))
        assertTrue(plan.isLaneActiveAt(1, 4_000_000L))
        assertFalse(plan.isLaneActiveAt(0, 7_000_000L))
        assertTrue(plan.isLaneActiveAt(1, 7_000_000L))
    }

    @Test
    fun `changing transition type keeps structureKey equal for live swaps, duration changes it`() {
        val dissolve = CompositionPlan.of(
            spec(
                video(4_000_000, "a", TransitionSpec(SpecTransitionType.DISSOLVE, 500_000)),
                video(4_000_000, "b"),
            ),
        )
        val slide = CompositionPlan.of(
            spec(
                video(4_000_000, "a", TransitionSpec(SpecTransitionType.SLIDE_LEFT, 500_000)),
                video(4_000_000, "b"),
            ),
        )
        val longer = CompositionPlan.of(
            spec(
                video(4_000_000, "a", TransitionSpec(SpecTransitionType.DISSOLVE, 1_000_000)),
                video(4_000_000, "b"),
            ),
        )
        val hardCut = CompositionPlan.of(
            spec(video(4_000_000, "a"), video(4_000_000, "b")),
        )
        assertEquals(dissolve.structureKey, slide.structureKey)
        assertNotEquals(dissolve.structureKey, longer.structureKey)
        assertNotEquals(dissolve.structureKey, hardCut.structureKey)
    }

    @Test
    fun `clipTransitionsFor evaluates progress and top-layer flag on both sides`() {
        val plan = CompositionPlan.of(
            spec(
                video(4_000_000, "a", TransitionSpec(SpecTransitionType.FADE_BLACK, 1_000_000)),
                video(4_000_000, "b", TransitionSpec(SpecTransitionType.CIRCLE, 1_000_000)),
                video(4_000_000, "c"),
            ),
        )
        val trA = plan.clipTransitionsFor(0)
        assertEquals(TransitionEval.NONE, trA.evaluate(2_000_000L))
        val outA = trA.evaluate(3_500_000L)
        assertEquals(TransitionType.FADE_BLACK.shaderKind, outA.kind)
        assertEquals(0.5f, outA.progress, 1e-4f)
        assertTrue(outA.isOutgoing)
        assertTrue(outA.isTopLayer)

        val trB = plan.clipTransitionsFor(1)
        val inB = trB.evaluate(500_000L)
        assertEquals(TransitionType.FADE_BLACK.shaderKind, inB.kind)
        assertEquals(0.5f, inB.progress, 1e-4f)
        assertFalse(inB.isOutgoing)
        assertFalse(inB.isTopLayer)

        val outB = trB.evaluate(3_250_000L)
        assertEquals(TransitionType.CIRCLE.shaderKind, outB.kind)
        assertEquals(0.25f, outB.progress, 1e-4f)
        assertTrue(outB.isOutgoing)
        assertFalse(outB.isTopLayer)
    }

    @Test
    fun `every SpecTransitionType maps to a unique positive shader kind`() {
        val kinds = SpecTransitionType.entries.map { TransitionType.of(it).shaderKind }
        assertTrue(kinds.all { it > 0 })
        assertEquals(SpecTransitionType.entries.size, kinds.toSet().size)
    }
}
