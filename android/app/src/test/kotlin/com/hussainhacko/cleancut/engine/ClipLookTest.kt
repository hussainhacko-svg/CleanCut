package com.hussainhacko.cleancut.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Test
import kotlin.math.min

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
    samples: List<TransformSampleSpec> = listOf(TransformSampleSpec(0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0)),
    borderWidth: Double = 0.0,
    borderRadius: Double = 0.0,
    flipX: Boolean = false,
    filterId: String? = null,
    filterIntensity: Double = 0.0,
    adjustments: ColorAdjustmentsSpec = adjustmentsSpec(),
    mask: MaskSpec? = null,
) = ClipStyleSpec(
    fitMode, crop[0], crop[1], crop[2], crop[3], flipX, false, samples,
    borderWidth, 0xFFFFFFFF, borderRadius, filterId, filterIntensity, adjustments, mask,
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

    private fun sample(
        t: Long,
        x: Double = 0.0,
        scale: Double = 1.0,
        rotation: Double = 0.0,
        opacity: Double = 1.0,
        blur: Double = 0.0,
    ) = TransformSampleSpec(t, x, 0.0, scale, rotation, opacity, blur)

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
                listOf(TransformSampleSpec(0, Double.NaN, 0.0, 0.0, Double.POSITIVE_INFINITY, 7.0, 5.0)),
                Double.NaN, 0xFF000000, 9.0,
                "film_gold", 4.0,
                adjustmentsSpec(exposure = Double.NaN, brightness = 9.0, sharpen = -1.0, vignette = 3.0),
                MaskSpec(
                    SpecMaskShape.CIRCLE,
                    true,
                    listOf(MaskSampleSpec(0, Double.NaN, 9.0, 0.0, 99.0, Double.NEGATIVE_INFINITY, -2.0)),
                ),
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
        assertEquals(1.0, t.blur, eps)
        assertEquals(0.0, style.borderWidth, eps)
        assertEquals(0.5, style.borderRadius, eps)
        assertEquals("film_gold", style.filterId)
        assertEquals(1.0, style.filterIntensity, eps)
        assertEquals(0.0, style.adjustments.exposure, eps)
        assertEquals(1.0, style.adjustments.brightness, eps)
        assertEquals(0.0, style.adjustments.sharpen, eps)
        assertEquals(1.0, style.adjustments.vignette, eps)
        val mask = requireNotNull(style.mask)
        val m = mask.samples.single()
        assertEquals(MaskShape.CIRCLE, mask.shape)
        assertEquals(true, mask.invert)
        assertEquals(0.0, m.centerX, eps)
        assertEquals(1.5, m.centerY, eps)
        assertEquals(0.05, m.sizeX, eps)
        assertEquals(4.0, m.sizeY, eps)
        assertEquals(0.0, m.rotation, eps)
        assertEquals(0.0, m.feather, eps)
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
            styleSpec(samples = listOf(TransformSampleSpec(0, 0.5, -1.0, 0.5, 90.0, 0.25, 0.4))),
        )
        val g = ClipFrameGeometry.of(style, 100, 100, 100, 100, 0)
        assertEquals(75.0, g.centerX, eps)
        assertEquals(0.0, g.centerY, eps)
        assertEquals(25.0, g.halfWidth, eps)
        assertEquals(0.0, g.cos, eps)
        assertEquals(1.0, g.sin, eps)
        assertEquals(0.25, g.opacity, eps)
        assertEquals(0.4, g.blur, eps)
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
        ClipSpec(uri, SpecMediaKind.VIDEO, 10_000_000, 0, outUs, 2.0, true, emptyList(), style, null, false)

    @Test
    fun `items start where the previous ones end on the timeline`() {
        val plan = CompositionPlan.of(
            CompositionSpec(listOf(clip("a", 4_000_000), clip("b", 2_000_000)), 1080, 1920, 30, backgroundSpec(), emptyList()),
        )
        assertEquals(listOf(0L, 2_000_000L), plan.timelineStartsUs)
    }

    @Test
    fun `looks do not change the structure key, media does`() {
        fun plan(style: ClipStyleSpec, background: BackgroundSpec, out: Long = 4_000_000) = CompositionPlan.of(
            CompositionSpec(listOf(clip("a", out, style)), 1080, 1920, 30, background, emptyList()),
        )
        val base = plan(styleSpec(), backgroundSpec())
        val restyled = plan(
            styleSpec(fitMode = SpecFitMode.FILL, borderRadius = 0.2, flipX = true),
            backgroundSpec(SpecBackgroundKind.BLUR, blur = 1.0),
        )
        assertNotEquals(base, restyled)
        assertEquals(base.structureKey, restyled.structureKey)
        assertNotEquals(base.structureKey, plan(styleSpec(), backgroundSpec(), out = 3_000_000).structureKey)

        // Changing blur or mask keeps the structure key intact (live look swap).
        val blurredMasked = plan(
            styleSpec(
                samples = listOf(sample(0, blur = 0.6)),
                mask = MaskSpec(
                    SpecMaskShape.HEART,
                    false,
                    listOf(MaskSampleSpec(0, 0.0, 0.0, 0.7, 0.7, 15.0, 0.2)),
                ),
            ),
            backgroundSpec(),
        )
        assertEquals(base.structureKey, blurredMasked.structureKey)
    }

    @Test
    fun `clip blur target shrinks monotonically and tolerates tiny crops`() {
        val p0 = ClipStyle.clipBlurPlan(1920.0, 1080.0, 0.0)
        val pMid = ClipStyle.clipBlurPlan(1920.0, 1080.0, 0.5)
        val pMax = ClipStyle.clipBlurPlan(1920.0, 1080.0, 1.0)
        assertEquals(360, p0.height)
        assertEquals(640, p0.width)
        assert(pMid.height in (pMax.height + 1) until p0.height)
        assertEquals(32, pMax.height)
        assert(pMax.width > pMax.height)

        // Tiny crop never returns 0.
        val tiny = ClipStyle.clipBlurPlan(4.0, 2.0, 1.0)
        assert(tiny.width >= 1 && tiny.height >= 1)
    }

    @Test
    fun `clip blur reuses a few target sizes while the amount changes`() {
        // A slider drag or keyframed blur must not reallocate GL targets every frame.
        val sizes = (0..1000).map { ClipStyle.clipBlurPlan(1920.0, 1080.0, it / 1000.0) }
            .map { it.width to it.height }
            .toSet()
        assert(sizes.size <= ClipStyle.CLIP_BLUR_LEVELS + 1) { "${sizes.size} sizes" }
    }

    @Test
    fun `clip blur radius is continuous and independent of source resolution`() {
        // Radius as a fraction of the clip's short side.
        fun radius(w: Double, h: Double, b: Double) =
            ClipStyle.clipBlurPlan(w, h, b).let { it.spread / min(it.width, it.height) }
        var last = 0.0
        for (i in 1..1000) {
            val b = i / 1000.0
            val hd = radius(1920.0, 1080.0, b)
            assertEquals(hd, radius(426.0, 240.0, b), hd * 0.02)
            assertEquals(hd, radius(80.0, 60.0, b), hd * 0.02)
            assert(hd >= last * 0.999) { "radius drops at $b" }
            last = hd
            assert(ClipStyle.clipBlurPlan(1920.0, 1080.0, b).spread <= 2.5)
        }
    }

    @Test
    fun `mask samples interpolate linearly and hold at ends`() {
        val mask = ClipMaskStyle.of(
            MaskSpec(
                SpecMaskShape.RECT,
                false,
                listOf(
                    MaskSampleSpec(1000, 0.5, -0.5, 1.0, 0.8, 90.0, 0.4),
                    MaskSampleSpec(0, -0.5, 0.5, 0.5, 0.4, 0.0, 0.0),
                ),
            ),
        )!!
        assertEquals(-0.5, mask.sampleAt(-10).centerX, eps)
        val mid = mask.sampleAt(500)
        assertEquals(0.0, mid.centerX, eps)
        assertEquals(0.0, mid.centerY, eps)
        assertEquals(0.75, mid.sizeX, eps)
        assertEquals(0.6, mid.sizeY, eps)
        assertEquals(45.0, mid.rotation, eps)
        assertEquals(0.2, mid.feather, eps)
        assertEquals(0.5, mask.sampleAt(2000).centerX, eps)
    }

    @Test
    fun `mask SDF classifies inside, boundary and outside for every shape`() {
        val r = 100.0
        // Linear: y <= 0 inside, y > 0 outside.
        assert(ClipMaskStyle.sdf(MaskShape.LINEAR, 0.0, -20.0, r, r) < 0)
        assertEquals(0.0, ClipMaskStyle.sdf(MaskShape.LINEAR, 50.0, 0.0, r, r), eps)
        assert(ClipMaskStyle.sdf(MaskShape.LINEAR, 0.0, 20.0, r, r) > 0)

        // Mirror: |y| <= r inside.
        assert(ClipMaskStyle.sdf(MaskShape.MIRROR, 0.0, 0.0, r, 40.0) < 0)
        assertEquals(0.0, ClipMaskStyle.sdf(MaskShape.MIRROR, 10.0, 40.0, r, 40.0), eps)
        assert(ClipMaskStyle.sdf(MaskShape.MIRROR, 0.0, 60.0, r, 40.0) > 0)

        // Circle / ellipse.
        assertEquals(-r, ClipMaskStyle.sdf(MaskShape.CIRCLE, 0.0, 0.0, r, r), eps)
        assertEquals(0.0, ClipMaskStyle.sdf(MaskShape.CIRCLE, r, 0.0, r, r), 1e-4)
        assert(ClipMaskStyle.sdf(MaskShape.CIRCLE, r + 20.0, 0.0, r, r) > 0)
        assertEquals(0.0, ClipMaskStyle.sdf(MaskShape.CIRCLE, 200.0, 0.0, 200.0, 100.0), 1e-4)

        // Rect.
        assertEquals(-r, ClipMaskStyle.sdf(MaskShape.RECT, 0.0, 0.0, r, r), eps)
        assertEquals(0.0, ClipMaskStyle.sdf(MaskShape.RECT, r, 20.0, r, r), eps)
        assert(ClipMaskStyle.sdf(MaskShape.RECT, r + 10.0, 0.0, r, r) > 0)

        // Heart: center inside, bottom tip on boundary, far corners outside.
        assert(ClipMaskStyle.sdf(MaskShape.HEART, 0.0, 0.0, r, r) < 0)
        assertEquals(0.0, ClipMaskStyle.sdf(MaskShape.HEART, 0.0, r, r, r), 1e-3)
        assert(ClipMaskStyle.sdf(MaskShape.HEART, r, r, r, r) > 0)
        assert(ClipMaskStyle.sdf(MaskShape.HEART, 0.0, -r - 20.0, r, r) > 0)

        // Star: center inside, top point (0, -r) on boundary, outer corner outside.
        assert(ClipMaskStyle.sdf(MaskShape.STAR, 0.0, 0.0, r, r) < 0)
        assertEquals(0.0, ClipMaskStyle.sdf(MaskShape.STAR, 0.0, -r, r, r), 1e-3)
        assert(ClipMaskStyle.sdf(MaskShape.STAR, 0.0, r * 0.45, r, r) in -1e-2..1e-2)
        assert(ClipMaskStyle.sdf(MaskShape.STAR, r, r, r, r) > 0)
    }

    @Test
    fun `mask alpha handles hard edges, feather and invert`() {
        assertEquals(1.0, ClipMaskStyle.alpha(-10.0, 0.0, invert = false), eps)
        assertEquals(0.5, ClipMaskStyle.alpha(0.0, 0.0, invert = false), eps)
        assertEquals(0.0, ClipMaskStyle.alpha(10.0, 0.0, invert = false), eps)

        // Inverted flips inside/outside.
        assertEquals(0.0, ClipMaskStyle.alpha(-10.0, 0.0, invert = true), eps)
        assertEquals(1.0, ClipMaskStyle.alpha(10.0, 0.0, invert = true), eps)

        // Feathered edge produces intermediate values inside [-halfF, halfF].
        val midIn = ClipMaskStyle.alpha(-5.0, 40.0, invert = false)
        val midOut = ClipMaskStyle.alpha(5.0, 40.0, invert = false)
        assert(midIn > 0.5 && midIn < 1.0)
        assert(midOut > 0.0 && midOut < 0.5)
        assertEquals(1.0, midIn + midOut, eps)
    }
}
