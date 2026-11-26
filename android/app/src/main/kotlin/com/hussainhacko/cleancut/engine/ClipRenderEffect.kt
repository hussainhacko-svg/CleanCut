package com.hussainhacko.cleancut.engine

import android.content.Context
import android.graphics.Bitmap
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
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

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
    private val blur = program(FRAGMENT_BLUR)

    private var inputWidth = 1
    private var inputHeight = 1

    /** Ping-pong textures for the blurred background, canvas aspect, small. */
    private val scratch = arrayOf(Target(), Target())

    /** A decoded image background and its key; the rendered result lives in [imageTarget]. */
    private var imageTexture: Int = NO_TEXTURE
    private var imageSize = Size(1, 1)
    private var imageUri: String? = null
    private var imageTarget = Target()
    private var imageTargetKey: Pair<String, Double>? = null

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
                BackgroundStyle.Kind.BLUR -> blurredInput(inputTexId, style.crop, bg)
                BackgroundStyle.Kind.IMAGE -> imageBackground(bg)
                else -> NO_TEXTURE
            }
            GlUtil.focusFramebufferUsingCurrentContext(outputFbo, canvasWidth, canvasHeight)
            val clipTimeUs = (presentationTimeUs - look.timelineStartUs).coerceAtLeast(0L)
            drawClip(inputTexId, style, bg, backgroundTexture, clipTimeUs)
        } catch (e: GlUtil.GlException) {
            throw VideoFrameProcessingException(e, presentationTimeUs)
        }
    }

    private fun drawClip(inputTexId: Int, style: ClipStyle, bg: BackgroundStyle, bgTexture: Int, timeUs: Long) {
        val g = ClipFrameGeometry.of(style, inputWidth, inputHeight, canvasWidth, canvasHeight, timeUs)
        main.use()
        main.setSamplerTexIdUniform("uTex", inputTexId, 0)
        // Bind the input again when there is no background texture: the sampler needs a texture.
        main.setSamplerTexIdUniform("uBgTex", if (bgTexture == NO_TEXTURE) inputTexId else bgTexture, 1)
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
        main.bindAttributesAndUniforms()
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GlUtil.checkGlError()
    }

    /** The current frame, cropped, filling the canvas, downsampled and blurred. */
    private fun blurredInput(inputTexId: Int, crop: CropBox, bg: BackgroundStyle): Int {
        val (w, h) = smallSize(bg)
        val srcW = inputWidth * crop.width
        val srcH = inputHeight * crop.height
        renderDownsample(inputTexId, srcW, srcH, crop, flipV = false, target = scratch[0].ensure(w, h))
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
        renderDownsample(imageTexture, imageSize.width.toDouble(), imageSize.height.toDouble(), full, flipV = true, target = first)
        if (bg.blur > 0) {
            val blurred = blurScratch(bg)
            // Copy the result into the cached target so the scratch textures stay free.
            val t = imageTarget.ensure(w, h)
            renderDownsample(blurred, w.toDouble(), h.toDouble(), full, flipV = false, target = t)
        }
        imageTargetKey = key
        return imageTarget.texture
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
    private fun renderDownsample(src: Int, srcW: Double, srcH: Double, crop: CropBox, flipV: Boolean, target: Target) {
        GlUtil.focusFramebufferUsingCurrentContext(target.fbo, target.width, target.height)
        downsample.use()
        downsample.setSamplerTexIdUniform("uSrc", src, 0)
        downsample.setFloatsUniform("uSrcSize", floatArrayOf(max(1.0, srcW).toFloat(), max(1.0, srcH).toFloat()))
        downsample.setFloatsUniform("uDst", floatArrayOf(target.width.toFloat(), target.height.toFloat()))
        downsample.setFloatsUniform("uCrop", floatArrayOf(crop.left.toFloat(), crop.top.toFloat(), crop.width.toFloat(), crop.height.toFloat()))
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
        val bitmap = runCatching { decode(uri) }
            .onFailure { Log.w(TAG, "Background image could not be read", it) }
            .getOrNull() ?: return
        imageTexture = GlUtil.createTexture(bitmap)
        imageSize = Size(bitmap.width, bitmap.height)
        bitmap.recycle()
    }

    /** Decodes [uri] upright (EXIF applied), at most [MAX_IMAGE_SIDE] on its long side. */
    private fun decode(uri: String): Bitmap {
        val source = ImageDecoder.createSource(context.contentResolver, Uri.parse(uri))
        return ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
            val longSide = max(info.size.width, info.size.height)
            var sample = 1
            while (longSide / (sample * 2) >= MAX_IMAGE_SIDE) sample *= 2
            decoder.setTargetSampleSize(sample)
            decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
        }
    }

    override fun release() {
        super.release()
        try {
            main.delete()
            downsample.delete()
            blur.delete()
            scratch.forEach { it.release() }
            imageTarget.release()
            if (imageTexture != NO_TEXTURE) GlUtil.deleteTexture(imageTexture)
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

        /** Background + clip. Pixel space has its origin at the top-left, y down. */
        const val FRAGMENT_MAIN = """#version 100
precision highp float;
uniform sampler2D uTex;
uniform sampler2D uBgTex;
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
varying vec2 vOut;

float roundRect(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 p = vec2(vOut.x, 1.0 - vOut.y) * uCanvas;
  vec4 bg;
  if (uBgKind == 1) {
    float t = clamp(dot(p - 0.5 * uCanvas, uGradAxis.xy) / uGradAxis.z + 0.5, 0.0, 1.0);
    bg = mix(uColorA, uColorB, t);
  } else if (uBgKind == 2) {
    bg = texture2D(uBgTex, vOut);
  } else {
    bg = uColorA;
  }
  bg = vec4(bg.rgb * bg.a, 1.0);

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
  vec4 c = texture2D(uTex, vec2(src.x, 1.0 - src.y));
  if (uBorder > 0.0) {
    float stroke = clamp(sd + uBorder + 0.5, 0.0, 1.0) * uBorderColor.a;
    c = vec4(mix(c.rgb, uBorderColor.rgb, stroke), max(c.a, stroke));
  }
  float alpha = coverage * uOpacity * c.a;
  gl_FragColor = vec4(mix(bg.rgb, c.rgb, alpha), 1.0);
}
"""

        /** Fill-maps a source's crop into a (small) target, averaging 4×4 taps per pixel. */
        const val FRAGMENT_DOWNSAMPLE = """#version 100
precision highp float;
uniform sampler2D uSrc;
uniform vec2 uSrcSize;
uniform vec2 uDst;
uniform vec4 uCrop;
uniform float uFlipV;
varying vec2 vOut;
void main() {
  vec2 p = vec2(vOut.x, 1.0 - vOut.y) * uDst;
  float s = max(uDst.x / uSrcSize.x, uDst.y / uSrcSize.y);
  vec2 sp = (p - 0.5 * uDst) / s + 0.5 * uSrcSize;
  vec2 u = uCrop.xy + sp / uSrcSize * uCrop.zw;
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
