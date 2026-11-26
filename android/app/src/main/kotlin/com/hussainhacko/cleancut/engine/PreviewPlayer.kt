package com.hussainhacko.cleancut.engine

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.CompositionPlayer
import io.flutter.view.TextureRegistry

/** Receives the preview's events on the main thread. */
interface PreviewListener {
    fun onState(state: PlayerStateEvent)
    fun onPosition(textureId: Long, positionUs: Long)
    fun onError(textureId: Long, code: String, message: String)
}

/**
 * Plays a composition with Media3's [CompositionPlayer] into a Flutter texture.
 * Must be used on the main thread.
 */
@OptIn(UnstableApi::class)
class PreviewPlayer(
    context: Context,
    private val producer: TextureRegistry.SurfaceProducer,
    private val listener: PreviewListener,
) {
    private val player = CompositionPlayer.Builder(context).build()
    private val handler = Handler(Looper.getMainLooper())
    private var size = Size(CompositionPlan.MIN_SIDE, CompositionPlan.MIN_SIDE)
    private var hasComposition = false

    /** The playing composition's live looks and the structure they belong to. */
    private var composed: ComposedPlan? = null
    private var structure: CompositionPlan? = null
    private var released = false

    private val ticker = object : Runnable {
        override fun run() {
            listener.onPosition(textureId, positionUs())
            handler.postDelayed(this, POSITION_INTERVAL_MS)
        }
    }

    init {
        player.addListener(
            object : Player.Listener {
                override fun onEvents(player: Player, events: Player.Events) {
                    if (events.containsAny(
                            Player.EVENT_PLAYBACK_STATE_CHANGED,
                            Player.EVENT_IS_PLAYING_CHANGED,
                            Player.EVENT_TIMELINE_CHANGED,
                            Player.EVENT_POSITION_DISCONTINUITY,
                        )
                    ) {
                        listener.onState(state())
                    }
                    if (events.contains(Player.EVENT_IS_PLAYING_CHANGED)) updateTicker()
                }

                override fun onPlayerError(error: PlaybackException) {
                    listener.onError(textureId, error.errorCodeName, error.message.orEmpty())
                }
            },
        )
        producer.setCallback(
            object : TextureRegistry.SurfaceProducer.Callback {
                // The surface is recreated e.g. after the app returns from the background.
                override fun onSurfaceAvailable() = attachSurface()

                override fun onSurfaceCleanup() = player.clearVideoSurface()
            },
        )
    }

    /** Texture id to show with Flutter's `Texture` widget. */
    val textureId: Long get() = producer.id()

    fun setComposition(spec: CompositionSpec, mimeTypeOf: (String) -> String?) {
        val plan = CompositionPlan.of(spec, mimeTypeOf)
        if (plan.width != size.width || plan.height != size.height) {
            size = Size(plan.width, plan.height)
            producer.setSize(plan.width, plan.height)
        }
        if (plan.items.isEmpty()) {
            // Clear before stop() so any listener callback triggered by stop()
            // also reports an empty timeline rather than stale duration/position.
            hasComposition = false
            player.stop()
            player.clearVideoSurface()
            listener.onState(state())
            return
        }
        val current = composed
        if (hasComposition && current != null && plan.structureKey == structure) {
            // Only looks changed (a slider or gesture): swap them in place, no rebuild.
            current.updateLooks(plan)
            // A paused player shows a stale frame; seeking in place redraws it.
            if (!player.isPlaying) player.seekTo(player.currentPosition)
            return
        }
        val keepMs = if (hasComposition) player.currentPosition else 0L
        val startMs = keepMs.coerceIn(0L, (plan.durationUs / 1000 - 1).coerceAtLeast(0L))
        val built = Media3Composer.build(plan)
        player.setComposition(built.composition, startMs)
        composed = built
        structure = plan.structureKey
        hasComposition = true
        attachSurface()
        player.prepare()
    }

    fun play() {
        if (!hasComposition) return
        // Replaying after the end starts again from the beginning.
        if (player.playbackState == Player.STATE_ENDED) player.seekTo(0)
        player.play()
    }

    fun pause() = player.pause()

    fun seekTo(positionUs: Long) {
        if (!hasComposition) return
        player.seekTo((positionUs.coerceAtLeast(0) + 500) / 1000)
    }

    fun release() {
        if (released) return
        released = true
        handler.removeCallbacks(ticker)
        producer.setCallback(null)
        player.release()
        producer.release()
    }

    private fun attachSurface() {
        if (!released) player.setVideoSurface(producer.surface, size)
    }

    private fun updateTicker() {
        handler.removeCallbacks(ticker)
        if (player.isPlaying) handler.post(ticker)
    }

    private fun positionUs(): Long = player.currentPosition.coerceAtLeast(0L) * 1000

    private fun state(): PlayerStateEvent {
        if (!hasComposition) {
            return PlayerStateEvent(textureId, PlaybackStatus.IDLE, false, 0, 0)
        }
        val durationMs = player.duration
        return PlayerStateEvent(
            textureId = textureId,
            status = when (player.playbackState) {
                Player.STATE_BUFFERING -> PlaybackStatus.BUFFERING
                Player.STATE_READY -> PlaybackStatus.READY
                Player.STATE_ENDED -> PlaybackStatus.ENDED
                else -> PlaybackStatus.IDLE
            },
            isPlaying = player.isPlaying,
            durationUs = if (durationMs == C.TIME_UNSET) 0 else durationMs * 1000,
            positionUs = positionUs(),
        )
    }

    private companion object {
        /** About 30 position updates a second while playing. */
        const val POSITION_INTERVAL_MS = 33L
    }
}
