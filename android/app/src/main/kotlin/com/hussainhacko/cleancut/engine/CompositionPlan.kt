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
    val background: BackgroundStyle = BackgroundStyle.DEFAULT,
) {
    /** Length of the sequence: sum of clip lengths minus active transition overlaps. */
    val durationUs: Long
        get() = if (items.isEmpty()) 0L else timelineStartsUs.last() + items.last().timelineDurationUs

    /** Timeline start of each item, accounting for overlapping transitions. */
    val timelineStartsUs: List<Long>
        get() {
            if (items.isEmpty()) return emptyList()
            val starts = ArrayList<Long>(items.size)
            var start = 0L
            for (i in items.indices) {
                starts.add(start)
                if (i < items.lastIndex) {
                    start += items[i].timelineDurationUs - overlapAfter(i)
                }
            }
            return starts
        }

    /** Effective transition overlap in µs between item [index] and [index] + 1. */
    fun overlapAfter(index: Int): Long {
        if (index !in 0 until items.lastIndex) return 0L
        val t = items[index].transitionOut ?: return 0L
        if (t.durationUs <= 0L) return 0L
        val cap = minOf(
            MAX_TRANSITION_US,
            minOf(items[index].timelineDurationUs, items[index + 1].timelineDurationUs) / 2L,
        )
        val overlap = minOf(t.durationUs, cap)
        // Clips too short for the minimum play as a hard cut (matches Dart).
        return if (overlap < MIN_TRANSITION_US) 0L else overlap
    }

    /** Effective transition overlap in µs before item [index]. */
    fun overlapBefore(index: Int): Long = if (index <= 0) 0L else overlapAfter(index - 1)

    /** True when at least one boundary has a non-zero transition overlap. */
    val hasTransitions: Boolean get() = (0 until items.lastIndex).any { overlapAfter(it) > 0L }

    /** True when at least one item is a video (may carry audio). */
    val hasVideo: Boolean get() = items.any { !it.isImage }

    /** Incoming and outgoing transitions for item [index] in clip-relative time. */
    fun clipTransitionsFor(index: Int): ClipTransitions {
        if (index !in items.indices) return ClipTransitions.NONE
        val isTopLayer = index % 2 == 0
        val inOverlap = overlapBefore(index)
        val incoming = if (inOverlap > 0L) {
            val type = items[index - 1].transitionOut?.type
            if (type != null) {
                ActiveTransition(
                    type = type,
                    startUs = 0L,
                    durationUs = inOverlap,
                    isOutgoing = false,
                    isTopLayer = isTopLayer,
                )
            } else {
                null
            }
        } else {
            null
        }
        val outOverlap = overlapAfter(index)
        val outgoing = if (outOverlap > 0L) {
            val type = items[index].transitionOut?.type
            if (type != null) {
                ActiveTransition(
                    type = type,
                    startUs = items[index].timelineDurationUs - outOverlap,
                    durationUs = outOverlap,
                    isOutgoing = true,
                    isTopLayer = isTopLayer,
                )
            } else {
                null
            }
        } else {
            null
        }
        return ClipTransitions(incoming = incoming, outgoing = outgoing)
    }

    /**
     * Ordered clips and gaps for A/B roll [lane] (`0` = even items, `1` = odd items),
     * covering `[0, durationUs]` with no zero-length gaps.
     */
    fun laneSegments(lane: Int): List<LaneSegment> {
        val starts = timelineStartsUs
        val total = durationUs
        val segments = mutableListOf<LaneSegment>()
        var cursor = 0L
        for (i in items.indices) {
            if (i % 2 != lane) continue
            val start = starts[i]
            val end = start + items[i].timelineDurationUs
            if (start > cursor) {
                segments.add(LaneSegment.Gap(cursor, start))
            }
            segments.add(LaneSegment.Clip(i, start, end))
            cursor = end
        }
        if (total > cursor) {
            segments.add(LaneSegment.Gap(cursor, total))
        }
        return segments
    }

    /**
     * Whether [lane] (`0` = even, `1` = odd) holds an active clip (not a gap) at
     * composition timestamp [presentationTimeUs].
     */
    fun isLaneActiveAt(lane: Int, presentationTimeUs: Long): Boolean {
        if (items.isEmpty()) return false
        val starts = timelineStartsUs
        val total = durationUs
        if (presentationTimeUs >= total) {
            return items.lastIndex % 2 == lane
        }
        for (i in items.indices) {
            if (i % 2 != lane) continue
            val start = starts[i]
            val end = start + items[i].timelineDurationUs
            if (presentationTimeUs >= start && presentationTimeUs < end) return true
        }
        return false
    }

    /**
     * The plan without its looks (clip styles, background, and transition types — keeping
     * transition durations because overlaps change track timing). Two plans with the same key
     * play the same media with the same timing, so the preview can swap looks and transition
     * types live without rebuilding.
     */
    val structureKey: CompositionPlan
        get() = copy(
            items = items.mapIndexed { i, item ->
                val overlap = overlapAfter(i)
                item.copy(
                    style = ClipStyle.DEFAULT,
                    transitionOut = if (overlap > 0L) ClipTransition(TransitionType.DISSOLVE, overlap) else null,
                )
            },
            background = BackgroundStyle.DEFAULT,
        )

    /** True when stills and videos mix, so audio must be padded with silence. */
    val needsSilentAudio: Boolean get() = items.any { it.isImage } && items.any { !it.isImage }

    companion object {
        /** Smallest preview side; Media3 needs a non-empty, even-sized surface. */
        const val MIN_SIDE = 2

        /** Slowest and fastest clip speed; matches the Dart model's `SpeedLimits`. */
        const val MIN_SPEED = 0.1f
        const val MAX_SPEED = 10f

        /** Longest transition overlap (3 s); matches Dart `TransitionLimits.maxDurationUs`. */
        const val MAX_TRANSITION_US = 3_000_000L

        /** Shortest transition overlap (0.1 s); matches Dart `TransitionLimits.minDurationUs`. */
        const val MIN_TRANSITION_US = 100_000L

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
                    style = ClipStyle.of(clip.style),
                    transitionOut = ClipTransition.of(clip.transitionOut),
                )
            }
            val rate = spec.frameRate.toInt().takeIf { it in 1..240 } ?: DEFAULT_FRAME_RATE
            return CompositionPlan(
                items,
                even(spec.canvasWidth),
                even(spec.canvasHeight),
                rate,
                BackgroundStyle.of(spec.background),
            )
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
            val normalized = listOf(inside.first().copy(startUs = 0)) + inside.drop(1)
            // Collapse adjacent equal-speed steps so flat stretches add no extra boundaries.
            return buildList {
                for (step in normalized) {
                    if (isEmpty() || last().speed != step.speed) add(step)
                }
            }
        }

        /** A usable speed: NaN and non-positive speeds play normally, others are clamped. */
        internal fun speedOf(speed: Double): Float =
            if (speed.isNaN() || speed <= 0.0) 1f else speed.toFloat().coerceIn(MIN_SPEED, MAX_SPEED)

        /** Rounds down to an even size of at least [MIN_SIDE] (video encoders need even sides). */
        internal fun even(px: Long): Int = (px.coerceIn(MIN_SIDE.toLong(), 8192L).toInt() / 2) * 2
    }
}

/** One entry in an A/B roll lane sequence when transitions are active. */
sealed class LaneSegment {
    abstract val startUs: Long
    abstract val endUs: Long
    val durationUs: Long get() = endUs - startUs

    data class Clip(val itemIndex: Int, override val startUs: Long, override val endUs: Long) : LaneSegment()
    data class Gap(override val startUs: Long, override val endUs: Long) : LaneSegment()
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
    /** Fit, crop, transform and border. */
    val style: ClipStyle = ClipStyle.DEFAULT,
    /** Optional transition into the next clip. */
    val transitionOut: ClipTransition? = null,
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
    val hasSpeedChange: Boolean
        get() = if (speedSteps.isNotEmpty()) speedSteps.any { it.speed != 1f } else speed != 1f

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
