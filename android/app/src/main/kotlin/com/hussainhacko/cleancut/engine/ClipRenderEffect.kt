package com.hussainhacko.cleancut.engine

import android.content.Context
import android.graphics.Bitmap
import android.graphics.ColorSpace
import android.graphics.ImageDecoder
import android.net.Uri
import android.opengl.GLES20
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.VideoFrameProcessingException
import androidx.media3.common.util.GlProgram
import androidx.media3.common.util.GlUtil
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BaseGlShaderProgram
import androidx.media3.effect.GlEffect
import androidx.media3.effect.GlShaderProgram
import java.nio.ByteBuffer
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

/** A clip's look, swappable while the preview runs (read on the GL thread every frame). */
class LiveClipLook(style: ClipStyle, val timelineStartUs: Long) {
    @Volatile
    var style: ClipStyle = style
}

/** The canvas background, shared by every clip of a composition and swappable live. */
class LiveBackground(background: BackgroundStyle) {
    @Volatile
    var background: BackgroundStyle = background
}

/**
 * Draws one clip onto the canvas: background (color, gradient, blurred clip or image), then the
 * clip cropped, fitted, transformed (keyframes), with rounded corners, border and opacity.
 * Output is always the canvas size, so every clip of the sequence lines up.
 */
@OptIn(UnstableApi::class)
class ClipRenderEffect(
    private val look: LiveClipLook,
    private val background: LiveBackground,
    private val canvasWidth: Int,
    private val canvasHeight: Int,
) : GlEffect {
    override fun toGlShaderProgram(context: Context, useHdr: Boolean): GlShaderProgram =
        ClipRenderProgram(context, useHdr, look, background, canvasWidth, canvasHeight)
}

@OptIn(UnstableApi::class)
private class ClipRenderProgram(
    private val context: Context,
    useHdr: Boolean,
    private val look: LiveClipLook,
    private val background: LiveBackground,
    private val canvasWidth: Int,
    private val canvasHeight: Int,
) : BaseGlShaderProgram(useHdr, /* texturePoolCapacity= */ 1) {
    private val main = program(FRAGMENT_MAIN)
    private val downsample = program(FRAGMENT_DOWNSAMPLE)
    private val cropCopy = program(FRAGMENT_CROP_COPY)
    private val blur = program(FRAGMENT_BLUR)

    private var inputWidth = 1
    private var inputHeight = 1

    /** Ping-pong textures for the blurred background, canvas aspect, small. */
    private val scratch = arrayOf(Target(), Target())

    /** Ping-pong textures for whole-clip Gaussian blur, cropped clip aspect. */
    private val clipBlurScratch = arrayOf(Target(), Target())

    /** A decoded image background and its key; the rendered result lives in [imageTarget]. */
    private var imageTexture: Int = NO_TEXTURE
    private var imageSize = Size(1, 1)
    private var imageUri: String? = null
    private var imageTarget = Target()
    private var imageTargetKey: Pair<String, Double>? = null

    /** Cached 2D LUT atlas textures: filterId -> (glTexId, lutSize), or null if failed. */
    private val lutCache = mutableMapOf<String, Pair<Int, Int>?>()

    override fun configure(inputWidth: Int, inputHeight: Int): Size {
        this.inputWidth = max(1, inputWidth)
        this.inputHeight = max(1, inputHeight)
        return Size(canvasWidth, canvasHeight)
    }

    override fun drawFrame(inputTexId: Int, presentationTimeUs: Long) {
        try {
            val outputFbo = IntArray(1).also { GLES20.glGetIntegerv(GLES20.GL_FRAMEBUFFER_BINDING, it, 0) }[0]
            val style = look.style
            val bg = background.background
            val backgroundTexture = when (bg.kind) {
                BackgroundStyle.Kind.BLUR -> {
                    releaseImageBackground()
                    blurredInput(inputTexId, style, bg)
                }
                BackgroundStyle.Kind.IMAGE -> imageBackground(bg)
                else -> {
                    releaseImageBackground()
                    NO_TEXTURE
                }
            }
            val clipTimeUs = (presentationTimeUs - look.timelineStartUs).coerceAtLeast(0L)
            val g = ClipFrameGeometry.of(style, inputWidth, inputHeight, canvasWidth, canvasHeight, clipTimeUs)
            val clipBlurTexture = if (g.blur > 0.0) blurredClip(inputTexId, style, g.blur) else NO_TEXTURE
            GlUtil.focusFramebufferUsingCurrentContext(outputFbo, canvasWidth, canvasHeight)
            drawClip(inputTexId, style, bg, backgroundTexture, clipBlurTexture, g, clipTimeUs)
        } catch (e: GlUtil.GlException) {
            throw VideoFrameProcessingException(e, presentationTimeUs)
        }
    }

    private fun drawClip(
        inputTexId: Int,
        style: ClipStyle,
        bg: BackgroundStyle,
        bgTexture: Int,
        clipBlurTexture: Int,
        g: ClipFrameGeometry,
        timeUs: Long,
    ) {
        val lut = style.filterId?.takeIf { style.filterIntensity > 0.0 }?.let(::lutTexture)
        val adj = style.adjustments
        main.use()
        main.setSamplerTexIdUniform("uTex", inputTexId, 0)
        // Bind the input again when there is no background/LUT/blur texture: samplers need a texture.
        main.setSamplerTexIdUniform("uBgTex", if (bgTexture == NO_TEXTURE) inputTexId else bgTexture, 1)
        main.setSamplerTexIdUniform("uLutTex", lut?.first ?: inputTexId, 2)
        main.setSamplerTexIdUniform("uClipBlurTex", if (clipBlurTexture == NO_TEXTURE) inputTexId else clipBlurTexture, 3)
        main.setFloatUniform(
            "uClipBlurMix",
            if (clipBlurTexture == NO_TEXTURE) 0f else (g.blur / CLIP_BLUR_FADE_IN).coerceIn(0.0, 1.0).toFloat(),
        )
        main.setFloatUniform("uLutSize", (lut?.second ?: 0).toFloat())
        main.setFloatUniform("uLutIntensity", if (lut != null) style.filterIntensity.toFloat() else 0f)
        main.setFloatsUniform("uTexel", floatArrayOf(1f / inputWidth, 1f / inputHeight))
        main.setFloatsUniform(
            "uAdjA",
            floatArrayOf(
                adj.exposure.toFloat(),
                adj.brightness.toFloat(),
                adj.contrast.toFloat(),
                adj.saturation.toFloat(),
            ),
        )
        main.setFloatsUniform(
            "uAdjB",
            floatArrayOf(
                adj.warmth.toFloat(),
                adj.tint.toFloat(),
                adj.highlights.toFloat(),
                adj.shadows.toFloat(),
            ),
        )
        main.setFloatsUniform(
            "uAdjC",
            floatArrayOf(adj.sharpen.toFloat(), adj.vignette.toFloat()),
        )
        main.setFloatsUniform("uCanvas", floatArrayOf(canvasWidth.toFloat(), canvasHeight.toFloat()))
        main.setIntUniform(
            "uBgKind",
            when {
                bg.kind == BackgroundStyle.Kind.GRADIENT -> 1
                bgTexture != NO_TEXTURE -> 2
                else -> 0
            },
        )
        main.setFloatsUniform("uColorA", rgba(if (bg.kind == BackgroundStyle.Kind.GRADIENT || bg.kind == BackgroundStyle.Kind.COLOR) bg.argb else BLACK))
        main.setFloatsUniform("uColorB", rgba(bg.endArgb))
        val (dx, dy, extent) = bg.gradientAxis(canvasWidth, canvasHeight)
        main.setFloatsUniform("uGradAxis", floatArrayOf(dx.toFloat(), dy.toFloat(), extent.toFloat()))
        main.setFloatsUniform("uCenter", floatArrayOf(g.centerX.toFloat(), g.centerY.toFloat()))
        main.setFloatsUniform("uHalf", floatArrayOf(g.halfWidth.toFloat(), g.halfHeight.toFloat()))
        main.setFloatsUniform("uRot", floatArrayOf(g.cos.toFloat(), g.sin.toFloat()))
        val c = style.crop
        main.setFloatsUniform("uCrop", floatArrayOf(c.left.toFloat(), c.top.toFloat(), c.width.toFloat(), c.height.toFloat()))
        main.setFloatsUniform("uFlip", floatArrayOf(if (style.flipX) -1f else 1f, if (style.flipY) -1f else 1f))
        main.setFloatUniform("uRadius", g.radiusPx.toFloat())
        main.setFloatUniform("uBorder", g.borderPx.toFloat())
        main.setFloatsUniform("uBorderColor", rgba(style.borderArgb))
        main.setFloatUniform("uOpacity", g.opacity.toFloat())
        val mask = style.mask
        if (mask == null) {
            main.setIntUniform("uMaskKind", 0)
            main.setFloatsUniform("uMaskGeom", floatArrayOf(0f, 0f, 1f, 1f))
            main.setFloatsUniform("uMaskParams", floatArrayOf(1f, 0f, 0f, 0f))
        } else {
            val m = mask.sampleAt(timeUs)
            val ref = min(g.halfWidth, g.halfHeight)
            val rad = m.rotation * PI / 180.0
            main.setIntUniform("uMaskKind", mask.shape.shaderKind)
            main.setFloatsUniform(
                "uMaskGeom",
                floatArrayOf(
                    (m.centerX * g.halfWidth).toFloat(),
                    (m.centerY * g.halfHeight).toFloat(),
                    max(1.0, m.sizeX * ref).toFloat(),
                    max(1.0, m.sizeY * ref).toFloat(),
                ),
            )
            main.setFloatsUniform(
                "uMaskParams",
                floatArrayOf(
                    cos(rad).toFloat(),
                    sin(rad).toFloat(),
                    (m.feather * ref).toFloat(),
                    if (mask.invert) 1f else 0f,
                ),
            )
        }
        main.bindAttributesAndUniforms()
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GlUtil.checkGlError()
    }

    /** Cropped clip frame downsampled and blurred with separable Gaussian passes. */
    private fun blurredClip(inputTexId: Int, style: ClipStyle, amount: Double): Int {
        val cropW = max(1.0, inputWidth * style.crop.width)
        val cropH = max(1.0, inputHeight * style.crop.height)
        val plan = ClipStyle.clipBlurPlan(cropW, cropH, amount)
        val a = clipBlurScratch[0].ensure(plan.width, plan.height)
        val b = clipBlurScratch[1].ensure(plan.width, plan.height)
        val c = style.crop
        GlUtil.focusFramebufferUsingCurrentContext(a.fbo, a.width, a.height)
        cropCopy.use()
        cropCopy.setSamplerTexIdUniform("uSrc", inputTexId, 0)
        cropCopy.setFloatsUniform("uCrop", floatArrayOf(c.left.toFloat(), c.top.toFloat(), c.width.toFloat(), c.height.toFloat()))
        cropCopy.setFloatsUniform("uDst", floatArrayOf(a.width.toFloat(), a.height.toFloat()))
        cropCopy.setFloatsUniform("uSrcTexel", floatArrayOf(1f / inputWidth, 1f / inputHeight))
        cropCopy.bindAttributesAndUniforms()
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        val spread = plan.spread.toFloat()
        repeat(BLUR_ROUNDS) {
            blurPass(a, b, spread / a.width, 0f)
            blurPass(b, a, 0f, spread / a.height)
        }
        return a.texture
    }

    /** The current frame, cropped and flipped like the clip, filling the canvas, downsampled and blurred. */
    private fun blurredInput(inputTexId: Int, style: ClipStyle, bg: BackgroundStyle): Int {
        val (w, h) = smallSize(bg)
        val srcW = inputWidth * style.crop.width
        val srcH = inputHeight * style.crop.height
        renderDownsample(
            src = inputTexId,
            srcW = srcW,
            srcH = srcH,
            crop = style.crop,
            flipX = style.flipX,
            flipY = style.flipY,
            flipV = false,
            target = scratch[0].ensure(w, h),
        )
        return blurScratch(bg)
    }

    /** The image background, rendered once per (image, blur) and reused for every frame. */
    private fun imageBackground(bg: BackgroundStyle): Int {
        val uri = bg.imageUri ?: return NO_TEXTURE
        if (uri != imageUri) {
            loadImage(uri)
            imageTargetKey = null
        }
        if (imageTexture == NO_TEXTURE) return NO_TEXTURE
        val key = Pair(uri, bg.blur)
        if (imageTargetKey == key) return imageTarget.texture
        val (w, h) = smallSize(bg)
        val full = CropBox()
        val first = if (bg.blur > 0) scratch[0].ensure(w, h) else imageTarget.ensure(w, h)
        renderDownsample(
            src = imageTexture,
            srcW = imageSize.width.toDouble(),
            srcH = imageSize.height.toDouble(),
            crop = full,
            flipX = false,
            flipY = false,
            flipV = true,
            target = first,
        )
        if (bg.blur > 0) {
            val blurred = blurScratch(bg)
            // Copy the result into the cached target so the scratch textures stay free.
            val t = imageTarget.ensure(w, h)
            renderDownsample(
                src = blurred,
                srcW = w.toDouble(),
                srcH = h.toDouble(),
                crop = full,
                flipX = false,
                flipY = false,
                flipV = false,
                target = t,
            )
        }
        imageTargetKey = key
        return imageTarget.texture
    }

    private fun releaseImageBackground() {
        if (imageTexture != NO_TEXTURE) {
            GlUtil.deleteTexture(imageTexture)
            imageTexture = NO_TEXTURE
        }
        if (imageTarget.texture != NO_TEXTURE) imageTarget.release()
        imageUri = null
        imageTargetKey = null
    }

    private fun smallSize(bg: BackgroundStyle): Pair<Int, Int> {
        val shortSide = bg.blurTextureShortSide(min(canvasWidth, canvasHeight))
        val ratio = canvasWidth.toDouble() / canvasHeight
        return if (ratio >= 1) {
            Pair(max(1, (shortSide * ratio).roundToInt()), shortSide)
        } else {
            Pair(shortSide, max(1, (shortSide / ratio).roundToInt()))
        }
    }

    /** Draws [src] (fill mapping of its [crop]) into [target], averaging 4×4 taps per pixel. */
    private fun renderDownsample(
        src: Int,
        srcW: Double,
        srcH: Double,
        crop: CropBox,
        flipX: Boolean,
        flipY: Boolean,
        flipV: Boolean,
        target: Target,
    ) {
        GlUtil.focusFramebufferUsingCurrentContext(target.fbo, target.width, target.height)
        downsample.use()
        downsample.setSamplerTexIdUniform("uSrc", src, 0)
        downsample.setFloatsUniform("uSrcSize", floatArrayOf(max(1.0, srcW).toFloat(), max(1.0, srcH).toFloat()))
        downsample.setFloatsUniform("uDst", floatArrayOf(target.width.toFloat(), target.height.toFloat()))
        downsample.setFloatsUniform("uCrop", floatArrayOf(crop.left.toFloat(), crop.top.toFloat(), crop.width.toFloat(), crop.height.toFloat()))
        downsample.setFloatsUniform("uFlip", floatArrayOf(if (flipX) -1f else 1f, if (flipY) -1f else 1f))
        downsample.setFloatUniform("uFlipV", if (flipV) 1f else 0f)
        downsample.bindAttributesAndUniforms()
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
    }

    /** Two rounds of a separable Gaussian over scratch[0]; the result ends in scratch[0]. */
    private fun blurScratch(bg: BackgroundStyle): Int {
        val a = scratch[0]
        if (bg.blur <= 0) return a.texture
        val b = scratch[1].ensure(a.width, a.height)
        repeat(BLUR_ROUNDS) {
            blurPass(a, b, 1f / a.width, 0f)
            blurPass(b, a, 0f, 1f / a.height)
        }
        return a.texture
    }

    private fun blurPass(from: Target, to: Target, stepX: Float, stepY: Float) {
        GlUtil.focusFramebufferUsingCurrentContext(to.fbo, to.width, to.height)
        blur.use()
        blur.setSamplerTexIdUniform("uSrc", from.texture, 0)
        blur.setFloatsUniform("uStep", floatArrayOf(stepX, stepY))
        blur.bindAttributesAndUniforms()
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
    }

    private fun loadImage(uri: String) {
        if (imageTexture != NO_TEXTURE) GlUtil.deleteTexture(imageTexture)
        imageTexture = NO_TEXTURE
        imageUri = uri
        val decoded = runCatching { decode(uri) }
            .onFailure { Log.w(TAG, "Background image could not be read", it) }
            .getOrNull() ?: return
        val upload = if (decoded.config == Bitmap.Config.ARGB_8888) {
            decoded
        } else {
            val copy = decoded.copy(Bitmap.Config.ARGB_8888, false)
            decoded.recycle()
            copy ?: return
        }
        try {
            imageTexture = runCatching { GlUtil.createTexture(upload) }
                .onFailure { Log.w(TAG, "Background image could not be uploaded", it) }
                .getOrDefault(NO_TEXTURE)
            if (imageTexture != NO_TEXTURE) {
                imageSize = Size(upload.width, upload.height)
            }
        } finally {
            upload.recycle()
        }
    }

    /** Decodes [uri] upright (EXIF applied), sRGB 8-bit, at most [MAX_IMAGE_SIDE] on its long side. */
    private fun decode(uri: String): Bitmap {
        val source = ImageDecoder.createSource(context.contentResolver, Uri.parse(uri))
        return ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
            decoder.setTargetSampleSize(
                BackgroundStyle.imageSampleSize(info.size.width, info.size.height, MAX_IMAGE_SIDE),
            )
            decoder.setTargetColorSpace(ColorSpace.get(ColorSpace.Named.SRGB))
            decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
        }
    }

    /**
     * The LUT [filterId] as a 2D atlas texture (id, LUT size), uploaded on first use. The `.cube`
     * file itself is parsed by [LutLibrary], normally ahead of time off the GL thread. A failure is
     * cached too, so a broken LUT is skipped instead of failing every frame.
     */
    private fun lutTexture(filterId: String): Pair<Int, Int>? {
        if (lutCache.containsKey(filterId)) return lutCache[filterId]
        val lut = LutLibrary.get(context, filterId)?.lut
        val entry = lut?.let(::uploadLut)
        lutCache[filterId] = entry
        return entry
    }

    private fun uploadLut(lut: CubeLut): Pair<Int, Int>? {
        val bytes = lut.toRgbaAtlasBytes()
        val buffer = ByteBuffer.allocateDirect(bytes.size).apply {
            put(bytes)
            position(0)
        }
        val ids = IntArray(1)
        GLES20.glGenTextures(1, ids, 0)
        val texId = ids[0]
        if (texId == 0) return null
        return try {
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texId)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
            // RGBA rows are 4-byte aligned, so the default GL_UNPACK_ALIGNMENT (4) is fine.
            GLES20.glTexImage2D(
                GLES20.GL_TEXTURE_2D,
                0,
                GLES20.GL_RGBA,
                lut.size * lut.size,
                lut.size,
                0,
                GLES20.GL_RGBA,
                GLES20.GL_UNSIGNED_BYTE,
                buffer,
            )
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
            GlUtil.checkGlError()
            Pair(texId, lut.size)
        } catch (e: GlUtil.GlException) {
            Log.w(TAG, "LUT texture upload failed (${lut.size}^3)", e)
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
            runCatching { GlUtil.deleteTexture(texId) }
            null
        }
    }

    override fun release() {
        super.release()
        try {
            main.delete()
            downsample.delete()
            cropCopy.delete()
            blur.delete()
            scratch.forEach { it.release() }
            clipBlurScratch.forEach { it.release() }
            imageTarget.release()
            if (imageTexture != NO_TEXTURE) GlUtil.deleteTexture(imageTexture)
            lutCache.values.filterNotNull().forEach { (texId, _) -> GlUtil.deleteTexture(texId) }
            lutCache.clear()
        } catch (e: GlUtil.GlException) {
            throw VideoFrameProcessingException(e)
        }
    }

    private fun program(fragment: String) = GlProgram(VERTEX, fragment).apply {
        setBufferAttribute("aFramePosition", GlUtil.getNormalizedCoordinateBounds(), GlUtil.HOMOGENEOUS_COORDINATE_VECTOR_SIZE)
    }

    /** An offscreen texture with its framebuffer, recreated when its size changes. */
    private class Target {
        var texture = NO_TEXTURE
        var fbo = NO_TEXTURE
        var width = 0
        var height = 0

        fun ensure(w: Int, h: Int): Target {
            if (w == width && h == height && texture != NO_TEXTURE) return this
            release()
            texture = GlUtil.createTexture(w, h, /* useHighPrecisionColorComponents= */ false)
            fbo = GlUtil.createFboForTexture(texture)
            width = w
            height = h
            return this
        }

        fun release() {
            if (fbo != NO_TEXTURE) GlUtil.deleteFbo(fbo)
            if (texture != NO_TEXTURE) GlUtil.deleteTexture(texture)
            texture = NO_TEXTURE
            fbo = NO_TEXTURE
            width = 0
            height = 0
        }
    }

    private companion object {
        const val TAG = "CleanCutEngine"
        const val NO_TEXTURE = -1
        const val BLACK = 0xFF000000.toInt()
        const val BLUR_ROUNDS = 2
        const val CLIP_BLUR_FADE_IN = 0.12
        const val MAX_IMAGE_SIDE = 2048

        fun rgba(argb: Int) = floatArrayOf(
            ((argb shr 16) and 0xFF) / 255f,
            ((argb shr 8) and 0xFF) / 255f,
            (argb and 0xFF) / 255f,
            ((argb ushr 24) and 0xFF) / 255f,
        )

        const val VERTEX = """#version 100
attribute vec4 aFramePosition;
varying vec2 vOut;
void main() {
  gl_Position = aFramePosition;
  vOut = aFramePosition.xy * 0.5 + 0.5;
}
"""

        /** Background + clip with blur, color adjustments, 3D LUT, sharpen, vignette and shape mask. Pixel space has top-left origin, y down. */
        const val FRAGMENT_MAIN = """#version 100
precision highp float;
uniform sampler2D uTex;
uniform sampler2D uBgTex;
uniform sampler2D uLutTex;
uniform sampler2D uClipBlurTex;
uniform float uClipBlurMix;
uniform float uLutSize;
uniform float uLutIntensity;
uniform vec2 uTexel;
uniform vec4 uAdjA;
uniform vec4 uAdjB;
uniform vec2 uAdjC;
uniform vec2 uCanvas;
uniform int uBgKind;
uniform vec4 uColorA;
uniform vec4 uColorB;
uniform vec3 uGradAxis;
uniform vec2 uCenter;
uniform vec2 uHalf;
uniform vec2 uRot;
uniform vec4 uCrop;
uniform vec2 uFlip;
uniform float uRadius;
uniform float uBorder;
uniform vec4 uBorderColor;
uniform float uOpacity;
uniform int uMaskKind;
uniform vec4 uMaskGeom;
uniform vec4 uMaskParams;
varying vec2 vOut;

float roundRect(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float dot2(vec2 v) {
  return dot(v, v);
}

float maskSdf(int kind, vec2 p, vec2 r) {
  vec2 s = max(r, vec2(1.0));
  if (kind == 1) {
    return p.y;
  }
  if (kind == 2) {
    return abs(p.y) - s.y;
  }
  if (kind == 3) {
    vec2 q = p / s;
    float k0 = length(q);
    if (k0 < 1e-5) return -min(s.x, s.y);
    float k1 = length(q / s);
    return k0 * (k0 - 1.0) / max(k1, 1e-5);
  }
  if (kind == 4) {
    vec2 q = abs(p) - s;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
  }
  if (kind == 5) {
    vec2 hp = vec2(abs(p.x / s.x) * 0.60355339, (-p.y / s.y) * 0.55177670 + 0.55177670);
    float raw;
    if (hp.y + hp.x > 1.0) {
      raw = sqrt(dot2(hp - vec2(0.25, 0.75))) - 0.35355339;
    } else {
      float d1 = dot2(hp - vec2(0.0, 1.0));
      float d2 = dot2(hp - 0.5 * max(hp.x + hp.y, 0.0));
      float sgn = hp.x >= hp.y ? 1.0 : -1.0;
      raw = sqrt(min(d1, d2)) * sgn;
    }
    return raw * min(s.x / 0.60355339, s.y / 0.55177670);
  }
  vec2 sp = vec2(abs(p.x / s.x), -p.y / s.y);
  vec2 k1 = vec2(0.809016994375, -0.587785252292);
  vec2 k2 = vec2(-0.809016994375, -0.587785252292);
  sp -= 2.0 * max(dot(k1, sp), 0.0) * k1;
  sp -= 2.0 * max(dot(k2, sp), 0.0) * k2;
  sp.x = abs(sp.x);
  sp.y -= 1.0;
  vec2 ba = 0.45 * vec2(0.587785252292, 0.809016994375) - vec2(0.0, 1.0);
  float h = clamp(dot(sp, ba) / dot(ba, ba), 0.0, 1.0);
  float crossVal = sp.y * ba.x - sp.x * ba.y;
  float raw = length(sp - ba * h) * (crossVal >= 0.0 ? 1.0 : -1.0);
  return raw * min(s.x, s.y);
}

vec3 sampleLut(vec3 rgb, float size) {
  vec3 c = clamp(rgb, 0.0, 1.0);
  float maxIdx = size - 1.0;
  float bScaled = c.b * maxIdx;
  float b0 = floor(bScaled);
  float b1 = min(b0 + 1.0, maxIdx);
  float bf = bScaled - b0;
  float uR = (c.r * maxIdx + 0.5) / size;
  float v = (c.g * maxIdx + 0.5) / size;
  vec3 c0 = texture2D(uLutTex, vec2((b0 + uR) / size, v)).rgb;
  vec3 c1 = texture2D(uLutTex, vec2((b1 + uR) / size, v)).rgb;
  return mix(c0, c1, bf);
}

/** Un-premultiplied color at [uv] clamped to [lo, hi]; [fallback] where fully transparent. */
vec3 sharpenTap(vec2 uv, vec2 lo, vec2 hi, vec3 fallback) {
  vec4 t = texture2D(uTex, clamp(uv, lo, hi));
  return t.a > 1e-4 ? t.rgb / t.a : fallback;
}

vec3 applyAdjustments(vec3 rgb) {
  float exposure = uAdjA.x;
  float brightness = uAdjA.y;
  float contrast = uAdjA.z;
  float saturation = uAdjA.w;
  float warmth = uAdjB.x;
  float tint = uAdjB.y;
  float highlights = uAdjB.z;
  float shadows = uAdjB.w;

  if (exposure != 0.0) {
    rgb *= exp2(exposure * 1.5);
  }
  if (brightness != 0.0) {
    rgb += vec3(brightness * 0.35);
  }
  if (contrast != 0.0) {
    rgb = (rgb - 0.5) * (1.0 + contrast * 0.85) + 0.5;
  }
  rgb = clamp(rgb, 0.0, 1.0);
  if (highlights != 0.0 || shadows != 0.0) {
    float luma = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
    float shMask = (1.0 - luma) * (1.0 - luma);
    float hiMask = luma * luma;
    rgb += vec3(shadows * 0.45 * shMask + highlights * 0.45 * hiMask);
    rgb = clamp(rgb, 0.0, 1.0);
  }
  if (warmth != 0.0 || tint != 0.0) {
    rgb.r += warmth * 0.14 + tint * 0.06;
    rgb.g -= tint * 0.12;
    rgb.b -= warmth * 0.14 - tint * 0.06;
    rgb = clamp(rgb, 0.0, 1.0);
  }
  if (saturation != 0.0) {
    float luma = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
    rgb = mix(vec3(luma), rgb, 1.0 + saturation);
    rgb = clamp(rgb, 0.0, 1.0);
  }
  return rgb;
}

void main() {
  vec2 p = vec2(vOut.x, 1.0 - vOut.y) * uCanvas;
  vec4 bg;
  if (uBgKind == 1) {
    float t = clamp(dot(p - 0.5 * uCanvas, uGradAxis.xy) / uGradAxis.z + 0.5, 0.0, 1.0);
    bg = vec4(mix(uColorA.rgb * uColorA.a, uColorB.rgb * uColorB.a, t), 1.0);
  } else if (uBgKind == 2) {
    bg = vec4(texture2D(uBgTex, vOut).rgb, 1.0);
  } else {
    bg = vec4(uColorA.rgb * uColorA.a, 1.0);
  }

  vec2 d = p - uCenter;
  vec2 local = vec2(uRot.x * d.x + uRot.y * d.y, -uRot.y * d.x + uRot.x * d.y);
  float radius = min(uRadius, min(uHalf.x, uHalf.y));
  float sd = roundRect(local, uHalf, radius);
  float coverage = clamp(0.5 - sd, 0.0, 1.0);
  if (coverage <= 0.0 || uOpacity <= 0.0) {
    gl_FragColor = bg;
    return;
  }
  vec2 u = local / max(uHalf, vec2(1e-4)) * 0.5 * uFlip + 0.5;
  vec2 src = uCrop.xy + clamp(u, 0.0, 1.0) * uCrop.zw;
  vec2 uv = vec2(src.x, 1.0 - src.y);
  // uTex is premultiplied (Android Bitmaps for PNGs; video frames have a = 1).
  vec4 c = texture2D(uTex, uv);
  vec4 bc = vec4(0.0);
  if (uClipBlurMix > 0.0) {
    vec2 cu = clamp(u, 0.0, 1.0);
    bc = texture2D(uClipBlurTex, vec2(cu.x, 1.0 - cu.y));
    c = mix(c, bc, uClipBlurMix);
  }
  vec3 outRgb = c.rgb;
  float outA = c.a;
  float sharpen = uAdjC.x;
  float vignette = uAdjC.y;
  bool hasColorGrade = uLutIntensity > 0.0 || sharpen > 0.0 || vignette > 0.0 ||
      uAdjA != vec4(0.0) || uAdjB != vec4(0.0);
  if (hasColorGrade && outA > 1e-4) {
    vec3 rgb = outRgb / outA;
    if (sharpen > 0.0) {
      // Neighbours stay inside the crop (half a texel in, so linear filtering
      // can't reach past it) and are un-premultiplied by their own alpha.
      vec2 lo = vec2(uCrop.x, 1.0 - uCrop.y - uCrop.w) + 0.5 * uTexel;
      vec2 hi = max(vec2(uCrop.x + uCrop.z, 1.0 - uCrop.y) - 0.5 * uTexel, lo);
      vec3 n = sharpenTap(uv + vec2(0.0, uTexel.y), lo, hi, rgb);
      vec3 s = sharpenTap(uv - vec2(0.0, uTexel.y), lo, hi, rgb);
      vec3 e = sharpenTap(uv + vec2(uTexel.x, 0.0), lo, hi, rgb);
      vec3 w = sharpenTap(uv - vec2(uTexel.x, 0.0), lo, hi, rgb);
      vec3 blurAvg = (n + s + e + w) * 0.25;
      if (uClipBlurMix > 0.0) {
        // The taps above read the sharp source. The blurred image is smooth at
        // this scale (its neighbours match its centre), so blend them the same
        // way as the centre; otherwise sharpen brings back the blurred detail.
        vec3 blurRgb = bc.a > 1e-4 ? bc.rgb / bc.a : rgb;
        blurAvg = mix(blurAvg, blurRgb, uClipBlurMix);
      }
      rgb = clamp(rgb + (rgb - blurAvg) * (sharpen * 1.4), 0.0, 1.0);
    }
    rgb = applyAdjustments(rgb);
    if (uLutIntensity > 0.0 && uLutSize > 1.0) {
      vec3 lutRgb = sampleLut(rgb, uLutSize);
      rgb = mix(rgb, lutRgb, uLutIntensity);
    }
    if (vignette > 0.0) {
      vec2 du = u - 0.5;
      float dist = length(du) * 1.41421356;
      float vig = 1.0 - vignette * 0.85 * smoothstep(0.35, 1.15, dist);
      rgb *= clamp(vig, 0.0, 1.0);
    }
    outRgb = clamp(rgb, 0.0, 1.0) * outA;
  }
  if (uBorder > 0.0) {
    float stroke = clamp(sd + uBorder + 0.5, 0.0, 1.0) * uBorderColor.a;
    outRgb = uBorderColor.rgb * stroke + outRgb * (1.0 - stroke);
    outA = stroke + outA * (1.0 - stroke);
  }
  float maskAlpha = 1.0;
  if (uMaskKind > 0) {
    vec2 md = local - uMaskGeom.xy;
    vec2 mp = vec2(
      uMaskParams.x * md.x + uMaskParams.y * md.y,
      -uMaskParams.y * md.x + uMaskParams.x * md.y
    );
    float msd = maskSdf(uMaskKind, mp, uMaskGeom.zw);
    float halfF = max(0.5, uMaskParams.z * 0.5);
    maskAlpha = 1.0 - smoothstep(-halfF, halfF, msd);
    if (uMaskParams.w > 0.5) {
      maskAlpha = 1.0 - maskAlpha;
    }
  }
  float mask = coverage * maskAlpha * uOpacity;
  gl_FragColor = vec4(bg.rgb * (1.0 - outA * mask) + outRgb * mask, 1.0);
}
"""

        /** Copies the cropped source region into a small target with 4×4 box filtering inside the crop. */
        const val FRAGMENT_CROP_COPY = """#version 100
precision highp float;
uniform sampler2D uSrc;
uniform vec4 uCrop;
uniform vec2 uDst;
uniform vec2 uSrcTexel;
varying vec2 vOut;
void main() {
  vec2 u = vec2(vOut.x, 1.0 - vOut.y);
  vec2 center = uCrop.xy + u * uCrop.zw;
  vec2 footprint = uCrop.zw / max(uDst, vec2(1.0));
  vec2 lo = uCrop.xy + 0.5 * uSrcTexel;
  vec2 hi = max(uCrop.xy + uCrop.zw - 0.5 * uSrcTexel, lo);
  vec4 sum = vec4(0.0);
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      vec2 p = clamp(center + ((vec2(float(i), float(j)) + 0.5) / 4.0 - 0.5) * footprint, lo, hi);
      sum += texture2D(uSrc, vec2(p.x, 1.0 - p.y));
    }
  }
  gl_FragColor = sum / 16.0;
}
"""

        /** Fill-maps a source's crop into a (small) target, averaging 4×4 taps per pixel. */
        const val FRAGMENT_DOWNSAMPLE = """#version 100
precision highp float;
uniform sampler2D uSrc;
uniform vec2 uSrcSize;
uniform vec2 uDst;
uniform vec4 uCrop;
uniform vec2 uFlip;
uniform float uFlipV;
varying vec2 vOut;
void main() {
  vec2 p = vec2(vOut.x, 1.0 - vOut.y) * uDst;
  float s = max(uDst.x / uSrcSize.x, uDst.y / uSrcSize.y);
  vec2 sp = (p - 0.5 * uDst) / s + 0.5 * uSrcSize;
  vec2 norm = (sp / uSrcSize - 0.5) * uFlip + 0.5;
  vec2 u = uCrop.xy + norm * uCrop.zw;
  vec2 footprint = (1.0 / s) / uSrcSize * uCrop.zw;
  vec4 sum = vec4(0.0);
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      vec2 uv = u + ((vec2(float(i), float(j)) + 0.5) / 4.0 - 0.5) * footprint;
      sum += texture2D(uSrc, vec2(uv.x, mix(1.0 - uv.y, uv.y, uFlipV)));
    }
  }
  gl_FragColor = sum / 16.0;
}
"""

        /** One direction of a 9-tap Gaussian. */
        const val FRAGMENT_BLUR = """#version 100
precision highp float;
uniform sampler2D uSrc;
uniform vec2 uStep;
varying vec2 vOut;
void main() {
  vec4 sum = texture2D(uSrc, vOut) * 0.2270270270;
  sum += texture2D(uSrc, vOut + uStep * 1.0) * 0.1945945946;
  sum += texture2D(uSrc, vOut - uStep * 1.0) * 0.1945945946;
  sum += texture2D(uSrc, vOut + uStep * 2.0) * 0.1216216216;
  sum += texture2D(uSrc, vOut - uStep * 2.0) * 0.1216216216;
  sum += texture2D(uSrc, vOut + uStep * 3.0) * 0.0540540541;
  sum += texture2D(uSrc, vOut - uStep * 3.0) * 0.0540540541;
  sum += texture2D(uSrc, vOut + uStep * 4.0) * 0.0162162162;
  sum += texture2D(uSrc, vOut - uStep * 4.0) * 0.0162162162;
  gl_FragColor = sum;
}
"""
    }
}
