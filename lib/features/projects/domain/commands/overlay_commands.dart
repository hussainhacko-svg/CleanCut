/// Commands and placement helpers for overlay (PiP) clips on
/// [Project.overlayTracks] (Phase 7A).
library;

import 'dart:math' as math;

import 'package:cleancut/features/projects/domain/commands/clip_commands.dart';
import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/retiming.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:cleancut/features/projects/domain/model/tracks.dart';
import 'package:cleancut/features/projects/domain/timeline/clip_lookup.dart';

/// Default scale of a newly added picture-in-picture overlay (50%, centered).
const double defaultOverlayScale = 0.5;

/// Adds visual [media] (videos or photos) as picture-in-picture overlays
/// starting at timeline time [atUs].
///
/// New overlays start scaled to [defaultOverlayScale] (centered) and video
/// overlays default to muted (owner decisions). Multiple picked items are
/// placed back-to-back starting at [atUs]; each lands on the lowest
/// non-overlapping overlay lane, or on a new top lane when all existing lanes
/// collide.
final class AddOverlayCommand extends EditCommand {
  /// Creates the command. [newId] names each clip; [newTrackId] names any
  /// newly created overlay track (defaults to [newId]).
  const new(
    this.media, {
    required this.atUs,
    required this.newId,
    this.newTrackId,
  });

  /// Visual media to add.
  final List<MediaRef> media;

  /// Timeline start time in microseconds (clamped to `>= 0`).
  final int atUs;

  /// Id source for created clips.
  final IdGenerator newId;

  /// Optional id source for newly created overlay tracks.
  final IdGenerator? newTrackId;

  @override
  Project apply(Project project) {
    if (media.isEmpty) return project;
    var tracks = project.overlayTracks;
    var cursorUs = math.max(0, atUs);
    final trackIdGen = newTrackId ?? newId;
    for (final m in media) {
      if (m.kind == MediaKind.audio) {
        throw InvalidEditException('Audio cannot go on an overlay track: $m');
      }
      if (m.durationUs case final d? when d <= 0) {
        throw InvalidEditException('Media has no duration: $m');
      }
      final clip = Clip.fromMedia(id: newId(), media: m).copyWith(
        transform: const ClipTransform(
          scale: Animatable<double>.constant(defaultOverlayScale),
        ),
        muted: m.kind == MediaKind.video,
      );
      final placed = PlacedClip(startUs: cursorUs, clip: clip);
      tracks = placeOnFreeOverlayTrack(tracks, placed, newTrackId: trackIdGen);
      cursorUs = placed.range.endUs;
    }
    return project.copyWith(overlayTracks: tracks);
  }
}

/// Moves overlay clip [clipId] to timeline time [startUs] and overlay lane
/// [trackIndex].
///
/// A [trackIndex] of `-1` (or less) creates a new top overlay lane above all
/// existing ones; `trackIndex >= overlayTracks.length` creates a new bottom
/// overlay lane just above the main track. Empty lanes left behind are pruned.
final class MoveOverlayCommand extends EditCommand {
  /// Creates the command.
  const new(
    this.clipId, {
    required this.startUs,
    required this.trackIndex,
    this.newTrackId,
  });

  /// Overlay clip to move.
  final String clipId;

  /// New timeline start time (`>= 0`).
  final int startUs;

  /// Destination overlay lane index (relative to the project before moving).
  final int trackIndex;

  /// Id source when creating a new overlay lane.
  final IdGenerator? newTrackId;

  @override
  Project apply(Project project) {
    if (startUs < 0) {
      throw InvalidEditException('Overlay start cannot be negative: $startUs');
    }
    final loc = locateClip(project, clipId);
    if (loc == null || !loc.isOverlay) {
      throw InvalidEditException('No overlay clip $clipId');
    }
    final sourceTrackIndex = loc.overlayTrackIndex!;
    final sourceTrack = project.overlayTracks[sourceTrackIndex];
    final currentItem = sourceTrack.items[loc.index];

    if (trackIndex == sourceTrackIndex && startUs == currentItem.startUs) {
      return project;
    }

    final moved = PlacedClip(startUs: startUs, clip: currentItem.clip);
    final tracks = [...project.overlayTracks];

    // Remove from source track first (keep slot until target index is used).
    final strippedSource = sourceTrack.copyWith(
      items: [...sourceTrack.items]..removeAt(loc.index),
    );
    tracks[sourceTrackIndex] = strippedSource;

    if (trackIndex < 0) {
      final id = _freshTrackId(tracks, newTrackId, clipId);
      tracks.insert(0, LayerTrack(id: id, items: [moved]));
    } else if (trackIndex >= tracks.length) {
      final id = _freshTrackId(tracks, newTrackId, clipId);
      tracks.add(LayerTrack(id: id, items: [moved]));
    } else {
      final target = tracks[trackIndex];
      if (trackOverlaps(target, moved.range)) {
        throw InvalidEditException(
          'Overlay $clipId would overlap another clip on track ${target.id}',
        );
      }
      final items = [...target.items, moved]
        ..sort((a, b) => a.startUs.compareTo(b.startUs));
      tracks[trackIndex] = target.copyWith(items: items);
    }

    // Prune any track that became empty.
    tracks.removeWhere((t) => t.items.isEmpty);
    return project.copyWith(overlayTracks: tracks);
  }
}

/// Trims overlay clip [clipId] to `[sourceInUs, sourceOutUs)` starting at
/// timeline time [startUs].
///
/// Moving [sourceInUs] shifts keyframes so they stay on the same frames.
/// Rejects trims that leave less than [minClipDurationUs], go outside the
/// media, start before `0`, or overlap a sibling clip on the same lane.
final class TrimOverlayCommand extends EditCommand {
  /// Creates the command.
  const new(
    this.clipId, {
    required this.startUs,
    required this.sourceInUs,
    required this.sourceOutUs,
  });

  /// Target overlay clip.
  final String clipId;

  /// New timeline start time (`>= 0`).
  final int startUs;

  /// New source start.
  final int sourceInUs;

  /// New source end (exclusive).
  final int sourceOutUs;

  @override
  Object? get coalesceKey => (TrimOverlayCommand, clipId);

  @override
  Project apply(Project project) {
    if (startUs < 0) {
      throw InvalidEditException('Overlay start cannot be negative: $startUs');
    }
    final loc = locateClip(project, clipId);
    if (loc == null || !loc.isOverlay) {
      throw InvalidEditException('No overlay clip $clipId');
    }
    final trackIndex = loc.overlayTrackIndex!;
    final track = project.overlayTracks[trackIndex];
    final item = track.items[loc.index];
    final clip = item.clip;
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
    if (startUs == item.startUs &&
        sourceInUs == clip.sourceInUs &&
        sourceOutUs == clip.sourceOutUs) {
      return project;
    }

    // Shift keyframes by the change in timeline start so they stay pinned to
    // the same timeline timestamps (works for both video left-edge trims and
    // still-image left-edge extensions).
    final shift = item.startUs - startUs;
    final updatedClip = clip.copyWith(
      sourceInUs: sourceInUs,
      sourceOutUs: sourceOutUs,
      transform: shift == 0 ? clip.transform : clip.transform.shifted(shift),
      blur: shift == 0
          ? clip.blur
          : shiftKeyframes(clip.blur, shift, lerpDouble),
      mask: shift == 0 ? clip.mask : clip.mask?.shifted(shift),
    );
    final updatedItem = PlacedClip(startUs: startUs, clip: updatedClip);
    if (trackOverlaps(track, updatedItem.range, ignoreClipId: clipId)) {
      throw InvalidEditException(
        'Trimmed overlay $clipId would overlap a sibling on track ${track.id}',
      );
    }

    final items = [...track.items]
      ..[loc.index] = updatedItem
      ..sort((a, b) => a.startUs.compareTo(b.startUs));
    final tracks = [...project.overlayTracks]
      ..[trackIndex] = track.copyWith(items: items);
    return project.copyWith(overlayTracks: tracks);
  }
}

/// Clamps a left-edge trim of overlay item [itemIndex] on [track] by timeline
/// delta [deltaTimelineUs], keeping its right edge anchored, `startUs >= 0`,
/// source within media, length `>= minClipDurationUs`, and clear of any
/// earlier sibling on [track].
///
/// Still images have no source start limit, so dragging their left edge earlier
/// grows `sourceOutUs` while keeping `sourceInUs == 0`.
({int startUs, int sourceInUs, int sourceOutUs}) clampOverlayTrimStart(
  LayerTrack track,
  int itemIndex, {
  required int deltaTimelineUs,
}) {
  final item = track.items[itemIndex];
  final clip = item.clip;
  final anchorEndUs = item.range.endUs;
  final prevEndUs = itemIndex > 0 ? track.items[itemIndex - 1].range.endUs : 0;
  final minStartUs = math.max(0, prevEndUs);
  final minDurationUs = math.min(minClipDurationUs, clip.durationUs);
  final maxStartUs = math.max(minStartUs, anchorEndUs - minDurationUs);

  if (clip.media.kind == MediaKind.image) {
    final newStartUs = (item.startUs + deltaTimelineUs).clamp(
      minStartUs,
      maxStartUs,
    );
    final newTimelineLen = anchorEndUs - newStartUs;
    final newSourceLen = math.max(
      1,
      (newTimelineLen * clip.averageSpeed).round(),
    );
    return (startUs: newStartUs, sourceInUs: 0, sourceOutUs: newSourceLen);
  }

  final desiredStartUs = math.max(minStartUs, item.startUs + deltaTimelineUs);
  final desiredTimelineLen = anchorEndUs - desiredStartUs;
  final desiredSourceLen = (desiredTimelineLen * clip.averageSpeed).round();
  final rawSourceIn = clip.sourceOutUs - desiredSourceLen;
  final clampedSourceIn = clampTrimStart(clip, rawSourceIn);
  final actualDurationUs = clip.timelineLengthOf(
    clip.sourceOutUs - clampedSourceIn,
  );
  final actualStartUs = anchorEndUs - actualDurationUs;
  if (actualStartUs < minStartUs) {
    final maxDurationUs = math.max(0, anchorEndUs - minStartUs);
    final minSourceIn = clampTrimStart(
      clip,
      clip.sourceOutUs - (maxDurationUs * clip.averageSpeed).floor(),
    );
    final fixedDur = clip.timelineLengthOf(clip.sourceOutUs - minSourceIn);
    return (
      startUs: math.max(minStartUs, anchorEndUs - fixedDur),
      sourceInUs: minSourceIn,
      sourceOutUs: clip.sourceOutUs,
    );
  }
  return (
    startUs: actualStartUs,
    sourceInUs: clampedSourceIn,
    sourceOutUs: clip.sourceOutUs,
  );
}

/// Clamps a right-edge trim of overlay item [itemIndex] on [track] to
/// [sourceOutUs], staying within media bounds, `>= minClipDurationUs`, and
/// clear of any later sibling on [track].
int clampOverlayTrimEnd(
  LayerTrack track,
  int itemIndex, {
  required int sourceOutUs,
}) {
  final item = track.items[itemIndex];
  final clip = item.clip;
  var clamped = clampTrimEnd(clip, sourceOutUs);
  if (itemIndex < track.items.length - 1) {
    final nextStartUs = track.items[itemIndex + 1].startUs;
    final maxTimelineUs = nextStartUs - item.startUs;
    if (clip.timelineLengthOf(clamped - clip.sourceInUs) > maxTimelineUs) {
      final maxSource =
          clip.sourceInUs + (maxTimelineUs * clip.averageSpeed).floor();
      clamped = clampTrimEnd(clip, maxSource);
      while (clamped > clip.sourceInUs + 1 &&
          clip.timelineLengthOf(clamped - clip.sourceInUs) > maxTimelineUs) {
        clamped--;
      }
    }
  }
  return clamped;
}

/// Whether placing an overlay spanning [range] (ignoring [movingClipId]) on
/// [targetTrackIndex] is valid (always true for a new lane `< 0` or
/// `>= tracks.length`).
bool canPlaceOverlayOnTrack(
  List<LayerTrack> tracks, {
  required String movingClipId,
  required int targetTrackIndex,
  required TimeRange range,
}) {
  if (range.startUs < 0) return false;
  if (targetTrackIndex < 0 || targetTrackIndex >= tracks.length) return true;
  return !trackOverlaps(
    tracks[targetTrackIndex],
    range,
    ignoreClipId: movingClipId,
  );
}

String _freshTrackId(
  List<LayerTrack> existing,
  IdGenerator? gen,
  String fallbackSeed,
) {
  if (gen != null) return gen();
  final used = {for (final t in existing) t.id};
  var n = 1;
  while (used.contains('${fallbackSeed}_lane_$n')) {
    n++;
  }
  return '${fallbackSeed}_lane_$n';
}
