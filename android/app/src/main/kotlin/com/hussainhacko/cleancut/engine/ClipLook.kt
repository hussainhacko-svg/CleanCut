package com.hussainhacko.cleancut.engine

import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Pure-Kotlin description of how a clip and the canvas background look (Phase 5).
 * [ClipRenderEffect] draws it with OpenGL; the math lives here so it can be unit-tested
 * on the JVM. Pixel coordinates have the origin at the canvas top-left, y down.
 */

/** How a clip is sized into the canvas before its transform. */
enum class FitMode { FIT, FILL, STRETCH }

/** A clip's placement and whole-clip blur at clip-relative timeline time [timeUs]. */
data class TransformSample(
    val timeUs: Long,
    val x: Double = 0.0,
    val y: Double = 0.0,
    val scale: Double = 1.0,
    val rotation: Double = 0.0,
    val opacity: Double = 1.0,
    val blur: Double = 0.0,
) {
    /** Linear blend towards [other] by [t] in [0, 1]. */
    fun lerp(other: TransformSample, t: Double, timeUs: Long) = TransformSample(
        timeUs = timeUs,
        x = x + (other.x - x) * t,
        y = y + (other.y - y) * t,
        scale = scale + (other.scale - scale) * t,
        rotation = rotation + (other.rotation - rotation) * t,
        opacity = opacity + (other.opacity - opacity) * t,
        blur = blur + (other.blur - blur) * t,
    )

    companion object {
        val IDENTITY = TransformSample(0)
    }
}

/** Geometric shape of a clip mask (Phase 6B). */
enum class MaskShape(val shaderKind: Int) {
    LINEAR(1),
    MIRROR(2),
    CIRCLE(3),
    RECT(4),
    HEART(5),
    STAR(6),
}

/** A clip mask's geometry at clip-relative timeline time [timeUs]. */
data class MaskSample(
    val timeUs: Long,
    val centerX: Double = 0.0,
    val centerY: Double = 0.0,
    val sizeX: Double = 0.7,
    val sizeY: Double = 0.7,
    val rotation: Double = 0.0,
    val feather: Double = 0.0,
) {
    /** Linear blend towards [other] by [t] in [0, 1]. */
    fun lerp(other: MaskSample, t: Double, timeUs: Long) = MaskSample(
        timeUs = timeUs,
        centerX = centerX + (other.centerX - centerX) * t,
        centerY = centerY + (other.centerY - centerY) * t,
        sizeX = sizeX + (other.sizeX - sizeX) * t,
        sizeY = sizeY + (other.sizeY - sizeY) * t,
        rotation = rotation + (other.rotation - rotation) * t,
        feather = feather + (other.feather - feather) * t,
    )

    companion object {
        val DEFAULT = MaskSample(0)
    }
}

/** Shape mask applied to a clip (Phase 6B). */
data class ClipMaskStyle(
    val shape: MaskShape,
    val invert: Boolean = false,
    /** Sorted by time, never empty; one sample = constant. */
    val samples: List<MaskSample> = listOf(MaskSample.DEFAULT),
) {
    /** The mask parameters at clip-relative [timeUs], linearly interpolated between samples. */
    fun sampleAt(timeUs: Long): MaskSample {
        val first = samples.first()
        if (samples.size == 1 || timeUs <= first.timeUs) return first
        val last = samples.last()
        if (timeUs >= last.timeUs) return last
        var lo = 0
        var hi = samples.size - 1
        while (hi - lo > 1) {
            val mid = (lo + hi) ushr 1
            if (samples[mid].timeUs <= timeUs) lo = mid else hi = mid
        }
        val a = samples[lo]
        val b = samples[hi]
        val t = (timeUs - a.timeUs).toDouble() / (b.timeUs - a.timeUs)
        return a.lerp(b, t, timeUs)
    }

    companion object {
        fun of(spec: MaskSpec?): ClipMaskStyle? {
            if (spec == null) return null
            val shape = when (spec.shape) {
                SpecMaskShape.LINEAR -> MaskShape.LINEAR
                SpecMaskShape.MIRROR -> MaskShape.MIRROR
                SpecMaskShape.CIRCLE -> MaskShape.CIRCLE
                SpecMaskShape.RECT -> MaskShape.RECT
                SpecMaskShape.HEART -> MaskShape.HEART
                SpecMaskShape.STAR -> MaskShape.STAR
            }
            val samples = spec.samples
                .map {
                    MaskSample(
                        timeUs = it.timeUs,
                        centerX = finite(it.centerX, 0.0).coerceIn(-1.5, 1.5),
                        centerY = finite(it.centerY, 0.0).coerceIn(-1.5, 1.5),
                        sizeX = finite(it.sizeX, 0.7).coerceIn(0.05, 4.0),
                        sizeY = finite(it.sizeY, 0.7).coerceIn(0.05, 4.0),
                        rotation = finite(it.rotation, 0.0),
                        feather = finite(it.feather, 0.0).coerceIn(0.0, 1.0),
                    )
                }
                .sortedBy { it.timeUs }
                .distinctBy { it.timeUs }
                .ifEmpty { listOf(MaskSample.DEFAULT) }
            return ClipMaskStyle(shape = shape, invert = spec.invert, samples = samples)
        }

        /**
         * Signed distance in pixels (`< 0` inside, `> 0` outside) matching `maskSdf` in
         * [ClipRenderEffect], so mask geometry can be unit-tested on the JVM.
         */
        fun sdf(shape: MaskShape, px: Double, py: Double, rx: Double, ry: Double): Double {
            val sx = max(rx, 1.0)
            val sy = max(ry, 1.0)
            return when (shape) {
                MaskShape.LINEAR -> py
                MaskShape.MIRROR -> abs(py) - sy
                MaskShape.CIRCLE -> {
                    val qx = px / sx
                    val qy = py / sy
                    val k0 = hypot(qx, qy)
                    if (k0 < 1e-5) -min(sx, sy)
                    else {
                        val k1 = hypot(qx / sx, qy / sy)
                        k0 * (k0 - 1.0) / max(k1, 1e-5)
                    }
                }
                MaskShape.RECT -> {
                    val qx = abs(px) - sx
                    val qy = abs(py) - sy
                    hypot(max(qx, 0.0), max(qy, 0.0)) + min(max(qx, qy), 0.0)
                }
                MaskShape.HEART -> {
                    // Matches GLSL IQ sdHeart mapped to [-sx, sx] x [-sy, sy] (y down).
                    val qx = abs(px / sx) * 0.60355339
                    val qy = (-py / sy) * 0.55177670 + 0.55177670
                    val raw = if (qy + qx > 1.0) {
                        hypot(qx - 0.25, qy - 0.75) - sqrt(2.0) / 4.0
                    } else {
                        val d1 = qx * qx + (qy - 1.0) * (qy - 1.0)
                        val m = 0.5 * max(qx + qy, 0.0)
                        val d2 = (qx - m) * (qx - m) + (qy - m) * (qy - m)
                        val sgn = if (qx >= qy) 1.0 else -1.0
                        sqrt(min(d1, d2)) * sgn
                    }
                    raw * min(sx / 0.60355339, sy / 0.55177670)
                }
                MaskShape.STAR -> {
                    // Matches GLSL IQ sdStar5 (outer radius 1.0, inner rf = 0.45, top point up).
                    var x = abs(px / sx)
                    var y = -py / sy
                    val k1x = 0.809016994375
                    val k1y = -0.587785252292
                    val k2x = -0.809016994375
                    val k2y = -0.587785252292
                    val d1 = max(k1x * x + k1y * y, 0.0)
                    x -= 2.0 * d1 * k1x
                    y -= 2.0 * d1 * k1y
                    val d2 = max(k2x * x + k2y * y, 0.0)
                    x -= 2.0 * d2 * k2x
                    y -= 2.0 * d2 * k2y
                    x = abs(x)
                    y -= 1.0
                    val bax = 0.45 * 0.587785252292
                    val bay = 0.45 * 0.809016994375 - 1.0
                    val h = ((x * bax + y * bay) / (bax * bax + bay * bay)).coerceIn(0.0, 1.0)
                    val cross = y * bax - x * bay
                    val raw = hypot(x - bax * h, y - bay * h) * (if (cross >= 0.0) 1.0 else -1.0)
                    raw * min(sx, sy)
                }
            }
        }

        /** Mask alpha in `[0, 1]` from signed pixel distance [sd], matching `FRAGMENT_MAIN`. */
        fun alpha(sd: Double, featherPx: Double, invert: Boolean): Double {
            val halfF = max(0.5, featherPx * 0.5)
            val t = ((sd + halfF) / (2.0 * halfF)).coerceIn(0.0, 1.0)
            val smooth = t * t * (3.0 - 2.0 * t)
            val a = 1.0 - smooth
            return if (invert) 1.0 - a else a
        }

        private fun finite(v: Double, fallback: Double) = if (v.isFinite()) v else fallback
    }
}

/** Offscreen target size and Gaussian step (in target texels) for whole-clip blur. */
data class ClipBlurPlan(val width: Int, val height: Int, val spread: Double)

/** Crop in normalized displayed-frame coordinates, y down. */
data class CropBox(val left: Double = 0.0, val top: Double = 0.0, val right: Double = 1.0, val bottom: Double = 1.0) {
    val width: Double get() = right - left
    val height: Double get() = bottom - top
}

/** Per-clip color and tone adjustments (Phase 6); 0 means no change. */
data class ColorAdjustments(
    val exposure: Double = 0.0,
    val brightness: Double = 0.0,
    val contrast: Double = 0.0,
    val saturation: Double = 0.0,
    val warmth: Double = 0.0,
    val tint: Double = 0.0,
    val highlights: Double = 0.0,
    val shadows: Double = 0.0,
    val sharpen: Double = 0.0,
    val vignette: Double = 0.0,
) {
    /** Whether every adjustment is neutral (0). */
    val isNone: Boolean
        get() = exposure == 0.0 &&
            brightness == 0.0 &&
            contrast == 0.0 &&
            saturation == 0.0 &&
            warmth == 0.0 &&
            tint == 0.0 &&
            highlights == 0.0 &&
            shadows == 0.0 &&
            sharpen == 0.0 &&
            vignette == 0.0

    companion object {
        val DEFAULT = ColorAdjustments()

        fun of(spec: ColorAdjustmentsSpec?): ColorAdjustments {
            if (spec == null) return DEFAULT
            return ColorAdjustments(
                exposure = clampSigned(spec.exposure),
                brightness = clampSigned(spec.brightness),
                contrast = clampSigned(spec.contrast),
                saturation = clampSigned(spec.saturation),
                warmth = clampSigned(spec.warmth),
                tint = clampSigned(spec.tint),
                highlights = clampSigned(spec.highlights),
                shadows = clampSigned(spec.shadows),
                sharpen = clampUnit(spec.sharpen),
                vignette = clampUnit(spec.vignette),
            )
        }

        private fun clampSigned(v: Double) = if (v.isFinite()) v.coerceIn(-1.0, 1.0) else 0.0
        private fun clampUnit(v: Double) = if (v.isFinite()) v.coerceIn(0.0, 1.0) else 0.0
    }
}

/** Everything about how one clip looks on the canvas. Immutable; swapped live while previewing. */
data class ClipStyle(
    val fitMode: FitMode = FitMode.FIT,
    val crop: CropBox = CropBox(),
    val flipX: Boolean = false,
    val flipY: Boolean = false,
    /** Sorted by time, never empty; one sample = constant. */
    val samples: List<TransformSample> = listOf(TransformSample.IDENTITY),
    /** Stroke width as a fraction of the canvas short side. */
    val borderWidth: Double = 0.0,
    val borderArgb: Int = 0xFFFFFFFF.toInt(),
    /** Corner radius as a fraction of the clip's shorter displayed side. */
    val borderRadius: Double = 0.0,
    /** Bundled LUT id (`luts/<filterId>.cube`), or null for none. */
    val filterId: String? = null,
    /** Blend strength of [filterId] in `0..1`. */
    val filterIntensity: Double = 0.0,
    /** Color and tone adjustments. */
    val adjustments: ColorAdjustments = ColorAdjustments.DEFAULT,
    /** Optional shape mask (null = unmasked). */
    val mask: ClipMaskStyle? = null,
) {
    /** The transform at clip-relative [timeUs], interpolated linearly between samples. */
    fun transformAt(timeUs: Long): TransformSample {
        val first = samples.first()
        if (samples.size == 1 || timeUs <= first.timeUs) return first
        val last = samples.last()
        if (timeUs >= last.timeUs) return last
        var lo = 0
        var hi = samples.size - 1
        while (hi - lo > 1) {
            val mid = (lo + hi) ushr 1
            if (samples[mid].timeUs <= timeUs) lo = mid else hi = mid
        }
        val a = samples[lo]
        val b = samples[hi]
        val t = (timeUs - a.timeUs).toDouble() / (b.timeUs - a.timeUs)
        return a.lerp(b, t, timeUs)
    }

    companion object {
        val DEFAULT = ClipStyle()

        /** Smallest crop side; keeps the shader away from a division by zero. */
        private const val MIN_CROP = 0.01

        /** Validates a spec: NaNs and out-of-range values fall back to safe ones. */
        fun of(spec: ClipStyleSpec?): ClipStyle {
            if (spec == null) return DEFAULT
            val left = finite(spec.cropLeft, 0.0).coerceIn(0.0, 1.0 - MIN_CROP)
            val top = finite(spec.cropTop, 0.0).coerceIn(0.0, 1.0 - MIN_CROP)
            val right = finite(spec.cropRight, 1.0).coerceIn(left + MIN_CROP, 1.0)
            val bottom = finite(spec.cropBottom, 1.0).coerceIn(top + MIN_CROP, 1.0)
            val samples = spec.transform
                .map {
                    TransformSample(
                        timeUs = it.timeUs,
                        x = finite(it.x, 0.0).coerceIn(-4.0, 4.0),
                        y = finite(it.y, 0.0).coerceIn(-4.0, 4.0),
                        scale = finite(it.scale, 1.0).coerceIn(0.01, 100.0),
                        rotation = finite(it.rotation, 0.0),
                        opacity = finite(it.opacity, 1.0).coerceIn(0.0, 1.0),
                        blur = finite(it.blur, 0.0).coerceIn(0.0, 1.0),
                    )
                }
                .sortedBy { it.timeUs }
                .distinctBy { it.timeUs }
                .ifEmpty { listOf(TransformSample.IDENTITY) }
            return ClipStyle(
                fitMode = when (spec.fitMode) {
                    SpecFitMode.FIT -> FitMode.FIT
                    SpecFitMode.FILL -> FitMode.FILL
                    SpecFitMode.STRETCH -> FitMode.STRETCH
                },
                crop = CropBox(left, top, right, bottom),
                flipX = spec.flipX,
                flipY = spec.flipY,
                samples = samples,
                borderWidth = finite(spec.borderWidth, 0.0).coerceIn(0.0, 0.5),
                borderArgb = spec.borderArgb.toInt(),
                borderRadius = finite(spec.borderRadius, 0.0).coerceIn(0.0, 0.5),
                filterId = spec.filterId?.takeIf { it.isNotEmpty() },
                filterIntensity = if (spec.filterId.isNullOrEmpty()) {
                    0.0
                } else {
                    finite(spec.filterIntensity, 0.0).coerceIn(0.0, 1.0)
                },
                adjustments = ColorAdjustments.of(spec.adjustments),
                mask = ClipMaskStyle.of(spec.mask),
            )
        }

        /** Number of size steps between the sharpest and the softest whole-clip blur target. */
        const val CLIP_BLUR_LEVELS = 16

        private const val CLIP_BLUR_MAX_SHORT = 360.0
        private const val CLIP_BLUR_MIN_SHORT = 32.0

        /**
         * Offscreen target and Gaussian spread for whole-clip blur at [blur] in `[0, 1]`.
         *
         * The blur radius, as a fraction of the clip's short side, is
         * `(0.6 + 1.2 b) / S(b)` with `S` shrinking exponentially from 360 to 32: it grows
         * smoothly and doesn't depend on the source resolution. The target only takes
         * [CLIP_BLUR_LEVELS] + 1 sizes (so dragging or animating blur doesn't reallocate GL
         * targets every frame), never larger than the crop; [ClipBlurPlan.spread] makes up the
         * difference between that size and `S`.
         */
        fun clipBlurPlan(cropWidth: Double, cropHeight: Double, blur: Double): ClipBlurPlan {
            val cw = max(1.0, cropWidth)
            val ch = max(1.0, cropHeight)
            val b = if (blur.isFinite()) blur.coerceIn(0.0, 1.0) else 0.0
            val ratioMinMax = CLIP_BLUR_MIN_SHORT / CLIP_BLUR_MAX_SHORT
            val ideal = CLIP_BLUR_MAX_SHORT * ratioMinMax.pow(b)
            // The level at or just above the ideal size.
            val level = (b * CLIP_BLUR_LEVELS).toInt().coerceIn(0, CLIP_BLUR_LEVELS)
            val levelShort = CLIP_BLUR_MAX_SHORT * ratioMinMax.pow(level.toDouble() / CLIP_BLUR_LEVELS)
            val shortSide = min(levelShort.roundToInt(), max(1, min(cw, ch).roundToInt())).coerceAtLeast(1)
            val spread = (0.6 + 1.2 * b) * shortSide / ideal
            val ratio = cw / ch
            val (w, h) = if (ratio >= 1.0) {
                Pair(max(1, (shortSide * ratio).roundToInt()), shortSide)
            } else {
                Pair(shortSide, max(1, (shortSide / ratio).roundToInt()))
            }
            return ClipBlurPlan(w, h, spread)
        }

        private fun finite(v: Double, fallback: Double) = if (v.isFinite()) v else fallback
    }
}

/** Where a clip lands on the canvas in one frame, in canvas pixels (y down). */
data class ClipFrameGeometry(
    val centerX: Double,
    val centerY: Double,
    /** Half the clip rectangle's size, after fit and scale (before rotation). */
    val halfWidth: Double,
    val halfHeight: Double,
    /** Clockwise rotation. */
    val cos: Double,
    val sin: Double,
    val radiusPx: Double,
    val borderPx: Double,
    val opacity: Double,
    val blur: Double = 0.0,
) {
    /**
     * Maps canvas pixel ([px], [py]) to normalized clip coordinates (0–1 across the clip rectangle,
     * y down, before flips), or null when the point is outside the rectangle's bounding box.
     */
    fun toClip(px: Double, py: Double): Pair<Double, Double>? {
        val dx = px - centerX
        val dy = py - centerY
        val lx = cos * dx + sin * dy
        val ly = -sin * dx + cos * dy
        if (abs(lx) > halfWidth || abs(ly) > halfHeight) return null
        return Pair(lx / halfWidth * 0.5 + 0.5, ly / halfHeight * 0.5 + 0.5)
    }

    companion object {
        /**
         * Places a clip whose (display-oriented) frame is [inputWidth]×[inputHeight] into a
         * [canvasWidth]×[canvasHeight] canvas at clip-relative [timeUs].
         */
        fun of(
            style: ClipStyle,
            inputWidth: Int,
            inputHeight: Int,
            canvasWidth: Int,
            canvasHeight: Int,
            timeUs: Long,
        ): ClipFrameGeometry {
            val w = canvasWidth.toDouble()
            val h = canvasHeight.toDouble()
            val srcW = max(1.0, inputWidth * style.crop.width)
            val srcH = max(1.0, inputHeight * style.crop.height)
            val (baseW, baseH) = when (style.fitMode) {
                FitMode.FIT -> min(w / srcW, h / srcH).let { Pair(srcW * it, srcH * it) }
                FitMode.FILL -> max(w / srcW, h / srcH).let { Pair(srcW * it, srcH * it) }
                FitMode.STRETCH -> Pair(w, h)
            }
            val t = style.transformAt(timeUs)
            val halfW = baseW * t.scale / 2
            val halfH = baseH * t.scale / 2
            val radians = t.rotation * PI / 180
            return ClipFrameGeometry(
                centerX = w / 2 + t.x * w / 2,
                centerY = h / 2 + t.y * h / 2,
                halfWidth = halfW,
                halfHeight = halfH,
                cos = cos(radians),
                sin = sin(radians),
                radiusPx = style.borderRadius * 2 * min(halfW, halfH),
                borderPx = style.borderWidth * min(w, h),
                opacity = t.opacity,
                blur = t.blur,
            )
        }
    }
}

/** What fills the canvas behind the clips. */
data class BackgroundStyle(
    val kind: Kind = Kind.COLOR,
    val argb: Int = 0xFF000000.toInt(),
    val endArgb: Int = 0xFF000000.toInt(),
    val angleDegrees: Double = 0.0,
    val blur: Double = 0.0,
    val imageUri: String? = null,
) {
    enum class Kind { COLOR, GRADIENT, BLUR, IMAGE }

    /**
     * Gradient direction in canvas pixels (y down) and the projected extent that maps the
     * canvas onto 0–1: `t = dot(p - center, dir) / extent + 0.5`.
     */
    fun gradientAxis(canvasWidth: Int, canvasHeight: Int): Triple<Double, Double, Double> {
        val radians = angleDegrees * PI / 180
        val dx = sin(radians)
        val dy = -cos(radians)
        val extent = abs(dx) * canvasWidth + abs(dy) * canvasHeight
        return Triple(dx, dy, max(extent, 1e-6))
    }

    /** Short side in pixels of the small texture the blurred background is rendered into. */
    fun blurTextureShortSide(canvasShortSide: Int): Int {
        val safeCanvas = max(1, canvasShortSide)
        if (blur <= 0.0) return safeCanvas
        // 0 -> 160 px (soft), 1 -> 16 px (very blurry); bilinear upscaling smooths it out.
        return (160 - 144 * blur.coerceIn(0.0, 1.0)).toInt().coerceIn(min(8, safeCanvas), safeCanvas)
    }

    companion object {
        val DEFAULT = BackgroundStyle()

        /**
         * Smallest power-of-two sample size that keeps the decoded image's long side
         * at or below [maxSide].
         */
        internal fun imageSampleSize(width: Int, height: Int, maxSide: Int): Int {
            if (maxSide <= 0) return 1
            val longSide = max(width, height)
            var sample = 1
            while (longSide / sample > maxSide) sample *= 2
            return sample
        }

        fun of(spec: BackgroundSpec?): BackgroundStyle {
            if (spec == null) return DEFAULT
            val kind = when (spec.kind) {
                SpecBackgroundKind.COLOR -> Kind.COLOR
                SpecBackgroundKind.GRADIENT -> Kind.GRADIENT
                SpecBackgroundKind.BLUR -> Kind.BLUR
                SpecBackgroundKind.IMAGE -> if (spec.imageUri.isNullOrEmpty()) Kind.COLOR else Kind.IMAGE
            }
            return BackgroundStyle(
                kind = kind,
                argb = spec.argb.toInt(),
                endArgb = spec.endArgb.toInt(),
                angleDegrees = if (spec.angleDegrees.isFinite()) spec.angleDegrees else 0.0,
                blur = if (spec.blur.isFinite()) spec.blur.coerceIn(0.0, 1.0) else 0.0,
                imageUri = spec.imageUri?.takeIf { it.isNotEmpty() },
            )
        }
    }
}
