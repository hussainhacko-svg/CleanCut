import 'dart:async';
import 'dart:math' as math;

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/features/projects/domain/model/clip_effects.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/crop_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/panel_widgets.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/tool_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Callback emitting whichever mask properties changed in [MaskPanel].
typedef MaskValuesCallback = void Function({
  Vec2? center,
  Vec2? size,
  double? rotation,
  double? feather,
  bool? invert,
});

/// Shape mask panel (Phase 6B): `None`, `Linear`, `Mirror`, `Circle`,
/// `Rectangle`, `Heart`, `Star` selector paired with Feather, Rotation, Size,
/// Invert and per-property keyframe toggles.
class MaskPanel extends StatelessWidget {
  /// Creates the panel.
  const new({
    required this.shape,
    required this.resolved,
    required this.invert,
    required this.onSelectShape,
    required this.onDrag,
    required this.onDragEnd,
    required this.onSet,
    required this.onClose,
    this.animatedProperties = const {},
    this.activeKeyframes = const {},
    this.onToggleKeyframe,
    super.key,
  });

  /// Active mask shape, or null when unmasked.
  final MaskShape? shape;

  /// Evaluated mask parameters at the playhead (null when unmasked).
  final ResolvedMask? resolved;

  /// Whether the active mask is inverted.
  final bool invert;

  /// Properties that have keyframes anywhere on the clip.
  final Set<MaskProperty> animatedProperties;

  /// Properties that have a keyframe at the playhead.
  final Set<MaskProperty> activeKeyframes;

  /// Toggles a keyframe for a mask property at the playhead.
  final ValueChanged<MaskProperty>? onToggleKeyframe;

  /// Picks a mask shape, or null for None (one undo step).
  final ValueChanged<MaskShape?> onSelectShape;

  /// Live slider drag callback (coalesced).
  final MaskValuesCallback onDrag;

  /// Ends a slider drag (seals the undo step).
  final VoidCallback onDragEnd;

  /// Discrete edit callback (typed value, invert toggle, etc.).
  final MaskValuesCallback onSet;

  /// Closes the panel.
  final VoidCallback onClose;

  Future<void> _typeNumber(
    BuildContext context, {
    required String title,
    required double current,
    required double min,
    required double max,
    required ValueChanged<double> onSubmit,
  }) async {
    final l10n = AppLocalizations.of(context);
    final lo = min.round().toString();
    final hi = max.round().toString();
    final typed = await showValueDialog(
      context,
      title: title,
      label: l10n.valueRangeLabel(lo, hi),
      invalidText: l10n.valueRangeInvalid(lo, hi),
      initialText: current.round().toString(),
      parse: (text) {
        final v = double.tryParse(text.replaceAll('−', '-'));
        if (v == null || !(v >= min && v <= max)) return null;
        return v == 0 ? 0 : v;
      },
    );
    if (typed != null) onSubmit(typed);
  }

  Widget? _keyframeButton(
    BuildContext context,
    MaskProperty property,
    String propertyLabel,
  ) {
    final onToggle = onToggleKeyframe;
    if (onToggle == null) return null;
    final l10n = AppLocalizations.of(context);
    final active = activeKeyframes.contains(property);
    return KeyframeToggleButton(
      active: active,
      animated: animatedProperties.contains(property),
      tooltip: active
          ? l10n.keyframeRemove(propertyLabel)
          : l10n.keyframeAdd(propertyLabel),
      onPressed: () => onToggle(property),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currentShape = shape;
    final values = resolved;

    return ToolPanel(
      title: l10n.toolMask,
      onClose: onClose,
      onReset: currentShape == null ? null : () => onSelectShape(null),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 68,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
              children: [
                _MaskShapeTile(
                  shape: null,
                  label: l10n.maskNone,
                  selected: currentShape == null,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    onSelectShape(null);
                  },
                ),
                const SizedBox(width: 6),
                for (final s in MaskShape.values) ...[
                  _MaskShapeTile(
                    shape: s,
                    label: _shapeLabel(l10n, s),
                    selected: currentShape == s,
                    onTap: () {
                      unawaited(HapticFeedback.selectionClick());
                      onSelectShape(s);
                    },
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          if (currentShape != null && values != null) ...[
            const SizedBox(height: 6),
            GradientSliderRow(
              label: l10n.maskFeather,
              valueText: l10n.percentValue((values.feather * 100).round()),
              position: values.feather,
              snapPositions: const [0],
              onChanged: (p) =>
                  onDrag(feather: (p * 100).roundToDouble() / 100),
              onChangeEnd: onDragEnd,
              onTapValue: () => unawaited(
                _typeNumber(
                  context,
                  title: l10n.maskFeather,
                  current: values.feather * 100,
                  min: 0,
                  max: 100,
                  onSubmit: (pct) => onSet(feather: pct / 100),
                ),
              ),
              trailing: _keyframeButton(
                context,
                MaskProperty.feather,
                l10n.maskFeather,
              ),
            ),
            GradientSliderRow(
              label: l10n.maskRotation,
              valueText: l10n.rotationValue(
                RotationScale.wrap(values.rotation).round(),
              ),
              position: RotationScale.positionOf(values.rotation),
              snapPositions: const [0, 0.25, 0.5, 0.75, 1],
              onChanged: (p) => onDrag(rotation: RotationScale.degreesAt(p)),
              onChangeEnd: onDragEnd,
              onTapValue: () => unawaited(
                _typeNumber(
                  context,
                  title: l10n.maskRotation,
                  current: RotationScale.wrap(values.rotation),
                  min: RotationScale.min,
                  max: RotationScale.max,
                  onSubmit: (deg) => onSet(rotation: deg),
                ),
              ),
              trailing: _keyframeButton(
                context,
                MaskProperty.rotation,
                l10n.maskRotation,
              ),
            ),
            if (currentShape != MaskShape.linear)
              _buildSizeRow(context, currentShape, values),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                24,
                0,
                onToggleKeyframe == null ? 24 : 12,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                      onTap: () {
                        unawaited(HapticFeedback.selectionClick());
                        onSet(invert: !invert);
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Row(
                          children: [
                            Text(
                              l10n.maskInvert,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 12,
                                    color: scheme.onSurface,
                                  ),
                            ),
                            const Spacer(),
                            Switch(
                              value: invert,
                              onChanged: (v) {
                                unawaited(HapticFeedback.selectionClick());
                                onSet(invert: v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ?_keyframeButton(
                    context,
                    MaskProperty.center,
                    l10n.maskPosition,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSizeRow(
    BuildContext context,
    MaskShape currentShape,
    ResolvedMask values,
  ) {
    final l10n = AppLocalizations.of(context);
    final isMirror = currentShape == MaskShape.mirror;
    final currentSize = isMirror
        ? values.size.y
        : (values.size.x + values.size.y) * 0.5;
    final defaultSize = isMirror
        ? MaskLimits.defaultMirrorSize.y
        : MaskLimits.defaultSize.x;
    const minS = MaskLimits.minSize;
    const maxS = MaskLimits.maxSize;
    final pos = ((currentSize - minS) / (maxS - minS)).clamp(0.0, 1.0);
    final defaultSnap = ((defaultSize - minS) / (maxS - minS)).clamp(0.0, 1.0);

    Vec2 scaledSize(double target) {
      final clamped = target.clamp(minS, maxS);
      if (isMirror) return Vec2(x: values.size.x, y: clamped);
      final cur = (values.size.x + values.size.y) * 0.5;
      if (cur <= 1e-4) return Vec2(x: clamped, y: clamped);
      final factor = clamped / cur;
      return MaskLimits.clampSize(
        Vec2(x: values.size.x * factor, y: values.size.y * factor),
      );
    }

    return GradientSliderRow(
      label: l10n.maskSize,
      valueText: l10n.percentValue((currentSize * 100).round()),
      position: pos,
      snapPositions: [defaultSnap],
      onChanged: (p) {
        final raw = minS + p * (maxS - minS);
        final rounded = (raw * 100).roundToDouble() / 100;
        onDrag(size: scaledSize(rounded));
      },
      onChangeEnd: onDragEnd,
      onTapValue: () => unawaited(
        _typeNumber(
          context,
          title: l10n.maskSize,
          current: currentSize * 100,
          min: minS * 100,
          max: maxS * 100,
          onSubmit: (pct) => onSet(size: scaledSize(pct / 100)),
        ),
      ),
      trailing: _keyframeButton(context, MaskProperty.size, l10n.maskSize),
    );
  }

  static String _shapeLabel(AppLocalizations l10n, MaskShape shape) =>
      switch (shape) {
        MaskShape.linear => l10n.maskLinear,
        MaskShape.mirror => l10n.maskMirror,
        MaskShape.circle => l10n.maskCircle,
        MaskShape.rect => l10n.maskRect,
        MaskShape.heart => l10n.maskHeart,
        MaskShape.star => l10n.maskStar,
      };
}

class _MaskShapeTile extends StatelessWidget {
  const new({
    required this.shape,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final MaskShape? shape;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gradient = selected ? AccentGradient.of(context).linear : null;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        child: Container(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 58),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected
                ? scheme.surfaceContainerHigh
                : scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                size: const Size.square(22),
                painter: _MaskShapeGlyphPainter(
                  shape: shape,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                  gradient: gradient,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontVariations: [FontVariation.weight(selected ? 700 : 500)],
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

class _MaskShapeGlyphPainter extends CustomPainter {
  new({required this.shape, required this.color, this.gradient});

  final MaskShape? shape;
  final Color color;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: gradient == null ? 0.2 : 0.32);
    if (gradient case final g?) {
      stroke.shader = g.createShader(rect);
      fill.shader = g.createShader(rect);
    }

    switch (shape) {
      case null:
        final c = rect.center;
        final r = rect.shortestSide / 2;
        canvas
          ..drawCircle(c, r, stroke)
          ..drawLine(
            Offset(c.dx - r * 0.68, c.dy + r * 0.68),
            Offset(c.dx + r * 0.68, c.dy - r * 0.68),
            stroke,
          );
      case MaskShape.linear:
        final topHalf = Rect.fromLTRB(
          rect.left,
          rect.top,
          rect.right,
          rect.center.dy,
        );
        canvas
          ..drawRect(topHalf, fill)
          ..drawLine(
            Offset(rect.left, rect.center.dy),
            Offset(rect.right, rect.center.dy),
            stroke,
          );
      case MaskShape.mirror:
        final band = Rect.fromLTRB(
          rect.left,
          rect.center.dy - rect.height * 0.25,
          rect.right,
          rect.center.dy + rect.height * 0.25,
        );
        canvas
          ..drawRect(band, fill)
          ..drawLine(band.topLeft, band.topRight, stroke)
          ..drawLine(band.bottomLeft, band.bottomRight, stroke);
      case MaskShape.circle:
        canvas
          ..drawCircle(rect.center, rect.shortestSide / 2, fill)
          ..drawCircle(rect.center, rect.shortestSide / 2, stroke);
      case MaskShape.rect:
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(2.5));
        canvas
          ..drawRRect(rr, fill)
          ..drawRRect(rr, stroke);
      case MaskShape.heart:
        final path = buildHeartPath(
          rect.center,
          rect.width / 2,
          rect.height / 2,
        );
        canvas
          ..drawPath(path, fill)
          ..drawPath(path, stroke);
      case MaskShape.star:
        final path = buildStarPath(
          rect.center,
          rect.width / 2,
          rect.height / 2,
        );
        canvas
          ..drawPath(path, fill)
          ..drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(_MaskShapeGlyphPainter old) =>
      old.shape != shape || old.color != color || old.gradient != gradient;
}

/// Builds a closed 5-pointed star [Path] centered at [center] with half-extents
/// `(rx, ry)` and inner radius factor 0.45 (matching the GLSL star SDF).
Path buildStarPath(Offset center, double rx, double ry) {
  const rf = 0.45;
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final angle = -math.pi / 2 + i * math.pi / 5;
    final scale = i.isEven ? 1.0 : rf;
    final x = center.dx + math.cos(angle) * rx * scale;
    final y = center.dy + math.sin(angle) * ry * scale;
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  return path..close();
}

/// Builds a closed heart [Path] centered at [center] with half-extents
/// `(rx, ry)` matching the GLSL `sdHeart` bounding box and lobes.
Path buildHeartPath(Offset center, double rx, double ry) {
  // Exact parameterization of IQ's sdHeart boundary:
  // bottom V from (0,0) to (±0.5, 0.5) + circular arcs at (±0.25, 0.75)
  // with radius sqrt(2)/4, mapped from x in [-0.60355, 0.60355],
  // y in [0, 1.10355].
  const halfW = 0.60355339;
  const halfH = 0.55177670;
  const radius = math.sqrt2 / 4;

  Offset mapPt(double hx, double hy) => Offset(
    center.dx + (hx / halfW) * rx,
    center.dy - ((hy - halfH) / halfH) * ry,
  );

  final path = Path()..moveTo(mapPt(0, 0).dx, mapPt(0, 0).dy);
  final rightStart = mapPt(0.5, 0.5);
  path.lineTo(rightStart.dx, rightStart.dy);

  // Right lobe arc from -pi/4 to 3*pi/4 in IQ's Y-up coordinates.
  const steps = 20;
  for (var i = 1; i <= steps; i++) {
    final a = -math.pi / 4 + (math.pi * i / steps);
    final pt = mapPt(0.25 + math.cos(a) * radius, 0.75 + math.sin(a) * radius);
    path.lineTo(pt.dx, pt.dy);
  }
  // Left lobe arc from pi/4 to 5*pi/4 in IQ's Y-up coordinates.
  for (var i = 1; i <= steps; i++) {
    final a = math.pi / 4 + (math.pi * i / steps);
    final pt = mapPt(-0.25 + math.cos(a) * radius, 0.75 + math.sin(a) * radius);
    path.lineTo(pt.dx, pt.dy);
  }
  return path..close();
}
