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
    /** Overlay (PiP) tracks, frontmost first (index 0 renders on top). */
    val overlayTracks: List<PlannedOverlayTrack> = emptyList(),
) {
    /** Length of the main track: sum of clip lengths minus active transition overlaps. */
    val mainDurationUs: Long
        get() = if (items.isEmpty()) 0L else timelineStartsUs.last() + items.last().timelineDurationUs

    /** Total length of the composition across main track and all overlay tracks. */
    val durationUs: Long
        get() = maxOf(mainDurationUs, overlayTracks.maxOfOrNull { it.endUs } ?: 0L)

    /** True when neither the main track nor any overlay track has clips. */
    val isEmpty: Boolean
        get() = items.isEmpty() && overlayTracks.all { it.items.isEmpty() }

    /** Timeline start of each main-track item, accounting for overlapping transitions. */
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

    /** True when at least one main-track boundary has a non-zero transition overlap. */
    val hasTransitions: Boolean get() = (0 until items.lastIndex).any { overlapAfter(it) > 0L }

    /** True when at least one overlay track holds a clip. */
    val hasOverlays: Boolean get() = overlayTracks.any { it.items.isNotEmpty() }

    /** True when Media3 must composite multiple sequences (transitions and/or overlays). */
    val isMultiSequence: Boolean get() = hasTransitions || hasOverlays

    /** True when at least one main-track item is an unmuted video (may carry audio). */
    val hasVideo: Boolean get() = items.any { !it.isImage && !it.muted }

    /** True when main-track audible videos mix with stills or muted clips, needing silence padding. */
    val needsSilentAudio: Boolean get() = hasVideo && items.any { it.isImage || it.muted }

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
     * Ordered clips and optional trailing gap for a single-lane main track inside a
     * multi-sequence composition (when overlays are present without transitions).
     */
    fun mainSingleSegments(): List<LaneSegment> {
        val starts = timelineStartsUs
        val segments = mutableListOf<LaneSegment>()
        var cursor = 0L
        for (i in items.indices) {
            val start = starts[i]
            val end = start + items[i].timelineDurationUs
            segments.add(LaneSegment.Clip(i, start, end))
            cursor = end
        }
        if (durationUs > cursor) {
            segments.add(LaneSegment.Gap(cursor, durationUs))
        }
        return segments
    }

    /**
     * Whether A/B roll [lane] (`0` = even, `1` = odd) holds an active clip (not a gap) at
     * composition timestamp [presentationTimeUs].
     */
    fun isLaneActiveAt(lane: Int, presentationTimeUs: Long): Boolean {
        if (items.isEmpty()) return false
        val starts = timelineStartsUs
        val mainEnd = mainDurationUs
        if (presentationTimeUs >= mainEnd) {
            // Only hold the last main clip at the very end if nothing extends past it.
            return mainEnd == durationUs && items.lastIndex % 2 == lane
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
     * Times (µs, ascending) where a sequence of a multi-sequence composition moves from an
     * earlier segment (gap or clip) into a video clip. Media3 1.11.1 (still in 1.12.0-rc01)
     * never starts such a video during playback: that sequence's player stays on its earlier
     * item. Starting a player inside the video works, so the preview restarts there
     * ([PreviewPlayer]). Empty for a single-sequence composition, which plays through fine.
     */
    val videoEntryTimesUs: List<Long>
        get() {
            if (!isMultiSequence) return emptyList()
            val times = sortedSetOf<Long>()
            fun scan(segments: List<LaneSegment>, isVideo: (Int) -> Boolean) {
                segments.forEachIndexed { k, segment ->
                    if (k > 0 && segment is LaneSegment.Clip && isVideo(segment.itemIndex)) times.add(segment.startUs)
                }
            }
            val total = durationUs
            overlayTracks.forEach { track -> scan(track.segments(total)) { !track.items[it].item.isImage } }
            if (items.isNotEmpty()) {
                val isVideo = { i: Int -> !items[i].isImage }
                if (hasTransitions) (0..1).forEach { scan(laneSegments(it), isVideo) } else scan(mainSingleSegments(), isVideo)
            }
            return times.toList()
        }

    /**
     * Times (µs, ascending) where any sequence of a multi-sequence composition switches from
     * one segment to the next, excluding 0 and the end. Empty for a single sequence.
     */
    val itemBoundariesUs: List<Long>
        get() {
            if (!isMultiSequence) return emptyList()
            val total = durationUs
            val times = sortedSetOf<Long>()
            fun scan(segments: List<LaneSegment>) {
                segments.forEach { if (it.startUs in 1 until total) times.add(it.startUs) }
            }
            overlayTracks.forEach { scan(it.segments(total)) }
            if (items.isNotEmpty()) {
                if (hasTransitions) (0..1).forEach { scan(laneSegments(it)) } else scan(mainSingleSegments())
            }
            return times.toList()
        }

    /**
     * Where to start a paused multi-sequence preview asked for [positionMs]. A paused start on
     * (or just before) a sequence's last frame right before it switches items showed only the top sequence,
     * the rest black (Media3 1.11.1), so such a start moves two frames back: the same clip
     * end on screen, with no sequence mid-switch. Other positions are returned unchanged.
     */
    fun safePausedStartMs(positionMs: Long): Long {
        val frameUs = 1_000_000L / frameRate
        val positionUs = positionMs * 1000
        // 1.5 frames: a seek to "last frame" arrives rounded to whole ms, a hair early.
        val boundary = itemBoundariesUs.firstOrNull { positionUs < it && positionUs >= it - frameUs * 3 / 2 }
            ?: return positionMs
        return ((boundary - 2 * frameUs) / 1000).coerceAtLeast(0L)
    }

    /** The first of [videoEntryTimesUs] strictly after [positionUs], or null. */
    fun nextVideoEntryAfterUs(positionUs: Long): Long? = videoEntryTimesUs.firstOrNull { it > positionUs }

    /**
     * Whether compositor sequence [inputId] holds an active clip (not a gap) at
     * [presentationTimeUs].
     *
     * Sequence order (index 0 = frontmost / top in Media3 `DefaultVideoCompositor`):
     * - `0 until overlayTracks.size`: overlay tracks (frontmost first)
     * - followed by main track: either 1 sequence (no transitions) or 2 A/B lanes (transitions)
     */
    fun isSequenceActiveAt(inputId: Int, presentationTimeUs: Long): Boolean {
        val overlayCount = overlayTracks.size
        if (inputId in 0 until overlayCount) {
            return overlayTracks[inputId].isActiveAt(presentationTimeUs, durationUs)
        }
        if (items.isEmpty()) return false
        val mainOffset = inputId - overlayCount
        if (hasTransitions) {
            return if (mainOffset in 0..1) isLaneActiveAt(mainOffset, presentationTimeUs) else false
        }
        if (mainOffset != 0) return false
        return isMainActiveAt(presentationTimeUs)
    }

    /**
     * Whether a main-track clip shows at [presentationTimeUs] (the last frame holds at the very
     * end only when no overlay runs past the main track).
     */
    fun isMainActiveAt(presentationTimeUs: Long): Boolean {
        if (items.isEmpty()) return false
        val mainEnd = mainDurationUs
        return presentationTimeUs < mainEnd || mainEnd == durationUs
    }

    /**
     * Whether overlay track [trackIndex] must paint the canvas background itself at
     * [presentationTimeUs]: no main clip and no lower overlay track (higher index) is showing,
     * so without it the overlay would sit on black.
     */
    fun overlayDrawsBackgroundAt(trackIndex: Int, presentationTimeUs: Long): Boolean {
        if (isMainActiveAt(presentationTimeUs)) return false
        val total = durationUs
        return (trackIndex + 1 until overlayTracks.size).none {
            overlayTracks[it].isActiveAt(presentationTimeUs, total)
        }
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
            overlayTracks = overlayTracks.map { track ->
                track.copy(
                    items = track.items.map { placed ->
                        placed.copy(
                            item = placed.item.copy(
                                style = ClipStyle.DEFAULT,
                                transitionOut = null,
                            ),
                        )
                    },
                )
            },
            background = BackgroundStyle.DEFAULT,
        )

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
            val items = spec.clips.mapNotNull { clip -> plannedItemOf(clip, mimeTypeOf) }
            val overlays = spec.overlayTracks.mapNotNull { track ->
                val placed = track.clips
                    .mapNotNull { p ->
                        val item = plannedItemOf(p.clip, mimeTypeOf) ?: return@mapNotNull null
                        PlannedOverlay(startUs = p.startUs.coerceAtLeast(0L), item = item)
                    }
                    .sortedBy { it.startUs }
                if (placed.isEmpty()) null else PlannedOverlayTrack(placed)
            }
            val rate = spec.frameRate.toInt().takeIf { it in 1..240 } ?: DEFAULT_FRAME_RATE
            return CompositionPlan(
                items = items,
                width = even(spec.canvasWidth),
                height = even(spec.canvasHeight),
                frameRate = rate,
                background = BackgroundStyle.of(spec.background),
                overlayTracks = overlays,
            )
        }

        private fun plannedItemOf(
            clip: ClipSpec,
            mimeTypeOf: (String) -> String?,
        ): PlannedItem? {
            val sourceDuration = clip.sourceDurationUs
            if (sourceDuration <= 0) return null
            val start = clip.sourceInUs.coerceIn(0, sourceDuration)
            val end = clip.sourceOutUs.coerceIn(0, sourceDuration)
            if (end <= start) return null
            val isImage = clip.kind == SpecMediaKind.IMAGE
            return PlannedItem(
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
                muted = clip.muted,
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

/** One overlay clip placed at timeline time [startUs]. */
data class PlannedOverlay(
    val startUs: Long,
    val item: PlannedItem,
) {
    /** Timeline end time (exclusive) in microseconds. */
    val endUs: Long get() = startUs + item.timelineDurationUs
}

/** One overlay track of non-overlapping clips, sorted by start time. */
data class PlannedOverlayTrack(
    val items: List<PlannedOverlay>,
) {
    /** Timeline end of the latest item on this track. */
    val endUs: Long get() = items.maxOfOrNull { it.endUs } ?: 0L

    /** True when at least one item on this track carries unmuted audio. */
    val hasAudio: Boolean get() = items.any { !it.item.isImage && !it.item.muted }

    /**
     * Ordered clips and gaps covering `[0, totalDurationUs]` with no zero-length gaps.
     */
    fun segments(totalDurationUs: Long): List<LaneSegment> {
        val segments = mutableListOf<LaneSegment>()
        var cursor = 0L
        for (i in items.indices) {
            val placed = items[i]
            val start = placed.startUs.coerceAtLeast(cursor)
            val end = start + placed.item.timelineDurationUs
            if (start > cursor) {
                segments.add(LaneSegment.Gap(cursor, start))
            }
            segments.add(LaneSegment.Clip(i, start, end))
            cursor = end
        }
        if (totalDurationUs > cursor) {
            segments.add(LaneSegment.Gap(cursor, totalDurationUs))
        }
        return segments
    }

    /** Whether any clip on this track is active (not in a gap) at [presentationTimeUs]. */
    fun isActiveAt(presentationTimeUs: Long, totalDurationUs: Long): Boolean {
        if (items.isEmpty()) return false
        if (presentationTimeUs >= totalDurationUs) {
            return items.last().endUs >= totalDurationUs
        }
        for (placed in items) {
            if (presentationTimeUs >= placed.startUs && presentationTimeUs < placed.endUs) {
                return true
            }
        }
        return false
    }
}

/** One entry in a sequence (main A/B lane, single main lane, or overlay lane). */
sealed class LaneSegment {
    abstract val startUs: Long
    abstract val endUs: Long
    val durationUs: Long get() = endUs - startUs

    data class Clip(val itemIndex: Int, override val startUs: Long, override val endUs: Long) : LaneSegment()
    data class Gap(override val startUs: Long, override val endUs: Long) : LaneSegment()
}

/** A constant-speed piece of a curve, from [startUs] (source time from the trim start). */
data class SpeedStep(val startUs: Long, val speed: Float)

/** One clip of a main or overlay sequence, in microseconds. */
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
    /** Whether this clip's audio is muted. */
    val muted: Boolean = false,
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
