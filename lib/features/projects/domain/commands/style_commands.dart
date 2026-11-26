/// Transform & style edits of main-track clips and the canvas (Phase 5):
/// fill mode, crop, rotate/mirror/flip, position/size/opacity with
/// keyframes, border and background.
library;

import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/model/canvas_background.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';

/// Returns [project] with main-track clip [clipId] replaced by
/// `update(clip)`. Throws an [InvalidEditException] for an unknown clip or
/// an invalid result.
Project _updateClip(
  Project project,
  String clipId,
  Clip Function(Clip clip) update,
) {
  final clips = project.mainTrack.clips;
  final index = clips.indexWhere((c) => c.id == clipId);
  if (index < 0) throw InvalidEditException('No clip $clipId');
  final updated = update(clips[index]);
  if (identical(updated, clips[index]) || updated == clips[index]) {
    return project;
  }
  final problems = updated.validate();
  if (problems.isNotEmpty) {
    throw InvalidEditException('Invalid clip: ${problems.join('; ')}');
  }
  return project.copyWith(
    mainTrack: project.mainTrack.copyWith(clips: [...clips]..[index] = updated),
  );
}

/// Half a frame at the project's frame rate: a keyframe this close to the
/// playhead counts as "at" the playhead.
int keyframeToleranceUs(Project project) =>
    Micros.perSecond ~/
    (2 * (project.canvas.fps <= 0 ? 30 : project.canvas.fps));

/// Clamps a clip-relative time into the clip.
int _clampToClip(Clip clip, int timeUs) =>
    timeUs.clamp(0, clip.durationUs < 0 ? 0 : clip.durationUs);

/// Sets how clip [clipId] is sized into the canvas.
final class SetClipFitModeCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId, this.fitMode);

  /// Target clip.
  final String clipId;

  /// The new fit mode.
  final FitMode fitMode;

  @override
  Project apply(Project project) =>
      _updateClip(project, clipId, (c) => c.copyWith(fitMode: fitMode));
}

/// Sets the crop of clip [clipId]. A whole handle drag is one undo step.
final class SetClipCropCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId, this.crop);

  /// Target clip.
  final String clipId;

  /// The new crop; must pass `CropRect.validate`.
  final CropRect crop;

  @override
  Object? get coalesceKey => (SetClipCropCommand, clipId);

  @override
  Project apply(Project project) =>
      _updateClip(project, clipId, (c) => c.copyWith(crop: crop));
}

/// Sets the border and corner radius of clip [clipId]. Slider drags
/// coalesce into one undo step.
final class SetClipBorderCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId, this.border);

  /// Target clip.
  final String clipId;

  /// The new border; must pass `ClipBorder.validate`.
  final ClipBorder border;

  @override
  Object? get coalesceKey => (SetClipBorderCommand, clipId);

  @override
  Project apply(Project project) =>
      _updateClip(project, clipId, (c) => c.copyWith(border: border));
}

/// Sets transform values of clip [clipId] as seen at clip-relative
/// [atUs] (the playhead): constant properties change for the whole clip,
/// keyframed ones get or update a keyframe there (see
/// `ClipTransform.withValuesAt`). Values are clamped into range.
///
/// Consecutive commands for one clip coalesce, so a gesture on the
/// preview or a slider drag is one undo step.
final class SetClipTransformValuesCommand extends EditCommand {
  /// Creates the command. Null values are left unchanged.
  const new(
    this.clipId, {
    required this.atUs,
    this.position,
    this.scale,
    this.rotation,
    this.opacity,
  });

  /// Target clip.
  final String clipId;

  /// Clip-relative time the values are seen at; clamped into the clip.
  final int atUs;

  /// New center offset.
  final Vec2? position;

  /// New size factor.
  final double? scale;

  /// New clockwise rotation in degrees.
  final double? rotation;

  /// New opacity.
  final double? opacity;

  @override
  Object? get coalesceKey => (SetClipTransformValuesCommand, clipId);

  @override
  Project apply(Project project) => _updateClip(
    project,
    clipId,
    (c) => c.copyWith(
      transform: c.transform.withValuesAt(
        _clampToClip(c, atUs),
        position: position,
        scale: scale,
        rotation: rotation,
        opacity: opacity,
        toleranceUs: keyframeToleranceUs(project),
      ),
    ),
  );
}

/// Adds a keyframe of [property] at clip-relative [atUs] on clip
/// [clipId], or removes the one already there (within half a frame).
final class ToggleClipKeyframeCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId, this.property, {required this.atUs});

  /// Target clip.
  final String clipId;

  /// Property to (un)keyframe.
  final TransformProperty property;

  /// Clip-relative time; clamped into the clip.
  final int atUs;

  @override
  Project apply(Project project) => _updateClip(
    project,
    clipId,
    (c) => c.copyWith(
      transform: c.transform.toggledKeyframe(
        property,
        _clampToClip(c, atUs),
        toleranceUs: keyframeToleranceUs(project),
      ),
    ),
  );
}

/// Turns clip [clipId] a quarter turn clockwise as seen at clip-relative
/// [atUs], snapping to the next multiple of 90°.
final class RotateClipQuarterCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId, {required this.atUs});

  /// Target clip.
  final String clipId;

  /// Clip-relative time; clamped into the clip.
  final int atUs;

  @override
  Project apply(Project project) => _updateClip(project, clipId, (c) {
    final at = _clampToClip(c, atUs);
    final current = c.transform.at(at).rotation;
    // Next multiple of 90 strictly after the current angle (with a little
    // slack so 89.9999 goes to 180, not 90).
    final next = ((current + 1e-6) / 90).floorToDouble() * 90 + 90;
    return c.copyWith(
      transform: c.transform.withValuesAt(
        at,
        rotation: next,
        toleranceUs: keyframeToleranceUs(project),
      ),
    );
  });
}

/// Mirrors (left-right, [horizontal]) or flips (upside down) clip
/// [clipId]; applying it again undoes it.
final class ToggleClipFlipCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId, {required this.horizontal});

  /// Target clip.
  final String clipId;

  /// Mirror when true, flip when false.
  final bool horizontal;

  @override
  Project apply(Project project) => _updateClip(
    project,
    clipId,
    (c) => c.copyWith(
      transform: horizontal
          ? c.transform.copyWith(flipX: !c.transform.flipX)
          : c.transform.copyWith(flipY: !c.transform.flipY),
    ),
  );
}

/// Replaces what fills the canvas behind the clips.
final class SetCanvasBackgroundCommand extends EditCommand {
  /// Creates the command. With [coalesce] (slider drags), consecutive
  /// coalescing background commands form one undo step.
  const new(this.background, {this.coalesce = false});

  /// The new background; must pass `CanvasBackground.validate`.
  final CanvasBackground background;

  /// Whether this merges with the previous coalescing background edit.
  final bool coalesce;

  @override
  Object? get coalesceKey => coalesce ? SetCanvasBackgroundCommand : null;

  @override
  Project apply(Project project) {
    final problems = background.validate();
    if (problems.isNotEmpty) {
      throw InvalidEditException('Invalid background: ${problems.join('; ')}');
    }
    return project.copyWith(
      canvas: project.canvas.copyWith(background: background),
    );
  }
}
