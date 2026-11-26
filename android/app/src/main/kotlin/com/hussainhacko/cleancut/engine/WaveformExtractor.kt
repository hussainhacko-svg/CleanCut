package com.hussainhacko.cleancut.engine

import android.content.Context
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.util.Log
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import java.io.File
import java.nio.ByteOrder
import kotlin.coroutines.coroutineContext

/**
 * Decodes a file's first audio track into waveform peaks, cached in
 * `cacheDir/waveforms`. Runs on the IO dispatcher.
 */
class WaveformExtractor(private val context: Context) {
    private val dir = File(context.cacheDir, "waveforms")

    suspend fun extract(uri: String, peaksPerSecond: Int): WaveformData? =
        withContext(Dispatchers.IO) {
            require(peaksPerSecond in 1..1000) { "peaksPerSecond must be in 1..1000" }
            dir.mkdirs()
            val file = File(dir, CacheKeys.waveform(uri, peaksPerSecond))
            if (file.isFile) WaveformFile.decode(file.readBytes())?.let { return@withContext it }

            val data = try {
                decode(Uri.parse(uri), peaksPerSecond)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // Revoked access, unreadable file or a codec failure: no waveform.
                Log.w(TAG, "Could not decode audio of $uri", e)
                null
            } ?: return@withContext null
            // Unique temp file so concurrent requests can't collide.
            val tmp = File.createTempFile("wave", ".tmp", dir)
            try {
                tmp.writeBytes(WaveformFile.encode(data))
                if (!tmp.renameTo(file)) tmp.delete()
            } finally {
                if (tmp.exists()) tmp.delete()
            }
            data
        }

    private suspend fun decode(uri: Uri, peaksPerSecond: Int): WaveformData? {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null
        try {
            extractor.setDataSource(context, uri, null)
            val track = (0 until extractor.trackCount).firstOrNull {
                extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true
            } ?: return null
            extractor.selectTrack(track)
            val format = extractor.getTrackFormat(track)
            val durationUs = if (format.containsKey(MediaFormat.KEY_DURATION)) {
                format.getLong(MediaFormat.KEY_DURATION)
            } else {
                0L
            }
            val decoder = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!) // checked above
            codec = decoder
            decoder.configure(format, null, null, 0)
            decoder.start()

            var accumulator: PeakAccumulator? = null
            var isFloat = false
            var samples = ShortArray(0)
            var floats = FloatArray(0)
            val info = MediaCodec.BufferInfo()
            var inputDone = false
            while (true) {
                coroutineContext.ensureActive()
                if (!inputDone) {
                    val inIndex = decoder.dequeueInputBuffer(TIMEOUT_US)
                    if (inIndex >= 0) {
                        val buffer = decoder.getInputBuffer(inIndex)!! // index from dequeue is valid
                        val size = extractor.readSampleData(buffer, 0)
                        if (size < 0) {
                            decoder.queueInputBuffer(inIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            decoder.queueInputBuffer(inIndex, 0, size, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }
                val outIndex = decoder.dequeueOutputBuffer(info, TIMEOUT_US)
                if (outIndex >= 0) {
                    if (info.size > 0) {
                        val acc = accumulator ?: run {
                            val format = decoder.outputFormat
                            isFloat = pcmEncodingOf(format) == AudioFormat.ENCODING_PCM_FLOAT
                            newAccumulator(format, peaksPerSecond) ?: return null
                        }.also { accumulator = it }
                        val out = decoder.getOutputBuffer(outIndex)!! // index from dequeue is valid
                        out.position(info.offset).limit(info.offset + info.size)
                        out.order(ByteOrder.nativeOrder())
                        if (isFloat) {
                            val buffer = out.asFloatBuffer()
                            val count = buffer.remaining()
                            if (floats.size < count) floats = FloatArray(count)
                            buffer.get(floats, 0, count)
                            acc.addFloats(floats, count)
                        } else {
                            val buffer = out.asShortBuffer()
                            val count = buffer.remaining()
                            if (samples.size < count) samples = ShortArray(count)
                            buffer.get(samples, 0, count)
                            acc.add(samples, count)
                        }
                    }
                    decoder.releaseOutputBuffer(outIndex, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
                }
            }
            val peaks = accumulator?.finish() ?: ByteArray(0)
            return WaveformData(peaks, peaksPerSecond.toLong(), durationUs)
        } finally {
            codec?.let {
                runCatching { it.stop() }
                it.release()
            }
            extractor.release()
        }
    }

    private fun pcmEncodingOf(format: MediaFormat): Int =
        if (format.containsKey(MediaFormat.KEY_PCM_ENCODING)) {
            format.getInteger(MediaFormat.KEY_PCM_ENCODING)
        } else {
            AudioFormat.ENCODING_PCM_16BIT
        }

    /** Null for PCM encodings other than 16-bit and float (no waveform). */
    private fun newAccumulator(format: MediaFormat, peaksPerSecond: Int): PeakAccumulator? {
        val encoding = pcmEncodingOf(format)
        if (encoding != AudioFormat.ENCODING_PCM_16BIT && encoding != AudioFormat.ENCODING_PCM_FLOAT) {
            Log.w(TAG, "Unsupported PCM encoding $encoding")
            return null
        }
        val rate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        val channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        return PeakAccumulator(rate, channels, peaksPerSecond.coerceAtMost(rate))
    }

    private companion object {
        const val TAG = "CleanCutWaveform"
        const val TIMEOUT_US = 10_000L
    }
}
