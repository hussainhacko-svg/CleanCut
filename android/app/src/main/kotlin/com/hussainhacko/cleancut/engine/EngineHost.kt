package com.hussainhacko.cleancut.engine

import android.content.Context
import android.net.Uri
import android.util.Log
import io.flutter.view.TextureRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Implements the Pigeon [EngineHostApi]: one preview player at a time plus
 * thumbnail and waveform extraction. Call [dispose] when the engine detaches.
 */
class EngineHost(
    private val context: Context,
    private val textures: TextureRegistry,
    private val flutterApi: EngineFlutterApi,
) : EngineHostApi {
    private val scope: CoroutineScope = MainScope()
    private val thumbnails = ThumbnailExtractor(context)
    private val waveforms = WaveformExtractor(context)
    private var preview: PreviewPlayer? = null

    private val listener = object : PreviewListener {
        override fun onState(state: PlayerStateEvent) = send { flutterApi.onPlayerState(state) }
        override fun onPosition(textureId: Long, positionUs: Long) =
            send { flutterApi.onPosition(textureId, positionUs) }

        override fun onError(textureId: Long, code: String, message: String) =
            send { flutterApi.onError(textureId, code, message) }
    }

    override fun createPreview(): Long {
        releasePreview()
        val player = PreviewPlayer(context, textures.createSurfaceProducer(), listener)
        preview = player
        return player.textureId
    }

    override fun setComposition(spec: CompositionSpec) {
        requirePreview().setComposition(spec) { uri ->
            runCatching { context.contentResolver.getType(Uri.parse(uri)) }.getOrNull()
        }
    }

    override fun play() = requirePreview().play()

    override fun pause() = requirePreview().pause()

    override fun seekTo(positionUs: Long) = requirePreview().seekTo(positionUs)

    override fun disposePreview(textureId: Long) {
        if (preview?.textureId == textureId) releasePreview()
    }

    override suspend fun thumbnails(uri: String, timesUs: List<Long>, heightPx: Long): List<String?> =
        thumbnails.extract(uri, timesUs, heightPx.toInt())

    override suspend fun waveform(uri: String, peaksPerSecond: Long): WaveformData? =
        waveforms.extract(uri, peaksPerSecond.toInt())

    fun dispose() {
        releasePreview()
        scope.cancel()
    }

    private fun releasePreview() {
        preview?.release()
        preview = null
    }

    private fun requirePreview(): PreviewPlayer =
        preview ?: throw FlutterError("no-preview", "createPreview() was not called", null)

    private fun send(block: suspend () -> Unit) {
        scope.launch {
            // Dart may be gone (e.g. hot restart); events are best effort.
            runCatching { block() }.onFailure { Log.d(TAG, "Event not delivered", it) }
        }
    }

    private companion object {
        const val TAG = "CleanCutEngine"
    }
}
