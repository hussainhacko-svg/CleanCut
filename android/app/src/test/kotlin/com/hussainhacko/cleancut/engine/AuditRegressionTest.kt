package com.hussainhacko.cleancut.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream

/** Regression tests for the post-Phase-2 audit findings in the engine. */
class AuditRegressionTest {
    private fun waveFile(peakCount: Int): ByteArray {
        val bytes = ByteArrayOutputStream()
        DataOutputStream(bytes).use {
            it.writeInt(1) // version
            it.writeInt(50)
            it.writeLong(1_000_000)
            it.writeInt(peakCount)
            it.write(ByteArray(4))
        }
        return bytes.toByteArray()
    }

    @Test
    fun `corrupt peak counts decode to null instead of throwing`() {
        assertNull(WaveformFile.decode(waveFile(-1)))
        assertNull(WaveformFile.decode(waveFile(Int.MAX_VALUE)))
        assertNull(WaveformFile.decode(waveFile(5))) // more than the file holds
    }

    @Test
    fun `float PCM gives the same peaks as 16-bit PCM`() {
        val shorts = PeakAccumulator(4, 1, 2).apply { add(shortArrayOf(0, -16384, 0, 32767)) }
        val floats = PeakAccumulator(4, 1, 2).apply { addFloats(floatArrayOf(0f, -0.5f, 0f, 32767f / 32768f)) }
        assertEquals(shorts.finish().toList(), floats.finish().toList())
    }

    @Test
    fun `float samples beyond full scale are clamped`() {
        val acc = PeakAccumulator(2, 1, 1).apply { addFloats(floatArrayOf(3f, -2f)) }
        assertEquals(listOf(255), acc.finish().map { it.toInt() and 0xFF })
    }

    @Test
    fun `a sub-millisecond still lasts at least 1 ms`() {
        val spec = CompositionSpec(
            listOf(ClipSpec("content://i", SpecMediaKind.IMAGE, 3_000_000, 0, 400, 1.0, true, emptyList())),
            1080,
            1920,
            30,
        )
        assertEquals(1L, CompositionPlan.of(spec).items.single().imageDurationMs)
        val normal = CompositionSpec(
            listOf(ClipSpec("content://i", SpecMediaKind.IMAGE, 3_000_000, 0, 2_500_000, 1.0, true, emptyList())),
            1080,
            1920,
            30,
        )
        assertEquals(2500L, CompositionPlan.of(normal).items.single().imageDurationMs)
    }
}
