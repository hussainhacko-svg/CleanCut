package com.hussainhacko.cleancut.engine

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WaveformTest {
    private fun peaksOf(acc: PeakAccumulator) = acc.finish().map { it.toInt() and 0xFF }

    @Test
    fun `one peak per bucket holds the loudest sample`() {
        val acc = PeakAccumulator(sampleRate = 4, channels = 1, peaksPerSecond = 2)
        acc.add(shortArrayOf(100, -16384, 0, 32767))
        assertEquals(listOf(127, 254), peaksOf(acc))
    }

    @Test
    fun `channels are folded into the same frame`() {
        val acc = PeakAccumulator(sampleRate = 2, channels = 2, peaksPerSecond = 1)
        // Frames: (L=0, R=-32768), (L=10, R=0) → one bucket.
        acc.add(shortArrayOf(0, Short.MIN_VALUE, 10, 0))
        assertEquals(listOf(255), peaksOf(acc))
    }

    @Test
    fun `samples may arrive split across buffers`() {
        val whole = PeakAccumulator(8, 2, 2).apply { add(ShortArray(16) { (it * 1000).toShort() }) }
        val split = PeakAccumulator(8, 2, 2).apply {
            val all = ShortArray(16) { (it * 1000).toShort() }
            add(all.copyOfRange(0, 5))
            add(all.copyOfRange(5, 16))
        }
        assertEquals(peaksOf(whole), peaksOf(split))
    }

    @Test
    fun `a final partial bucket is kept`() {
        val acc = PeakAccumulator(4, 1, 2)
        acc.add(shortArrayOf(0, 0, 32767))
        assertEquals(listOf(0, 254), peaksOf(acc))
    }

    @Test
    fun `silence and no input`() {
        assertEquals(listOf(0), peaksOf(PeakAccumulator(4, 1, 1).apply { add(ShortArray(4)) }))
        assertEquals(emptyList<Int>(), peaksOf(PeakAccumulator(4, 1, 1)))
    }

    @Test(expected = IllegalArgumentException::class)
    fun `more peaks than samples is rejected`() {
        PeakAccumulator(sampleRate = 10, channels = 1, peaksPerSecond = 11)
    }

    @Test
    fun `waveform file round-trips`() {
        val data = WaveformData(byteArrayOf(0, 1, -1, 127), 50, 1_234_567)
        val back = WaveformFile.decode(WaveformFile.encode(data))!! // asserted non-null by the round trip
        assertArrayEquals(data.peaks, back.peaks)
        assertEquals(50, back.peaksPerSecond)
        assertEquals(1_234_567, back.durationUs)
    }

    @Test
    fun `damaged or foreign files decode to null`() {
        assertNull(WaveformFile.decode(byteArrayOf(1, 2)))
        val other = WaveformFile.encode(WaveformData(ByteArray(2), 1, 1)).also { it[3] = 9 }
        assertNull(WaveformFile.decode(other))
    }

    @Test
    fun `cache keys bucket times and ignore time for stills`() {
        assertEquals(1_000_000, CacheKeys.bucketUs(1_004_999))
        assertEquals(1_010_000, CacheKeys.bucketUs(1_005_000))
        assertEquals(0, CacheKeys.bucketUs(-7))
        assertEquals(
            CacheKeys.thumbnail("u", 1_000_000, 60, isImage = false),
            CacheKeys.thumbnail("u", 1_003_000, 60, isImage = false),
        )
        assertNotEquals(
            CacheKeys.thumbnail("u", 1_000_000, 60, isImage = false),
            CacheKeys.thumbnail("u", 2_000_000, 60, isImage = false),
        )
        assertEquals(CacheKeys.thumbnail("u", 1, 60, true), CacheKeys.thumbnail("u", 9_000_000, 60, true))
        assertNotEquals(CacheKeys.thumbnail("u", 0, 60, true), CacheKeys.thumbnail("u", 0, 120, true))
        assertNotEquals(CacheKeys.waveform("u", 50), CacheKeys.waveform("u", 100))
    }
}
