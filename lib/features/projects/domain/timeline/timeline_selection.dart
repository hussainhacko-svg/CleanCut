import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// What is selected on the timeline. Selection is UI state, not part of the
/// project, so it is not undoable.
@immutable
sealed class TimelineSelection {
  const new();

  /// Nothing is selected: the dock shows the "add" tools.
  static const TimelineSelection none = NoSelection();

  /// This selection if its item still exists in [project], else [none]
  /// (e.g. after the item was deleted or an undo removed it). An overlay
  /// selection follows its clip onto another overlay lane (a lane move, its
  /// undo, or a speed change that bumped the clip).
  TimelineSelection validIn(Project project) => switch (this) {
    NoSelection() => this,
    MainClipSelection(:final clipId) =>
      project.mainTrack.clips.any((c) => c.id == clipId) ? this : none,
    TransitionSelection(:final afterClipId) =>
      project.mainTrack.clips.indexWhere((c) => c.id == afterClipId) >= 0 &&
              project.mainTrack.clips.indexWhere((c) => c.id == afterClipId) <
                  project.mainTrack.clips.length - 1
          ? this
          : none,
    OverlaySelection(:final trackId, :final clipId) => switch (project
        .overlayTracks
        .where((t) => t.items.any((i) => i.clip.id == clipId))
        .firstOrNull) {
      null => none,
      final track when track.id == trackId => this,
      final track => OverlaySelection(trackId: track.id, clipId: clipId),
    },
    AudioSelection(:final trackId, :final clipId) =>
      project.audioTracks.any(
            (t) => t.id == trackId && t.items.any((i) => i.clip.id == clipId),
          )
          ? this
          : none,
  };
}

/// No selection.
final class NoSelection extends TimelineSelection {
  /// Creates the empty selection.
  const new();

  @override
  bool operator ==(Object other) => other is NoSelection;

  @override
  int get hashCode => 0;
}

/// A clip on the main video track.
final class MainClipSelection extends TimelineSelection {
  /// Selects main-track clip [clipId].
  const new(this.clipId);

  /// The selected clip's id.
  final String clipId;

  @override
  bool operator ==(Object other) =>
      other is MainClipSelection && other.clipId == clipId;

  @override
  int get hashCode => clipId.hashCode;
}

/// A transition boundary immediately after main-track clip [afterClipId].
final class TransitionSelection extends TimelineSelection {
  /// Selects the transition boundary after [afterClipId].
  const new(this.afterClipId);

  /// Id of the clip immediately preceding the boundary.
  final String afterClipId;

  @override
  bool operator ==(Object other) =>
      other is TransitionSelection && other.afterClipId == afterClipId;

  @override
  int get hashCode => Object.hash(TransitionSelection, afterClipId);
}

/// A clip on an overlay track.
final class OverlaySelection extends TimelineSelection {
  /// Selects [clipId] on overlay track [trackId].
  const new({required this.trackId, required this.clipId});

  /// The overlay track.
  final String trackId;

  /// The selected clip's id.
  final String clipId;

  @override
  bool operator ==(Object other) =>
      other is OverlaySelection &&
      other.trackId == trackId &&
      other.clipId == clipId;

  @override
  int get hashCode => Object.hash(trackId, clipId);
}

/// A clip on an audio track.
final class AudioSelection extends TimelineSelection {
  /// Selects [clipId] on audio track [trackId].
  const new({required this.trackId, required this.clipId});

  /// The audio track.
  final String trackId;

  /// The selected clip's id.
  final String clipId;

  @override
  bool operator ==(Object other) =>
      other is AudioSelection &&
      other.trackId == trackId &&
      other.clipId == clipId;

  @override
  int get hashCode => Object.hash(trackId, clipId);
}
