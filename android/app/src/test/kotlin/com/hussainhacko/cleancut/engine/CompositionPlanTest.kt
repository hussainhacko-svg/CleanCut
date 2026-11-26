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
    ) = ClipSpec(uri, SpecMediaKind.VIDEO, durationUs, inUs, outUs, speed, keepPitch)

    private fun image(inUs: Long, outUs: Long, speed: Double = 1.0) =
        ClipSpec("content://i", SpecMediaKind.IMAGE, 3_000_000, inUs, outUs, speed, true)

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
