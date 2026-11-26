import 'dart:async';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart'
    show SpeedLimits;
import 'package:cleancut/features/projects/domain/model/speed_curve.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/curve_widgets.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/panel_widgets.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/speed_scale.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/tool_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The kit's "Speed" panel with a "Normal | Curve" tab row (kit "Filters"
/// tabs) and a keep-pitch switch for video.
///
/// Normal: a value bubble riding over a tick ruler with the labelled
/// speeds underneath. Dragging updates the bubble live and reports the
/// speed once, on release ([onChanged]); tapping the ruler or a label jumps
/// there; tapping the bubble types an exact value; Reset returns to 1×.
/// Ticks at the labels snap with a haptic click.
///
/// Curve: preset tiles (None, Custom, Montage, Hero, Bullet, Flash in/out);
/// tapping the selected one opens the [CurveEditor]. Reset restores the
/// preset's shape.
class SpeedPanel extends StatefulWidget {
  /// Creates the panel.
  const new({
    required this.speed,
    required this.keepPitch,
    required this.onChanged,
    required this.onClose,
    this.onKeepPitchChanged,
    this.curve,
    this.onCurveChanged,
    this.playheadProgress,
    super.key,
  });

  /// The clip's current speed.
  final double speed;

  /// Whether the clip's audio keeps its pitch.
  final bool keepPitch;

  /// Called with a new speed when a drag ends, on a tap, a typed value or
  /// Reset.
  final ValueChanged<double> onChanged;

  /// Called when keep pitch is toggled; null hides the switch (stills).
  final ValueChanged<bool>? onKeepPitchChanged;

  /// Closes the panel.
  final VoidCallback onClose;

  /// The clip's speed curve, if any.
  final SpeedCurve? curve;

  /// Called with a new curve (null = constant speed); null hides the
  /// Curve tab.
  final ValueChanged<SpeedCurve?>? onCurveChanged;

  /// Where the playhead is in the clip (0–1 of its source), or null when
  /// it is outside; the curve editor adds points there.
  final double? playheadProgress;

  /// Key of the bubble + ruler area (for tests and integration drivers).
  static const rulerKey = Key('speedPanelRuler');

  /// Distance of the ruler from the panel's left and right edges.
  static const double rulerInset = 44;

  @override
  State<SpeedPanel> createState() => _SpeedPanelState();
}

class _SpeedPanelState extends State<SpeedPanel> {
  /// Speed shown while a finger is down (local, ephemeral gesture state).
  double? _dragSpeed;

  /// Inset of the ruler from the panel edges (kit: labels from x≈40).
  static const double _inset = SpeedPanel.rulerInset;

  double get _speed => _dragSpeed ?? widget.speed;

  /// Open tab (local UI state): starts on Curve when the clip has one.
  late bool _curveTab = widget.curve != null && widget.onCurveChanged != null;

  /// Whether the Curve tab shows the editor instead of the presets.
  bool _editing = false;

  @override
  void didUpdateWidget(SpeedPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The curve went away (None, undo): back to the presets.
    if (widget.curve == null) _editing = false;
  }

  void _selectPreset(SpeedCurvePreset? preset) {
    setState(() => _editing = false);
    widget.onCurveChanged?.call(preset?.curve);
  }

  double _speedAtDx(double dx, double width) =>
      SpeedScale.speedAt((dx - _inset) / (width - 2 * _inset));

  void _preview(double speed) {
    if (speed == _speed) return;
    if (SpeedScale.markIndexOf(speed) != null) {
      unawaited(HapticFeedback.selectionClick());
    }
    setState(() => _dragSpeed = speed);
  }

  void _commit(double speed) {
    setState(() => _dragSpeed = null);
    if (speed != widget.speed || widget.curve != null) {
      widget.onChanged(speed);
    }
  }

  Future<void> _type() async {
    final l10n = AppLocalizations.of(context);
    final speed = widget.speed;
    final typed = await showValueDialog(
      context,
      title: l10n.speedTypeTitle,
      label: l10n.speedTypeLabel,
      invalidText: l10n.speedTypeInvalid,
      initialText: speed == speed.roundToDouble()
          ? speed.toStringAsFixed(0)
          : speed.toString(),
      parse: (text) {
        final parsed = double.tryParse(text);
        if (parsed == null || !SpeedLimits.contains(parsed)) return null;
        return SpeedScale.round(parsed);
      },
    );
    if (typed != null && mounted) _commit(typed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onKeepPitch = widget.onKeepPitchChanged;
    final onCurve = widget.onCurveChanged;
    final curve = widget.curve;
    final curveTab = _curveTab && onCurve != null;
    final VoidCallback? reset;
    if (curveTab) {
      reset = curve == null || curve == curve.preset.curve
          ? null
          : () => onCurve(curve.preset.curve);
    } else {
      reset =
          widget.speed == SpeedScale.normal &&
              widget.curve == null &&
              _dragSpeed == null
          ? null
          : () => _commit(SpeedScale.normal);
    }
    return ToolPanel(
      title: l10n.toolSpeed,
      onClose: widget.onClose,
      onReset: reset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onCurve != null)
            PanelTabs(
              labels: [l10n.speedTabNormal, l10n.speedTabCurve],
              selected: curveTab ? 1 : 0,
              onSelect: (i) => setState(() {
                _curveTab = i == 1;
                _editing = false;
              }),
            ),
          if (!curveTab)
            _normal(context)
          else if (_editing && curve != null)
            CurveEditor(
              curve: curve,
              playheadProgress: widget.playheadProgress,
              onChanged: onCurve,
              onBack: () => setState(() => _editing = false),
            )
          else
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 12),
              child: CurvePresetRow(
                curve: curve,
                onSelect: _selectPreset,
                onEdit: () => setState(() => _editing = true),
              ),
            ),
          if (onKeepPitch != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(34, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.speedKeepPitch,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Switch(value: widget.keepPitch, onChanged: onKeepPitch),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// The Normal tab: value bubble, tick ruler and labels (kit "Speed").
  Widget _normal(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final speed = _speed;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final track = width - 2 * _inset;
        double xOf(double position) => _inset + position * track;
        final bubbleX = xOf(SpeedScale.positionOf(speed));
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // Bubble + ruler: drag or tap anywhere on it.
            Semantics(
              slider: true,
              label: l10n.toolSpeed,
              value: l10n.speedValue(speed),
              hint: l10n.speedTypeHint,
              onTap: () => unawaited(_type()),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (d) =>
                    _preview(_speedAtDx(d.localPosition.dx, width)),
                onHorizontalDragUpdate: (d) =>
                    _preview(_speedAtDx(d.localPosition.dx, width)),
                onHorizontalDragEnd: (_) => _commit(_speed),
                onHorizontalDragCancel: () => setState(() => _dragSpeed = null),
                onTapUp: (d) {
                  // The bubble types an exact value; the rest jumps.
                  if ((d.localPosition.dx - bubbleX).abs() <= 24 &&
                      d.localPosition.dy <= 48) {
                    unawaited(_type());
                  } else {
                    _commit(_speedAtDx(d.localPosition.dx, width));
                  }
                },
                child: SizedBox(
                  key: SpeedPanel.rulerKey,
                  height: 72,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        top: 50,
                        child: CustomPaint(
                          painter: _RulerPainter(
                            inset: _inset,
                            color: scheme.onSurface,
                            markerX: bubbleX,
                          ),
                        ),
                      ),
                      Positioned(
                        left: bubbleX - 24,
                        top: 10,
                        width: 48,
                        child: Center(
                          child: ValueBubble(text: l10n.speedValue(speed)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final (i, mark) in SpeedScale.marks.indexed)
                    Positioned(
                      left:
                          xOf(SpeedScale.markPosition(i)) -
                          track / (SpeedScale.marks.length - 1) / 2,
                      top: 0,
                      bottom: 0,
                      width: track / (SpeedScale.marks.length - 1),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _commit(mark),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: PanelLabel(
                                text: l10n.speedValue(mark),
                                selected: mark == speed,
                                fontSize: width < 360 ? 12 : 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Ticks: a tall one at every label, three short ones between, and a
/// taller marker under the value bubble (kit "Speed").
class _RulerPainter extends CustomPainter {
  new({required this.inset, required this.color, required this.markerX});

  final double inset;
  final Color color;

  /// Where the current value is (under the bubble).
  final double markerX;

  /// Height of the current-value marker tick.
  static const double markerHeight = 16;

  static const int _minorPerSegment = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1.5;
    final segments = SpeedScale.marks.length - 1;
    final steps = segments * _minorPerSegment;
    final track = size.width - 2 * inset;
    for (var i = 0; i <= steps; i++) {
      final major = i % _minorPerSegment == 0;
      final x = inset + track * i / steps;
      final h = major ? 8.0 : 4.0;
      paint.color = color.withValues(alpha: major ? 1 : 0.6);
      canvas.drawLine(Offset(x, -h / 2), Offset(x, h / 2), paint);
    }
    canvas.drawLine(
      Offset(markerX, -markerHeight / 2),
      Offset(markerX, markerHeight / 2),
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.inset != inset || old.color != color || old.markerX != markerX;
}
