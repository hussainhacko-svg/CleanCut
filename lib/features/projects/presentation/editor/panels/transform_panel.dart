import 'dart:async';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/crop_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/panel_widgets.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/tool_panel.dart';
import 'package:flutter/material.dart' hide TransformProperty;

/// Non-linear mapping between slider position (`0..1`) and clip scale
/// (`5%..1000%`), placing `100%` (1.0) right in the middle at `0.5`.
abstract final class TransformScale {
  /// Evenly spaced stops on the slider; `1.0` sits at index 3 (position 0.5).
  static const List<double> marks = [0.05, 0.25, 0.5, 1, 2, 5, 10];

  /// Normalized slider position of `1.0` (100%).
  static const double defaultPosition = 0.5;

  /// Slider position (`0..1`) for [scale].
  static double positionOf(double scale) {
    if (!scale.isFinite) return defaultPosition;
    final clamped = scale.clamp(marks.first, marks.last);
    final segments = marks.length - 1;
    for (var i = 0; i < segments; i++) {
      final a = marks[i];
      final b = marks[i + 1];
      if (clamped <= b) {
        final t = (clamped - a) / (b - a);
        return (i + t) / segments;
      }
    }
    return 1;
  }

  /// Scale value for slider [position] in `[0, 1]`, rounded to whole percent
  /// (`0.01`).
  static double scaleAt(double position) {
    if (!position.isFinite) return 1;
    final p = position.clamp(0.0, 1.0);
    final segments = marks.length - 1;
    final scaled = p * segments;
    final i = scaled.floor().clamp(0, segments - 1);
    final t = scaled - i;
    final raw = marks[i] + (marks[i + 1] - marks[i]) * t;
    final rounded = (raw * 100).roundToDouble() / 100;
    return TransformLimits.clampScale(rounded);
  }
}

/// Tabs of [TransformPanel].
enum TransformTab {
  /// Fit / Fill / Stretch.
  fill,

  /// X, Y, Scale, Rotation.
  position,

  /// Opacity.
  opacity,

  /// Border width, corner radius and color.
  border,
}

/// Phase 5 Transform panel: `Fill | Position | Opacity | Border` tabs.
///
/// Reset restores only the currently open tab's properties in one undo step.
class TransformPanel extends StatefulWidget {
  /// Creates the panel.
  const new({
    required this.fitMode,
    required this.position,
    required this.scale,
    required this.rotation,
    required this.opacity,
    required this.border,
    required this.onFitMode,
    required this.onTransformDrag,
    required this.onTransformDragEnd,
    required this.onTransformSet,
    required this.onBorderDrag,
    required this.onBorderDragEnd,
    required this.onBorderSet,
    required this.onClose,
    this.initialTab = TransformTab.fill,
    this.animatedProperties = const {},
    this.activeKeyframes = const {},
    this.onToggleKeyframe,
    super.key,
  });

  /// Current fit mode.
  final FitMode fitMode;

  /// Current center offset at the playhead.
  final Vec2 position;

  /// Current scale factor at the playhead.
  final double scale;

  /// Current clockwise rotation (degrees) at the playhead.
  final double rotation;

  /// Current opacity (`0..1`) at the playhead.
  final double opacity;

  /// Current border and corner radius.
  final ClipBorder border;

  /// Tab open initially.
  final TransformTab initialTab;

  /// Properties that currently have at least one keyframe on the clip.
  final Set<TransformProperty> animatedProperties;

  /// Properties that have a keyframe at the current playhead time.
  final Set<TransformProperty> activeKeyframes;

  /// Toggles a keyframe of the given property at the playhead.
  final ValueChanged<TransformProperty>? onToggleKeyframe;

  /// Sets the fit mode (one undo step).
  final ValueChanged<FitMode> onFitMode;

  /// Live transform slider drag callback (coalescing).
  final void Function({
    Vec2? position,
    double? scale,
    double? rotation,
    double? opacity,
  })
  onTransformDrag;

  /// Ends a transform slider drag (seals undo step).
  final VoidCallback onTransformDragEnd;

  /// Discrete transform set (typed value or Reset; non-coalescing).
  final void Function({
    Vec2? position,
    double? scale,
    double? rotation,
    double? opacity,
  })
  onTransformSet;

  /// Live border slider drag callback (coalescing).
  final ValueChanged<ClipBorder> onBorderDrag;

  /// Ends a border slider drag (seals undo step).
  final VoidCallback onBorderDragEnd;

  /// Discrete border set (swatch tap, typed value or Reset; non-coalescing).
  final ValueChanged<ClipBorder> onBorderSet;

  /// Closes the panel.
  final VoidCallback onClose;

  @override
  State<TransformPanel> createState() => _TransformPanelState();
}

class _TransformPanelState extends State<TransformPanel> {
  late TransformTab _tab = widget.initialTab;

  VoidCallback? _resetCallback() => switch (_tab) {
    TransformTab.fill =>
      widget.fitMode == FitMode.fit
          ? null
          : () => widget.onFitMode(FitMode.fit),
    TransformTab.position =>
      widget.position == Vec2.zero &&
              widget.scale == 1 &&
              sameAngle(widget.rotation, 0)
          ? null
          : () => widget.onTransformSet(
              position: Vec2.zero,
              scale: 1,
              rotation: 0,
            ),
    TransformTab.opacity =>
      widget.opacity == 1 ? null : () => widget.onTransformSet(opacity: 1),
    TransformTab.border =>
      widget.border == const ClipBorder()
          ? null
          : () => widget.onBorderSet(const ClipBorder()),
  };

  Future<void> _typeNumber({
    required String title,
    required double current,
    required double min,
    required double max,
    required ValueChanged<double> onSubmit,
    String? minLabel,
    String? maxLabel,
  }) async {
    final l10n = AppLocalizations.of(context);
    final lo = minLabel ?? _formatPlain(min);
    final hi = maxLabel ?? _formatPlain(max);
    final typed = await showValueDialog(
      context,
      title: title,
      label: l10n.valueRangeLabel(lo, hi),
      invalidText: l10n.valueRangeInvalid(lo, hi),
      initialText: _formatPlain(current),
      parse: (text) {
        final parsed = double.tryParse(text.replaceAll('−', '-'));
        if (parsed == null || !(parsed >= min && parsed <= max)) return null;
        return parsed == 0 ? 0 : parsed;
      },
    );
    if (typed != null && mounted) onSubmit(typed);
  }

  static String _formatPlain(double v) {
    final clean = v == 0 ? 0.0 : v;
    if (clean == clean.roundToDouble()) return clean.toStringAsFixed(0);
    return double.parse(clean.toStringAsFixed(1)).toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ToolPanel(
      title: l10n.toolTransform,
      onClose: widget.onClose,
      onReset: _resetCallback(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelTabs(
            labels: [
              l10n.transformTabFill,
              l10n.transformTabPosition,
              l10n.transformTabOpacity,
              l10n.transformTabBorder,
            ],
            selected: _tab.index,
            onSelect: (i) => setState(() => _tab = TransformTab.values[i]),
          ),
          const SizedBox(height: 8),
          switch (_tab) {
            TransformTab.fill => _buildFillTab(context),
            TransformTab.position => _buildPositionTab(context),
            TransformTab.opacity => _buildOpacityTab(context),
            TransformTab.border => _buildBorderTab(context),
          },
        ],
      ),
    );
  }

  Widget _buildFillTab(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final choices = <(FitMode, String)>[
      (FitMode.fit, l10n.fitModeFit),
      (FitMode.fill, l10n.fitModeFill),
      (FitMode.stretch, l10n.fitModeStretch),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final (mode, label) in choices)
            _FitModeTile(
              mode: mode,
              label: label,
              selected: widget.fitMode == mode,
              onTap: () => widget.onFitMode(mode),
            ),
        ],
      ),
    );
  }

  Widget? _keyframeButton(
    BuildContext context,
    TransformProperty property,
    String propertyLabel,
  ) {
    final onToggle = widget.onToggleKeyframe;
    if (onToggle == null) return null;
    final l10n = AppLocalizations.of(context);
    final active = widget.activeKeyframes.contains(property);
    return KeyframeToggleButton(
      active: active,
      animated: widget.animatedProperties.contains(property),
      tooltip: active
          ? l10n.keyframeRemove(propertyLabel)
          : l10n.keyframeAdd(propertyLabel),
      onPressed: () => onToggle(property),
    );
  }

  Widget _buildPositionTab(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const maxOff = TransformLimits.maxOffset;
    final xPct = (widget.position.x * 100).round();
    final yPct = (widget.position.y * 100).round();
    final scalePct = (widget.scale * 100).round();
    final wrappedRot = RotationScale.wrap(widget.rotation);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GradientSliderRow(
          label: l10n.transformX,
          valueText: l10n.percentValue(xPct),
          position: (widget.position.x + maxOff) / (2 * maxOff),
          snapPositions: const [0.5],
          onChanged: (p) {
            final x = ((p * 2 - 1) * maxOff * 100).roundToDouble() / 100;
            widget.onTransformDrag(
              position: Vec2(x: x == 0 ? 0 : x, y: widget.position.y),
            );
          },
          onChangeEnd: widget.onTransformDragEnd,
          onTapValue: () => unawaited(
            _typeNumber(
              title: l10n.transformX,
              current: widget.position.x * 100,
              min: -maxOff * 100,
              max: maxOff * 100,
              onSubmit: (pct) => widget.onTransformSet(
                position: Vec2(x: pct / 100, y: widget.position.y),
              ),
            ),
          ),
          trailing: _keyframeButton(
            context,
            TransformProperty.position,
            l10n.transformX,
          ),
        ),
        GradientSliderRow(
          label: l10n.transformY,
          valueText: l10n.percentValue(yPct),
          position: (widget.position.y + maxOff) / (2 * maxOff),
          snapPositions: const [0.5],
          onChanged: (p) {
            final y = ((p * 2 - 1) * maxOff * 100).roundToDouble() / 100;
            widget.onTransformDrag(
              position: Vec2(x: widget.position.x, y: y == 0 ? 0 : y),
            );
          },
          onChangeEnd: widget.onTransformDragEnd,
          onTapValue: () => unawaited(
            _typeNumber(
              title: l10n.transformY,
              current: widget.position.y * 100,
              min: -maxOff * 100,
              max: maxOff * 100,
              onSubmit: (pct) => widget.onTransformSet(
                position: Vec2(x: widget.position.x, y: pct / 100),
              ),
            ),
          ),
          trailing: _keyframeButton(
            context,
            TransformProperty.position,
            l10n.transformY,
          ),
        ),
        GradientSliderRow(
          label: l10n.transformScale,
          valueText: l10n.percentValue(scalePct),
          position: TransformScale.positionOf(widget.scale),
          snapPositions: const [TransformScale.defaultPosition],
          onChanged: (p) =>
              widget.onTransformDrag(scale: TransformScale.scaleAt(p)),
          onChangeEnd: widget.onTransformDragEnd,
          onTapValue: () => unawaited(
            _typeNumber(
              title: l10n.transformScale,
              current: widget.scale * 100,
              min: TransformLimits.minScale * 100,
              max: TransformLimits.maxScale * 100,
              onSubmit: (pct) => widget.onTransformSet(scale: pct / 100),
            ),
          ),
          trailing: _keyframeButton(
            context,
            TransformProperty.scale,
            l10n.transformScale,
          ),
        ),
        GradientSliderRow(
          label: l10n.cropRotation,
          valueText: l10n.rotationValue(wrappedRot.round()),
          position: RotationScale.positionOf(widget.rotation),
          snapPositions: const [0, 0.25, 0.5, 0.75, 1],
          onChanged: (p) =>
              widget.onTransformDrag(rotation: RotationScale.degreesAt(p)),
          onChangeEnd: widget.onTransformDragEnd,
          onTapValue: () => unawaited(
            _typeNumber(
              title: l10n.cropRotation,
              current: wrappedRot,
              min: RotationScale.min,
              max: RotationScale.max,
              onSubmit: (deg) => widget.onTransformSet(rotation: deg),
            ),
          ),
          trailing: _keyframeButton(
            context,
            TransformProperty.rotation,
            l10n.cropRotation,
          ),
        ),
      ],
    );
  }

  Widget _buildOpacityTab(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pct = (widget.opacity * 100).round();
    return GradientSliderRow(
      label: l10n.transformOpacity,
      valueText: l10n.percentValue(pct),
      position: widget.opacity,
      snapPositions: const [1],
      onChanged: (p) =>
          widget.onTransformDrag(opacity: (p * 100).roundToDouble() / 100),
      onChangeEnd: widget.onTransformDragEnd,
      onTapValue: () => unawaited(
        _typeNumber(
          title: l10n.transformOpacity,
          current: widget.opacity * 100,
          min: 0,
          max: 100,
          onSubmit: (p) => widget.onTransformSet(opacity: p / 100),
        ),
      ),
      trailing: _keyframeButton(
        context,
        TransformProperty.opacity,
        l10n.transformOpacity,
      ),
    );
  }

  Widget _buildBorderTab(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final border = widget.border;
    final widthPct = (border.width / BorderLimits.maxWidth * 100).round();
    final radiusPct = (border.radius / BorderLimits.maxRadius * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradientSliderRow(
          label: l10n.transformBorderWidth,
          valueText: l10n.percentValue(widthPct),
          position: border.width / BorderLimits.maxWidth,
          snapPositions: const [0],
          onChanged: (p) => widget.onBorderDrag(
            border.copyWith(
              width: ((p * 100).round() / 100) * BorderLimits.maxWidth,
            ),
          ),
          onChangeEnd: widget.onBorderDragEnd,
          onTapValue: () => unawaited(
            _typeNumber(
              title: l10n.transformBorderWidth,
              current: border.width / BorderLimits.maxWidth * 100,
              min: 0,
              max: 100,
              onSubmit: (pct) => widget.onBorderSet(
                border.copyWith(width: (pct / 100) * BorderLimits.maxWidth),
              ),
            ),
          ),
        ),
        GradientSliderRow(
          label: l10n.transformBorderCorners,
          valueText: l10n.percentValue(radiusPct),
          position: border.radius / BorderLimits.maxRadius,
          snapPositions: const [0],
          onChanged: (p) => widget.onBorderDrag(
            border.copyWith(
              radius: ((p * 100).round() / 100) * BorderLimits.maxRadius,
            ),
          ),
          onChangeEnd: widget.onBorderDragEnd,
          onTapValue: () => unawaited(
            _typeNumber(
              title: l10n.transformBorderCorners,
              current: border.radius / BorderLimits.maxRadius * 100,
              min: 0,
              max: 100,
              onSubmit: (pct) => widget.onBorderSet(
                border.copyWith(radius: (pct / 100) * BorderLimits.maxRadius),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        ColorSwatchRow(
          selectedArgb: border.argb,
          onSelect: (argb) => widget.onBorderSet(border.copyWith(argb: argb)),
        ),
      ],
    );
  }
}

class _FitModeTile extends StatelessWidget {
  const new({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final FitMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = selected ? AccentGradient.of(context).linear : null;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72, minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: const Size(40, 30),
                  painter: _FitModeGlyphPainter(
                    mode: mode,
                    color: scheme.onSurfaceVariant,
                    gradient: gradient,
                  ),
                ),
                const SizedBox(height: 8),
                PanelLabel(
                  text: label,
                  selected: selected,
                  fontSize: 12,
                  muted: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FitModeGlyphPainter extends CustomPainter {
  new({required this.mode, required this.color, this.gradient});

  final FitMode mode;
  final Color color;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = (Offset.zero & size).deflate(1.5);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = gradient == null ? 1.5 : 2
      ..color = color;
    if (gradient case final g?) stroke.shader = g.createShader(outer);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, const Radius.circular(4)),
      stroke,
    );

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: gradient == null ? 0.35 : 0.65);
    if (gradient case final g?) fill.shader = g.createShader(outer);

    switch (mode) {
      case FitMode.fit:
        // Letterboxed picture inside the canvas frame.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              outer.left + 8,
              outer.top + 3.5,
              outer.right - 8,
              outer.bottom - 3.5,
            ),
            const Radius.circular(2),
          ),
          fill,
        );
      case FitMode.fill:
        // Picture fills the entire canvas frame.
        canvas.drawRRect(
          RRect.fromRectAndRadius(outer.deflate(3.5), const Radius.circular(2)),
          fill,
        );
      case FitMode.stretch:
        // Full-width stretched bar with opposing horizontal chevrons.
        final inner = outer.deflate(3.5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(inner, const Radius.circular(2)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = color.withValues(alpha: 0.7),
        );
        final cy = inner.center.dy;
        final arrow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color;
        if (gradient case final g?) arrow.shader = g.createShader(outer);
        canvas
          ..drawLine(
            Offset(inner.left + 5, cy),
            Offset(inner.right - 5, cy),
            arrow,
          )
          ..drawPath(
            Path()
              ..moveTo(inner.left + 9, cy - 3.5)
              ..lineTo(inner.left + 5, cy)
              ..lineTo(inner.left + 9, cy + 3.5),
            arrow,
          )
          ..drawPath(
            Path()
              ..moveTo(inner.right - 9, cy - 3.5)
              ..lineTo(inner.right - 5, cy)
              ..lineTo(inner.right - 9, cy + 3.5),
            arrow,
          );
    }
  }

  @override
  bool shouldRepaint(_FitModeGlyphPainter old) =>
      old.mode != mode || old.color != color || old.gradient != gradient;
}
