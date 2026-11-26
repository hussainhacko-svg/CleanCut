import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';

/// Short side of the preview surface in pixels. Export renders at the
/// canvas resolution instead; preview stays light for smooth scrubbing.
const int previewShortSidePx = 720;

/// Maps a project's main track to the engine's [CompositionSpec].
///
/// Phase 2 scope: trims, stills and the canvas size. Speed, transforms and
/// effects are added to the spec by the phases that introduce them.
CompositionSpec compositionSpecOf(
  Project project, {
  int shortSidePx = previewShortSidePx,
}) {
  final size = project.canvas.aspect.pixelSize(shortSidePx);
  return CompositionSpec(
    clips: [
      for (final clip in project.mainTrack.clips)
        ClipSpec(
          uri: clip.media.uri,
          kind: clip.media.kind == MediaKind.image
              ? SpecMediaKind.image
              : SpecMediaKind.video,
          // Stills have no intrinsic length; their trim defines it.
          sourceDurationUs: clip.media.durationUs ?? clip.sourceOutUs,
          sourceInUs: clip.sourceInUs,
          sourceOutUs: clip.sourceOutUs,
        ),
    ],
    canvasWidth: size.width,
    canvasHeight: size.height,
    frameRate: project.canvas.fps,
  );
}
