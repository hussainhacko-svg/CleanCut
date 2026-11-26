package com.hussainhacko.cleancut.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CompositionPlanTest {
    private fun video(
        inUs: Long,
        outUs: Long,
        durationUs: Long = 10_000_000,
        uri: String = "content://v",
        speed: Double = 1.0,
        keepPitch: Boolean = true,
        steps: List<SpeedStepSpec> = emptyList(),
    ) = ClipSpec(uri, SpecMediaKind.VIDEO, durationUs, inUs, outUs, speed, keepPitch, steps)

    private fun image(inUs: Long, outUs: Long, speed: Double = 1.0) =
        ClipSpec("content://i", SpecMediaKind.IMAGE, 3_000_000, inUs, outUs, speed, true, emptyList())

    private fun spec(vararg clips: ClipSpec, w: Long = 1080, h: Long = 1920, fps: Long = 30) =
        CompositionSpec(clips.toList(), w, h, fps)

    @Test
    fun `video keeps its trim and full source length`() {
        val plan = CompositionPlan.of(spec(video(1_000_000, 4_000_000)))
        val item = plan.items.single()
        assertEquals(10_000_000, item.sourceDurationUs)
        assertEquals(1_000_000, item.clipStartUs)
        assertEquals(4_000_000, item.clipEndUs)
        assertEquals(3_000_000, plan.durationUs)
    }

    @Test
    fun `speed shortens or lengthens the timeline, not the trim`() {
        val plan = CompositionPlan.of(
            spec(video(0, 4_000_000, speed = 2.0, keepPitch = false), video(0, 1_000_000, uri = "b", speed = 0.5)),
        )
        val (fast, slow) = plan.items
        assertEquals(4_000_000, fast.clippedDurationUs)
        assertEquals(2_000_000, fast.timelineDurationUs)
        assertTrue(fast.hasSpeedChange)
        assertFalse(fast.keepPitch)
        assertEquals(2_000_000, slow.timelineDurationUs)
        assertEquals(4_000_000, plan.durationUs)
    }

    @Test
    fun `unusable speeds play normally and extremes are clamped`() {
        val speeds = CompositionPlan.of(
            spec(
                video(0, 1_000_000, speed = Double.NaN),
                video(0, 1_000_000, speed = 0.0),
                video(0, 1_000_000, speed = -2.0),
                video(0, 1_000_000, speed = 0.01),
                video(0, 1_000_000, speed = 50.0),
            ),
        ).items.map { it.speed }
        assertEquals(listOf(1f, 1f, 1f, CompositionPlan.MIN_SPEED, CompositionPlan.MAX_SPEED), speeds)
    }

    @Test
    fun `images ignore speed`() {
        val item = CompositionPlan.of(spec(image(0, 2_000_000, speed = 4.0))).items.single()
        assertEquals(1f, item.speed)
        assertFalse(item.hasSpeedChange)
        assertEquals(2_000_000, item.timelineDurationUs)
    }

    @Test
    fun `curve steps set the speed over the clip and its length`() {
        // 4 s of source: 2 s at 2x, then 2 s at 0.5x -> 1 s + 4 s.
        val steps = listOf(SpeedStepSpec(0, 2.0), SpeedStepSpec(2_000_000, 0.5))
        val item = CompositionPlan.of(spec(video(1_000_000, 5_000_000, steps = steps))).items.single()
        assertTrue(item.hasSpeedChange)
        assertEquals(5_000_000, item.timelineDurationUs)
        assertEquals(2f, item.speedAt(0))
        assertEquals(2f, item.speedAt(1_999_999))
        assertEquals(0.5f, item.speedAt(2_000_000))
        assertEquals(0.5f, item.speedAt(9_000_000))
        assertEquals(2_000_000L, item.nextSpeedChangeUs(0))
        assertEquals(null, item.nextSpeedChangeUs(2_000_000))
    }

    @Test
    fun `curve steps are cleaned up`() {
        val steps = listOf(
            SpeedStepSpec(3_000_000, 4.0),
            SpeedStepSpec(500_000, Double.NaN),
            SpeedStepSpec(500_000, 3.0),
            SpeedStepSpec(9_000_000, 2.0), // past the 4 s clip
            SpeedStepSpec(-5, 2.0),
        )
        val item = CompositionPlan.of(spec(video(0, 4_000_000, steps = steps))).items.single()
        // Sorted, deduplicated, inside the clip, first stretched to 0, speeds usable.
        assertEquals(listOf(SpeedStep(0, 1f), SpeedStep(3_000_000, 4f)), item.speedSteps)
    }

    @Test
    fun `images ignore curve steps`() {
        val image = ClipSpec(
            "content://i", SpecMediaKind.IMAGE, 3_000_000, 0, 2_000_000, 1.0, true,
            listOf(SpeedStepSpec(0, 4.0)),
        )
        val item = CompositionPlan.of(spec(image)).items.single()
        assertTrue(item.speedSteps.isEmpty())
        assertFalse(item.hasSpeedChange)
    }

    @Test
    fun `trims are clamped into the source`() {
        val item = CompositionPlan.of(spec(video(-5, 20_000_000))).items.single()
        assertEquals(0, item.clipStartUs)
        assertEquals(10_000_000, item.clipEndUs)
    }

    @Test
    fun `zero-length and inverted clips are dropped`() {
        val plan = CompositionPlan.of(
            spec(video(2_000_000, 2_000_000), video(3_000_000, 1_000_000), video(0, 1_000_000, durationUs = 0)),
        )
        assertTrue(plan.items.isEmpty())
        assertEquals(0, plan.durationUs)
    }

    @Test
    fun `image shows for its trimmed length from zero`() {
        val item = CompositionPlan.of(spec(image(500_000, 2_500_000))).items.single()
        assertTrue(item.isImage)
        assertEquals(2_000_000, item.sourceDurationUs)
        assertEquals(0, item.clipStartUs)
        assertEquals(2_000_000, item.clipEndUs)
    }

    @Test
    fun `durations add up in timeline order`() {
        val plan = CompositionPlan.of(spec(video(0, 1_000_000, uri = "a"), image(0, 3_000_000), video(0, 2_000_000, uri = "b")))
        assertEquals(listOf("a", "content://i", "b"), plan.items.map { it.uri })
        assertEquals(6_000_000, plan.durationUs)
    }

    @Test
    fun `silent audio only when stills and videos mix`() {
        assertTrue(CompositionPlan.of(spec(video(0, 1), image(0, 1))).needsSilentAudio)
        assertFalse(CompositionPlan.of(spec(video(0, 1))).needsSilentAudio)
        assertFalse(CompositionPlan.of(spec(image(0, 1))).needsSilentAudio)
    }

    @Test
    fun `canvas size is even and at least 2`() {
        val plan = CompositionPlan.of(spec(w = 1081, h = 1))
        assertEquals(1080, plan.width)
        assertEquals(2, plan.height)
    }

    @Test
    fun `invalid frame rate falls back to 30`() {
        assertEquals(30, CompositionPlan.of(spec(fps = 0)).frameRate)
        assertEquals(24, CompositionPlan.of(spec(fps = 24)).frameRate)
    }

    @Test
    fun `mime types are resolved per uri`() {
        val plan = CompositionPlan.of(spec(image(0, 1))) { if (it == "content://i") "image/jpeg" else null }
        assertEquals("image/jpeg", plan.items.single().mimeType)
    }
}
