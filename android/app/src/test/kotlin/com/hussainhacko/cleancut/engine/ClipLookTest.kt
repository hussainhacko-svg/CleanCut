package com.hussainhacko.cleancut.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Neutral adjustments spec (all 0). */
fun adjustmentsSpec(
    exposure: Double = 0.0,
    brightness: Double = 0.0,
    contrast: Double = 0.0,
    saturation: Double = 0.0,
    warmth: Double = 0.0,
    tint: Double = 0.0,
    highlights: Double = 0.0,
    shadows: Double = 0.0,
    sharpen: Double = 0.0,
    vignette: Double = 0.0,
) = ColorAdjustmentsSpec(
    exposure, brightness, contrast, saturation, warmth, tint, highlights, shadows, sharpen, vignette,
)

/** A style spec with no crop, no border and an identity transform, plus overrides. */
fun styleSpec(
    fitMode: SpecFitMode = SpecFitMode.FIT,
    crop: List<Double> = listOf(0.0, 0.0, 1.0, 1.0),
    samples: List<TransformSampleSpec> = listOf(TransformSampleSpec(0, 0.0, 0.0, 1.0, 0.0, 1.0)),
    borderWidth: Double = 0.0,
    borderRadius: Double = 0.0,
    flipX: Boolean = false,
    filterId: String? = null,
    filterIntensity: Double = 0.0,
    adjustments: ColorAdjustmentsSpec = adjustmentsSpec(),
) = ClipStyleSpec(
    fitMode, crop[0], crop[1], crop[2], crop[3], flipX, false, samples,
    borderWidth, 0xFFFFFFFF, borderRadius, filterId, filterIntensity, adjustments,
)

/** A black color background. */
fun backgroundSpec(
    kind: SpecBackgroundKind = SpecBackgroundKind.COLOR,
    angle: Double = 0.0,
    blur: Double = 0.0,
    imageUri: String? = null,
) = BackgroundSpec(kind, 0xFF000000, 0xFFFFFFFF, angle, blur, imageUri)

class ClipLookTest {
    private val eps = 1e-6

    private fun sample(t: Long, x: Double = 0.0, scale: Double = 1.0, rotation: Double = 0.0, opacity: Double = 1.0) =
        TransformSampleSpec(t, x, 0.0, scale, rotation, opacity)

    @Test
    fun `transform interpolates linearly between samples and holds at the ends`() {
        val style = ClipStyle.of(styleSpec(samples = listOf(sample(1000, x = 1.0), sample(0, x = 0.0))))
        assertEquals(0.0, style.transformAt(-5).x, eps)
        assertEquals(0.25, style.transformAt(250).x, eps)
        assertEquals(1.0, style.transformAt(5000).x, eps)
    }

    @Test
    fun `bad values fall back to safe ones`() {
        val style = ClipStyle.of(
            ClipStyleSpec(
                SpecFitMode.FILL, Double.NaN, -1.0, 0.0, 2.0, false, false,
                listOf(TransformSampleSpec(0, Double.NaN, 0.0, 0.0, Double.POSITIVE_INFINITY, 7.0)),
                Double.NaN, 0xFF000000, 9.0,
                "film_gold", 4.0,
                adjustmentsSpec(exposure = Double.NaN, brightness = 9.0, sharpen = -1.0, vignette = 3.0),
            ),
        )
        assertEquals(0.0, style.crop.left, eps)
        assertEquals(0.0, style.crop.top, eps)
        // A crop narrower than the minimum is widened.
        assertEquals(0.01, style.crop.right, eps)
        assertEquals(1.0, style.crop.bottom, eps)
        val t = style.samples.single()
        assertEquals(0.0, t.x, eps)
        assertEquals(0.01, t.scale, eps)
        assertEquals(0.0, t.rotation, eps)
        assertEquals(1.0, t.opacity, eps)
        assertEquals(0.0, style.borderWidth, eps)
        assertEquals(0.5, style.borderRadius, eps)
        assertEquals("film_gold", style.filterId)
        assertEquals(1.0, style.filterIntensity, eps)
        assertEquals(0.0, style.adjustments.exposure, eps)
        assertEquals(1.0, style.adjustments.brightness, eps)
        assertEquals(0.0, style.adjustments.sharpen, eps)
        assertEquals(1.0, style.adjustments.vignette, eps)
    }

    @Test
    fun `an empty sample list is the identity`() {
        assertEquals(listOf(TransformSample.IDENTITY), ClipStyle.of(styleSpec(samples = emptyList())).samples)
    }

    @Test
    fun `fit letterboxes, fill covers, stretch matches the canvas`() {
        // A 1920x1080 frame on a 1080x1920 canvas.
        fun geometry(mode: SpecFitMode) =
            ClipFrameGeometry.of(ClipStyle.of(styleSpec(fitMode = mode)), 1920, 1080, 1080, 1920, 0)

        val fit = geometry(SpecFitMode.FIT)
        assertEquals(540.0, fit.halfWidth, eps)
        assertEquals(303.75, fit.halfHeight, eps)
        assertEquals(540.0, fit.centerX, eps)
        assertEquals(960.0, fit.centerY, eps)

        val fill = geometry(SpecFitMode.FILL)
        assertEquals(960.0, fill.halfHeight, eps)
        assertEquals(1920.0 * 1920 / 1080 / 2, fill.halfWidth, eps)

        val stretch = geometry(SpecFitMode.STRETCH)
        assertEquals(540.0, stretch.halfWidth, eps)
        assertEquals(960.0, stretch.halfHeight, eps)
    }

    @Test
    fun `crop changes the fitted aspect`() {
        // Cropping a 1920x1080 frame to its central square fits a square canvas exactly.
        val left = (1 - 1080.0 / 1920) / 2
        val style = ClipStyle.of(styleSpec(crop = listOf(left, 0.0, 1 - left, 1.0)))
        val g = ClipFrameGeometry.of(style, 1920, 1080, 1000, 1000, 0)
        assertEquals(500.0, g.halfWidth, 1e-3)
        assertEquals(500.0, g.halfHeight, 1e-3)
    }

    @Test
    fun `position, scale, rotation and opacity come from the transform`() {
        val style = ClipStyle.of(
            styleSpec(samples = listOf(TransformSampleSpec(0, 0.5, -1.0, 0.5, 90.0, 0.25))),
        )
        val g = ClipFrameGeometry.of(style, 100, 100, 100, 100, 0)
        assertEquals(75.0, g.centerX, eps)
        assertEquals(0.0, g.centerY, eps)
        assertEquals(25.0, g.halfWidth, eps)
        assertEquals(0.0, g.cos, eps)
        assertEquals(1.0, g.sin, eps)
        assertEquals(0.25, g.opacity, eps)
    }

    @Test
    fun `rotation is clockwise on screen`() {
        // A wide clip turned 90° clockwise: its right edge (clip x = 1) faces down.
        val style = ClipStyle.of(styleSpec(samples = listOf(sample(0, rotation = 90.0))))
        val g = ClipFrameGeometry.of(style, 200, 100, 200, 200, 0)
        val (u, v) = g.toClip(100.0, 100.0 + g.halfWidth * 0.9)!!
        assertEquals(0.95, u, eps)
        assertEquals(0.5, v, eps)
        assertNull(g.toClip(100.0 + g.halfWidth * 0.9, 100.0))
    }

    @Test
    fun `corner radius and border scale with the clip and canvas`() {
        val style = ClipStyle.of(styleSpec(borderWidth = 0.01, borderRadius = 0.5))
        val g = ClipFrameGeometry.of(style, 1920, 1080, 1920, 1080, 0)
        // Half the shorter side: a pill.
        assertEquals(540.0, g.radiusPx, eps)
        assertEquals(10.8, g.borderPx, eps)
    }

    @Test
    fun `gradient axis follows the angle`() {
        val up = BackgroundStyle.of(backgroundSpec(SpecBackgroundKind.GRADIENT, angle = 0.0))
        val (ux, uy, uExtent) = up.gradientAxis(100, 200)
        assertEquals(0.0, ux, eps)
        assertEquals(-1.0, uy, eps)
        assertEquals(200.0, uExtent, eps)
        val right = BackgroundStyle.of(backgroundSpec(SpecBackgroundKind.GRADIENT, angle = 90.0))
        val (rx, ry, rExtent) = right.gradientAxis(100, 200)
        assertEquals(1.0, rx, eps)
        assertEquals(0.0, ry, eps)
        assertEquals(100.0, rExtent, eps)
    }

    @Test
    fun `blur textures shrink as the blur grows`() {
        fun side(blur: Double, canvasShortSide: Int = 720) =
            BackgroundStyle.of(backgroundSpec(SpecBackgroundKind.BLUR, blur = blur))
                .blurTextureShortSide(canvasShortSide)
        assertEquals(720, side(0.0))
        assertEquals(160 - 72, side(0.5))
        assertEquals(16, side(1.0))
        // Tiny canvases below 8 px must not crash coerceIn.
        assertEquals(2, side(0.5, canvasShortSide = 2))
        assertEquals(1, side(1.0, canvasShortSide = 0))
    }

    @Test
    fun `image sample size keeps the decoded long side at or below maxSide`() {
        assertEquals(1, BackgroundStyle.imageSampleSize(2048, 1080, 2048))
        assertEquals(2, BackgroundStyle.imageSampleSize(2049, 1080, 2048))
        assertEquals(2, BackgroundStyle.imageSampleSize(4000, 3000, 2048))
        assertEquals(4, BackgroundStyle.imageSampleSize(8192, 4096, 2048))
    }

    @Test
    fun `an image background without a uri falls back to a color`() {
        assertEquals(
            BackgroundStyle.Kind.COLOR,
            BackgroundStyle.of(backgroundSpec(SpecBackgroundKind.IMAGE, imageUri = "")).kind,
        )
        assertEquals(
            BackgroundStyle.Kind.IMAGE,
            BackgroundStyle.of(backgroundSpec(SpecBackgroundKind.IMAGE, imageUri = "content://x")).kind,
        )
    }

    private fun clip(uri: String, outUs: Long, style: ClipStyleSpec = styleSpec()) =
        ClipSpec(uri, SpecMediaKind.VIDEO, 10_000_000, 0, outUs, 2.0, true, emptyList(), style)

    @Test
    fun `items start where the previous ones end on the timeline`() {
        val plan = CompositionPlan.of(
            CompositionSpec(listOf(clip("a", 4_000_000), clip("b", 2_000_000)), 1080, 1920, 30, backgroundSpec()),
        )
        assertEquals(listOf(0L, 2_000_000L), plan.timelineStartsUs)
    }

    @Test
    fun `looks do not change the structure key, media does`() {
        fun plan(style: ClipStyleSpec, background: BackgroundSpec, out: Long = 4_000_000) = CompositionPlan.of(
            CompositionSpec(listOf(clip("a", out, style)), 1080, 1920, 30, background),
        )
        val base = plan(styleSpec(), backgroundSpec())
        val restyled = plan(
            styleSpec(fitMode = SpecFitMode.FILL, borderRadius = 0.2, flipX = true),
            backgroundSpec(SpecBackgroundKind.BLUR, blur = 1.0),
        )
        assertNotEquals(base, restyled)
        assertEquals(base.structureKey, restyled.structureKey)
        assertNotEquals(base.structureKey, plan(styleSpec(), backgroundSpec(), out = 3_000_000).structureKey)
    }
}
