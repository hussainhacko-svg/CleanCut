import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/domain/timeline/clip_lookup.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Renames the project. Leading and trailing whitespace is removed.
final class RenameProjectCommand extends EditCommand {
  /// Creates the command.
  const new(this.name);

  /// The new name.
  final String name;

  @override
  Project apply(Project project) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const InvalidEditException('Project name must not be empty');
    }
    return project.copyWith(name: trimmed);
  }
}

/// Changes the canvas aspect ratio.
final class SetCanvasAspectCommand extends EditCommand {
  /// Creates the command.
  const new(this.aspect);

  /// The new aspect ratio.
  final CanvasAspect aspect;

  @override
  Project apply(Project project) =>
      project.copyWith(canvas: project.canvas.copyWith(aspect: aspect));
}

/// Appends visual media to the end of the main track, in order.
final class AppendMediaCommand extends EditCommand {
  /// Creates the command; [newId] names each created clip.
  const new(this.media, {required this.newId});

  /// Media to append. Must be video or image.
  final List<MediaRef> media;

  /// Id source for the new clips.
  final IdGenerator newId;

  @override
  Project apply(Project project) {
    if (media.isEmpty) return project;
    final clips = <Clip>[];
    for (final m in media) {
      if (m.kind == MediaKind.audio) {
        throw InvalidEditException('Audio cannot go on the main track: $m');
      }
      if (m.durationUs case final d? when d <= 0) {
        throw InvalidEditException('Media has no duration: $m');
      }
      clips.add(Clip.fromMedia(id: newId(), media: m));
    }
    return project.copyWith(
      mainTrack: project.mainTrack.copyWith(
        clips: [...project.mainTrack.clips, ...clips],
      ),
    );
  }
}

/// Replaces the transform of the clip [clipId] on the main track.
///
/// Consecutive commands for the same clip coalesce, so a whole drag on
/// the preview is one undo step.
final class SetClipTransformCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId, this.transform);

  /// Target clip.
  final String clipId;

  /// The new transform.
  final ClipTransform transform;

  @override
  Object? get coalesceKey => (SetClipTransformCommand, clipId);

  @override
  Project apply(Project project) =>
      replaceClip(project, clipId, (c) => c.copyWith(transform: transform));
}

/// Creates a new empty project with sensible canvas defaults.
@useResult
Project newProject({
  required String id,
  required String name,
  required DateTime now,
  CanvasAspect aspect = CanvasAspect.landscape16x9,
}) => Project(
  id: id,
  name: name,
  createdAt: now,
  updatedAt: now,
  canvas: ProjectCanvas(aspect: aspect),
);
