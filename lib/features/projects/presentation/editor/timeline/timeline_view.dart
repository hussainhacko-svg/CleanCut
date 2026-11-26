import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui show Clip;

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/timeline_colors.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/domain/commands/clip_commands.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:cleancut/features/projects/domain/timeline/reorder.dart';
import 'package:cleancut/features/projects/domain/timeline/ruler.dart';
import 'package:cleancut/features/projects/domain/timeline/snapping.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_scale.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_selection.dart';
import 'package:cleancut/features/projects/presentation/editor/editor_state.dart';
import 'package:cleancut/features/projects/presentation/playback/playback_controller.dart';
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

  late final MainStripGestures _gestures = MainStripGestures(
    onTrimStart: _onTrimStart,
    onTrimUpdate: _onTrimUpdate,
    onTrimEnd: _onTrimEnd,
    onReorderStart: _onReorderStart,
    onReorderUpdate: _onReorderUpdate,
    onReorderEnd: _onReorderEnd,
  );

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
    final clips = widget.project.mainTrack.clips;
    final index = clips.indexWhere((c) => c.id == reorder.clipId);
    if (index < 0) return;
    final center =
        widget.project.mainTrack.startOf(index) +
        clips[index].durationUs ~/ 2 +
        _scale.toUs(dx);
    final target = reorderTargetIndex(
      [for (final c in clips) c.durationUs],
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
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // The playhead: fixed in the middle, over the lanes.
                // Spans the lanes only, as in the kit, and follows the
                // vertical lane scroll (only this line rebuilds).
                ListenableBuilder(
                  listenable: _laneScroll,
                  builder: (context, line) {
                    final dy = _laneScroll.hasClients
                        ? _laneScroll.offset
                        : 0.0;
                    final top = math.max(0, playheadTop - dy).toDouble();
                    final bottom = math.min(lanesBottom - dy, viewportHeight);
                    return Positioned(
                      left: pad - 1,
                      top: top,
                      height: math.max(0, bottom - top).toDouble(),
                      child: line!,
                    );
                  },
                  child: IgnorePointer(
                    key: TimelineView.playheadKey,
                    child: Container(
                      width: 2,
                      color: Theme.of(context).colorScheme.onSurface,
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
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
            dotColor: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    ];

    // Overlay lanes.
    for (final (i, track) in project.overlayTracks.indexed) {
      for (final item in track.items) {
        final sel = OverlaySelection(trackId: track.id, clipId: item.clip.id);
        children.add(
          _pill(
            top: layout.overlayTops[i],
            startUs: item.range.startUs,
            endUs: item.range.endUs,
            child: LanePill(
              color: colors.overlay,
              icon: AppIcons.laneOverlay,
              label: item.clip.media.displayName ?? l10n.laneOverlay,
              selected: selection == sel,
              dimmed: dimOthers,
              onTap: () => selector.toggle(sel),
            ),
          ),
        );
      }
    }

    // Main strip: back-to-back clips with transition markers between them.
    // A trimmed clip is drawn with its new range until the finger lifts;
    // a long-pressed clip follows the finger above the others.
    var start = 0;
    final clips = project.mainTrack.clips;
    final clipLefts = <double>[];
    Widget? lifted;
    final handles = <Widget>[];
    for (final (i, clip) in clips.indexed) {
      final trimming = trim?.clipId == clip.id ? trim : null;
      final shown = trimming == null
          ? clip
          : clip.copyWith(
              sourceInUs: trimming.sourceInUs,
              sourceOutUs: trimming.sourceOutUs,
            );
      // Trimming the start moves the left edge; the right edge stays until
      // release, when the main track closes the gap.
      final shownStart = trimming != null && trimming.start
          ? start + clip.durationUs - shown.durationUs
          : start;
      final end = trimming != null && !trimming.start
          ? start + shown.durationUs
          : start + clip.durationUs;
      final sel = MainClipSelection(clip.id);
      final isLifted = reorder?.clipId == clip.id;
      final left =
          _x(shownStart) +
          TimelineMetrics.clipGap / 2 +
          (isLifted ? reorder!.dx : 0);
      final width = math.max<double>(
        2,
        scale.toPx(shown.durationUs) - TimelineMetrics.clipGap,
      );
      clipLefts.add(_x(start));
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
        final clipStart = start;
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
      if (i > 0 && reorder == null) {
        // Decorative until transitions are built: a 48dp target here
        // would cover short clips and swallow their taps.
        children.add(
          Positioned(
            left: _x(start) - 11,
            top: layout.mainTop + TimelineMetrics.mainHeight / 2 - 11,
            child: const IgnorePointer(
              child: AppIcon(AppIcons.transition, size: 22),
            ),
          ),
        );
      }
      start = end;
    }
    children.addAll(handles);
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
          icon: AppIcon(AppIcons.mute, size: 19, color: scheme.onSurface),
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
    const radius = BorderRadius.all(Radius.circular(10));
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
                border: Border.all(color: scheme.onSurface, width: 2),
              ),
            ),
          ),
          for (final left in [true, false])
            Positioned(
              left: left ? -9 : null,
              right: left ? null : -9,
              top: TimelineMetrics.mainHeight / 2 - 7,
              child: _Handle(color: scheme.onSurface),
            ),
        ],
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
        oldWidget.scale != widget.scale;
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
    final width = widget.scale.toPx(widget.clip.durationUs);
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

  /// Source time shown at [px] into the clip, on the sampling grid.
  int _sourceTimeAt(double px) {
    final clip = widget.clip;
    final timelineUs = widget.scale.toUs(px);
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

/// A rounded lane clip (VCLIP pill): icon, label and optional trailing
/// content such as a waveform.
class LanePill extends StatelessWidget {
  /// Creates a pill.
  const new({
    required this.color,
    required this.icon,
    required this.label,
    required this.selected,
    required this.dimmed,
    required this.onTap,
    this.trailing,
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

  /// Selects / deselects the clip.
  final VoidCallback onTap;

  /// Content after the label (e.g. a waveform).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(18.5));
    final textStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontSize: 10, color: scheme.onSurface);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: dimmed ? TimelineColors.dimmedLane : 1,
          child: Stack(
            clipBehavior: ui.Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(
                            alpha: TimelineColors.selectedPillFill,
                          )
                        : color,
                    borderRadius: radius,
                    border: selected
                        ? Border.all(color: color, width: 2)
                        : null,
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
        ),
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
