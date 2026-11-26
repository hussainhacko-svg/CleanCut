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
                    speedSteps = if (isImage) emptyList() else stepsOf(clip.speedSteps, end - start),
                )
            }
            val rate = spec.frameRate.toInt().takeIf { it in 1..240 } ?: DEFAULT_FRAME_RATE
            return CompositionPlan(items, even(spec.canvasWidth), even(spec.canvasHeight), rate)
        }

        /**
         * Usable curve steps within a clip of [clippedUs]: sorted, inside the clip,
         * starting at 0, with usable speeds. Empty when there is no curve.
         */
        internal fun stepsOf(steps: List<SpeedStepSpec>, clippedUs: Long): List<SpeedStep> {
            val inside = steps
                .filter { it.startUs in 0 until clippedUs }
                .sortedBy { it.startUs }
                .distinctBy { it.startUs }
                .map { SpeedStep(it.startUs, speedOf(it.speed)) }
            if (inside.isEmpty()) return emptyList()
            // The first step must start the clip; stretch it back to 0 if needed.
            return listOf(inside.first().copy(startUs = 0)) + inside.drop(1)
        }

        /** A usable speed: NaN and non-positive speeds play normally, others are clamped. */
        internal fun speedOf(speed: Double): Float =
            if (speed.isNaN() || speed <= 0.0) 1f else speed.toFloat().coerceIn(MIN_SPEED, MAX_SPEED)

        /** Rounds down to an even size of at least [MIN_SIDE] (video encoders need even sides). */
        internal fun even(px: Long): Int = (px.coerceIn(MIN_SIDE.toLong(), 8192L).toInt() / 2) * 2
    }
}

/** A constant-speed piece of a curve, from [startUs] (source time from the trim start). */
data class SpeedStep(val startUs: Long, val speed: Float)

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
    /** A speed curve as constant-speed steps (first at 0); replaces [speed] when not empty. */
    val speedSteps: List<SpeedStep> = emptyList(),
) {
    /** Length of the used source range. */
    val clippedDurationUs: Long get() = clipEndUs - clipStartUs

    /** Length on the timeline after [speed] or [speedSteps], rounded like the Dart model. */
    val timelineDurationUs: Long
        get() {
            if (speedSteps.isEmpty()) return Math.round(clippedDurationUs / speed.toDouble())
            var total = 0.0
            for (i in speedSteps.indices) {
                val end = speedSteps.getOrNull(i + 1)?.startUs ?: clippedDurationUs
                total += (end - speedSteps[i].startUs) / speedSteps[i].speed.toDouble()
            }
            return Math.round(total)
        }

    /** Whether the item plays at a speed other than 1. */
    val hasSpeedChange: Boolean get() = speedSteps.isNotEmpty() || speed != 1f

    /** Speed at [timeUs] (source time from the trim start), following [speedSteps] if any. */
    fun speedAt(timeUs: Long): Float {
        if (speedSteps.isEmpty()) return speed
        return speedSteps[stepIndexAt(timeUs)].speed
    }

    /** Start of the next speed step after [timeUs], or null when the speed no longer changes. */
    fun nextSpeedChangeUs(timeUs: Long): Long? {
        if (speedSteps.isEmpty()) return null
        return speedSteps.getOrNull(stepIndexAt(timeUs) + 1)?.startUs
    }

    /** Index of the last step starting at or before [timeUs] (0 before the first). */
    private fun stepIndexAt(timeUs: Long): Int {
        var lo = 0
        var hi = speedSteps.size - 1
        while (lo < hi) {
            val mid = (lo + hi + 1) / 2
            if (speedSteps[mid].startUs <= timeUs) lo = mid else hi = mid - 1
        }
        return lo
    }

    /** Display length of a still in whole ms; Media3 rejects 0, so at least 1. */
    val imageDurationMs: Long get() = (sourceDurationUs / 1000).coerceAtLeast(1L)
}
