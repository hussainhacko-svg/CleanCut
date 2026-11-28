package com.hussainhacko.cleancut.engine

import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.OverlaySettings
import androidx.media3.common.SpeedParameters
import androidx.media3.common.VideoCompositorSettings
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.DefaultGainProvider
import androidx.media3.common.audio.GainProcessor
import androidx.media3.common.audio.SpeedProvider
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects

/** A built composition plus the handles that change its looks without a rebuild. */
class ComposedPlan(
    val composition: Composition,
    /** One per plan item, in order. */
    val looks: List<LiveClipLook>,
    val background: LiveBackground,
) {
    /**
     * Swaps in the looks and transition types of [plan], which must have the same structure
     * (see [CompositionPlan.structureKey]) as the plan this was built from.
     */
    fun updateLooks(plan: CompositionPlan) {
        background.background = plan.background
        plan.items.forEachIndexed { i, item ->
            looks[i].style = item.style
            looks[i].transitions = plan.clipTransitionsFor(i)
        }
    }
}

/**
 * Builds the Media3 [Composition] for a [CompositionPlan]. Preview and export both
 * use this, so what the user sees is what gets exported (AGENTS.md §3).
 */
@OptIn(UnstableApi::class)
object Media3Composer {
    fun build(plan: CompositionPlan): ComposedPlan {
        require(plan.items.isNotEmpty()) { "An empty plan has no composition" }
        val background = LiveBackground(plan.background)
        val starts = plan.timelineStartsUs
        val looks = plan.items.mapIndexed { i, item ->
            LiveClipLook(item.style, starts[i], plan.clipTransitionsFor(i))
        }
        if (!plan.hasTransitions) {
            val items = plan.items.mapIndexed { i, item ->
                val render = ClipRenderEffect(looks[i], background, plan.width, plan.height)
                editedItem(item, plan.frameRate, render, audioProcessors = emptyList())
            }
            // Same as before Phase 6C: one sequence, stills padded with silence so
            // audio and video stay aligned.
            val sequence = EditedMediaItemSequence.Builder(items)
                .experimentalSetForceAudioTrack(plan.needsSilentAudio)
                .build()
            return ComposedPlan(Composition.Builder(sequence).build(), looks, background)
        }

        // A/B roll: even clips on lane 0 (top), odd clips on lane 1 (bottom), padded with gaps
        // so both sequences span [0, durationUs] and overlap cleanly across every transition.
        val laneTracks = if (plan.hasVideo) {
            setOf(C.TRACK_TYPE_VIDEO, C.TRACK_TYPE_AUDIO)
        } else {
            setOf(C.TRACK_TYPE_VIDEO)
        }
        val sequences = (0..1).map { lane ->
            val builder = EditedMediaItemSequence.Builder(laneTracks)
            for (segment in plan.laneSegments(lane)) {
                when (segment) {
                    is LaneSegment.Gap -> builder.addGap(segment.durationUs)
                    is LaneSegment.Clip -> {
                        val i = segment.itemIndex
                        val item = plan.items[i]
                        val render = ClipRenderEffect(looks[i], background, plan.width, plan.height)
                        val audio = audioCrossfadeProcessors(
                            item,
                            inOverlapUs = plan.overlapBefore(i),
                            outOverlapUs = plan.overlapAfter(i),
                        )
                        builder.addItem(editedItem(item, plan.frameRate, render, audio))
                    }
                }
            }
            builder.build()
        }
        val composition = Composition.Builder(sequences)
            .setVideoCompositorSettings(TransitionCompositorSettings(plan))
            .build()
        return ComposedPlan(composition, looks, background)
    }

    private fun editedItem(
        item: PlannedItem,
        frameRate: Int,
        render: ClipRenderEffect,
        audioProcessors: List<AudioProcessor>,
    ): EditedMediaItem {
        val media = MediaItem.Builder().setUri(item.uri)
        item.mimeType?.let(media::setMimeType)
        if (item.isImage) {
            media.setImageDurationMs(item.imageDurationMs)
        } else {
            media.setClippingConfiguration(
                MediaItem.ClippingConfiguration.Builder()
                    .setStartPositionUs(item.clipStartUs)
                    .setEndPositionUs(item.clipEndUs)
                    .build(),
            )
        }
        return EditedMediaItem.Builder(media.build())
            .setDurationUs(item.sourceDurationUs)
            .apply { if (item.isImage) setFrameRate(frameRate) }
            .apply {
                if (item.hasSpeedChange) {
                    setSpeed(SpeedParameters(ItemSpeedProvider(item), item.keepPitch))
                }
            }
            .setEffects(Effects(audioProcessors, listOf(render)))
            .build()
    }

    /** Equal-power audio fade-in / fade-out across transition overlaps on a video clip. */
    private fun audioCrossfadeProcessors(
        item: PlannedItem,
        inOverlapUs: Long,
        outOverlapUs: Long,
    ): List<AudioProcessor> {
        if (item.isImage || (inOverlapUs <= 1L && outOverlapUs <= 1L)) return emptyList()
        val builder = DefaultGainProvider.Builder(1.0f)
        if (inOverlapUs > 1L) {
            builder.addFadeAt(0L, inOverlapUs, DefaultGainProvider.FADE_IN_EQUAL_POWER)
        }
        if (outOverlapUs > 1L) {
            val fadeOutStart = (item.timelineDurationUs - outOverlapUs).coerceAtLeast(0L)
            builder.addFadeAt(fadeOutStart, outOverlapUs, DefaultGainProvider.FADE_OUT_EQUAL_POWER)
        }
        return listOf(GainProcessor(builder.build()))
    }
}

/**
 * Keeps the output sized to the canvas (even when lane 0 is inside a blank-frame gap) and hides
 * whichever A/B roll lane is currently in a gap so the active lane shines through.
 */
@OptIn(UnstableApi::class)
internal class TransitionCompositorSettings(
    private val plan: CompositionPlan,
) : VideoCompositorSettings {
    override fun getOutputSize(inputSizes: List<Size>): Size = Size(plan.width, plan.height)

    override fun getOverlaySettings(inputId: Int, presentationTimeUs: Long): OverlaySettings =
        if (plan.isLaneActiveAt(inputId, presentationTimeUs)) OPAQUE else HIDDEN

    private companion object {
        val OPAQUE = object : OverlaySettings {}
        val HIDDEN = object : OverlaySettings {
            override fun getAlphaScale(): Float = 0f
        }
    }
}

/**
 * Plays a clip at its constant speed or along its speed-curve steps (Flow).
 * Media3 passes source times measured from the clip's trim start.
 */
internal class ItemSpeedProvider(private val item: PlannedItem) : SpeedProvider {
    override fun getSpeed(timeUs: Long): Float = item.speedAt(timeUs)

    override fun getNextSpeedChangeTimeUs(timeUs: Long): Long =
        item.nextSpeedChangeUs(timeUs) ?: C.TIME_UNSET
}
