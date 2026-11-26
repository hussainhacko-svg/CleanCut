/// Basic editing of main-track clips (Phase 4): trim, split, delete,
/// duplicate, reorder and speed ("Flow").
library;

import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/retiming.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';

/// Shortest timeline length a trim or split may leave (0.1 s).
const int minClipDurationUs = 100000;

int _indexOf(Project project, String clipId) {
  final index = project.mainTrack.clips.indexWhere((c) => c.id == clipId);
  if (index < 0) throw InvalidEditException('No clip $clipId');
  return index;
}

Project _withClips(Project project, List<Clip> clips) =>
    project.copyWith(mainTrack: project.mainTrack.copyWith(clips: clips));

/// Timeline length of [sourceUs] of source at [speed].
int _timelineUs(int sourceUs, double speed) =>
    Micros.scaledBySpeed(sourceUs, speed);

/// Source length that plays for [timelineUs] at [speed].
int _sourceUs(int timelineUs, double speed) => (timelineUs * speed).round();

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
    if (sourceOutUs <= sourceInUs ||
        _timelineUs(sourceOutUs - sourceInUs, clip.speed) < minClipDurationUs) {
      throw const InvalidEditException(
        'Trim leaves less than $minClipDurationUs us',
      );
    }
    if (sourceInUs == clip.sourceInUs && sourceOutUs == clip.sourceOutUs) {
      return project;
    }
    // Keyframes are clip-relative: moving the start right by n source µs
    // moves them left by n / speed on the timeline.
    final shift = -_timelineUs(sourceInUs - clip.sourceInUs, clip.speed);
    final updated = [...project.mainTrack.clips];
    updated[index] = clip.copyWith(
      sourceInUs: sourceInUs,
      sourceOutUs: sourceOutUs,
      transform: clip.transform.shifted(shift),
    );
    return _withClips(project, updated);
  }
}

/// Source length that keeps [clip] at least [minClipDurationUs] long.
int _minSourceUs(Clip clip) => (minClipDurationUs * clip.speed).ceil();

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
/// the value at the cut. Both parts must be at least [minClipDurationUs]
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
    final cut = clip.sourceInUs + _sourceUs(offset, clip.speed);
    final first = clip.copyWith(
      sourceOutUs: cut,
      transform: clip.transform.clipped(offset),
    );
    final second = clip.copyWith(
      id: newId(),
      sourceInUs: cut,
      transform: clip.transform.shifted(-offset),
    );
    final updated = [...project.mainTrack.clips]
      ..replaceRange(index, index + 1, [first, second]);
    return _withClips(project, updated);
  }
}

/// Whether [SplitClipCommand] can cut clip [clipId] at [timeUs].
bool canSplitAt(Project project, String clipId, int timeUs) {
  final index = project.mainTrack.clips.indexWhere((c) => c.id == clipId);
  if (index < 0) return false;
  final offset = timeUs - project.mainTrack.startOf(index);
  return offset >= minClipDurationUs &&
      project.mainTrack.clips[index].durationUs - offset >= minClipDurationUs;
}

/// Removes clip [clipId]; later clips move up (the main track is magnetic).
final class DeleteClipCommand extends EditCommand {
  /// Creates the command.
  const new(this.clipId);

  /// Clip to remove.
  final String clipId;

  @override
  Project apply(Project project) {
    final index = _indexOf(project, clipId);
    return _withClips(project, [...project.mainTrack.clips]..removeAt(index));
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
    return _withClips(
      project,
      [...project.mainTrack.clips]
        ..insert(index + 1, clip.copyWith(id: newId())),
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
    return _withClips(project, updated);
  }
}

/// Sets the constant playback speed of clip [clipId] (Flow) and whether its
/// audio keeps its pitch.
///
/// The source range stays the same, so the clip gets longer or shorter on
/// the timeline; its keyframes are re-timed to stay on the same frames.
/// Speed must be within [SpeedLimits]. Consecutive changes of one clip
/// (a slider drag) are one undo step.
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
    if (speed == clip.speed && pitch == clip.keepPitch) return project;
    if (clip.media.kind == MediaKind.image && pitch != clip.keepPitch) {
      throw const InvalidEditException('Images have no audio pitch');
    }
    final updated = [...project.mainTrack.clips];
    updated[index] = clip.copyWith(
      speed: speed,
      keepPitch: pitch,
      transform: clip.transform.scaledInTime(clip.speed / speed),
    );
    return _withClips(project, updated);
  }
}
