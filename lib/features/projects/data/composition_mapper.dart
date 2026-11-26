import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/domain/model/canvas_background.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/speed_curve.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';

/// Short side of the preview surface in pixels. Export renders at the
/// canvas resolution instead; preview stays light for smooth scrubbing.
const int previewShortSidePx = 720;

/// Maps a project's main track to the engine's [CompositionSpec].
///
/// Covers trims, constant speed and speed curves (Flow), stills, the
/// canvas size and background, and each clip's fit, crop, transform
/// (keyframes sampled at the canvas frame rate) and border.
CompositionSpec compositionSpecOf(
  Project project, {
  int shortSidePx = previewShortSidePx,
}) {
  final size = project.canvas.aspect.pixelSize(shortSidePx);
  final fps = project.canvas.fps;
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
            style: clipStyleSpecOf(clip, fps: fps),
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
            style: clipStyleSpecOf(clip, fps: fps),
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
  );
}

/// Times at which an animated [transform] is sampled within a clip of
/// [durationUs]: every frame at [fps], every keyframe inside the clip and
/// the end. A constant transform needs only time 0.
List<int> transformSampleTimes(
  ClipTransform transform,
  int durationUs,
  int fps,
) {
  if (!transform.isAnimated || durationUs <= 0) return const [0];
  final step = Micros.perSecond ~/ (fps <= 0 ? 30 : fps);
  return {
    for (var t = 0; t < durationUs; t += step) t,
    for (final k in transform.keyframeTimes)
      if (k <= durationUs) k,
    durationUs,
  }.toList()..sort();
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
