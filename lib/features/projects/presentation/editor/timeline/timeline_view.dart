import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui show Clip;

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/timeline_colors.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:cleancut/features/projects/domain/timeline/ruler.dart';
import 'package:cleancut/features/projects/domain/timeline/snapping.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_scale.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_selection.dart';
import 'package:cleancut/features/projects/presentation/editor/editor_state.dart';
import 'package:cleancut/features/projects/presentation/playback/playback_controller.dart';
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

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView> {
  final _scroll = ScrollController();

  // Ephemeral gesture state (AGENTS.md §4 allows local widget state).
  bool _userScrolling = false;
  bool _resumeAfterScrub = false;
  int? _lastSnapUs;
  final _pointers = <int, Offset>{};
  double? _pinchStartDistance;
  TimelineScale? _pinchStartScale;

  late List<int> _snapTargets = snapTargets(widget.project);

  @override
  void didUpdateWidget(TimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project) {
      _snapTargets = snapTargets(widget.project);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
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
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // The playhead: fixed in the middle, over the lanes.
                // Spans the lanes only, as in the kit.
                Positioned(
                  left: pad - 1,
                  top: playheadTop,
                  height: math.max(
                    0,
                    math.min(lanesBottom, viewportHeight) - playheadTop,
                  ),
                  child: IgnorePointer(
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
  });

  final String projectId;
  final Project project;
  final _LaneLayout layout;
  final TimelineScale scale;
  final double pad;
  final double viewport;
  final ScrollController scroll;
  final TimelineSelection selection;

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
    var start = 0;
    final clips = project.mainTrack.clips;
    for (final (i, clip) in clips.indexed) {
      final end = start + clip.durationUs;
      final sel = MainClipSelection(clip.id);
      final left = _x(start) + TimelineMetrics.clipGap / 2;
      final width = math.max<double>(
        2,
        scale.toPx(clip.durationUs) - TimelineMetrics.clipGap,
      );
      children.add(
        Positioned(
          left: left,
          top: layout.mainTop,
          width: width,
          height: TimelineMetrics.mainHeight,
          child: MainClipView(
            clip: clip,
            scale: scale,
            contentLeft: left,
            viewport: viewport,
            scroll: scroll,
            selected: selection == sel,
            onTap: () => selector.toggle(sel),
          ),
        ),
      );
      if (i > 0) {
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

  @override
  Widget build(BuildContext context) {
    final colors = TimelineColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(10));
    return Semantics(
      button: true,
      selected: selected,
      label: clip.media.displayName,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
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
                    color: colors.selectionTint.withValues(alpha: 0.85),
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
        ),
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
    final source = clip.sourceInUs + (timelineUs * clip.speed).round();
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
