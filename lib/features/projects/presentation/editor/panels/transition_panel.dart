import 'dart:async';
import 'dart:math' as math;

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/features/projects/domain/model/clip_transition.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/panel_widgets.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/tool_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Transition picker & duration panel (Phase 6C): category tabs
/// (`Basic | Slide | Wipe | Zoom`), horizontal strip of transition tiles
/// (`None` + presets with custom glyphs), duration slider (`0.1s`..max), and
/// optional `Apply to all`.
class TransitionPanel extends StatefulWidget {
  /// Creates the panel.
  const new({
    required this.transition,
    required this.maxDurationUs,
    required this.onSelect,
    required this.onDurationDrag,
    required this.onDurationDragEnd,
    required this.onDurationSet,
    required this.onClose,
    this.canApplyAll = false,
    this.onApplyAll,
    super.key,
  });

  /// Active transition on the selected boundary, or null for None (hard cut).
  final ClipTransition? transition;

  /// Maximum usable duration in microseconds for this boundary.
  final int maxDurationUs;

  /// Whether the project has multiple boundaries so `Apply to all` is useful.
  final bool canApplyAll;

  /// Called when a transition tile (or None / Reset) is tapped.
  final ValueChanged<ClipTransition?> onSelect;

  /// Called live while dragging the duration slider (coalesced).
  final ValueChanged<int> onDurationDrag;

  /// Called when a duration slider drag ends (seals the undo step).
  final VoidCallback onDurationDragEnd;

  /// Called when an exact duration is typed via the value dialog.
  final ValueChanged<int> onDurationSet;

  /// Applies the current transition (or None) to every boundary.
  final VoidCallback? onApplyAll;

  /// Closes the panel.
  final VoidCallback onClose;

  @override
  State<TransitionPanel> createState() => _TransitionPanelState();
}

class _TransitionPanelState extends State<TransitionPanel> {
  // Ephemeral UI tab state: opens on the active transition's category.
  late int _categoryIndex = _initialCategoryIndex(widget.transition);

  static int _initialCategoryIndex(ClipTransition? transition) {
    if (transition == null) return 0;
    return TransitionCategory.values.indexOf(transition.type.category);
  }

  @override
  void didUpdateWidget(TransitionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextType = widget.transition?.type;
    if (nextType != null && nextType != oldWidget.transition?.type) {
      final idx = TransitionCategory.values.indexOf(nextType.category);
      if (idx >= 0) _categoryIndex = idx;
    }
  }

  int get _effectiveMaxUs =>
      math.min(TransitionLimits.maxDurationUs, widget.maxDurationUs);

  int _clampedUs(int rawUs) {
    final maxUs = _effectiveMaxUs;
    if (maxUs <= TransitionLimits.minDurationUs) {
      return TransitionLimits.minDurationUs;
    }
    return rawUs.clamp(TransitionLimits.minDurationUs, maxUs);
  }

  Future<void> _typeDuration(int currentUs) async {
    final l10n = AppLocalizations.of(context);
    const minSec = TransitionLimits.minDurationUs / Micros.perSecond;
    final maxSec = _effectiveMaxUs / Micros.perSecond;
    final minText = minSec.toStringAsFixed(1);
    final maxText = maxSec.toStringAsFixed(1);
    final typed = await showValueDialog(
      context,
      title: l10n.transitionDuration,
      label: l10n.valueRangeLabel(minText, maxText),
      invalidText: l10n.valueRangeInvalid(minText, maxText),
      initialText: (currentUs / Micros.perSecond).toStringAsFixed(1),
      parse: (text) {
        final v = double.tryParse(text.replaceAll('−', '-'));
        if (v == null || !(v >= minSec - 1e-6 && v <= maxSec + 1e-6)) {
          return null;
        }
        return _clampedUs((v * Micros.perSecond).round()).toDouble();
      },
    );
    if (typed != null && mounted) widget.onDurationSet(typed.round());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final active = widget.transition;
    final maxUs = _effectiveMaxUs;
    final tooShort = maxUs < TransitionLimits.minDurationUs;
    final category = TransitionCategory.values[_categoryIndex];
    final types = TransitionType.inCategory(category);

    return ToolPanel(
      title: l10n.transitionTitle,
      onClose: widget.onClose,
      onReset: active == null ? null : () => widget.onSelect(null),
      child: tooShort
          ? Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 20),
              child: Text(
                l10n.transitionTooShort,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Apply to all shares the tabs row so the panel fits the phone
                // sheet without scrolling.
                Row(
                  children: [
                    Expanded(
                      child: PanelTabs(
                        labels: [
                          l10n.transitionCategoryBasic,
                          l10n.transitionCategorySlide,
                          l10n.transitionCategoryWipe,
                          l10n.transitionCategoryZoom,
                        ],
                        selected: _categoryIndex,
                        onSelect: (i) => setState(() => _categoryIndex = i),
                      ),
                    ),
                    if (widget.canApplyAll && widget.onApplyAll != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 12),
                        child: TextButton(
                          onPressed: () {
                            unawaited(HapticFeedback.selectionClick());
                            widget.onApplyAll!();
                          },
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: scheme.primary,
                          ),
                          child: Text(l10n.transitionApplyAll),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 70,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 14,
                    ),
                    children: [
                      _TransitionTile(
                        type: null,
                        label: l10n.transitionNone,
                        selected: active == null,
                        onTap: () {
                          unawaited(HapticFeedback.selectionClick());
                          widget.onSelect(null);
                        },
                      ),
                      const SizedBox(width: 6),
                      for (final t in types) ...[
                        _TransitionTile(
                          type: t,
                          label: _typeLabel(l10n, t),
                          selected: active?.type == t,
                          onTap: () {
                            unawaited(HapticFeedback.selectionClick());
                            final durationUs = _clampedUs(
                              active?.durationUs ??
                                  TransitionLimits.defaultDurationUs,
                            );
                            widget.onSelect(
                              ClipTransition(type: t, durationUs: durationUs),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
                if (active != null) ...[
                  const SizedBox(height: 6),
                  _buildDurationSlider(context, active, maxUs),
                ],
              ],
            ),
    );
  }

  Widget _buildDurationSlider(
    BuildContext context,
    ClipTransition active,
    int maxUs,
  ) {
    final l10n = AppLocalizations.of(context);
    const minUs = TransitionLimits.minDurationUs;
    final currentUs = _clampedUs(active.durationUs);
    final span = maxUs - minUs;
    final position = span <= 0
        ? 1.0
        : ((currentUs - minUs) / span).clamp(0.0, 1.0);
    final snaps = <double>[
      if (span > 0 && TransitionLimits.defaultDurationUs <= maxUs)
        (TransitionLimits.defaultDurationUs - minUs) / span,
      if (span > 0 && Micros.perSecond <= maxUs)
        (Micros.perSecond - minUs) / span,
    ];
    final secText = (currentUs / Micros.perSecond).toStringAsFixed(1);
    return GradientSliderRow(
      label: l10n.transitionDuration,
      valueText: l10n.transitionDurationValue(secText),
      position: position,
      snapPositions: snaps,
      onChanged: (p) {
        if (span <= 0) return;
        final rawUs = minUs + (p * span).round();
        // Quantize to 0.1 s steps so the slider and readout stay crisp.
        final quantized = (rawUs / 100000).round() * 100000;
        widget.onDurationDrag(_clampedUs(quantized));
      },
      onChangeEnd: widget.onDurationDragEnd,
      onTapValue: () => unawaited(_typeDuration(currentUs)),
    );
  }

  static String _typeLabel(AppLocalizations l10n, TransitionType type) =>
      switch (type) {
        TransitionType.dissolve => l10n.transitionDissolve,
        TransitionType.fadeBlack => l10n.transitionFadeBlack,
        TransitionType.fadeWhite => l10n.transitionFadeWhite,
        TransitionType.circle => l10n.transitionCircle,
        TransitionType.slideLeft => l10n.transitionSlideLeft,
        TransitionType.slideRight => l10n.transitionSlideRight,
        TransitionType.slideUp => l10n.transitionSlideUp,
        TransitionType.slideDown => l10n.transitionSlideDown,
        TransitionType.wipeLeft => l10n.transitionWipeLeft,
        TransitionType.wipeRight => l10n.transitionWipeRight,
        TransitionType.wipeUp => l10n.transitionWipeUp,
        TransitionType.wipeDown => l10n.transitionWipeDown,
        TransitionType.zoomIn => l10n.transitionZoomIn,
        TransitionType.zoomOut => l10n.transitionZoomOut,
      };
}

class _TransitionTile extends StatelessWidget {
  const new({
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final TransitionType? type;
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
          constraints: const BoxConstraints(minWidth: 68, minHeight: 60),
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
                painter: _TransitionGlyphPainter(
                  type: type,
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

class _TransitionGlyphPainter extends CustomPainter {
  new({required this.type, required this.color, this.gradient});

  final TransitionType? type;
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
      ..color = color.withValues(alpha: gradient == null ? 0.22 : 0.35);
    if (gradient case final g?) {
      stroke.shader = g.createShader(rect);
      fill.shader = g.createShader(rect);
    }

    switch (type) {
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
      case TransitionType.dissolve:
        final a = Rect.fromLTWH(rect.left, rect.top + 2, 11, 11);
        final b = Rect.fromLTWH(rect.right - 11, rect.bottom - 13, 11, 11);
        canvas
          ..drawRRect(
            RRect.fromRectAndRadius(a, const Radius.circular(2)),
            stroke,
          )
          ..drawRRect(
            RRect.fromRectAndRadius(b, const Radius.circular(2)),
            fill,
          )
          ..drawRRect(
            RRect.fromRectAndRadius(b, const Radius.circular(2)),
            stroke,
          );
      case TransitionType.fadeBlack:
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
        canvas
          ..drawRRect(rr, stroke)
          ..drawRect(
            Rect.fromLTRB(
              rect.center.dx - 2,
              rect.top + 1,
              rect.center.dx + 2,
              rect.bottom - 1,
            ),
            fill,
          );
      case TransitionType.fadeWhite:
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
        final bright = Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.75);
        canvas
          ..drawRRect(rr, stroke)
          ..drawCircle(rect.center, 4, bright);
      case TransitionType.circle:
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
        canvas
          ..drawRRect(rr, stroke)
          ..drawCircle(rect.center, rect.shortestSide * 0.28, fill)
          ..drawCircle(rect.center, rect.shortestSide * 0.28, stroke);
      case TransitionType.slideLeft:
        _drawArrowFrame(canvas, rect, stroke, fill, dx: -1, dy: 0);
      case TransitionType.slideRight:
        _drawArrowFrame(canvas, rect, stroke, fill, dx: 1, dy: 0);
      case TransitionType.slideUp:
        _drawArrowFrame(canvas, rect, stroke, fill, dx: 0, dy: -1);
      case TransitionType.slideDown:
        _drawArrowFrame(canvas, rect, stroke, fill, dx: 0, dy: 1);
      case TransitionType.wipeLeft:
        _drawWipeFrame(canvas, rect, stroke, fill, edge: _WipeEdge.right);
      case TransitionType.wipeRight:
        _drawWipeFrame(canvas, rect, stroke, fill, edge: _WipeEdge.left);
      case TransitionType.wipeUp:
        _drawWipeFrame(canvas, rect, stroke, fill, edge: _WipeEdge.bottom);
      case TransitionType.wipeDown:
        _drawWipeFrame(canvas, rect, stroke, fill, edge: _WipeEdge.top);
      case TransitionType.zoomIn:
        _drawZoomFrame(canvas, rect, stroke, fill, zoomIn: true);
      case TransitionType.zoomOut:
        _drawZoomFrame(canvas, rect, stroke, fill, zoomIn: false);
    }
  }

  void _drawArrowFrame(
    Canvas canvas,
    Rect rect,
    Paint stroke,
    Paint fill, {
    required double dx,
    required double dy,
  }) {
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(rr, stroke);
    final c = rect.center;
    final len = rect.shortestSide * 0.26;
    final tail = Offset(c.dx - dx * len, c.dy - dy * len);
    final tip = Offset(c.dx + dx * len, c.dy + dy * len);
    final head = len * 0.7;
    final perpX = -dy * head * 0.7;
    final perpY = dx * head * 0.7;
    canvas
      ..drawLine(tail, tip, stroke)
      ..drawLine(
        tip,
        Offset(tip.dx - dx * head + perpX, tip.dy - dy * head + perpY),
        stroke,
      )
      ..drawLine(
        tip,
        Offset(tip.dx - dx * head - perpX, tip.dy - dy * head - perpY),
        stroke,
      );
  }

  void _drawWipeFrame(
    Canvas canvas,
    Rect rect,
    Paint stroke,
    Paint fill, {
    required _WipeEdge edge,
  }) {
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    final half = switch (edge) {
      _WipeEdge.left => Rect.fromLTRB(
        rect.left,
        rect.top,
        rect.center.dx,
        rect.bottom,
      ),
      _WipeEdge.right => Rect.fromLTRB(
        rect.center.dx,
        rect.top,
        rect.right,
        rect.bottom,
      ),
      _WipeEdge.top => Rect.fromLTRB(
        rect.left,
        rect.top,
        rect.right,
        rect.center.dy,
      ),
      _WipeEdge.bottom => Rect.fromLTRB(
        rect.left,
        rect.center.dy,
        rect.right,
        rect.bottom,
      ),
    };
    canvas
      ..save()
      ..clipRRect(rr)
      ..drawRect(half, fill)
      ..restore()
      ..drawRRect(rr, stroke);
    if (edge == _WipeEdge.left || edge == _WipeEdge.right) {
      canvas.drawLine(
        Offset(rect.center.dx, rect.top),
        Offset(rect.center.dx, rect.bottom),
        stroke,
      );
    } else {
      canvas.drawLine(
        Offset(rect.left, rect.center.dy),
        Offset(rect.right, rect.center.dy),
        stroke,
      );
    }
  }

  void _drawZoomFrame(
    Canvas canvas,
    Rect rect,
    Paint stroke,
    Paint fill, {
    required bool zoomIn,
  }) {
    final outer = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    final inner = RRect.fromRectAndRadius(
      rect.deflate(4.5),
      const Radius.circular(2),
    );
    canvas
      ..drawRRect(outer, zoomIn ? stroke : fill)
      ..drawRRect(outer, stroke)
      ..drawRRect(inner, zoomIn ? fill : stroke)
      ..drawRRect(inner, stroke);
  }

  @override
  bool shouldRepaint(_TransitionGlyphPainter old) =>
      old.type != type || old.color != color || old.gradient != gradient;
}

enum _WipeEdge { left, right, top, bottom }
