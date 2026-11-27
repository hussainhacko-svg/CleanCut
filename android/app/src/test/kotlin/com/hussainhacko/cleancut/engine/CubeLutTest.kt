package com.hussainhacko.cleancut.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class CubeLutTest {
    private val eps = 1e-4f

    @Test
    fun `identity LUT maps colors unchanged and preserves alpha`() {
        val lut = CubeLut.identity(4)
        for (r in listOf(0f, 0.25f, 0.5f, 0.73f, 1f)) {
            for (g in listOf(0f, 0.4f, 1f)) {
                for (b in listOf(0f, 0.6f, 1f)) {
                    val out = lut.sample(r, g, b)
                    assertEquals(r, out[0], eps)
                    assertEquals(g, out[1], eps)
                    assertEquals(b, out[2], eps)
                }
            }
        }
        val argb = 0x8034679A.toInt()
        assertEquals(argb, lut.applyToArgb(argb))
    }

    @Test
    fun `parses standard cube text and packs 2D RGBA atlas`() {
        val text = """
            # Sample 2x2x2 LUT that swaps R and B
            TITLE "SwapRB"
            LUT_3D_SIZE 2
            DOMAIN_MIN 0.0 0.0 0.0
            DOMAIN_MAX 1.0 1.0 1.0
            0.0 0.0 0.0
            0.0 0.0 1.0
            0.0 1.0 0.0
            0.0 1.0 1.0
            1.0 0.0 0.0
            1.0 0.0 1.0
            1.0 1.0 0.0
            1.0 1.0 1.0
        """.trimIndent()
        val lut = CubeLut.parse(text)
        assertEquals(2, lut.size)
        val swapped = lut.sample(1f, 0.25f, 0f)
        assertEquals(0f, swapped[0], eps)
        assertEquals(0.25f, swapped[1], eps)
        assertEquals(1f, swapped[2], eps)

        val atlas = lut.toRgbaAtlasBytes()
        // Width = 2*2 = 4, height = 2 -> 4*2*4 = 32 bytes.
        assertEquals(32, atlas.size)
        // Pixel (r=1, g=0, b=0) -> x = 0*2 + 1 = 1, y = 0 -> (0, 0, 255, 255).
        val off = (0 * 4 + 1) * 4
        assertEquals(0, atlas[off].toInt() and 0xFF)
        assertEquals(0, atlas[off + 1].toInt() and 0xFF)
        assertEquals(255, atlas[off + 2].toInt() and 0xFF)
        assertEquals(255, atlas[off + 3].toInt() and 0xFF)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `rejects cube file without LUT_3D_SIZE`() {
        CubeLut.parse("0.0 0.0 0.0\n")
    }

    @Test(expected = IllegalArgumentException::class)
    fun `rejects LUTs too large for a 2D atlas texture`() {
        // 64 * 64 = 4096 px wide: over the GL_MAX_TEXTURE_SIZE of many phones.
        CubeLut.parse("LUT_3D_SIZE 64\n")
    }

    @Test(expected = IllegalArgumentException::class)
    fun `rejects cube file with wrong entry count`() {
        CubeLut.parse("LUT_3D_SIZE 2\n0.0 0.0 0.0\n")
    }

    @Test
    fun `all 12 bundled cube LUT assets parse cleanly`() {
        val dir = File("src/main/assets/luts")
        val files = dir.listFiles { f -> f.extension == "cube" }.orEmpty()
        assertEquals(12, files.size)
        for (file in files) {
            val lut = CubeLut.parse(file.readText())
            assertEquals(16, lut.size)
            val mid = lut.sample(0.5f, 0.5f, 0.5f)
            assertTrue(mid.all { it in 0f..1f })
        }
    }
}
