package com.hussainhacko.cleancut.engine

import android.content.Context
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
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

            val data = decode(Uri.parse(uri), peaksPerSecond) ?: return@withContext null
            val tmp = File(file.path + ".tmp")
            tmp.writeBytes(WaveformFile.encode(data))
            if (!tmp.renameTo(file)) tmp.delete()
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
            var samples = ShortArray(0)
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
                        val acc = accumulator ?: newAccumulator(decoder.outputFormat, peaksPerSecond)
                            .also { accumulator = it }
                        val out = decoder.getOutputBuffer(outIndex)!! // index from dequeue is valid
                        out.position(info.offset).limit(info.offset + info.size)
                        val shorts = out.order(ByteOrder.nativeOrder()).asShortBuffer()
                        val count = shorts.remaining()
                        if (samples.size < count) samples = ShortArray(count)
                        shorts.get(samples, 0, count)
                        acc.add(samples, count)
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

    private fun newAccumulator(format: MediaFormat, peaksPerSecond: Int): PeakAccumulator {
        val encoding = if (format.containsKey(MediaFormat.KEY_PCM_ENCODING)) {
            format.getInteger(MediaFormat.KEY_PCM_ENCODING)
        } else {
            AudioFormat.ENCODING_PCM_16BIT
        }
        check(encoding == AudioFormat.ENCODING_PCM_16BIT) { "Unsupported PCM encoding $encoding" }
        val rate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        return PeakAccumulator(rate, format.getInteger(MediaFormat.KEY_CHANNEL_COUNT), peaksPerSecond.coerceAtMost(rate))
    }

    private companion object {
        const val TIMEOUT_US = 10_000L
    }
}
