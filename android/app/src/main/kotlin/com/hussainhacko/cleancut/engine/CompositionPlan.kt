package com.hussainhacko.cleancut.engine

/**
 * A validated, Media3-independent view of a [CompositionSpec].
 *
 * Pure Kotlin so the mapping rules can be unit-tested on the JVM; [Media3Composer]
 * turns it into a Media3 `Composition`.
 */
data class CompositionPlan(
    val items: List<PlannedItem>,
    val width: Int,
    val height: Int,
    val frameRate: Int,
) {
    /** Length of the sequence: the sum of the trimmed items after their speed. */
    val durationUs: Long get() = items.sumOf { it.timelineDurationUs }

    /** True when stills and videos mix, so audio must be padded with silence. */
    val needsSilentAudio: Boolean get() = items.any { it.isImage } && items.any { !it.isImage }

    companion object {
        /** Smallest preview side; Media3 needs a non-empty, even-sized surface. */
        const val MIN_SIDE = 2

        /** Slowest and fastest clip speed; matches the Dart model's `SpeedLimits`. */
        const val MIN_SPEED = 0.1f
        const val MAX_SPEED = 10f

        /** Used when the spec has no usable frame rate. */
        const val DEFAULT_FRAME_RATE = 30

        /**
         * Builds a plan. Trims are clamped into the source; clips that end up empty
         * are dropped. [mimeTypeOf] resolves each URI's MIME type (null = unknown).
         */
        fun of(spec: CompositionSpec, mimeTypeOf: (String) -> String? = { null }): CompositionPlan {
            val items = spec.clips.mapNotNull { clip ->
                val sourceDuration = clip.sourceDurationUs
                if (sourceDuration <= 0) return@mapNotNull null
                val start = clip.sourceInUs.coerceIn(0, sourceDuration)
                val end = clip.sourceOutUs.coerceIn(0, sourceDuration)
                if (end <= start) return@mapNotNull null
                val isImage = clip.kind == SpecMediaKind.IMAGE
                PlannedItem(
                    uri = clip.uri,
                    mimeType = mimeTypeOf(clip.uri),
                    isImage = isImage,
                    // A still has no source timeline: it simply shows for the trimmed length.
                    sourceDurationUs = if (isImage) end - start else sourceDuration,
                    clipStartUs = if (isImage) 0 else start,
                    clipEndUs = if (isImage) end - start else end,
                    // Stills show for their trimmed length; speed only applies to video.
                    speed = if (isImage) 1f else speedOf(clip.speed),
                    keepPitch = clip.keepPitch,
                )
            }
            val rate = spec.frameRate.toInt().takeIf { it in 1..240 } ?: DEFAULT_FRAME_RATE
            return CompositionPlan(items, even(spec.canvasWidth), even(spec.canvasHeight), rate)
        }

        /** A usable speed: NaN and non-positive speeds play normally, others are clamped. */
        internal fun speedOf(speed: Double): Float =
            if (speed.isNaN() || speed <= 0.0) 1f else speed.toFloat().coerceIn(MIN_SPEED, MAX_SPEED)

        /** Rounds down to an even size of at least [MIN_SIDE] (video encoders need even sides). */
        internal fun even(px: Long): Int = (px.coerceIn(MIN_SIDE.toLong(), 8192L).toInt() / 2) * 2
    }
}

/** One clip of the main sequence, in microseconds. */
data class PlannedItem(
    val uri: String,
    val mimeType: String?,
    val isImage: Boolean,
    /** Whole source length (videos) or display length (images). */
    val sourceDurationUs: Long,
    val clipStartUs: Long,
    val clipEndUs: Long,
    /** Constant playback speed (1 = normal). */
    val speed: Float = 1f,
    /** Whether sped-up or slowed-down audio keeps its pitch. */
    val keepPitch: Boolean = true,
) {
    /** Length of the used source range. */
    val clippedDurationUs: Long get() = clipEndUs - clipStartUs

    /** Length on the timeline after [speed], rounded like the Dart model. */
    val timelineDurationUs: Long get() = Math.round(clippedDurationUs / speed.toDouble())

    /** Whether the item plays at a speed other than 1. */
    val hasSpeedChange: Boolean get() = speed != 1f

    /** Display length of a still in whole ms; Media3 rejects 0, so at least 1. */
    val imageDurationMs: Long get() = (sourceDurationUs / 1000).coerceAtLeast(1L)
}
