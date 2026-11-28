import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:cleancut/features/projects/domain/model/tracks.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_selection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Where a visual [clip] lives in a [Project] — either on the main track or on
/// one of [Project.overlayTracks].
@immutable
final class LocatedClip {
  /// Creates a clip location.
  const new({
    required this.clip,
    required this.startUs,
    required this.index,
    this.overlayTrackId,
    this.overlayTrackIndex,
    this.isLastMainClip = false,
  });

  /// The located visual clip.
  final Clip clip;

  /// Timeline start time in microseconds.
  final int startUs;

  /// Index within its track (`mainTrack.clips` or `overlayTrack.items`).
  final int index;

  /// Id of the owning overlay track, or `null` for a main-track clip.
  final String? overlayTrackId;

  /// Index of the owning overlay track in [Project.overlayTracks], or `null`
  /// for a main-track clip.
  final int? overlayTrackIndex;

  /// Whether this is the final clip on the main track.
  final bool isLastMainClip;

  /// Whether this clip lives on an overlay track.
  bool get isOverlay => overlayTrackId != null;

  /// Timeline end time (exclusive) in microseconds.
  int get endUs => startUs + clip.durationUs;
}

/// Finds visual clip [clipId] on either [Project.mainTrack] or
/// [Project.overlayTracks], or returns `null` when absent.
LocatedClip? locateClip(Project project, String clipId) {
  final mainClips = project.mainTrack.clips;
  for (var i = 0; i < mainClips.length; i++) {
    if (mainClips[i].id == clipId) {
      return LocatedClip(
        clip: mainClips[i],
        startUs: project.mainTrack.startOf(i),
        index: i,
        isLastMainClip: i == mainClips.length - 1,
      );
    }
  }
  for (var t = 0; t < project.overlayTracks.length; t++) {
    final track = project.overlayTracks[t];
    for (var i = 0; i < track.items.length; i++) {
      final item = track.items[i];
      if (item.clip.id == clipId) {
        return LocatedClip(
          clip: item.clip,
          startUs: item.startUs,
          index: i,
          overlayTrackId: track.id,
          overlayTrackIndex: t,
        );
      }
    }
  }
  return null;
}

/// Finds the visual clip identified by [selection] (either [MainClipSelection]
/// or [OverlaySelection]), or returns `null`.
LocatedClip? locateSelection(Project project, TimelineSelection selection) =>
    switch (selection) {
      MainClipSelection(:final clipId) ||
      OverlaySelection(:final clipId) => locateClip(project, clipId),
      NoSelection() || TransitionSelection() || AudioSelection() => null,
    };

/// Returns [project] with visual clip [clipId] (on either the main track or an
/// overlay track) replaced by `update(clip)`.
///
/// Throws [InvalidEditException] when [clipId] does not exist or the updated
/// clip fails validation.
Project replaceClip(
  Project project,
  String clipId,
  Clip Function(Clip clip) update,
) {
  final mainClips = project.mainTrack.clips;
  final mainIndex = mainClips.indexWhere((c) => c.id == clipId);
  if (mainIndex >= 0) {
    final current = mainClips[mainIndex];
    final updated = update(current);
    if (identical(updated, current) || updated == current) return project;
    final problems = updated.validate();
    if (problems.isNotEmpty) {
      throw InvalidEditException('Invalid clip: ${problems.join('; ')}');
    }
    return project.copyWith(
      mainTrack: project.mainTrack.copyWith(
        clips: [...mainClips]..[mainIndex] = updated,
      ),
    );
  }

  final overlayTracks = project.overlayTracks;
  for (var t = 0; t < overlayTracks.length; t++) {
    final track = overlayTracks[t];
    final itemIndex = track.items.indexWhere((i) => i.clip.id == clipId);
    if (itemIndex < 0) continue;
    final item = track.items[itemIndex];
    final updated = update(item.clip);
    if (identical(updated, item.clip) || updated == item.clip) return project;
    final problems = updated.validate();
    if (problems.isNotEmpty) {
      throw InvalidEditException('Invalid clip: ${problems.join('; ')}');
    }
    final nextItems = [...track.items]
      ..[itemIndex] = item.copyWith(clip: updated);
    final nextTracks = [...overlayTracks]
      ..[t] = track.copyWith(items: nextItems);
    return project.copyWith(overlayTracks: nextTracks);
  }

  throw InvalidEditException('No clip $clipId');
}

/// Inserts [placed] onto the lowest non-overlapping overlay track in [tracks]
/// (closest to the main track), or creates a new top track at index `0` with
/// [newTrackId] when every existing track overlaps [placed].
///
/// Items on each track stay sorted by `startUs`.
List<LayerTrack> placeOnFreeOverlayTrack(
  List<LayerTrack> tracks,
  PlacedClip placed, {
  required String Function() newTrackId,
}) {
  final range = placed.range;
  for (var t = tracks.length - 1; t >= 0; t--) {
    if (!trackOverlaps(tracks[t], range)) {
      final items = [...tracks[t].items, placed]
        ..sort((a, b) => a.startUs.compareTo(b.startUs));
      return [...tracks]..[t] = tracks[t].copyWith(items: items);
    }
  }
  return [
    LayerTrack(id: newTrackId(), items: [placed]),
    ...tracks,
  ];
}

/// Whether [range] overlaps any item on [track] (optionally skipping
/// [ignoreClipId]).
bool trackOverlaps(LayerTrack track, TimeRange range, {String? ignoreClipId}) {
  for (final item in track.items) {
    if (item.clip.id == ignoreClipId) continue;
    if (item.range.overlaps(range)) return true;
  }
  return false;
}
