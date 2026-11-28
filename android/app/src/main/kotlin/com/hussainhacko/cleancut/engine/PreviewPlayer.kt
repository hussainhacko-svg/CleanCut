package com.hussainhacko.cleancut.engine

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.MultipleInputVideoGraph
import androidx.media3.transformer.CompositionPlayer
import io.flutter.view.TextureRegistry
import kotlin.math.min

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
    private val context: Context,
    private val producer: TextureRegistry.SurfaceProducer,
    private val listener: PreviewListener,
) {
    private var multiInput = false
    private var player: CompositionPlayer = createPlayer(multiInput = false)
    private val handler = Handler(Looper.getMainLooper())
    private var size = Size(CompositionPlan.MIN_SIDE, CompositionPlan.MIN_SIDE)
    private var hasComposition = false

    /** The playing composition's live looks, plan, and structure key. */
    private var composed: ComposedPlan? = null
    private var currentPlan: CompositionPlan? = null
    private var structure: CompositionPlan? = null
    private var released = false

    /**
     * A multi-input rebuild waiting for scrubs or drags to settle (see [scheduleLoad]).
     * [positionMs] is a seek target, or null to keep the player's position when it runs.
     */
    private data class PendingLoad(val plan: CompositionPlan, val positionMs: Long?, val play: Boolean)

    private var pendingLoad: PendingLoad? = null
    private var pendingSinceMs = 0L
    private val loadRunnable = Runnable { runPendingLoad() }

    /**
     * Set when a multi-input preview reached the end on its own (see [finishAtEnd]): Media3
     * 1.11.1's multi-sequence CompositionPlayer keeps "playing" past the end and never
     * reports [Player.STATE_ENDED].
     */
    private var endedAtEnd = false

    /**
     * The next time a sequence enters a video that Media3 won't start on its own
     * ([CompositionPlan.videoEntryTimesUs]); playback restarts the player there. Null when none.
     */
    private var nextVideoEntryUs: Long? = null

    private val ticker = object : Runnable {
        override fun run() {
            if (multiInput &&
                pendingLoad == null &&
                reachedEnd(player.currentPosition, player.duration)
            ) {
                finishAtEnd()
                return
            }
            if (maybeRestartAtVideoEntry()) return
            listener.onPosition(textureId, positionUs())
            handler.postDelayed(this, POSITION_INTERVAL_MS)
        }
    }

    private val playerListener = object : Player.Listener {
        override fun onEvents(player: Player, events: Player.Events) {
            if (player !== this@PreviewPlayer.player) return
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
    }

    init {
        player.addListener(playerListener)
        producer.setCallback(
            object : TextureRegistry.SurfaceProducer.Callback {
                // The surface is recreated e.g. after the app returns from the background.
                override fun onSurfaceAvailable() = attachSurface()

                override fun onSurfaceCleanup() = player.clearVideoSurface()
            },
        )
    }

    private fun createPlayer(multiInput: Boolean): CompositionPlayer {
        val builder = CompositionPlayer.Builder(context)
        if (multiInput) {
            builder.setVideoGraphFactory(MultipleInputVideoGraph.Factory())
        } else {
            // Keeps the last frame so a look change while paused can be redrawn in place
            // (MultipleInputVideoGraph.redraw() is not implemented in Media3 1.11.1).
            builder.experimentalSetEnableReplayableCache(true)
        }
        return builder.build()
    }

    private fun recreatePlayer(needsMultiInput: Boolean) {
        handler.removeCallbacks(ticker)
        player.removeListener(playerListener)
        player.release()
        multiInput = needsMultiInput
        player = createPlayer(multiInput = needsMultiInput).also { it.addListener(playerListener) }
    }

    /** Texture id to show with Flutter's `Texture` widget. */
    val textureId: Long get() = producer.id()

    fun setComposition(spec: CompositionSpec, mimeTypeOf: (String) -> String?) {
        val plan = CompositionPlan.of(spec, mimeTypeOf)
        if (plan.width != size.width || plan.height != size.height) {
            size = Size(plan.width, plan.height)
            producer.setSize(plan.width, plan.height)
        }
        if (plan.isEmpty) {
            // Clear before stop() so any listener callback triggered by stop()
            // also reports an empty timeline rather than stale duration/position.
            cancelPendingLoad()
            hasComposition = false
            composed = null
            currentPlan = null
            structure = null
            player.stop()
            player.clearVideoSurface()
            listener.onState(state())
            return
        }
        val current = composed
        if (hasComposition &&
            current != null &&
            plan.structureKey == structure &&
            player.playbackState != Player.STATE_IDLE &&
            player.playerError == null
        ) {
            // Only looks changed (a slider, gesture or transition type): swap them in
            // place. The GL effects read them every frame, so a playing preview shows
            // them on its next frame.
            current.updateLooks(plan)
            currentPlan = plan
            if (!multiInput) {
                // Re-run the last frame through the effects immediately: while paused
                // seeking in place doesn't redraw, and while playing a sparse/static
                // video might not deliver a new decoded frame for seconds.
                player.experimentalRedrawLastFrame()
                return
            }
            val pending = pendingLoad
            if (pending != null) {
                // Keep the newest look and restart the quiet-time timer.
                scheduleLoad(pending.copy(plan = plan))
            } else if (!player.isPlaying) {
                // MultipleInputVideoGraph can't redraw, so a paused preview shows the
                // new look by rebuilding once the slider settles.
                scheduleLoad(PendingLoad(plan, positionMs = null, play = false))
            }
            return
        }
        val pending = pendingLoad
        val load = PendingLoad(
            plan = plan,
            positionMs = if (hasComposition) pending?.positionMs else 0L,
            play = pending?.play ?: (hasComposition && player.isPlaying),
        )
        if (multiInput && plan.isMultiSequence) {
            // Structure changed (e.g. a transition duration drag or overlay move): rebuild once it settles.
            scheduleLoad(load)
        } else {
            // First load, a switch between graph modes, or a single-input update.
            cancelPendingLoad()
            loadPlanAt(load.plan, load.positionMs ?: player.currentPosition, load.play)
        }
    }

    private fun loadPlanAt(plan: CompositionPlan, positionMs: Long, play: Boolean) {
        // Media3 1.11.1's MultipleInputVideoGraph.flush() does not flush DefaultVideoCompositor,
        // leaving stale frames queued after a seek or setComposition. Recreating the player
        // whenever multi-input is active (or when switching graph modes) guarantees a clean
        // compositor at the target timestamp. Callers coalesce these rebuilds through
        // [scheduleLoad] so scrubs and slider drags don't rebuild on every event.
        if (plan.isMultiSequence || multiInput) {
            recreatePlayer(needsMultiInput = plan.isMultiSequence)
        }
        endedAtEnd = false
        val requestedMs = positionMs.coerceIn(0L, (plan.durationUs / 1000 - 1).coerceAtLeast(0L))
        val startMs = if (plan.isMultiSequence && !play) plan.safePausedStartMs(requestedMs) else requestedMs
        nextVideoEntryUs = if (plan.isMultiSequence) plan.nextVideoEntryAfterUs(startMs * 1000) else null
        val built = Media3Composer.build(plan)
        player.setComposition(built.composition, startMs)
        composed = built
        currentPlan = plan
        structure = plan.structureKey
        hasComposition = true
        attachSurface()
        player.prepare()
        if (play) player.play()
    }

    /**
     * Queues a multi-input rebuild, replacing any queued one. It runs once requests stop for
     * [LOAD_DEBOUNCE_MS], and at least every [LOAD_MAX_WAIT_MS] during a long scrub.
     */
    private fun scheduleLoad(load: PendingLoad) {
        val now = SystemClock.uptimeMillis()
        if (pendingLoad == null) pendingSinceMs = now
        pendingLoad = load
        handler.removeCallbacks(loadRunnable)
        val waited = now - pendingSinceMs
        val delay = minOf(LOAD_DEBOUNCE_MS, (LOAD_MAX_WAIT_MS - waited).coerceAtLeast(0L))
        handler.postDelayed(loadRunnable, delay)
    }

    private fun cancelPendingLoad() {
        handler.removeCallbacks(loadRunnable)
        pendingLoad = null
    }

    private fun runPendingLoad() {
        val load = pendingLoad ?: return
        cancelPendingLoad()
        if (released) return
        loadPlanAt(load.plan, load.positionMs ?: player.currentPosition, load.play)
    }

    fun play() {
        if (!hasComposition) return
        pendingLoad?.let { load ->
            pendingLoad = load.copy(play = true)
            runPendingLoad()
            return
        }
        // Replaying after the end starts again from the beginning.
        if (player.playbackState == Player.STATE_ENDED || endedAtEnd) {
            val plan = currentPlan
            if (multiInput && plan != null) {
                loadPlanAt(plan, 0L, play = true)
                return
            }
            player.seekTo(0)
        }
        player.play()
    }

    fun pause() {
        pendingLoad?.let { pendingLoad = it.copy(play = false) }
        player.pause()
    }

    fun seekTo(positionUs: Long) {
        if (!hasComposition) return
        val targetMs = (positionUs.coerceAtLeast(0) + 500) / 1000
        val plan = pendingLoad?.plan ?: currentPlan
        if (multiInput && plan != null) {
            val play = pendingLoad?.play ?: player.isPlaying
            // Hold the old player still while the seek settles; [positionUs] already
            // reports the target, so the playhead doesn't jump back.
            scheduleLoad(PendingLoad(plan, targetMs, play))
            if (player.isPlaying) player.pause()
            return
        }
        player.seekTo(targetMs)
    }

    fun release() {
        if (released) return
        released = true
        handler.removeCallbacks(ticker)
        cancelPendingLoad()
        producer.setCallback(null)
        player.release()
        producer.release()
    }

    /**
     * Ends a multi-input preview that reached the end: stops it, shows the true last frame
     * (rebuilt paused at the end, since the stuck player can leave a stale lane on screen)
     * and reports [PlaybackStatus.ENDED] like a single-input player would.
     */
    private fun finishAtEnd() {
        val plan = currentPlan ?: return
        handler.removeCallbacks(ticker)
        player.pause()
        loadPlanAt(plan, plan.durationUs / 1000, play = false)
        endedAtEnd = true
        listener.onState(state())
    }

    /**
     * Restarts a playing multi-input preview inside the video it is about to enter (see
     * [nextVideoEntryUs]); a short hitch instead of a frozen or missing layer. Returns whether
     * it restarted (the new player restarts the ticker).
     */
    private fun maybeRestartAtVideoEntry(): Boolean {
        val entryUs = nextVideoEntryUs ?: return false
        val plan = currentPlan ?: return false
        if (!multiInput || pendingLoad != null || !player.isPlaying) return false
        val positionMs = player.currentPosition
        if (positionMs * 1000 < entryUs - VIDEO_ENTRY_LEAD_US) return false
        loadPlanAt(plan, videoEntryRestartMs(entryUs, positionMs), play = true)
        return true
    }

    private fun attachSurface() {
        if (!released) player.setVideoSurface(producer.surface, size)
    }

    private fun updateTicker() {
        handler.removeCallbacks(ticker)
        if (player.isPlaying) handler.post(ticker)
    }

    private fun positionUs(): Long {
        // While a rebuild is queued, the old player's position is stale.
        pendingLoad?.positionMs?.let { return it * 1000 }
        return reportedPositionUs(
            player.currentPosition,
            player.duration,
            ended = player.playbackState == Player.STATE_ENDED || endedAtEnd,
        )
    }

    private fun state(): PlayerStateEvent {
        if (!hasComposition) {
            return PlayerStateEvent(textureId, PlaybackStatus.IDLE, false, 0, 0)
        }
        val durationMs = player.duration
        return PlayerStateEvent(
            textureId = textureId,
            status = if (endedAtEnd) PlaybackStatus.ENDED else statusOf(player.playbackState),
            isPlaying = player.isPlaying && !endedAtEnd,
            durationUs = if (durationMs == C.TIME_UNSET) 0 else durationMs * 1000,
            positionUs = positionUs(),
        )
    }

    private fun statusOf(playbackState: Int): PlaybackStatus = when (playbackState) {
        Player.STATE_BUFFERING -> PlaybackStatus.BUFFERING
        Player.STATE_READY -> PlaybackStatus.READY
        Player.STATE_ENDED -> PlaybackStatus.ENDED
        else -> PlaybackStatus.IDLE
    }

    companion object {
        /** Restart this early (µs) before a video entry: about half a position tick. */
        private const val VIDEO_ENTRY_LEAD_US = 15_000L

        /**
         * Where to restart for a video entry at [entryUs] with the playhead at [positionMs]:
         * rounded up to whole ms so the new player starts inside the video (rounding down
         * could land just before it, stuck again, restarting forever), and never behind the
         * playhead.
         */
        fun videoEntryRestartMs(entryUs: Long, positionMs: Long): Long = maxOf((entryUs + 999) / 1000, positionMs)

        /** About 30 position updates a second while playing. */
        private const val POSITION_INTERVAL_MS = 33L

        /** Quiet time after the last seek or look change before a multi-input rebuild. */
        private const val LOAD_DEBOUNCE_MS = 120L

        /** Longest a continuous scrub waits between multi-input rebuilds. */
        private const val LOAD_MAX_WAIT_MS = 400L

        /** How close to the end (ms) a multi-input preview counts as finished. */
        private const val END_TOLERANCE_MS = 40L

        /**
         * Whether a player at [positionMs] of [durationMs] ([C.TIME_UNSET] when unknown) has
         * reached the end, within about one frame.
         */
        fun reachedEnd(positionMs: Long, durationMs: Long): Boolean =
            durationMs != C.TIME_UNSET && durationMs > 0 && positionMs >= durationMs - END_TOLERANCE_MS

        /**
         * The playhead position to report, in µs, for a player at [positionMs] of
         * [durationMs] ([C.TIME_UNSET] when unknown). CompositionPlayer keeps advancing
         * for a few hundred ms after the last frame, so the position is capped at the
         * duration, and an ended player reports exactly the duration.
         */
        fun reportedPositionUs(positionMs: Long, durationMs: Long, ended: Boolean): Long {
            val position = positionMs.coerceAtLeast(0L)
            if (durationMs == C.TIME_UNSET || durationMs < 0) return position * 1000
            return (if (ended) durationMs else min(position, durationMs)) * 1000
        }
    }
}
