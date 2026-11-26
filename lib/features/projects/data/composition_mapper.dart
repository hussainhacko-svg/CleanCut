import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/speed_curve.dart';

/// Short side of the preview surface in pixels. Export renders at the
/// canvas resolution instead; preview stays light for smooth scrubbing.
const int previewShortSidePx = 720;

/// Maps a project's main track to the engine's [CompositionSpec].
///
/// Covers trims, constant speed and speed curves (Flow), stills and the
/// canvas size.
/// Transforms and effects are added by the phases that introduce them.
CompositionSpec compositionSpecOf(
  Project project, {
  int shortSidePx = previewShortSidePx,
}) {
  final size = project.canvas.aspect.pixelSize(shortSidePx);
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
          ),
    ],
    canvasWidth: size.width,
    canvasHeight: size.height,
    frameRate: project.canvas.fps,
  );
}
