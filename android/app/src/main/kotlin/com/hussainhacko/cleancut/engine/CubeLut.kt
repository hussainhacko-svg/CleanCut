package com.hussainhacko.cleancut.engine

import kotlin.math.floor
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * A parsed Adobe `.cube` 3D color lookup table (pure Kotlin, JVM-testable).
 *
 * Entries are stored in standard `.cube` order (R varies fastest, then G, then B).
 * Used both to upload a 2D atlas texture for [ClipRenderEffect] (preview + export)
 * and to render CPU filter preview thumbnails in [FilterPreviewGenerator].
 */
class CubeLut(
    val size: Int,
    /** Packed RGB floats in `[0, 1]`, length `size * size * size * 3`. */
    val rgb: FloatArray,
) {
    init {
        require(size in MIN_SIZE..MAX_SIZE) { "LUT size $size out of range $MIN_SIZE..$MAX_SIZE" }
        require(rgb.size == size * size * size * 3) {
            "Expected ${size * size * size * 3} floats for size $size, got ${rgb.size}"
        }
    }

    /**
     * Packs this 3D LUT into a 2D RGBA atlas of width `size * size` and height `size`:
     * row `y = g`, column `x = b * size + r`, alpha = 255.
     */
    fun toRgbaAtlasBytes(): ByteArray {
        val width = size * size
        val out = ByteArray(width * size * 4)
        for (b in 0 until size) {
            for (g in 0 until size) {
                for (r in 0 until size) {
                    val src = ((b * size + g) * size + r) * 3
                    val x = b * size + r
                    val dst = (g * width + x) * 4
                    out[dst] = toByte(rgb[src])
                    out[dst + 1] = toByte(rgb[src + 1])
                    out[dst + 2] = toByte(rgb[src + 2])
                    out[dst + 3] = 0xFF.toByte()
                }
            }
        }
        return out
    }

    /** Trilinearly samples the LUT for normalized `[r, g, b]` in `0..1`. */
    fun sample(r: Float, g: Float, b: Float): FloatArray {
        val maxIdx = (size - 1).toFloat()
        val rs = r.coerceIn(0f, 1f) * maxIdx
        val gs = g.coerceIn(0f, 1f) * maxIdx
        val bs = b.coerceIn(0f, 1f) * maxIdx

        val r0 = floor(rs).toInt()
        val g0 = floor(gs).toInt()
        val b0 = floor(bs).toInt()
        val r1 = min(r0 + 1, size - 1)
        val g1 = min(g0 + 1, size - 1)
        val b1 = min(b0 + 1, size - 1)
        val rf = rs - r0
        val gf = gs - g0
        val bf = bs - b0

        val out = FloatArray(3)
        for (c in 0..2) {
            val c000 = at(r0, g0, b0, c)
            val c100 = at(r1, g0, b0, c)
            val c010 = at(r0, g1, b0, c)
            val c110 = at(r1, g1, b0, c)
            val c001 = at(r0, g0, b1, c)
            val c101 = at(r1, g0, b1, c)
            val c011 = at(r0, g1, b1, c)
            val c111 = at(r1, g1, b1, c)

            val c00 = c000 + (c100 - c000) * rf
            val c10 = c010 + (c110 - c010) * rf
            val c01 = c001 + (c101 - c001) * rf
            val c11 = c011 + (c111 - c011) * rf

            val c0 = c00 + (c10 - c00) * gf
            val c1 = c01 + (c11 - c01) * gf
            out[c] = (c0 + (c1 - c0) * bf).coerceIn(0f, 1f)
        }
        return out
    }

    /** Applies the LUT to an `0xAARRGGBB` pixel, preserving alpha. */
    fun applyToArgb(argb: Int): Int {
        val a = argb and 0xFF000000.toInt()
        val r = ((argb ushr 16) and 0xFF) / 255f
        val g = ((argb ushr 8) and 0xFF) / 255f
        val b = (argb and 0xFF) / 255f
        val mapped = sample(r, g, b)
        val ri = (mapped[0] * 255f).roundToInt().coerceIn(0, 255)
        val gi = (mapped[1] * 255f).roundToInt().coerceIn(0, 255)
        val bi = (mapped[2] * 255f).roundToInt().coerceIn(0, 255)
        return a or (ri shl 16) or (gi shl 8) or bi
    }

    private fun at(r: Int, g: Int, b: Int, channel: Int): Float =
        rgb[((b * size + g) * size + r) * 3 + channel]

    companion object {
        const val MIN_SIZE = 2
        /**
         * Largest supported size. The atlas is `size * size` texels wide, and 33 (1089 px) stays
         * well under the 4096 px GL_MAX_TEXTURE_SIZE that many phones have; 64/65 would not.
         */
        const val MAX_SIZE = 33

        private fun toByte(v: Float): Byte =
            (v.coerceIn(0f, 1f) * 255f).roundToInt().coerceIn(0, 255).toByte()

        /** Creates an identity 3D LUT of [size] (useful for tests). */
        fun identity(size: Int = 2): CubeLut {
            require(size in MIN_SIZE..MAX_SIZE) { "LUT size $size out of range" }
            val denom = (size - 1).toFloat()
            val rgb = FloatArray(size * size * size * 3)
            var idx = 0
            for (b in 0 until size) {
                for (g in 0 until size) {
                    for (r in 0 until size) {
                        rgb[idx++] = r / denom
                        rgb[idx++] = g / denom
                        rgb[idx++] = b / denom
                    }
                }
            }
            return CubeLut(size, rgb)
        }

        /** Parses an Adobe `.cube` 3D LUT text file. */
        fun parse(text: String): CubeLut {
            var size = -1
            var values: FloatArray? = null
            var count = 0
            for (rawLine in text.lineSequence()) {
                val line = rawLine.substringBefore('#').trim()
                if (line.isEmpty()) continue
                val parts = line.split(WHITESPACE)
                when (parts[0]) {
                    "TITLE", "DOMAIN_MIN", "DOMAIN_MAX" -> continue
                    "LUT_3D_SIZE" -> {
                        val parsed = parts.getOrNull(1)?.toIntOrNull()
                            ?: throw IllegalArgumentException("Invalid LUT_3D_SIZE: $line")
                        require(parsed in MIN_SIZE..MAX_SIZE) { "Unsupported LUT_3D_SIZE: $parsed" }
                        size = parsed
                        values = FloatArray(size * size * size * 3)
                    }
                    else -> {
                        val buf = values ?: throw IllegalArgumentException("Data before LUT_3D_SIZE")
                        if (parts.size < 3) throw IllegalArgumentException("Invalid LUT row: $line")
                        val r = parts[0].toFloatOrNull()
                        val g = parts[1].toFloatOrNull()
                        val b = parts[2].toFloatOrNull()
                        if (r == null || g == null || b == null) {
                            throw IllegalArgumentException("Non-numeric LUT row: $line")
                        }
                        if (count + 3 > buf.size) {
                            throw IllegalArgumentException("Too many entries for LUT_3D_SIZE $size")
                        }
                        buf[count++] = r.coerceIn(0f, 1f)
                        buf[count++] = g.coerceIn(0f, 1f)
                        buf[count++] = b.coerceIn(0f, 1f)
                    }
                }
            }
            val buf = values ?: throw IllegalArgumentException("Missing LUT_3D_SIZE")
            require(count == buf.size) { "Expected ${buf.size / 3} LUT rows, got ${count / 3}" }
            return CubeLut(size, buf)
        }

        private val WHITESPACE = Regex("\\s+")
    }
}
