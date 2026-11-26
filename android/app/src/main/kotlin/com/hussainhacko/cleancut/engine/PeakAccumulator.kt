package com.hussainhacko.cleancut.engine

import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import kotlin.math.abs

/**
 * Turns interleaved 16-bit PCM into waveform peaks: one byte (0–255) per
 * `1 / peaksPerSecond` seconds, holding the loudest sample of any channel.
 */
class PeakAccumulator(
    sampleRate: Int,
    private val channels: Int,
    peaksPerSecond: Int,
) {
    private val framesPerPeak: Int
    private val out = ByteArrayOutputStream()
    private var framesInPeak = 0
    private var channelIndex = 0
    private var max = 0

    init {
        require(sampleRate > 0) { "sampleRate must be > 0" }
        require(channels > 0) { "channels must be > 0" }
        require(peaksPerSecond in 1..sampleRate) { "peaksPerSecond must be in 1..sampleRate" }
        framesPerPeak = sampleRate / peaksPerSecond
    }

    /** Adds [count] interleaved samples from [samples]. */
    fun add(samples: ShortArray, count: Int = samples.size) {
        for (i in 0 until count) {
            val v = abs(samples[i].toInt())
            if (v > max) max = v
            if (++channelIndex == channels) {
                channelIndex = 0
                if (++framesInPeak == framesPerPeak) flushPeak()
            }
        }
    }

    /** Returns all peaks, including a final partial one. */
    fun finish(): ByteArray {
        if (framesInPeak > 0 || channelIndex > 0) flushPeak()
        return out.toByteArray()
    }

    private fun flushPeak() {
        // 32768 (|Short.MIN_VALUE|) maps to 255.
        out.write(((max.coerceAtMost(32768) * 255L) / 32768L).toInt())
        max = 0
        framesInPeak = 0
    }
}

/** Disk format of a cached waveform: version, peaks/s, duration, then the peaks. */
object WaveformFile {
    private const val VERSION = 1

    fun encode(data: WaveformData): ByteArray {
        val bytes = ByteArrayOutputStream()
        DataOutputStream(bytes).use {
            it.writeInt(VERSION)
            it.writeInt(data.peaksPerSecond.toInt())
            it.writeLong(data.durationUs)
            it.writeInt(data.peaks.size)
            it.write(data.peaks)
        }
        return bytes.toByteArray()
    }

    /** Returns null for an unknown version or a damaged file. */
    fun decode(bytes: ByteArray): WaveformData? = try {
        DataInputStream(bytes.inputStream()).use {
            if (it.readInt() != VERSION) return null
            val pps = it.readInt()
            val duration = it.readLong()
            val peaks = ByteArray(it.readInt())
            it.readFully(peaks)
            WaveformData(peaks, pps.toLong(), duration)
        }
    } catch (e: java.io.IOException) {
        null
    }
}
