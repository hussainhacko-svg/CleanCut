package com.hussainhacko.cleancut.engine

import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Pure-Kotlin description of how a clip and the canvas background look (Phase 5).
 * [ClipRenderEffect] draws it with OpenGL; the math lives here so it can be unit-tested
 * on the JVM. Pixel coordinates have the origin at the canvas top-left, y down.
 */

/** How a clip is sized into the canvas before its transform. */
enum class FitMode { FIT, FILL, STRETCH }

/** A clip's placement at clip-relative timeline time [timeUs]. */
data class TransformSample(
    val timeUs: Long,
    val x: Double = 0.0,
    val y: Double = 0.0,
    val scale: Double = 1.0,
    val rotation: Double = 0.0,
    val opacity: Double = 1.0,
) {
    /** Linear blend towards [other] by [t] in [0, 1]. */
    fun lerp(other: TransformSample, t: Double, timeUs: Long) = TransformSample(
        timeUs = timeUs,
        x = x + (other.x - x) * t,
        y = y + (other.y - y) * t,
        scale = scale + (other.scale - scale) * t,
        rotation = rotation + (other.rotation - rotation) * t,
        opacity = opacity + (other.opacity - opacity) * t,
    )

    companion object {
        val IDENTITY = TransformSample(0)
    }
}

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
            )
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
