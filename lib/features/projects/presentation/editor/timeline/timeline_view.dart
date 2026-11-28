import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui show Clip;

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/core/theme/timeline_colors.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/domain/commands/clip_commands.dart';
import 'package:cleancut/features/projects/domain/commands/overlay_commands.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:cleancut/features/projects/domain/model/tracks.dart';
import 'package:cleancut/features/projects/domain/timeline/clip_lookup.dart';
import 'package:cleancut/features/projects/domain/timeline/reorder.dart';
import 'package:cleancut/features/projects/domain/timeline/ruler.dart';
import 'package:cleancut/features/projects/domain/timeline/snapping.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_scale.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_selection.dart';
import 'package:cleancut/features/projects/presentation/editor/editor_state.dart';
import 'package:cleancut/features/projects/presentation/playback/playback_controller.dart';
import 'package:cleancut/features/projects/presentation/project_providers.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Geometry of the VCLIP "Timeline" frame (logical px).
abstract final class TimelineMetrics {
  /// Ruler row (labels and dots).
  static const double rulerHeight = 23;

  /// Space between the ruler and the first lane.
  static const double rulerGap = 9;

  /// Pill lanes (effect, text, overlay, audio).
  static const double laneHeight = 30;

  /// The main video strip.
  static const double mainHeight = 60;

  /// Vertical space between lanes.
  static const double laneGap = 7;

  /// Gap drawn between neighbouring main-track clips (visual only; times
  /// stay exact).
  static const double clipGap = 4;

  /// Horizontal tap reach (dp) of a transition marker into a neighbouring
  /// clip of width [clipWidthPx]: full 24 dp (for a 48 dp target) when the
  /// clip has room, shrinking on short clips so at least 70% of the short
  /// clip remains tappable.
  static double transitionTapReach(double clipWidthPx) {
    if (clipWidthPx >= 48) return 24;
    if (clipWidthPx <= 8) return 0;
    return (clipWidthPx * 0.3).clamp(0.0, 24.0);
  }
}

/// A trim in progress: the dragged clip's source range so far. Drawn
/// without touching the project; committed as one `TrimClipCommand` on
/// release (so the preview reloads once).
typedef TrimDrag = ({
  String clipId,
  bool start,
  int sourceInUs,
  int sourceOutUs,
});

/// A long-press reorder in progress: the clip, how far it moved and the
/// index it would land on.
typedef ReorderDrag = ({String clipId, double dx, int toIndex});

/// An overlay trim in progress: committed as one `TrimOverlayCommand` on
/// release.
typedef OverlayTrimDrag = ({
  String trackId,
  String clipId,
  bool start,
  int startUs,
  int sourceInUs,
  int sourceOutUs,
});

/// An overlay long-press move in progress (horizontal time + vertical lane).
typedef OverlayMoveDrag = ({
  String trackId,
  String clipId,
  int originTrackIndex,
  int originStartUs,
  int durationUs,
  Offset offset,
  int targetStartUs,
  int targetTrackIndex,
  bool valid,
});

/// Callbacks from overlay pill trim handles and long-press move gestures.
final class OverlayGestures {
  /// Creates the callbacks.
  const new({
    required this.onTrimStart,
    required this.onTrimUpdate,
    required this.onTrimEnd,
    required this.onMoveStart,
    required this.onMoveUpdate,
    required this.onMoveEnd,
  });

  /// A trim handle of overlay item `itemIndex` on track `trackId` was grabbed.
  final void Function(String trackId, int itemIndex, {required bool start})
  onTrimStart;

  /// The grabbed overlay trim handle moved by `dx` px.
  final ValueChanged<double> onTrimUpdate;

  /// The overlay trim handle was released.
  final VoidCallback onTrimEnd;

  /// Overlay item `itemIndex` on track `trackId` was long-pressed to move.
  final void Function(String trackId, int itemIndex) onMoveStart;

  /// The lifted overlay moved by `offsetFromOrigin` px.
  final ValueChanged<Offset> onMoveUpdate;

  /// The lifted overlay was dropped.
  final VoidCallback onMoveEnd;
}

/// Callbacks from the main strip's trim handles and long-press reorder.
final class MainStripGestures {
  /// Creates the callbacks.
  const new({
    required this.onTrimStart,
    required this.onTrimUpdate,
    required this.onTrimEnd,
    required this.onReorderStart,
    required this.onReorderUpdate,
    required this.onReorderEnd,
  });

  /// A trim handle of `clip` (starting at timeline `clipStartUs`) was
  /// grabbed; `start` is the left handle.
  final void Function(Clip clip, int clipStartUs, {required bool start})
  onTrimStart;

  /// The grabbed handle moved by `dx` px.
  final ValueChanged<double> onTrimUpdate;

  /// The handle was released.
  final VoidCallback onTrimEnd;

  /// `clip` was long-pressed to reorder it.
  final ValueChanged<Clip> onReorderStart;

  /// The long-pressed clip moved by `dx` px from where it was lifted.
  final ValueChanged<double> onReorderUpdate;

  /// The long-pressed clip was dropped.
  final VoidCallback onReorderEnd;
}

/// The timeline: ruler, lanes and a fixed playhead in the middle. Dragging
/// scrubs (snapping to clip edges with a haptic tick), pinching zooms,
/// tapping selects. Always left-to-right (AGENTS.md §8).
class TimelineView extends ConsumerStatefulWidget {
  /// Creates the timeline of [project].
  const new({required this.projectId, required this.project, super.key});

  /// The open project's id.
  final String projectId;

  /// The project shown (the session's present state).
  final Project project;

  /// Key of the playhead line, for tests.
  @visibleForTesting
  static const ValueKey<String> playheadKey = ValueKey('timeline-playhead');

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView> {
  final _scroll = ScrollController();

  /// Vertical lane scroll; the playhead line follows it.
  final _laneScroll = ScrollController();

  // Ephemeral gesture state (AGENTS.md §4 allows local widget state).
  bool _userScrolling = false;
  bool _resumeAfterScrub = false;
  int? _lastSnapUs;
  final _pointers = <int, Offset>{};
  double? _pinchStartDistance;
  TimelineScale? _pinchStartScale;

  late List<int> _snapTargets = snapTargets(widget.project);

  // Trim: the clip as it was when grabbed and the finger's travel.
  TrimDrag? _trim;
  Clip? _trimOrigin;
  int _trimClipStartUs = 0;
  double _trimDx = 0;
  bool _trimSnapped = false;

  // Reorder (long-press + drag).
  ReorderDrag? _reorder;

  // Overlay trim (selected overlay handles).
  OverlayTrimDrag? _overlayTrim;
  LayerTrack? _overlayTrimTrack;
  int _overlayTrimIndex = -1;
  double _overlayTrimDx = 0;
  bool _overlayTrimSnapped = false;

  // Overlay move (long-press + drag in time and across lanes).
  OverlayMoveDrag? _overlayMove;
  List<int> _overlayMoveSnapTargets = const [];
  int? _overlayMoveLastSnapUs;

  late final MainStripGestures _gestures = MainStripGestures(
    onTrimStart: _onTrimStart,
    onTrimUpdate: _onTrimUpdate,
    onTrimEnd: _onTrimEnd,
    onReorderStart: _onReorderStart,
    onReorderUpdate: _onReorderUpdate,
    onReorderEnd: _onReorderEnd,
  );

  late final OverlayGestures _overlayGestures = OverlayGestures(
    onTrimStart: _onOverlayTrimStart,
    onTrimUpdate: _onOverlayTrimUpdate,
    onTrimEnd: _onOverlayTrimEnd,
    onMoveStart: _onOverlayMoveStart,
    onMoveUpdate: _onOverlayMoveUpdate,
    onMoveEnd: _onOverlayMoveEnd,
  );

  @override
  void initState() {
    super.initState();
    // Align with the current playhead on mount (e.g. after switching between
    // phone and tablet layouts while playback is past zero).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_userScrolling) {
        _jumpTo(ref.read(playbackPositionProvider(widget.projectId)));
      }
    });
  }

  @override
  void didUpdateWidget(TimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project) {
      _snapTargets = snapTargets(widget.project);
      final clips = widget.project.mainTrack.clips;
      if (_trim != null && !clips.any((c) => c.id == _trim!.clipId)) {
        _trim = null;
        _trimOrigin = null;
      }
      if (_reorder != null && !clips.any((c) => c.id == _reorder!.clipId)) {
        _reorder = null;
      }
      if (_overlayTrim != null &&
          locateClip(widget.project, _overlayTrim!.clipId) == null) {
        _overlayTrim = null;
        _overlayTrimTrack = null;
      }
      if (_overlayMove != null &&
          locateClip(widget.project, _overlayMove!.clipId) == null) {
        _overlayMove = null;
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _laneScroll.dispose();
    super.dispose();
  }

  Playback get _playback =>
      ref.read(playbackProvider(widget.projectId).notifier);

  TimelineScale get _scale => ref.read(timelineZoomProvider(widget.projectId));

  /// Puts the playhead (scroll offset) at [timeUs] without seeking.
  void _jumpTo(int timeUs) {
    if (!_scroll.hasClients) return;
    final target = _scale
        .toPx(timeUs)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    if ((target - _scroll.offset).abs() > 0.5) _scroll.jumpTo(target);
  }

  bool _onScroll(ScrollNotification n) {
    // Only the horizontal timeline scroll scrubs; vertical lane scrolling does
    // not move the playhead.
    if (n.metrics.axis != Axis.horizontal) return false;
    if (_pinchStartDistance != null) return false;
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _userScrolling = true;
      _lastSnapUs = null;
      _resumeAfterScrub = ref
          .read(playbackProvider(widget.projectId))
          .isPlaying;
      if (_resumeAfterScrub) unawaited(_playback.pause());
    } else if (n is ScrollUpdateNotification && _userScrolling) {
      final raw = _scale.toUs(_scroll.offset);
      final snapped = snapTo(
        raw,
        _snapTargets,
        toleranceUs: _scale.toUs(snapDistancePx),
      );
      if (snapped != null && snapped != _lastSnapUs) {
        unawaited(HapticFeedback.selectionClick());
      }
      _lastSnapUs = snapped;
      unawaited(_playback.seekTo(snapped ?? raw));
    } else if (n is ScrollEndNotification && _userScrolling) {
      _userScrolling = false;
      final resume = _resumeAfterScrub;
      _resumeAfterScrub = false;
      // Settle exactly on the snapped edge.
      if (_lastSnapUs case final snap?) _jumpTo(snap);
      if (resume) unawaited(_playback.play());
    }
    return false;
  }

  ProjectSession get _session =>
      ref.read(projectSessionProvider(widget.projectId).notifier);

  /// Clip edits pause playback so the playhead stays put.
  void _pauseForEdit() {
    if (ref.read(playbackProvider(widget.projectId)).isPlaying) {
      unawaited(_playback.pause());
    }
  }

  void _onTrimStart(Clip clip, int clipStartUs, {required bool start}) {
    _pauseForEdit();
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _trimOrigin = clip;
      _trimClipStartUs = clipStartUs;
      _trimDx = 0;
      _trimSnapped = false;
      _trim = (
        clipId: clip.id,
        start: start,
        sourceInUs: clip.sourceInUs,
        sourceOutUs: clip.sourceOutUs,
      );
    });
  }

  void _onTrimUpdate(double dx) {
    final clip = _trimOrigin;
    final trim = _trim;
    if (clip == null || trim == null) return;
    _trimDx += dx;
    final playhead = ref.read(playbackPositionProvider(widget.projectId));
    final tolerance = _scale.toUs(snapDistancePx);
    final deltaSource = (_scale.toUs(_trimDx) * clip.averageSpeed).round();
    var sourceIn = clip.sourceInUs;
    var sourceOut = clip.sourceOutUs;
    var snapped = false;
    if (trim.start) {
      sourceIn = clampTrimStart(clip, clip.sourceInUs + deltaSource);
      // The left edge is drawn at start + (old length - new length).
      final edge =
          _trimClipStartUs +
          clip.durationUs -
          clip.timelineLengthOf(sourceOut - sourceIn);
      if ((edge - playhead).abs() <= tolerance) {
        final length = _trimClipStartUs + clip.durationUs - playhead;
        sourceIn = clampTrimStart(
          clip,
          sourceOut - (length * clip.averageSpeed).round(),
        );
        snapped = true;
      }
    } else {
      sourceOut = clampTrimEnd(clip, clip.sourceOutUs + deltaSource);
      final edge =
          _trimClipStartUs + clip.timelineLengthOf(sourceOut - sourceIn);
      if ((edge - playhead).abs() <= tolerance) {
        sourceOut = clampTrimEnd(
          clip,
          sourceIn +
              ((playhead - _trimClipStartUs) * clip.averageSpeed).round(),
        );
        snapped = true;
      }
    }
    if (snapped && !_trimSnapped) {
      unawaited(HapticFeedback.selectionClick());
    }
    _trimSnapped = snapped;
    if (sourceIn == trim.sourceInUs && sourceOut == trim.sourceOutUs) return;
    setState(() {
      _trim = (
        clipId: trim.clipId,
        start: trim.start,
        sourceInUs: sourceIn,
        sourceOutUs: sourceOut,
      );
    });
  }

  void _onTrimEnd() {
    final trim = _trim;
    final clip = _trimOrigin;
    if (trim == null || clip == null) return;
    setState(() {
      _trim = null;
      _trimOrigin = null;
    });
    if (!widget.project.mainTrack.clips.any((c) => c.id == clip.id)) return;
    if (trim.sourceInUs == clip.sourceInUs &&
        trim.sourceOutUs == clip.sourceOutUs) {
      return;
    }
    _session
      ..apply(
        TrimClipCommand(
          clip.id,
          sourceInUs: trim.sourceInUs,
          sourceOutUs: trim.sourceOutUs,
        ),
      )
      ..seal();
    // Show the frame at the trimmed edge (DESIGN.md section 4).
    final length = clip.timelineLengthOf(trim.sourceOutUs - trim.sourceInUs);
    final frameUs = Micros.perSecond ~/ widget.project.canvas.fps;
    final edge = trim.start
        ? _trimClipStartUs
        : _trimClipStartUs + math.max<int>(0, length - frameUs);
    unawaited(_playback.seekTo(edge));
  }

  void _onReorderStart(Clip clip) {
    final index = widget.project.mainTrack.clips.indexWhere(
      (c) => c.id == clip.id,
    );
    if (index < 0) return;
    _pauseForEdit();
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _reorder = (clipId: clip.id, dx: 0, toIndex: index));
  }

  void _onReorderUpdate(double dx) {
    final reorder = _reorder;
    if (reorder == null) return;
    final main = widget.project.mainTrack;
    final clips = main.clips;
    final index = clips.indexWhere((c) => c.id == reorder.clipId);
    if (index < 0) return;
    final (slotStart, slotEnd) = main.visualSlotOf(index);
    final center = (slotStart + slotEnd) ~/ 2 + _scale.toUs(dx);
    final target = reorderTargetIndex(
      [
        for (var i = 0; i < clips.length; i++)
          main.visualSlotOf(i).$2 - main.visualSlotOf(i).$1,
      ],
      index,
      center,
    );
    if (target != reorder.toIndex) {
      unawaited(HapticFeedback.selectionClick());
    }
    setState(
      () => _reorder = (clipId: reorder.clipId, dx: dx, toIndex: target),
    );
  }

  void _onReorderEnd() {
    final reorder = _reorder;
    if (reorder == null) return;
    setState(() => _reorder = null);
    final index = widget.project.mainTrack.clips.indexWhere(
      (c) => c.id == reorder.clipId,
    );
    if (index < 0 || index == reorder.toIndex) return;
    _session
      ..apply(MoveClipCommand(reorder.clipId, toIndex: reorder.toIndex))
      ..seal();
  }

  void _onOverlayTrimStart(
    String trackId,
    int itemIndex, {
    required bool start,
  }) {
    final track = widget.project.overlayTracks
        .where((t) => t.id == trackId)
        .firstOrNull;
    if (track == null || itemIndex < 0 || itemIndex >= track.items.length) {
      return;
    }
    final item = track.items[itemIndex];
    _pauseForEdit();
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _overlayTrimTrack = track;
      _overlayTrimIndex = itemIndex;
      _overlayTrimDx = 0;
      _overlayTrimSnapped = false;
      _overlayTrim = (
        trackId: trackId,
        clipId: item.clip.id,
        start: start,
        startUs: item.startUs,
        sourceInUs: item.clip.sourceInUs,
        sourceOutUs: item.clip.sourceOutUs,
      );
    });
  }

  void _onOverlayTrimUpdate(double dx) {
    final track = _overlayTrimTrack;
    final trim = _overlayTrim;
    if (track == null ||
        trim == null ||
        _overlayTrimIndex < 0 ||
        _overlayTrimIndex >= track.items.length) {
      return;
    }
    final item = track.items[_overlayTrimIndex];
    final clip = item.clip;
    _overlayTrimDx += dx;
    final playhead = ref.read(playbackPositionProvider(widget.projectId));
    final tolerance = _scale.toUs(snapDistancePx);
    final deltaTimeline = _scale.toUs(_overlayTrimDx);
    var startUs = item.startUs;
    var sourceIn = clip.sourceInUs;
    var sourceOut = clip.sourceOutUs;
    var snapped = false;

    if (trim.start) {
      final clamped = clampOverlayTrimStart(
        track,
        _overlayTrimIndex,
        deltaTimelineUs: deltaTimeline,
      );
      startUs = clamped.startUs;
      sourceIn = clamped.sourceInUs;
      sourceOut = clamped.sourceOutUs;
      if ((startUs - playhead).abs() <= tolerance) {
        final snappedClamp = clampOverlayTrimStart(
          track,
          _overlayTrimIndex,
          deltaTimelineUs: playhead - item.startUs,
        );
        startUs = snappedClamp.startUs;
        sourceIn = snappedClamp.sourceInUs;
        sourceOut = snappedClamp.sourceOutUs;
        snapped = true;
      }
    } else {
      final deltaSource = (deltaTimeline * clip.averageSpeed).round();
      sourceOut = clampOverlayTrimEnd(
        track,
        _overlayTrimIndex,
        sourceOutUs: clip.sourceOutUs + deltaSource,
      );
      final edge =
          item.startUs + clip.timelineLengthOf(sourceOut - clip.sourceInUs);
      if ((edge - playhead).abs() <= tolerance) {
        sourceOut = clampOverlayTrimEnd(
          track,
          _overlayTrimIndex,
          sourceOutUs:
              clip.sourceInUs +
              ((playhead - item.startUs) * clip.averageSpeed).round(),
        );
        snapped = true;
      }
    }

    if (snapped && !_overlayTrimSnapped) {
      unawaited(HapticFeedback.selectionClick());
    }
    _overlayTrimSnapped = snapped;
    if (startUs == trim.startUs &&
        sourceIn == trim.sourceInUs &&
        sourceOut == trim.sourceOutUs) {
      return;
    }
    setState(() {
      _overlayTrim = (
        trackId: trim.trackId,
        clipId: trim.clipId,
        start: trim.start,
        startUs: startUs,
        sourceInUs: sourceIn,
        sourceOutUs: sourceOut,
      );
    });
  }

  void _onOverlayTrimEnd() {
    final trim = _overlayTrim;
    final track = _overlayTrimTrack;
    final itemIndex = _overlayTrimIndex;
    if (trim == null || track == null) return;
    setState(() {
      _overlayTrim = null;
      _overlayTrimTrack = null;
      _overlayTrimIndex = -1;
    });
    if (itemIndex < 0 || itemIndex >= track.items.length) return;
    final item = track.items[itemIndex];
    final clip = item.clip;
    if (locateClip(widget.project, clip.id) == null) return;
    if (trim.startUs == item.startUs &&
        trim.sourceInUs == clip.sourceInUs &&
        trim.sourceOutUs == clip.sourceOutUs) {
      return;
    }
    _session
      ..apply(
        TrimOverlayCommand(
          clip.id,
          startUs: trim.startUs,
          sourceInUs: trim.sourceInUs,
          sourceOutUs: trim.sourceOutUs,
        ),
      )
      ..seal();
    final length = clip.timelineLengthOf(trim.sourceOutUs - trim.sourceInUs);
    final frameUs = Micros.perSecond ~/ widget.project.canvas.fps;
    final edge = trim.start
        ? trim.startUs
        : trim.startUs + math.max<int>(0, length - frameUs);
    unawaited(_playback.seekTo(edge));
  }

  void _onOverlayMoveStart(String trackId, int itemIndex) {
    final trackIndex = widget.project.overlayTracks.indexWhere(
      (t) => t.id == trackId,
    );
    if (trackIndex < 0) return;
    final track = widget.project.overlayTracks[trackIndex];
    if (itemIndex < 0 || itemIndex >= track.items.length) return;
    final item = track.items[itemIndex];
    _pauseForEdit();
    unawaited(HapticFeedback.mediumImpact());
    final playhead = ref.read(playbackPositionProvider(widget.projectId));
    // Snap targets exclude this overlay's own current edges so it doesn't stick
    // to its starting position while dragging away.
    final targets = <int>{0, playhead};
    final main = widget.project.mainTrack;
    for (var i = 0; i < main.clips.length; i++) {
      targets
        ..add(main.startOf(i))
        ..add(main.endOf(i));
    }
    for (final t in widget.project.overlayTracks) {
      for (final other in t.items) {
        if (other.clip.id == item.clip.id) continue;
        targets
          ..add(other.range.startUs)
          ..add(other.range.endUs);
      }
    }
    _overlayMoveSnapTargets = targets.toList()..sort();
    _overlayMoveLastSnapUs = null;
    setState(() {
      _overlayMove = (
        trackId: trackId,
        clipId: item.clip.id,
        originTrackIndex: trackIndex,
        originStartUs: item.startUs,
        durationUs: item.clip.durationUs,
        offset: Offset.zero,
        targetStartUs: item.startUs,
        targetTrackIndex: trackIndex,
        valid: true,
      );
    });
  }

  void _onOverlayMoveUpdate(Offset offsetFromOrigin) {
    final move = _overlayMove;
    if (move == null) return;
    final tracks = widget.project.overlayTracks;
    final rawStart = math.max(
      0,
      move.originStartUs + _scale.toUs(offsetFromOrigin.dx),
    );
    final tolerance = _scale.toUs(snapDistancePx);
    final startSnap = snapTo(
      rawStart,
      _overlayMoveSnapTargets,
      toleranceUs: tolerance,
    );
    final endSnap = snapTo(
      rawStart + move.durationUs,
      _overlayMoveSnapTargets,
      toleranceUs: tolerance,
    );
    var targetStart = rawStart;
    int? snappedUs;
    if (startSnap != null &&
        (endSnap == null ||
            (startSnap - rawStart).abs() <=
                (endSnap - (rawStart + move.durationUs)).abs())) {
      targetStart = startSnap;
      snappedUs = startSnap;
    } else if (endSnap != null && endSnap - move.durationUs >= 0) {
      targetStart = endSnap - move.durationUs;
      snappedUs = endSnap;
    }
    if (snappedUs != null && snappedUs != _overlayMoveLastSnapUs) {
      unawaited(HapticFeedback.selectionClick());
    }
    _overlayMoveLastSnapUs = snappedUs;

    const laneStep = TimelineMetrics.laneHeight + TimelineMetrics.laneGap;
    final laneDelta = (offsetFromOrigin.dy / laneStep).round();
    final targetTrackIndex = (move.originTrackIndex + laneDelta).clamp(
      -1,
      tracks.length,
    );
    if (targetTrackIndex != move.targetTrackIndex) {
      unawaited(HapticFeedback.selectionClick());
    }
    final valid = canPlaceOverlayOnTrack(
      tracks,
      movingClipId: move.clipId,
      targetTrackIndex: targetTrackIndex,
      range: TimeRange(targetStart, targetStart + move.durationUs),
    );
    setState(() {
      _overlayMove = (
        trackId: move.trackId,
        clipId: move.clipId,
        originTrackIndex: move.originTrackIndex,
        originStartUs: move.originStartUs,
        durationUs: move.durationUs,
        offset: offsetFromOrigin,
        targetStartUs: targetStart,
        targetTrackIndex: targetTrackIndex,
        valid: valid,
      );
    });
  }

  void _onOverlayMoveEnd() {
    final move = _overlayMove;
    if (move == null) return;
    setState(() => _overlayMove = null);
    if (!move.valid) return;
    if (move.targetStartUs == move.originStartUs &&
        move.targetTrackIndex == move.originTrackIndex) {
      return;
    }
    // The selection follows the clip onto its new lane
    // (TimelineSelection.validIn).
    _session
      ..apply(
        MoveOverlayCommand(
          move.clipId,
          startUs: move.targetStartUs,
          trackIndex: move.targetTrackIndex,
          newTrackId: ref.read(idGeneratorProvider),
        ),
      )
      ..seal();
  }

  // Pinch: two pointers zoom around the playhead; scrolling pauses.
  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) {
      // Cancel any in-progress 1-finger scrub so zoom adjustments via _jumpTo
      // aren't treated as user scrubs.
      if (_userScrolling) {
        _userScrolling = false;
        _lastSnapUs = null;
        if (_resumeAfterScrub) {
          _resumeAfterScrub = false;
          unawaited(_playback.play());
        }
      }
      final [a, b] = _pointers.values.toList();
      _pinchStartDistance = (a - b).distance;
      _pinchStartScale = _scale;
      setState(() {});
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    final start = _pinchStartDistance;
    final startScale = _pinchStartScale;
    if (_pointers.length != 2 || start == null || startScale == null) return;
    if (start < 1) return;
    final [a, b] = _pointers.values.toList();
    final factor = (a - b).distance / start;
    ref
        .read(timelineZoomProvider(widget.projectId).notifier)
        .set(startScale.zoomed(factor));
  }

  void _onPointerUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2 && _pinchStartDistance != null) {
      setState(() {
        _pinchStartDistance = null;
        _pinchStartScale = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final scale = ref.watch(timelineZoomProvider(widget.projectId));
    final selection = ref.watch(
      timelineSelectionControllerProvider(widget.projectId),
    );

    // Follow playback (and seeks from elsewhere) without rebuilding.
    ref
      ..listen(playbackPositionProvider(widget.projectId), (_, us) {
        if (!_userScrolling) _jumpTo(us);
      })
      ..listen(timelineZoomProvider(widget.projectId), (_, _) {
        // Keep the playhead on the same time while zooming.
        final position = ref.read(playbackPositionProvider(widget.projectId));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _jumpTo(position);
        });
      });

    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.maxWidth;
          final pad = viewport / 2;
          final contentWidth = scale.toPx(project.durationUs) + viewport;
          final layout = _LaneLayout.of(project);
          final viewportHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : layout.height;
          final contentHeight = math.max(layout.height, viewportHeight);
          final physics = _pinchStartDistance != null
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics();
          const playheadTop = TimelineMetrics.rulerHeight + 4;
          final lanesBottom =
              layout.audioTops.last + TimelineMetrics.laneHeight;

          return Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerUp,
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _laneScroll,
                  physics: physics,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: SingleChildScrollView(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      physics: physics,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: ref
                            .read(
                              timelineSelectionControllerProvider(
                                widget.projectId,
                              ).notifier,
                            )
                            .clear,
                        child: SizedBox(
                          width: contentWidth,
                          height: contentHeight,
                          child: _TimelineContent(
                            projectId: widget.projectId,
                            project: project,
                            layout: layout,
                            scale: scale,
                            pad: pad,
                            viewport: viewport,
                            scroll: _scroll,
                            selection: selection,
                            trim: _trim,
                            reorder: _reorder,
                            gestures: _gestures,
                            overlayTrim: _overlayTrim,
                            overlayMove: _overlayMove,
                            overlayGestures: _overlayGestures,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // The Clipcraft playhead: fixed in the middle with a circular
                // cap in `primary`, spanning the lanes and following vertical
                // lane scroll.
                ListenableBuilder(
                  listenable: _laneScroll,
                  builder: (context, line) {
                    final dy = _laneScroll.hasClients
                        ? _laneScroll.offset
                        : 0.0;
                    final top = math.max(0, playheadTop - dy).toDouble();
                    final bottom = math.min(lanesBottom - dy, viewportHeight);
                    return Positioned(
                      left: pad - 5,
                      top: top,
                      height: math.max(0, bottom - top).toDouble(),
                      child: line!,
                    );
                  },
                  child: IgnorePointer(
                    key: TimelineView.playheadKey,
                    child: SizedBox(
                      width: 10,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Vertical placement of the rows: ruler, overlay lanes, main strip,
/// audio lanes (at least one, which also holds the mute toggle).
class _LaneLayout {
  const new({
    required this.overlayTops,
    required this.mainTop,
    required this.audioTops,
    required this.height,
  });

  factory of(Project project) {
    var y = TimelineMetrics.rulerHeight + TimelineMetrics.rulerGap;
    final overlays = <double>[];
    for (final _ in project.overlayTracks) {
      overlays.add(y);
      y += TimelineMetrics.laneHeight + TimelineMetrics.laneGap;
    }
    final main = y;
    y += TimelineMetrics.mainHeight + TimelineMetrics.laneGap;
    final audio = <double>[];
    for (var i = 0; i < math.max(1, project.audioTracks.length); i++) {
      audio.add(y);
      y += TimelineMetrics.laneHeight + TimelineMetrics.laneGap;
    }
    return _LaneLayout(
      overlayTops: overlays,
      mainTop: main,
      audioTops: audio,
      // Extra 5dp below the last lane keeps the 48dp mute button inside bounds.
      height: y + 5,
    );
  }

  final List<double> overlayTops;
  final double mainTop;
  final List<double> audioTops;
  final double height;
}

class _TimelineContent extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.project,
    required this.layout,
    required this.scale,
    required this.pad,
    required this.viewport,
    required this.scroll,
    required this.selection,
    required this.trim,
    required this.reorder,
    required this.gestures,
    required this.overlayTrim,
    required this.overlayMove,
    required this.overlayGestures,
  });

  final String projectId;
  final Project project;
  final _LaneLayout layout;
  final TimelineScale scale;
  final double pad;
  final double viewport;
  final ScrollController scroll;
  final TimelineSelection selection;
  final TrimDrag? trim;
  final ReorderDrag? reorder;
  final MainStripGestures gestures;
  final OverlayTrimDrag? overlayTrim;
  final OverlayMoveDrag? overlayMove;
  final OverlayGestures overlayGestures;

  /// Width of each trim handle's touch target (AGENTS.md section 8).
  static const double handleTarget = 48;

  double _x(int us) => pad + scale.toPx(us);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = TimelineColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final selector = ref.read(
      timelineSelectionControllerProvider(projectId).notifier,
    );
    // While a main clip is selected the other lanes step back (kit "Video").
    final dimOthers = selection is MainClipSelection;
    void soon() => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.editorToolSoon)));

    final children = <Widget>[
      Positioned.fill(
        child: CustomPaint(
          painter: _RulerPainter(
            scale: scale,
            pad: pad,
            viewport: viewport,
            scroll: scroll,
            style: AppTokens.timecodeStyle(context).copyWith(fontSize: 10),
            dotColor: scheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
    ];

    // Overlay lanes: trim handles on selected overlay, long-press drag to
    // reposition in time or across lanes, plus keyframe markers.
    Widget? liftedOverlay;
    final overlayHandles = <Widget>[];
    for (final (i, track) in project.overlayTracks.indexed) {
      for (final (itemIndex, item) in track.items.indexed) {
        final clip = item.clip;
        final sel = OverlaySelection(trackId: track.id, clipId: clip.id);
        final trimming = overlayTrim?.clipId == clip.id ? overlayTrim : null;
        final shownClip = trimming == null
            ? clip
            : clip.copyWith(
                sourceInUs: trimming.sourceInUs,
                sourceOutUs: trimming.sourceOutUs,
              );
        final shownStartUs = trimming?.startUs ?? item.startUs;
        final shownEndUs = shownStartUs + shownClip.durationUs;
        final isLifted = overlayMove?.clipId == clip.id;
        final pillLeft =
            _x(shownStartUs) + (isLifted ? overlayMove!.offset.dx : 0);
        final pillTop =
            layout.overlayTops[i] + (isLifted ? overlayMove!.offset.dy : 0);
        final pillWidth = math.max(
          TimelineMetrics.laneHeight,
          scale.toPx(shownEndUs - shownStartUs),
        );
        final keyframeTimes = shownClip.keyframeTimes;
        final pillWidget = Positioned(
          // Keyed so a lifted overlay keeps its long-press gesture recognizer
          // when moved to the top of the Stack.
          key: ValueKey(('overlayClip', clip.id)),
          left: pillLeft,
          top: pillTop,
          width: pillWidth,
          height: TimelineMetrics.laneHeight,
          child: LanePill(
            color: colors.overlay,
            icon: AppIcons.laneOverlay,
            label: clip.media.displayName ?? l10n.laneOverlay,
            selected: selection == sel,
            dimmed: dimOthers,
            lifted: isLifted,
            onTap: () => selector.toggle(sel),
            onLongPressStart: () =>
                overlayGestures.onMoveStart(track.id, itemIndex),
            onLongPressMove: overlayGestures.onMoveUpdate,
            onLongPressEnd: overlayGestures.onMoveEnd,
            overlay: keyframeTimes.isEmpty
                ? null
                : ClipKeyframeMarkers(
                    timesUs: keyframeTimes,
                    clipDurationUs: shownClip.durationUs,
                    scale: scale,
                  ),
          ),
        );
        if (isLifted) {
          liftedOverlay = pillWidget;
        } else {
          children.add(pillWidget);
        }
        if (selection == sel && overlayMove == null && reorder == null) {
          // Each 48dp target reaches at most a quarter of the pill inward, so
          // the middle of a short pill stays free for long-press moves.
          final inward = math.min(handleTarget / 2, pillWidth / 4);
          for (final isStart in [true, false]) {
            final edgeX = isStart ? pillLeft : pillLeft + pillWidth;
            overlayHandles.add(
              Positioned(
                key: ValueKey(isStart ? 'overlayTrimStart' : 'overlayTrimEnd'),
                left: isStart
                    ? edgeX - (handleTarget - inward)
                    : edgeX - inward,
                top: layout.overlayTops[i] - 9,
                width: handleTarget,
                height: 48,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  dragStartBehavior: DragStartBehavior.down,
                  onHorizontalDragStart: (_) => overlayGestures.onTrimStart(
                    track.id,
                    itemIndex,
                    start: isStart,
                  ),
                  onHorizontalDragUpdate: (d) => overlayGestures.onTrimUpdate(
                    d.primaryDelta ?? d.delta.dx,
                  ),
                  onHorizontalDragEnd: (_) => overlayGestures.onTrimEnd(),
                  onHorizontalDragCancel: overlayGestures.onTrimEnd,
                ),
              ),
            );
          }
        }
      }
    }
    if (overlayMove case final move?) {
      const laneStep = TimelineMetrics.laneHeight + TimelineMetrics.laneGap;
      final ghostTop = move.targetTrackIndex < 0
          ? layout.overlayTops.first - laneStep * 0.45
          : move.targetTrackIndex >= layout.overlayTops.length
          ? layout.overlayTops.last + laneStep * 0.45
          : layout.overlayTops[move.targetTrackIndex];
      final ghostColor = move.valid ? colors.overlay : scheme.error;
      children.add(
        Positioned(
          key: const ValueKey('overlayDropGhost'),
          left: _x(move.targetStartUs),
          top: ghostTop,
          width: math.max(
            TimelineMetrics.laneHeight,
            scale.toPx(move.durationUs),
          ),
          height: TimelineMetrics.laneHeight,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ghostColor.withValues(alpha: 0.22),
                borderRadius: const BorderRadius.all(
                  Radius.circular(TimelineMetrics.laneHeight / 2),
                ),
                border: Border.all(color: ghostColor, width: 1.5),
              ),
            ),
          ),
        ),
      );
    }

    // Main strip: clips laid out along their visual slots (overlapping across
    // transitions, split evenly at each boundary center) with interactive ⧓
    // transition markers between them. A trimmed clip draws its new range
    // until release; a long-pressed clip follows the finger above the others.
    final main = project.mainTrack;
    final clips = main.clips;
    final clipLefts = <double>[];
    final clipWidths = <double>[];
    Widget? lifted;
    final handles = <Widget>[];
    final markers = <Widget>[];
    final overlapBands = <Widget>[];
    for (final (i, clip) in clips.indexed) {
      final clipStart = main.startOf(i);
      final (slotStart, slotEnd) = main.visualSlotOf(i);
      final slotDurationUs = slotEnd - slotStart;
      final leadInUs = slotStart - clipStart;
      final trimming = trim?.clipId == clip.id ? trim : null;
      final shown = trimming == null
          ? clip
          : clip.copyWith(
              sourceInUs: trimming.sourceInUs,
              sourceOutUs: trimming.sourceOutUs,
            );
      final deltaDurationUs = shown.durationUs - clip.durationUs;
      final shownSlotStart = trimming != null && trimming.start
          ? slotStart - deltaDurationUs
          : slotStart;
      final shownSlotDuration = math.max<int>(
        1,
        slotDurationUs + deltaDurationUs,
      );
      final sel = MainClipSelection(clip.id);
      final isLifted = reorder?.clipId == clip.id;
      final left =
          _x(shownSlotStart) +
          TimelineMetrics.clipGap / 2 +
          (isLifted ? reorder!.dx : 0);
      final width = math.max<double>(
        2,
        scale.toPx(shownSlotDuration) - TimelineMetrics.clipGap,
      );
      clipLefts.add(_x(slotStart));
      clipWidths.add(width);
      final view = Positioned(
        // Keyed so a lifted clip keeps its element (and the long-press
        // recognizer tracking the finger) when it moves to the top.
        key: ValueKey(('mainClip', clip.id)),
        left: left,
        top: layout.mainTop,
        width: width,
        height: TimelineMetrics.mainHeight,
        child: MainClipView(
          clip: shown,
          scale: scale,
          contentLeft: left,
          viewport: viewport,
          scroll: scroll,
          selected: selection == sel,
          lifted: isLifted,
          visualLeadInUs: leadInUs,
          visualDurationUs: shownSlotDuration,
          onTap: () => selector.toggle(sel),
          onLongPressStart: () => gestures.onReorderStart(clip),
          onLongPressMove: gestures.onReorderUpdate,
          onLongPressEnd: gestures.onReorderEnd,
        ),
      );
      if (isLifted) {
        lifted = view;
      } else {
        children.add(view);
      }
      if (selection == sel && reorder == null) {
        for (final isStart in [true, false]) {
          final edgeX = isStart ? left : left + width;
          handles.add(
            Positioned(
              key: ValueKey(isStart ? 'trimStart' : 'trimEnd'),
              left: edgeX - handleTarget / 2,
              top: layout.mainTop,
              width: handleTarget,
              height: TimelineMetrics.mainHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Count the finger's whole travel, including the touch slop,
                // so the edge stays under the finger.
                dragStartBehavior: DragStartBehavior.down,
                onHorizontalDragStart: (_) =>
                    gestures.onTrimStart(clip, clipStart, start: isStart),
                onHorizontalDragUpdate: (d) =>
                    gestures.onTrimUpdate(d.primaryDelta ?? d.delta.dx),
                onHorizontalDragEnd: (_) => gestures.onTrimEnd(),
                onHorizontalDragCancel: gestures.onTrimEnd,
              ),
            ),
          );
        }
      }
    }

    if (reorder == null) {
      final gradient = AccentGradient.of(context).linear;
      for (var i = 1; i < clips.length; i++) {
        final leftClip = clips[i - 1];
        final rightClip = clips[i];
        final afterId = leftClip.id;
        final boundaryCenterUs = main.boundaryCenterOf(i - 1);
        final boundaryX = _x(boundaryCenterUs);
        final transition = main.transitionAfter(i - 1);
        final overlapUs = main.overlapAfter(i - 1);
        final tSel = TransitionSelection(afterId);
        final isSelected = selection == tSel;
        final hasTransition = transition != null && overlapUs > 0;

        if (hasTransition) {
          final bandWidth = math.max<double>(6, scale.toPx(overlapUs));
          overlapBands.add(
            Positioned(
              left: boundaryX - bandWidth / 2,
              top: layout.mainTop + TimelineMetrics.mainHeight - 4,
              width: bandWidth,
              height: 4,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }

        // Keep trim handles unobstructed on the edges of a selected clip.
        final adjacentClipSelected =
            selection == MainClipSelection(leftClip.id) ||
            selection == MainClipSelection(rightClip.id);
        final leftReach = adjacentClipSelected
            ? 0.0
            : TimelineMetrics.transitionTapReach(clipWidths[i - 1]);
        final rightReach = adjacentClipSelected
            ? 0.0
            : TimelineMetrics.transitionTapReach(clipWidths[i]);
        final badge = Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected ? gradient : null,
            color: isSelected
                ? null
                : hasTransition
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: scheme.onSurface, width: 1.5)
                : Border.all(
                    color: hasTransition
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
          ),
          child: AppIcon(
            AppIcons.transition,
            size: 13,
            color: isSelected
                ? scheme.onPrimary
                : hasTransition
                ? scheme.primary
                : null,
          ),
        );

        final tapWidth = leftReach + rightReach;
        if (tapWidth <= 0) {
          markers.add(
            Positioned(
              left: boundaryX - 11,
              top: layout.mainTop + TimelineMetrics.mainHeight / 2 - 11,
              child: IgnorePointer(child: badge),
            ),
          );
        } else {
          final overlapStartUs = main.startOf(i);
          final overlapEndUs = main.endOf(i - 1);
          markers.add(
            Positioned(
              key: ValueKey(('transitionMarker', afterId)),
              left: boundaryX - leftReach,
              top: layout.mainTop + TimelineMetrics.mainHeight / 2 - 24,
              width: tapWidth,
              height: 48,
              child: Semantics(
                button: true,
                selected: isSelected,
                label: l10n.timelineTransitionBetween(i, i + 1),
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    final opening = selection != tSel;
                    selector.toggle(tSel);
                    if (opening) {
                      final pos = ref.read(playbackPositionProvider(projectId));
                      final inWindow = overlapUs > 0
                          ? (pos >= overlapStartUs && pos <= overlapEndUs)
                          : pos == boundaryCenterUs;
                      if (!inWindow) {
                        unawaited(
                          ref
                              .read(playbackProvider(projectId).notifier)
                              .seekTo(boundaryCenterUs),
                        );
                      }
                    }
                  },
                  child: Stack(
                    clipBehavior: ui.Clip.none,
                    children: [
                      Positioned(left: leftReach - 11, top: 13, child: badge),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    children
      ..addAll(overlapBands)
      ..addAll(markers)
      ..addAll(handles)
      ..addAll(overlayHandles);
    if (liftedOverlay != null) children.add(liftedOverlay);
    if (reorder != null && lifted != null) {
      // Where the lifted clip will land: before the clip now at that slot
      // (ignoring the lifted one), or after the last.
      final others = [
        for (final (i, c) in clips.indexed)
          if (c.id != reorder!.clipId) i,
      ];
      final x = reorder!.toIndex < others.length
          ? clipLefts[others[reorder!.toIndex]]
          : _x(project.mainTrack.durationUs);
      children
        ..add(
          Positioned(
            key: const ValueKey('reorderIndicator'),
            left: x - 1,
            top: layout.mainTop - 4,
            width: 2,
            height: TimelineMetrics.mainHeight + 8,
            child: IgnorePointer(child: ColoredBox(color: scheme.onSurface)),
          ),
        )
        ..add(lifted);
    }

    // Audio lanes; the first row also holds the "mute original audio"
    // toggle left of time 0, as in the kit.
    children.add(
      Positioned(
        left: _x(0) - 52,
        top: layout.audioTops.first + TimelineMetrics.laneHeight / 2 - 24,
        child: IconButton(
          tooltip: l10n.timelineMuteOriginal,
          onPressed: soon,
          icon: const AppIcon(AppIcons.mute, size: 19),
        ),
      ),
    );
    for (final (i, track) in project.audioTracks.indexed) {
      for (final item in track.items) {
        final sel = AudioSelection(trackId: track.id, clipId: item.clip.id);
        children.add(
          _pill(
            top: layout.audioTops[i],
            startUs: item.range.startUs,
            endUs: item.range.endUs,
            child: LanePill(
              color: colors.audio,
              icon: AppIcons.laneAudio,
              label: item.clip.media.displayName ?? l10n.laneAudio,
              selected: selection == sel,
              dimmed: dimOthers,
              onTap: () => selector.toggle(sel),
              trailing: _Waveform(
                uri: item.clip.media.uri,
                sourceInUs: item.clip.sourceInUs,
                sourceOutUs: item.clip.sourceOutUs,
              ),
            ),
          ),
        );
      }
    }

    return Stack(clipBehavior: ui.Clip.none, children: children);
  }

  Widget _pill({
    required double top,
    required int startUs,
    required int endUs,
    required Widget child,
  }) => Positioned(
    left: _x(startUs),
    top: top,
    width: math.max(TimelineMetrics.laneHeight, scale.toPx(endUs - startUs)),
    height: TimelineMetrics.laneHeight,
    child: child,
  );
}

/// Paints only the ticks in view; repaints as the timeline scrolls.
class _RulerPainter extends CustomPainter {
  new({
    required this.scale,
    required this.pad,
    required this.viewport,
    required this.scroll,
    required this.style,
    required this.dotColor,
  }) : super(repaint: scroll);

  final TimelineScale scale;
  final double pad;
  final double viewport;
  final ScrollController scroll;
  final TextStyle style;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final offset = scroll.hasClients ? scroll.offset : 0.0;
    final from = scale.toUs(offset - pad - 40);
    final to = scale.toUs(offset + viewport - pad + 40);
    final dot = Paint()..color = dotColor;
    for (final tick in rulerTicks(scale, fromUs: from, toUs: to)) {
      final x = pad + scale.toPx(tick.timeUs);
      if (tick.isMajor) {
        final painter = TextPainter(
          text: TextSpan(text: rulerLabel(tick.timeUs), style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(canvas, Offset(x - painter.width / 2, 2));
      } else {
        canvas.drawRect(Rect.fromLTWH(x - 0.5, 12, 1, 2), dot);
      }
    }
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.scale != scale ||
      old.pad != pad ||
      old.viewport != viewport ||
      old.style != style ||
      old.dotColor != dotColor;
}

/// A main-track clip: its thumbnail strip, and when selected the kit's
/// cream tint, white outline and white trim handles.
class MainClipView extends StatelessWidget {
  /// Creates the clip view.
  const new({
    required this.clip,
    required this.scale,
    required this.contentLeft,
    required this.viewport,
    required this.scroll,
    required this.selected,
    required this.onTap,
    this.lifted = false,
    this.visualLeadInUs = 0,
    this.visualDurationUs,
    this.onLongPressStart,
    this.onLongPressMove,
    this.onLongPressEnd,
    super.key,
  });

  /// The clip.
  final Clip clip;

  /// Current zoom.
  final TimelineScale scale;

  /// The clip's left edge inside the scroll content.
  final double contentLeft;

  /// Visible width of the timeline.
  final double viewport;

  /// The timeline's scroll position (for virtualizing thumbnails).
  final ScrollController scroll;

  /// Whether the clip is selected.
  final bool selected;

  /// Selects / deselects the clip.
  final VoidCallback onTap;

  /// Whether the clip is lifted for reordering (drawn raised).
  final bool lifted;

  /// Timeline µs trimmed visually off the start of this strip slot for an
  /// incoming transition overlap.
  final int visualLeadInUs;

  /// Visual duration of this strip slot in µs (defaults to `clip.durationUs`).
  final int? visualDurationUs;

  /// Long press: lift the clip to reorder it.
  final VoidCallback? onLongPressStart;

  /// The lifted clip moved by `dx` px from where it was lifted.
  final ValueChanged<double>? onLongPressMove;

  /// The lifted clip was dropped.
  final VoidCallback? onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    final colors = TimelineColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(AppTokens.cardRadius));
    final keyframeTimes = clip.keyframeTimes;
    final move = onLongPressMove;
    final strip = Stack(
      clipBehavior: ui.Clip.none,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: radius,
            child: ColoredBox(
              color: scheme.surfaceContainerHigh,
              child: ThumbnailStrip(
                clip: clip,
                scale: scale,
                contentLeft: contentLeft,
                viewport: viewport,
                scroll: scroll,
                leadInUs: visualLeadInUs,
                visibleDurationUs: visualDurationUs ?? clip.durationUs,
              ),
            ),
          ),
        ),
        if (selected) ...[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.selectionTint.withValues(
                  alpha: TimelineColors.selectedClipTint,
                ),
                borderRadius: radius,
                border: Border.all(color: colors.video, width: 2),
              ),
            ),
          ),
          for (final left in [true, false])
            Positioned(
              left: left ? -9 : null,
              right: left ? null : -9,
              top: TimelineMetrics.mainHeight / 2 - 7,
              child: _Handle(color: colors.video),
            ),
        ],
        if (keyframeTimes.isNotEmpty)
          Positioned.fill(
            child: ClipKeyframeMarkers(
              timesUs: keyframeTimes,
              clipDurationUs: clip.durationUs,
              scale: scale,
              leadInUs: visualLeadInUs,
            ),
          ),
      ],
    );
    return Semantics(
      button: true,
      selected: selected,
      label: clip.media.displayName,
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: onLongPressStart == null
            ? null
            : (_) => onLongPressStart!(),
        onLongPressMoveUpdate: move == null
            ? null
            : (d) => move(d.offsetFromOrigin.dx),
        onLongPressEnd: onLongPressEnd == null
            ? null
            : (_) => onLongPressEnd!(),
        onLongPressCancel: onLongPressEnd,
        child: lifted
            ? Transform.translate(
                offset: const Offset(0, -6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.6),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Opacity(opacity: 0.9, child: strip),
                ),
              )
            : strip,
      ),
    );
  }
}

/// The kit's 4×14 rounded trim handle.
class _Handle extends StatelessWidget {
  const new({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 4,
    height: 14,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

/// Diamond markers rendered along the top edge of a timeline clip for each
/// keyframe timestamp in [timesUs], keeping them visible even when an open
/// tool panel shrinks the timeline and clear of centered trim/transition
/// chrome.
class ClipKeyframeMarkers extends StatelessWidget {
  /// Creates the marker strip.
  const new({
    required this.timesUs,
    required this.clipDurationUs,
    required this.scale,
    this.leadInUs = 0,
    super.key,
  });

  /// Clip-relative keyframe times in microseconds.
  final List<int> timesUs;

  /// Current displayed clip duration in microseconds.
  final int clipDurationUs;

  /// Current timeline zoom scale.
  final TimelineScale scale;

  /// Leading clip µs tucked behind an incoming transition overlap.
  final int leadInUs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = AccentGradient.of(context);
    return IgnorePointer(
      child: CustomPaint(
        painter: _ClipKeyframeMarkersPainter(
          timesUs: timesUs,
          clipDurationUs: clipDurationUs,
          scale: scale,
          leadInUs: leadInUs,
          borderColor: scheme.onSurface,
          shadowColor: scheme.scrim,
          gradient: gradient,
        ),
      ),
    );
  }
}

class _ClipKeyframeMarkersPainter extends CustomPainter {
  new({
    required this.timesUs,
    required this.clipDurationUs,
    required this.scale,
    required this.leadInUs,
    required this.borderColor,
    required this.shadowColor,
    required this.gradient,
  });

  final List<int> timesUs;
  final int clipDurationUs;
  final TimelineScale scale;
  final int leadInUs;
  final Color borderColor;
  final Color shadowColor;
  final AccentGradient gradient;

  static const double _radius = 4;
  static const double _topOffset = 9;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || timesUs.isEmpty) return;
    const cy = _topOffset;
    final minX = math.min(size.width / 2, _radius + 3);
    final maxX = math.max(minX, size.width - _radius - 3);
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = shadowColor.withValues(alpha: 0.65);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = borderColor;

    for (final t in timesUs) {
      if (t < 0 || t > clipDurationUs) continue;
      final rawX = scale.toPx(t - leadInUs) - TimelineMetrics.clipGap / 2;
      final cx = rawX.clamp(minX, maxX);
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: _radius);
      final diamond = Path()
        ..moveTo(cx, cy - _radius)
        ..lineTo(cx + _radius, cy)
        ..lineTo(cx, cy + _radius)
        ..lineTo(cx - _radius, cy)
        ..close();
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = gradient.linear.createShader(rect);
      canvas
        ..drawPath(diamond, shadowPaint)
        ..drawPath(diamond, fillPaint)
        ..drawPath(diamond, strokePaint);
    }
  }

  @override
  bool shouldRepaint(_ClipKeyframeMarkersPainter old) =>
      old.timesUs != timesUs ||
      old.clipDurationUs != clipDurationUs ||
      old.scale != scale ||
      old.leadInUs != leadInUs ||
      old.borderColor != borderColor ||
      old.shadowColor != shadowColor ||
      old.gradient != gradient;
}

/// Thumbnail tiles of a clip, built only near the visible part of the
/// timeline (long clips at high zoom would otherwise need thousands).
class ThumbnailStrip extends ConsumerStatefulWidget {
  /// Creates the strip.
  const new({
    required this.clip,
    required this.scale,
    required this.contentLeft,
    required this.viewport,
    required this.scroll,
    this.leadInUs = 0,
    this.visibleDurationUs,
    super.key,
  });

  /// The clip.
  final Clip clip;

  /// Current zoom.
  final TimelineScale scale;

  /// The clip's left edge inside the scroll content.
  final double contentLeft;

  /// Visible width of the timeline.
  final double viewport;

  /// The timeline's scroll position.
  final ScrollController scroll;

  /// Leading clip µs tucked behind an incoming transition overlap.
  final int leadInUs;

  /// Visible slot duration in µs (defaults to `clip.durationUs`).
  final int? visibleDurationUs;

  @override
  ConsumerState<ThumbnailStrip> createState() => _ThumbnailStripState();
}

class _ThumbnailStripState extends ConsumerState<ThumbnailStrip> {
  // Visible tile range; local because it changes with scrolling only.
  (int, int) _range = (0, -1);

  /// Thumbnails are sampled on this grid so zooming reuses cached frames.
  static const int _timeGridUs = 250000;

  double get _tileWidth {
    final media = widget.clip.media;
    final aspect = media.displayHeight > 0
        ? media.displayWidth / media.displayHeight
        : 1.0;
    return (TimelineMetrics.mainHeight * aspect).clamp(34.0, 107.0);
  }

  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_update);
    _range = _compute();
    _requestVisible();
  }

  @override
  void didUpdateWidget(ThumbnailStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scroll != widget.scroll) {
      oldWidget.scroll.removeListener(_update);
      widget.scroll.addListener(_update);
    }
    final next = _compute();
    final changed =
        next != _range ||
        oldWidget.clip != widget.clip ||
        oldWidget.scale != widget.scale ||
        oldWidget.leadInUs != widget.leadInUs ||
        oldWidget.visibleDurationUs != widget.visibleDurationUs;
    _range = next;
    if (changed) _requestVisible();
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_update);
    super.dispose();
  }

  (int, int) _compute() {
    final offset = widget.scroll.hasClients ? widget.scroll.offset : 0.0;
    final width = widget.scale.toPx(
      widget.visibleDurationUs ?? widget.clip.durationUs,
    );
    final tile = _tileWidth;
    final count = (width / tile).ceil();
    // One extra viewport on each side so tiles are ready before they show.
    final from = offset - widget.viewport - widget.contentLeft;
    final to = offset + 2 * widget.viewport - widget.contentLeft;
    final first = (from / tile).floor().clamp(0, count);
    final last = ((to / tile).ceil() - 1).clamp(-1, count - 1);
    return (first, last);
  }

  void _update() {
    final next = _compute();
    if (next != _range) {
      setState(() => _range = next);
      _requestVisible();
    }
  }

  /// Requests all visible tile timestamps in a single batched engine call.
  void _requestVisible() {
    final (first, last) = _range;
    if (last < first) return;
    final clip = widget.clip;
    final isImage = clip.media.kind == MediaKind.image;
    final tile = _tileWidth;
    final times = isImage
        ? const [0]
        : <int>{
            for (var i = first; i <= last; i++) _sourceTimeAt((i + 0.5) * tile),
          };
    unawaited(
      Future.microtask(() {
        if (!mounted) return;
        unawaited(
          ref
              .read(
                clipThumbnailsProvider(clip.media.uri, _Tile.heightPx).notifier,
              )
              .ensure(times),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final tile = _tileWidth;
    final isImage = clip.media.kind == MediaKind.image;
    final (first, last) = _range;
    return Stack(
      children: [
        for (var i = first; i <= last; i++)
          Positioned(
            left: i * tile,
            top: 0,
            width: tile,
            height: TimelineMetrics.mainHeight,
            child: _Tile(
              uri: clip.media.uri,
              timeUs: isImage ? 0 : _sourceTimeAt((i + 0.5) * tile),
            ),
          ),
      ],
    );
  }

  /// Source time shown at [px] into the clip slot, on the sampling grid.
  int _sourceTimeAt(double px) {
    final clip = widget.clip;
    final timelineUs = widget.leadInUs + widget.scale.toUs(px);
    final source = clip.sourceInUs + clip.sourceOffsetAt(timelineUs);
    final clamped = source.clamp(clip.sourceInUs, clip.sourceOutUs - 1);
    return (clamped ~/ _timeGridUs) * _timeGridUs;
  }
}

class _Tile extends ConsumerWidget {
  const new({required this.uri, required this.timeUs});

  final String uri;
  final int timeUs;

  /// Tiles are 60 dp tall; 2× for sharp pixels.
  static const int heightPx = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(
      clipThumbnailsProvider(uri, heightPx).select((m) => m[timeUs]),
    );
    if (path == null) return const SizedBox.shrink();
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      cacheHeight: heightPx,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

/// A rounded lane clip (Clipcraft Timeline T1 pill): icon, label and
/// optional trailing content such as a waveform.
class LanePill extends StatelessWidget {
  /// Creates a pill.
  const new({
    required this.color,
    required this.icon,
    required this.label,
    required this.selected,
    required this.dimmed,
    required this.onTap,
    this.lifted = false,
    this.onLongPressStart,
    this.onLongPressMove,
    this.onLongPressEnd,
    this.trailing,
    this.overlay,
    super.key,
  });

  /// Lane color.
  final Color color;

  /// Small glyph before the label.
  final AppIcons icon;

  /// Clip name.
  final String label;

  /// Selected: darker fill, outline and handles in the lane color.
  final bool selected;

  /// Dimmed while a main-track clip is selected.
  final bool dimmed;

  /// Whether the pill is lifted for moving (drawn raised with shadow).
  final bool lifted;

  /// Selects / deselects the clip.
  final VoidCallback onTap;

  /// Long press: lift the pill to move it.
  final VoidCallback? onLongPressStart;

  /// The lifted pill moved by `offsetFromOrigin` px.
  final ValueChanged<Offset>? onLongPressMove;

  /// The lifted pill was dropped.
  final VoidCallback? onLongPressEnd;

  /// Content after the label (e.g. a waveform).
  final Widget? trailing;

  /// Optional overlay painted across the pill (e.g. keyframe diamond markers).
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(
      Radius.circular(TimelineMetrics.laneHeight / 2),
    );
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation.weight(700)],
      color: scheme.onSurface,
    );
    final move = onLongPressMove;
    final body = Opacity(
      opacity: dimmed ? TimelineColors.dimmedLane : 1,
      child: Stack(
        clipBehavior: ui.Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: selected
                      ? TimelineColors.selectedPillFill
                      : TimelineColors.unselectedPillFill,
                ),
                borderRadius: radius,
                border: Border.all(
                  color: selected ? color : color.withValues(alpha: 0.45),
                  width: selected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Drop label / waveform on narrow pills so short or
                    // zoomed-out clips never trigger a Row overflow.
                    final showLabel = constraints.maxWidth >= 44;
                    final showTrailing =
                        trailing != null && constraints.maxWidth >= 72;
                    return Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: showLabel ? 10 : 0,
                        end: showLabel ? 4 : 0,
                      ),
                      child: Row(
                        mainAxisAlignment: showLabel
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          AppIcon(icon, size: 10, color: scheme.onSurface),
                          if (showLabel) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textStyle,
                              ),
                            ),
                          ],
                          if (trailing case final t? when showTrailing) ...[
                            const SizedBox(width: 8),
                            Expanded(child: t),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (overlay case final o?) Positioned.fill(child: o),
          if (selected)
            for (final left in [true, false])
              Positioned(
                left: left ? -8 : null,
                right: left ? null : -8,
                top: TimelineMetrics.laneHeight / 2 - 7,
                child: _Handle(color: color),
              ),
        ],
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: onLongPressStart == null
            ? null
            : (_) => onLongPressStart!(),
        onLongPressMoveUpdate: move == null
            ? null
            : (d) => move(d.offsetFromOrigin),
        onLongPressEnd: onLongPressEnd == null
            ? null
            : (_) => onLongPressEnd!(),
        onLongPressCancel: onLongPressEnd,
        child: lifted
            ? Transform.translate(
                offset: const Offset(0, -4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.6),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Opacity(opacity: 0.9, child: body),
                ),
              )
            : body,
      ),
    );
  }
}

/// Slices [data]'s peaks to the clip's `[sourceInUs, sourceOutUs)` range.
List<int> sliceWaveformPeaks(
  WaveformData data,
  int sourceInUs,
  int sourceOutUs,
) {
  final peaks = data.peaks;
  if (peaks.isEmpty || data.peaksPerSecond <= 0 || sourceOutUs <= sourceInUs) {
    return peaks;
  }
  final start = (sourceInUs * data.peaksPerSecond / Micros.perSecond)
      .floor()
      .clamp(0, peaks.length);
  final end = (sourceOutUs * data.peaksPerSecond / Micros.perSecond)
      .ceil()
      .clamp(start, peaks.length);
  return peaks.sublist(start, end);
}

/// White waveform bars of an audio clip (kit "Golden horses" lane).
class _Waveform extends ConsumerWidget {
  const new({
    required this.uri,
    required this.sourceInUs,
    required this.sourceOutUs,
  });

  final String uri;
  final int sourceInUs;
  final int sourceOutUs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clipWaveformProvider(uri)).value;
    if (data == null) return const SizedBox.shrink();
    final peaks = sliceWaveformPeaks(data, sourceInUs, sourceOutUs);
    if (peaks.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: _WaveformPainter(
        peaks: peaks,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  new({required this.peaks, required this.color});

  final List<int> peaks;
  final Color color;

  static const double _barWidth = 2;
  static const double _barGap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = _barWidth
      ..strokeCap = StrokeCap.round;
    final bars = (size.width / (_barWidth + _barGap)).floor();
    final mid = size.height / 2;
    final maxHalf = size.height * 0.3;
    for (var i = 0; i < bars; i++) {
      final peak = peaks[(i * peaks.length / bars).floor()] / 255;
      final half = math.max(1, peak * maxHalf);
      final x = i * (_barWidth + _barGap) + _barWidth / 2;
      canvas.drawLine(Offset(x, mid - half), Offset(x, mid + half), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      !identical(old.peaks, peaks) || old.color != color;
}
