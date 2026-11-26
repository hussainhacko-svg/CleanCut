package com.hussainhacko.cleancut.engine

import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.SpeedParameters
import androidx.media3.common.audio.SpeedProvider
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.Presentation
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects

/**
 * Builds the Media3 [Composition] for a [CompositionPlan]. Preview and export both
 * use this, so what the user sees is what gets exported (AGENTS.md §3).
 */
@OptIn(UnstableApi::class)
object Media3Composer {
    fun build(plan: CompositionPlan): Composition {
        require(plan.items.isNotEmpty()) { "An empty plan has no composition" }
        val items = plan.items.map { editedItem(it, plan.frameRate) }
        val sequence = EditedMediaItemSequence.Builder(items)
            // Stills have no audio; pad them with silence so audio and video stay aligned.
            .experimentalSetForceAudioTrack(plan.needsSilentAudio)
            .build()
        // Every clip is fitted (letterboxed) into the canvas; fill modes arrive in Phase 5.
        val fitToCanvas = Presentation.createForWidthAndHeight(
            plan.width,
            plan.height,
            Presentation.LAYOUT_SCALE_TO_FIT,
        )
        return Composition.Builder(sequence)
            .setEffects(Effects(emptyList(), listOf(fitToCanvas)))
            .build()
    }

    private fun editedItem(item: PlannedItem, frameRate: Int): EditedMediaItem {
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
                    setSpeed(SpeedParameters(ConstantSpeedProvider(item.speed), item.keepPitch))
                }
            }
            .build()
    }
}

/** Plays a whole clip at one [speed] (Flow without a curve). */
internal class ConstantSpeedProvider(private val speed: Float) : SpeedProvider {
    override fun getSpeed(timeUs: Long): Float = speed

    override fun getNextSpeedChangeTimeUs(timeUs: Long): Long = C.TIME_UNSET
}
