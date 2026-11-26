import 'dart:async';
import 'dart:math' as math;

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart'
    show SpeedLimits;
import 'package:cleancut/features/projects/domain/model/speed_curve.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visible name of [preset] (null = no curve).
String curvePresetLabel(AppLocalizations l10n, SpeedCurvePreset? preset) =>
    switch (preset) {
      null => l10n.curveNone,
      SpeedCurvePreset.custom => l10n.curveCustom,
      SpeedCurvePreset.montage => l10n.curveMontage,
      SpeedCurvePreset.hero => l10n.curveHero,
      SpeedCurvePreset.bullet => l10n.curveBullet,
      SpeedCurvePreset.flashIn => l10n.curveFlashIn,
      SpeedCurvePreset.flashOut => l10n.curveFlashOut,
    };

/// Speed ↔ vertical position on curve graphs: log scale, 10× at the top,
/// 1× in the middle, 0.1× at the bottom.
abstract final class CurveAxis {
  /// 0 (bottom, 0.1×) to 1 (top, 10×).
  static double heightOf(double speed) =>
      (math.log(speed.clamp(SpeedLimits.min, SpeedLimits.max)) / math.ln10 +
          1) /
      2;

  /// Inverse of [heightOf].
  static double speedAt(double height) =>
      math.pow(10, height.clamp(0.0, 1.0) * 2 - 1).toDouble();
}

/// The Curve tab's preset tiles (kit "Filters" tile row): None, Custom and
/// the ramps, each with its shape drawn. Tapping the selected curve again
/// opens the editor.
class CurvePresetRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.curve,
    required this.onSelect,
    required this.onEdit,
    super.key,
  });

  /// The clip's curve (null = constant speed).
  final SpeedCurve? curve;

  /// Called with the tapped preset (null = None).
  final ValueChanged<SpeedCurvePreset?> onSelect;

  /// Called when the selected curve is tapped again.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = curve?.preset;
    final labelHeight = MediaQuery.textScalerOf(context).scale(16) + 12;
    return SizedBox(
      height: _PresetTile._tile + 6 + labelHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 30),
        children: [
          for (final preset in <SpeedCurvePreset?>[
            null,
            ...SpeedCurvePreset.values,
          ])
            _PresetTile(
              label: curvePresetLabel(l10n, preset),
              curve: preset == null
                  ? null
                  : (preset == selected ? curve : preset.curve),
              selected: preset == selected,
              editable: preset != null && preset == selected,
              onTap: () => preset != null && preset == selected
                  ? onEdit()
                  : onSelect(preset),
            ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const new({
    required this.label,
    required this.curve,
    required this.selected,
    required this.editable,
    required this.onTap,
  });

  final String label;
  final SpeedCurve? curve;
  final bool selected;
  final bool editable;
  final VoidCallback onTap;

  static const double _tile = 70;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const radius = BorderRadius.all(Radius.circular(AppTokens.cardRadius));
    final curve = this.curve;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      hint: editable ? l10n.curveEditHint : null,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
          child: Column(
            children: [
              Container(
                width: _tile,
                height: _tile,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: radius,
                  border: Border.all(
                    color: selected ? scheme.onSurface : scheme.outline,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: curve == null
                    ? Icon(Icons.block, color: scheme.onSurfaceVariant)
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: CustomPaint(
                                painter: _MiniCurvePainter(
                                  curve: curve,
                                  color: scheme.onSurface,
                                  guide: scheme.outline,
                                ),
                              ),
                            ),
                          ),
                          if (editable)
                            PositionedDirectional(
                              end: 4,
                              bottom: 4,
                              child: Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: scheme.onSurface,
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tile-sized sketch of a curve with a faint 1× line.
class _MiniCurvePainter extends CustomPainter {
  new({required this.curve, required this.color, required this.guide});

  final SpeedCurve curve;
  final Color color;
  final Color guide;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    canvas
      ..drawLine(
        Offset(0, mid),
        Offset(size.width, mid),
        Paint()
          ..color = guide
          ..strokeWidth = 1,
      )
      ..drawPath(
        _curvePath(curve, size, samples: 32),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_MiniCurvePainter old) =>
      old.curve != curve || old.color != color || old.guide != guide;
}

Path _curvePath(SpeedCurve curve, Size size, {required int samples}) {
  final path = Path();
  for (var i = 0; i <= samples; i++) {
    final x = i / samples;
    final y = size.height * (1 - CurveAxis.heightOf(curve.speedAt(x)));
    if (i == 0) {
      path.moveTo(0, y);
    } else {
      path.lineTo(x * size.width, y);
    }
  }
  return path;
}

/// The custom curve editor: a graph of speed (0.1×–10×, log) over the
/// clip, with draggable points and a playhead line. Tap a point to select
/// it; "Add point" adds one at the playhead, "Delete point" removes the
/// selected inner point. Drags show live and report the curve once, on
/// release; dragging near 1× snaps there with a haptic tick.
class CurveEditor extends StatefulWidget {
  /// Creates the editor.
  const new({
    required this.curve,
    required this.playheadProgress,
    required this.onChanged,
    required this.onBack,
    super.key,
  });

  /// The curve being edited.
  final SpeedCurve curve;

  /// Where the playhead is in the clip (0–1), or null when outside it.
  final double? playheadProgress;

  /// Called with the edited curve (same preset) after each change.
  final ValueChanged<SpeedCurve> onChanged;

  /// Returns to the preset tiles.
  final VoidCallback onBack;

  /// Key of the graph (for tests and integration drivers).
  static const graphKey = Key('curveEditorGraph');

  /// Horizontal inset of the graph (room for the speed labels).
  static const double graphInset = 44;

  /// Height of the graph.
  static const double graphHeight = 150;

  @override
  State<CurveEditor> createState() => _CurveEditorState();
}

class _CurveEditorState extends State<CurveEditor> {
  /// Points while a finger is down (local, ephemeral gesture state).
  List<CurvePoint>? _dragPoints;
  int? _dragIndex;
  int? _selected;
  bool _snapped = false;

  static const double _inset = CurveEditor.graphInset;
  static const double _height = CurveEditor.graphHeight;

  /// Vertical padding inside the graph so end points stay touchable.
  static const double _pad = 12;

  List<CurvePoint> get _points => _dragPoints ?? widget.curve.points;

  /// The graph's box, to turn global drag positions into graph positions.
  final GlobalKey _graphBox = GlobalKey();

  @override
  void didUpdateWidget(CurveEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.curve != widget.curve) {
      _dragPoints = null;
      _dragIndex = null;
      if ((_selected ?? 0) >= widget.curve.points.length) {
        _selected = null;
      }
    }
  }

  Offset _toPx(CurvePoint p, double width) => Offset(
    _inset + p.x * (width - 2 * _inset),
    _pad + (1 - CurveAxis.heightOf(p.speed)) * (_height - 2 * _pad),
  );

  int? _hit(Offset local, double width) {
    int? best;
    var bestDistance = 24.0;
    for (final (i, p) in _points.indexed) {
      final d = (_toPx(p, width) - local).distance;
      if (d <= bestDistance) {
        best = i;
        bestDistance = d;
      }
    }
    return best;
  }

  void _dragTo(Offset local, double width) {
    final i = _dragIndex;
    final points = _dragPoints;
    if (i == null || points == null) return;
    final height = 1 - (local.dy - _pad) / (_height - 2 * _pad);
    var speed = CurveAxis.speedAt(height);
    final nearOne = (CurveAxis.heightOf(speed) - 0.5).abs() < 0.03;
    if (nearOne) speed = 1;
    if (nearOne && !_snapped) unawaited(HapticFeedback.selectionClick());
    _snapped = nearOne;
    speed = speed.clamp(SpeedLimits.min, SpeedLimits.max);
    var x = points[i].x;
    if (i > 0 && i < points.length - 1) {
      final lo = points[i - 1].x + SpeedCurve.minGap;
      final hi = points[i + 1].x - SpeedCurve.minGap;
      if (lo < hi) {
        x = ((local.dx - _inset) / (width - 2 * _inset)).clamp(lo, hi);
      }
    }
    setState(() {
      _dragPoints = [...points]..[i] = CurvePoint(x: x, speed: speed);
    });
  }

  /// [global] in the graph's coordinates.
  Offset _toGraph(Offset global) {
    final box = _graphBox.currentContext?.findRenderObject();
    return box is RenderBox ? box.globalToLocal(global) : global;
  }

  /// Index of the point under [global], if any.
  int? _graphHit(Offset global, double width) => _hit(_toGraph(global), width);

  /// Starts dragging (and selects) the point under [global].
  void _startDrag(Offset global, double width) {
    final i = _graphHit(global, width);
    if (i == null) return;
    setState(() {
      _dragIndex = i;
      _selected = i;
      _dragPoints = [...widget.curve.points];
      _snapped = false;
    });
  }

  void _endDrag() {
    final points = _dragPoints;
    if (points == null && _dragIndex == null) return;
    setState(() {
      _dragPoints = null;
      _dragIndex = null;
    });
    // A tap on a point only selects it: no change, no undo step.
    if (points != null && !listEquals(points, widget.curve.points)) {
      widget.onChanged(widget.curve.copyWith(points: points));
    }
  }

  void _cancelDrag() {
    if (_dragPoints == null && _dragIndex == null) return;
    setState(() {
      _dragPoints = null;
      _dragIndex = null;
    });
  }

  /// Index where a point at the playhead could be added, or null.
  int? get _addIndex {
    final p = widget.playheadProgress;
    final points = widget.curve.points;
    if (p == null || points.length >= SpeedCurve.maxPoints) return null;
    for (var i = 1; i < points.length; i++) {
      if (p < points[i].x) {
        final fits =
            p - points[i - 1].x >= SpeedCurve.minGap &&
            points[i].x - p >= SpeedCurve.minGap;
        return fits ? i : null;
      }
    }
    return null;
  }

  void _addPoint() {
    final i = _addIndex;
    final p = widget.playheadProgress;
    if (i == null || p == null) return;
    final curve = widget.curve;
    final point = CurvePoint(x: p, speed: curve.speedAt(p));
    setState(() => _selected = i);
    widget.onChanged(
      curve.copyWith(points: [...curve.points]..insert(i, point)),
    );
  }

  void _deleteSelected() {
    final i = _selected;
    final curve = widget.curve;
    if (i == null || i == 0 || i == curve.points.length - 1) return;
    setState(() => _selected = null);
    widget.onChanged(curve.copyWith(points: [...curve.points]..removeAt(i)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = _selected;
    final canDelete =
        selected != null &&
        selected > 0 &&
        selected < widget.curve.points.length - 1;
    final shown = widget.curve.copyWith(points: _points);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Semantics(
              label: l10n.curveGraph,
              // A finger on a point claims the gesture at once, so the
              // panel's scroll view (on short screens) can't steal a
              // vertical drag; touches that miss a point still scroll.
              child: RawGestureDetector(
                key: CurveEditor.graphKey,
                behavior: HitTestBehavior.opaque,
                gestures: {
                  _PointDragRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        _PointDragRecognizer
                      >(
                        () => _PointDragRecognizer(
                          hitsPoint: (global) =>
                              _graphHit(global, width) != null,
                        ),
                        (r) => r
                          ..hitsPoint = ((global) =>
                              _graphHit(global, width) != null)
                          ..onStart = ((global) => _startDrag(global, width))
                          ..onUpdate = ((global) =>
                              _dragTo(_toGraph(global), width))
                          ..onEnd = _endDrag
                          ..onCancel = _cancelDrag,
                      ),
                  TapGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        TapGestureRecognizer
                      >(
                        TapGestureRecognizer.new,
                        // A tap off the points clears the selection.
                        (r) =>
                            r.onTapUp = (_) => setState(() => _selected = null),
                      ),
                },
                child: SizedBox(
                  key: _graphBox,
                  height: _height,
                  child: CustomPaint(
                    painter: _GraphPainter(
                      curve: shown,
                      selected: selected,
                      playhead: widget.playheadProgress,
                      inset: _inset,
                      pad: _pad,
                      line: scheme.primary,
                      point: scheme.onSurface,
                      guide: scheme.outline,
                      label: theme.textTheme.labelSmall!.copyWith(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                      labels: [
                        l10n.speedValue(10),
                        l10n.speedValue(1),
                        l10n.speedValue(0.1),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 0),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.chevron_left, size: 18),
                label: Text(l10n.curveBackToPresets),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onSurfaceVariant,
                  minimumSize: const Size(48, 48),
                ),
              ),
              const Spacer(),
              if (canDelete)
                OutlinedButton.icon(
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.remove, size: 18),
                  label: Text(l10n.curveDeletePoint),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onSurface,
                    minimumSize: const Size(48, 48),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _addIndex == null ? null : _addPoint,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.curveAddPoint),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onSurface,
                    minimumSize: const Size(48, 48),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Drags a curve point. Unlike the standard drag recognizers it claims
/// the gesture as soon as a finger lands on a point (before any movement),
/// so a surrounding scroll view never takes a vertical point drag. Touches
/// elsewhere are not tracked at all.
final class _PointDragRecognizer extends OneSequenceGestureRecognizer {
  new({required this.hitsPoint});

  /// Whether a finger at this global position is on a point.
  bool Function(Offset global) hitsPoint;

  ValueChanged<Offset>? onStart;
  ValueChanged<Offset>? onUpdate;
  VoidCallback? onEnd;
  VoidCallback? onCancel;

  bool _active = false;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      !_active && hitsPoint(event.position) && super.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _active = true;
    resolve(GestureDisposition.accepted);
    onStart?.call(event.position);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      onUpdate?.call(event.position);
    } else if (event is PointerUpEvent) {
      _finish(commit: true);
      stopTrackingPointer(event.pointer);
    } else if (event is PointerCancelEvent) {
      _finish(commit: false);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    _finish(commit: false);
    super.rejectGesture(pointer);
  }

  void _finish({required bool commit}) {
    if (!_active) return;
    _active = false;
    (commit ? onEnd : onCancel)?.call();
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'curve point drag';
}

class _GraphPainter extends CustomPainter {
  new({
    required this.curve,
    required this.selected,
    required this.playhead,
    required this.inset,
    required this.pad,
    required this.line,
    required this.point,
    required this.guide,
    required this.label,
    required this.labels,
  });

  final SpeedCurve curve;
  final int? selected;
  final double? playhead;
  final double inset;
  final double pad;
  final Color line;
  final Color point;
  final Color guide;
  final TextStyle label;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      inset,
      pad,
      size.width - inset,
      size.height - pad,
    );
    final guidePaint = Paint()
      ..color = guide
      ..strokeWidth = 1;
    // 10×, 1× and 0.1× guides with their labels on the left.
    for (final (i, height) in [1.0, 0.5, 0.0].indexed) {
      final y = plot.bottom - height * plot.height;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), guidePaint);
      final text = TextPainter(
        text: TextSpan(text: labels[i], style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset(plot.left - text.width - 6, y - text.height / 2),
      );
    }
    canvas
      ..save()
      ..translate(plot.left, plot.top)
      ..drawPath(
        _curvePath(curve, plot.size, samples: 96),
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      )
      ..restore();
    if (playhead case final p?) {
      final x = plot.left + p * plot.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = point
          ..strokeWidth = 2,
      );
    }
    for (final (i, cp) in curve.points.indexed) {
      final c = Offset(
        plot.left + cp.x * plot.width,
        plot.bottom - CurveAxis.heightOf(cp.speed) * plot.height,
      );
      final isSelected = i == selected;
      canvas
        ..drawCircle(c, isSelected ? 8 : 6, Paint()..color = point)
        ..drawCircle(
          c,
          isSelected ? 5 : 3.5,
          Paint()..color = isSelected ? line : guide,
        );
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.curve != curve ||
      old.selected != selected ||
      old.playhead != playhead ||
      old.inset != inset ||
      old.line != line ||
      old.point != point ||
      old.guide != guide ||
      old.label != label;
}
