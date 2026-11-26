package com.hussainhacko.cleancut.engine

import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.SpeedParameters
import androidx.media3.common.audio.SpeedProvider
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
     * Swaps in the looks of [plan], which must have the same structure (see
     * [CompositionPlan.structureKey]) as the plan this was built from.
     */
    fun updateLooks(plan: CompositionPlan) {
        background.background = plan.background
        plan.items.forEachIndexed { i, item -> looks[i].style = item.style }
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
        val looks = plan.items.zip(plan.timelineStartsUs) { item, start -> LiveClipLook(item.style, start) }
        val items = plan.items.mapIndexed { i, item ->
            // Every clip renders onto the full canvas: background, fit, crop, transform, border.
            val render = ClipRenderEffect(looks[i], background, plan.width, plan.height)
            editedItem(item, plan.frameRate, render)
        }
        val sequence = EditedMediaItemSequence.Builder(items)
            // Stills have no audio; pad them with silence so audio and video stay aligned.
            .experimentalSetForceAudioTrack(plan.needsSilentAudio)
            .build()
        return ComposedPlan(Composition.Builder(sequence).build(), looks, background)
    }

    private fun editedItem(item: PlannedItem, frameRate: Int, render: ClipRenderEffect): EditedMediaItem {
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
            .setEffects(Effects(emptyList(), listOf(render)))
            .build()
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
