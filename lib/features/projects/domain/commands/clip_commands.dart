/// Basic editing of main-track clips (Phase 4): trim, split, delete,
/// duplicate, reorder and speed ("Flow").
library;

import 'dart:math' as math;

import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_transition.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/retiming.dart';
import 'package:cleancut/features/projects/domain/model/speed_curve.dart';

/// Shortest timeline length a trim or split may leave (0.1 s).
const int minClipDurationUs = 100000;

int _indexOf(Project project, String clipId) {
  final index = project.mainTrack.clips.indexWhere((c) => c.id == clipId);
  if (index < 0) throw InvalidEditException('No clip $clipId');
  return index;
}

Project _withClips(Project project, List<Clip> clips) =>
    project.copyWith(mainTrack: project.mainTrack.copyWith(clips: clips));

/// Re-times [clip]'s keyframes after its timeline length changed from
/// [clip]'s to [updated]'s (speed or curve change), so they stay on the
/// same frames.
Clip _retimed(Clip clip, Clip updated) {
  if (clip.durationUs <= 0 || updated.durationUs <= 0) return updated;
  final factor = updated.durationUs / clip.durationUs;
  return updated.copyWith(
    transform: clip.transform.scaledInTime(factor),
    blur: scaleKeyframes(clip.blur, factor),
    mask: clip.mask?.scaledInTime(factor),
  );
}

/// Sets the used source range `[sourceInUs, sourceOutUs)` of clip [clipId].
///
/// Moving the start shifts the clip's keyframes so they stay on the same
/// frames. The clip must stay inside its media and at least
/// [minClipDurationUs] long on the timeline; use [clampTrimStart] and
/// [clampTrimEnd] to keep a drag
/// inside these limits. Consecutive trims of one clip are one undo step.
final class TrimClipCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId, {required this.sourceInUs, required this.sourceOutUs});

  /// Target clip.
  final String clipId;

  /// New source start.
  final int sourceInUs;

  /// New source end (exclusive).
  final int sourceOutUs;

  @override
  Object? get coalesceKey => (TrimClipCommand, clipId);

  @override
  Project apply(Project project) {
    final index = _indexOf(project, clipId);
    final clip = project.mainTrack.clips[index];
    if (sourceInUs < 0) {
      throw InvalidEditException('Trim starts before the media: $sourceInUs');
    }
    if (clip.media.durationUs case final d? when sourceOutUs > d) {
      throw InvalidEditException('Trim ends after the media: $sourceOutUs');
    }
    final minDuration = math.min(minClipDurationUs, clip.durationUs);
    if (sourceOutUs <= sourceInUs ||
        clip.timelineLengthOf(sourceOutUs - sourceInUs) < minDuration) {
      throw InvalidEditException('Trim leaves less than $minDuration us');
    }
    if (sourceInUs == clip.sourceInUs && sourceOutUs == clip.sourceOutUs) {
      return project;
    }
    // Keyframes are clip-relative: moving the start right by n source µs
    // moves them left by n / (average) speed on the timeline.
    final shift = -((sourceInUs - clip.sourceInUs) / clip.averageSpeed).round();
    final updated = [...project.mainTrack.clips];
    updated[index] = clip.copyWith(
      sourceInUs: sourceInUs,
      sourceOutUs: sourceOutUs,
      transform: clip.transform.shifted(shift),
      blur: shiftKeyframes(clip.blur, shift, lerpDouble),
      mask: clip.mask?.shifted(shift),
    );
    return _withClips(project, updated);
  }
}

/// Source length that keeps [clip] at least [minClipDurationUs] long, or no
/// shorter than its current length when it is already below the minimum.
int _minSourceUs(Clip clip) => clip.durationUs < minClipDurationUs
    ? clip.sourceDurationUs
    : (minClipDurationUs * clip.averageSpeed).ceil();

/// The closest valid source start for [clip] to [sourceInUs] when dragging
/// its start edge: not before the media, and leaving at least
/// [minClipDurationUs] on the timeline.
int clampTrimStart(Clip clip, int sourceInUs) {
  final maxIn = clip.sourceOutUs - _minSourceUs(clip);
  if (maxIn <= 0) return 0;
  return sourceInUs.clamp(0, maxIn);
}

/// The closest valid source end for [clip] to [sourceOutUs] when dragging
/// its end edge: not after the media (images have no limit), and leaving
/// at least [minClipDurationUs] on the timeline.
int clampTrimEnd(Clip clip, int sourceOutUs) {
  final minOut = clip.sourceInUs + _minSourceUs(clip);
  final maxOut = clip.media.durationUs;
  if (maxOut != null && minOut >= maxOut) return maxOut;
  if (sourceOutUs < minOut) return minOut;
  if (maxOut != null && sourceOutUs > maxOut) return maxOut;
  return sourceOutUs;
}

/// Splits the main-track clip under timeline time [timeUs] into two clips.
///
/// The first part keeps its id; the second gets [newId]'s id and is placed
/// right after it. Keyframes are partitioned at the cut, each half pinning
/// the value at the cut; a speed curve is divided the same way (owner
/// decision), each half stretched back over its part. Both parts must be at
/// least [minClipDurationUs]
/// long, so a split right at a clip edge is rejected.
final class SplitClipCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId, {required this.timeUs, required this.newId});

  /// Clip to split; [timeUs] must lie inside it.
  final String clipId;

  /// Timeline time of the cut (e.g. the playhead).
  final int timeUs;

  /// Id source for the second part.
  final IdGenerator newId;

  @override
  Project apply(Project project) {
    final index = _indexOf(project, clipId);
    final clip = project.mainTrack.clips[index];
    final offset = timeUs - project.mainTrack.startOf(index);
    if (offset < minClipDurationUs ||
        clip.durationUs - offset < minClipDurationUs) {
      throw InvalidEditException(
        'Split at $timeUs us is too close to an edge of $clipId',
      );
    }
    final cut = clip.sourceInUs + clip.sourceOffsetAt(offset);
    final halves = clip.speedCurve?.splitAt(
      (cut - clip.sourceInUs) / clip.sourceDurationUs,
    );
    final first = clip.copyWith(
      sourceOutUs: cut,
      speedCurve: halves?.$1,
      transform: clip.transform.clipped(offset),
      blur: clipKeyframes(clip.blur, offset, lerpDouble),
      mask: clip.mask?.clipped(offset),
    );
    final second = clip.copyWith(
      id: newId(),
      sourceInUs: cut,
      speedCurve: halves?.$2,
      transform: clip.transform.shifted(-offset),
      blur: shiftKeyframes(clip.blur, -offset, lerpDouble),
      mask: clip.mask?.shifted(-offset),
    );
    final updated = [...project.mainTrack.clips]
      ..replaceRange(index, index + 1, [first, second]);
    // Keep any outgoing transition attached to the second half; the new
    // middle cut starts without a transition.
    final transitions = Map<String, ClipTransition>.of(
      project.mainTrack.transitions,
    );
    final trailing = transitions.remove(clip.id);
    if (trailing != null) transitions[second.id] = trailing;
    final track = project.mainTrack.copyWith(
      clips: updated,
      transitions: transitions,
    );
    // A transition is capped at half its shorter clip, so a piece that is
    // too short would shorten it and shift every later clip. A split must
    // keep the project's timing.
    final old = project.mainTrack;
    if (track.overlapBefore(index) != old.overlapBefore(index) ||
        track.overlapAfter(index + 1) != old.overlapAfter(index)) {
      throw InvalidEditException(
        'Split at $timeUs us would shorten a transition of $clipId',
      );
    }
    return project.copyWith(mainTrack: track);
  }
}

/// Whether [SplitClipCommand] can cut clip [clipId] at [timeUs]: far enough
/// from both edges ([splitTooCloseToEdge]) and without shortening a
/// neighbouring transition.
bool canSplitAt(Project project, String clipId, int timeUs) {
  if (splitTooCloseToEdge(project, clipId, timeUs)) return false;
  try {
    SplitClipCommand(
      clipId,
      timeUs: timeUs,
      newId: () => '_split_probe',
    ).apply(project);
    return true;
  } on InvalidEditException {
    return false;
  }
}

/// Whether a cut of clip [clipId] at [timeUs] is outside the clip or would
/// leave a piece shorter than [minClipDurationUs].
bool splitTooCloseToEdge(Project project, String clipId, int timeUs) {
  final index = project.mainTrack.clips.indexWhere((c) => c.id == clipId);
  if (index < 0) return true;
  final offset = timeUs - project.mainTrack.startOf(index);
  return offset < minClipDurationUs ||
      project.mainTrack.clips[index].durationUs - offset < minClipDurationUs;
}

/// Removes clip [clipId]; later clips move up (the main track is magnetic).
final class DeleteClipCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId);

  /// Clip to remove.
  final String clipId;

  @override
  Project apply(Project project) {
    final clips = project.mainTrack.clips;
    final index = _indexOf(project, clipId);
    final updated = [...clips]..removeAt(index);
    final transitions = Map<String, ClipTransition>.of(
      project.mainTrack.transitions,
    )..remove(clipId);
    if (index > 0) transitions.remove(clips[index - 1].id);
    return project.copyWith(
      mainTrack: project.mainTrack.copyWith(
        clips: updated,
        transitions: transitions,
      ),
    );
  }
}

/// Inserts a copy of clip [clipId] right after it, with [newId]'s id.
final class DuplicateClipCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId, {required this.newId});

  /// Clip to copy.
  final String clipId;

  /// Id source for the copy.
  final IdGenerator newId;

  @override
  Project apply(Project project) {
    final index = _indexOf(project, clipId);
    final clip = project.mainTrack.clips[index];
    final copyId = newId();
    final updated = [...project.mainTrack.clips]
      ..insert(index + 1, clip.copyWith(id: copyId));
    // Move any outgoing transition onto the copy (still facing the old next
    // clip); the new cut between clip and its copy starts without one.
    final transitions = Map<String, ClipTransition>.of(
      project.mainTrack.transitions,
    );
    final trailing = transitions.remove(clip.id);
    if (trailing != null) transitions[copyId] = trailing;
    return project.copyWith(
      mainTrack: project.mainTrack.copyWith(
        clips: updated,
        transitions: transitions,
      ),
    );
  }
}

/// Moves clip [clipId] to position [toIndex] of the main track (counted
/// after removing it, so `toIndex == clips.length - 1` is the end).
final class MoveClipCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId, {required this.toIndex});

  /// Clip to move.
  final String clipId;

  /// Its new index.
  final int toIndex;

  @override
  Project apply(Project project) {
    final clips = project.mainTrack.clips;
    final index = _indexOf(project, clipId);
    if (toIndex < 0 || toIndex >= clips.length) {
      throw InvalidEditException('Index $toIndex outside the main track');
    }
    if (toIndex == index) return project;
    final updated = [...clips];
    final clip = updated.removeAt(index);
    updated.insert(toIndex, clip);
    // Preserve transitions only where the same adjacent pair stayed together.
    final oldPairs = <(String, String), ClipTransition>{
      for (var i = 0; i < clips.length - 1; i++)
        (clips[i].id, clips[i + 1].id):
            ?project.mainTrack.transitions[clips[i].id],
    };
    final transitions = <String, ClipTransition>{
      for (var i = 0; i < updated.length - 1; i++)
        updated[i].id: ?oldPairs[(updated[i].id, updated[i + 1].id)],
    };
    return project.copyWith(
      mainTrack: project.mainTrack.copyWith(
        clips: updated,
        transitions: transitions,
      ),
    );
  }
}

/// Sets the constant playback speed of clip [clipId] (Flow "Normal") and,
/// when given, whether its audio keeps its pitch.
///
/// A constant speed replaces a speed curve. The source range stays the
/// same, so the clip gets longer or shorter on the timeline; its keyframes
/// are re-timed to stay on the same frames. Speed must be within
/// [SpeedLimits]. Consecutive changes of one clip (a slider drag) are one
/// undo step.
final class SetClipSpeedCommand extends EditCommand {
  /// Creates the command; a null [keepPitch] leaves it unchanged.
  const new(this.clipId, {required this.speed, this.keepPitch});

  /// Target clip.
  final String clipId;

  /// The new speed.
  final double speed;

  /// Whether the audio keeps its pitch.
  final bool? keepPitch;

  @override
  Object? get coalesceKey => (SetClipSpeedCommand, clipId);

  @override
  Project apply(Project project) {
    if (!SpeedLimits.contains(speed)) {
      throw InvalidEditException('Speed $speed outside the allowed range');
    }
    final index = _indexOf(project, clipId);
    final clip = project.mainTrack.clips[index];
    final pitch = keepPitch ?? clip.keepPitch;
    if (speed == clip.speed &&
        pitch == clip.keepPitch &&
        clip.speedCurve == null) {
      return project;
    }
    if (clip.media.kind == MediaKind.image && pitch != clip.keepPitch) {
      throw const InvalidEditException('Images have no audio pitch');
    }
    final updated = [...project.mainTrack.clips];
    updated[index] = _retimed(
      clip,
      clip.copyWith(speed: speed, speedCurve: null, keepPitch: pitch),
    );
    return _withClips(project, updated);
  }
}

/// Sets (or, with null, removes) the speed curve of clip [clipId] (Flow
/// "Curve"). The curve replaces the constant speed while set; removing it
/// returns to that speed. Keyframes are re-timed to stay on the same
/// frames.
final class SetClipSpeedCurveCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId, this.curve);

  /// Target clip.
  final String clipId;

  /// The new curve; null for constant speed.
  final SpeedCurve? curve;

  @override
  Project apply(Project project) {
    if (curve case final c?) {
      final problems = c.validate();
      if (problems.isNotEmpty) {
        throw InvalidEditException('Invalid speed curve: $problems');
      }
    }
    final index = _indexOf(project, clipId);
    final clip = project.mainTrack.clips[index];
    if (curve == clip.speedCurve) return project;
    final updated = [...project.mainTrack.clips];
    updated[index] = _retimed(clip, clip.copyWith(speedCurve: curve));
    return _withClips(project, updated);
  }
}

/// Sets whether clip [clipId]'s sped-up or slowed-down audio keeps its
/// pitch, leaving its speed or curve as it is.
final class SetClipKeepPitchCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId, {required this.keepPitch});

  /// Target clip.
  final String clipId;

  /// Whether the audio keeps its pitch.
  final bool keepPitch;

  @override
  Project apply(Project project) {
    final index = _indexOf(project, clipId);
    final clip = project.mainTrack.clips[index];
    if (clip.keepPitch == keepPitch) return project;
    if (clip.media.kind == MediaKind.image) {
      throw const InvalidEditException('Images have no audio pitch');
    }
    final updated = [...project.mainTrack.clips];
    updated[index] = clip.copyWith(keepPitch: keepPitch);
    return _withClips(project, updated);
  }
}
