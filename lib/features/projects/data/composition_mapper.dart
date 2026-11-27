import 'dart:math' as math;

import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/canvas_background.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/speed_curve.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';

/// Short side of the preview surface in pixels. Export renders at the
/// canvas resolution instead; preview stays light for smooth scrubbing.
const int previewShortSidePx = 720;

/// Maps a project's main track to the engine's [CompositionSpec].
///
/// Covers trims, constant speed and speed curves (Flow), stills, the
/// canvas size and background, and each clip's fit, crop, transform
/// (keyframes sampled at the canvas frame rate) and border.
///
/// When [uncroppedClipId] is set (while the Crop panel is open), that clip
/// renders uncropped and fitted (preserving its flip and rotation) so the
/// on-preview crop handles sit over the whole source frame.
CompositionSpec compositionSpecOf(
  Project project, {
  int shortSidePx = previewShortSidePx,
  String? uncroppedClipId,
}) {
  final size = project.canvas.aspect.pixelSize(shortSidePx);
  final fps = project.canvas.fps;
  ClipStyleSpec styleOf(Clip clip) {
    if (uncroppedClipId == null || clip.id != uncroppedClipId) {
      return clipStyleSpecOf(clip, fps: fps);
    }
    return clipStyleSpecOf(
      clip.copyWith(
        fitMode: FitMode.fit,
        crop: CropRect.full,
        border: const ClipBorder(),
        transform: clip.transform.copyWith(
          position: const Animatable.constant(Vec2.zero),
          scale: const Animatable.constant(1),
          opacity: const Animatable.constant(1),
        ),
      ),
      fps: fps,
    );
  }

  return CompositionSpec(
    clips: [
      for (final clip in project.mainTrack.clips)
        if (clip.media.kind == MediaKind.image)
          // A still has no source timeline: it simply shows for its length
          // on the timeline, which already includes its speed.
          ClipSpec(
            uri: clip.media.uri,
            kind: SpecMediaKind.image,
            sourceDurationUs: clip.durationUs,
            sourceInUs: 0,
            sourceOutUs: clip.durationUs,
            speed: 1,
            keepPitch: true,
            speedSteps: const [],
            style: styleOf(clip),
          )
        else
          ClipSpec(
            uri: clip.media.uri,
            kind: SpecMediaKind.video,
            sourceDurationUs: clip.media.durationUs ?? clip.sourceOutUs,
            sourceInUs: clip.sourceInUs,
            sourceOutUs: clip.sourceOutUs,
            speed: clip.speed,
            keepPitch: clip.keepPitch,
            speedSteps: [
              for (final step
                  in clip.speedCurve?.steps(clip.sourceDurationUs) ??
                      const <SpeedStep>[])
                SpeedStepSpec(startUs: step.startUs, speed: step.speed),
            ],
            style: styleOf(clip),
          ),
    ],
    canvasWidth: size.width,
    canvasHeight: size.height,
    frameRate: fps,
    background: backgroundSpecOf(project.canvas.background),
  );
}

/// The engine's view of [clip]'s look. Keyframed transforms are sampled
/// once per frame at [fps] plus at every keyframe and the clip's end, so
/// the engine's linear interpolation follows the eased curves closely.
ClipStyleSpec clipStyleSpecOf(Clip clip, {required int fps}) {
  final transform = clip.transform;
  final crop = clip.crop;
  final filter = clip.filter;
  final adj = clip.adjustments;
  return ClipStyleSpec(
    fitMode: switch (clip.fitMode) {
      FitMode.fit => SpecFitMode.fit,
      FitMode.fill => SpecFitMode.fill,
      FitMode.stretch => SpecFitMode.stretch,
    },
    cropLeft: crop.left,
    cropTop: crop.top,
    cropRight: crop.right,
    cropBottom: crop.bottom,
    flipX: transform.flipX,
    flipY: transform.flipY,
    transform: [
      for (final t in transformSampleTimes(transform, clip.durationUs, fps))
        _sample(t, transform.at(t)),
    ],
    borderWidth: clip.border.width,
    borderArgb: clip.border.argb,
    borderRadius: clip.border.radius,
    filterId: filter?.id,
    filterIntensity: filter?.intensity ?? 0,
    adjustments: ColorAdjustmentsSpec(
      exposure: adj.exposure,
      brightness: adj.brightness,
      contrast: adj.contrast,
      saturation: adj.saturation,
      warmth: adj.warmth,
      tint: adj.tint,
      highlights: adj.highlights,
      shadows: adj.shadows,
      sharpen: adj.sharpen,
      vignette: adj.vignette,
    ),
  );
}

/// Times at which an animated [transform] is sampled within a clip of
/// [durationUs]: `0`, every keyframe inside the clip, [durationUs], plus
/// per-frame samples at [fps] (clamped to `1..240`) across any interval
/// whose easing is non-linear. Constant and linear segments need no extra
/// samples because the engine interpolates linearly between samples.
List<int> transformSampleTimes(
  ClipTransform transform,
  int durationUs,
  int fps,
) {
  if (!transform.isAnimated || durationUs <= 0) return const [0];
  final clampedFps = fps <= 0 ? 30 : fps.clamp(1, 240);
  final step = math.max(1, Micros.perSecond ~/ clampedFps);
  final times = <int>{
    0,
    for (final k in transform.keyframeTimes)
      if (k >= 0 && k <= durationUs) k,
    durationUs,
  };
  void sampleEased(Animatable<Object?> property) {
    if (property is! KeyframedAnimatable<Object?>) return;
    final keyframes = property.keyframes;
    for (var i = 0; i < keyframes.length - 1; i++) {
      final from = keyframes[i];
      if (from.easing.isLinear) continue;
      final start = math.max(0, from.timeUs);
      final end = math.min(durationUs, keyframes[i + 1].timeUs);
      if (start >= end) continue;
      for (var t = start; t < end; t += step) {
        times.add(t);
      }
    }
  }

  sampleEased(transform.position);
  sampleEased(transform.scale);
  sampleEased(transform.rotation);
  sampleEased(transform.opacity);
  return times.toList()..sort();
}

TransformSampleSpec _sample(int timeUs, ResolvedTransform t) =>
    TransformSampleSpec(
      timeUs: timeUs,
      x: t.position.x,
      y: t.position.y,
      scale: t.scale,
      rotation: t.rotation,
      opacity: t.opacity,
    );

/// The engine's view of a canvas [background].
BackgroundSpec backgroundSpecOf(CanvasBackground background) =>
    switch (background) {
      ColorBackground(:final argb) => BackgroundSpec(
        kind: SpecBackgroundKind.color,
        argb: argb,
        endArgb: argb,
        angleDegrees: 0,
        blur: 0,
      ),
      GradientBackground(
        :final startArgb,
        :final endArgb,
        :final angleDegrees,
      ) =>
        BackgroundSpec(
          kind: SpecBackgroundKind.gradient,
          argb: startArgb,
          endArgb: endArgb,
          angleDegrees: angleDegrees,
          blur: 0,
        ),
      BlurBackground(:final amount) => BackgroundSpec(
        kind: SpecBackgroundKind.blur,
        argb: 0xFF000000,
        endArgb: 0xFF000000,
        angleDegrees: 0,
        blur: amount,
      ),
      ImageBackground(:final uri, :final blur) => BackgroundSpec(
        kind: SpecBackgroundKind.image,
        argb: 0xFF000000,
        endArgb: 0xFF000000,
        angleDegrees: 0,
        blur: blur,
        imageUri: uri,
      ),
    };
