import 'dart:async';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The panel's text tabs (kit "Filters"): the selected one bold in the
/// accent gradient, the others muted. Each is a 48dp target.
class PanelTabs extends StatelessWidget {
  /// Creates the tab row.
  const new({
    required this.labels,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  /// Tab labels in order.
  final List<String> labels;

  /// Index of the open tab.
  final int selected;

  /// Called with the tapped tab's index.
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 22),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (i, label) in labels.indexed)
              Semantics(
                selected: i == selected,
                button: true,
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        widthFactor: 1,
                        child: PanelLabel(
                          text: label,
                          selected: i == selected,
                          muted: scheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The white value bubble over a ruler (kit "1/4×").
class ValueBubble extends StatelessWidget {
  /// Creates a bubble showing [text].
  const new({required this.text, super.key});

  /// The value.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 5,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: scheme.onSurface,
        borderRadius: BorderRadius.circular(13),
      ),
      // widthFactor 1: as wide as the text (a circle for "1×"), not as wide
      // as the slot the bubble rides in.
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          maxLines: 1,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation.weight(700)],
            color: scheme.surface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// A label under a ruler or in a preset row; the selected one bold in the
/// accent gradient.
class PanelLabel extends StatelessWidget {
  /// Creates a label.
  const new({
    required this.text,
    required this.selected,
    this.fontSize = 14,
    this.muted,
    super.key,
  });

  /// The text.
  final String text;

  /// Whether this is the current value or tab.
  final bool selected;

  /// Font size.
  final double fontSize;

  /// Colour when not selected (default: on-surface).
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      fontSize: fontSize,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      fontVariations: [FontVariation.weight(selected ? 700 : 400)],
      color: selected
          ? theme.colorScheme.onSurface
          : (muted ?? theme.colorScheme.onSurface),
    );
    final label = Text(text, textAlign: TextAlign.center, style: style);
    if (!selected) return label;
    final gradient = AccentGradient.of(context).linear;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: gradient.createShader,
      child: label,
    );
  }
}

/// Asks for an exact number. Completes with the value [parse] accepts, or
/// null when cancelled.
///
/// [parse] gets the trimmed text (a decimal comma already turned into a
/// point) and returns the value, or null when it is not allowed; the field
/// then shows [invalidText] and Save is disabled.
Future<double?> showValueDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String invalidText,
  required String initialText,
  required double? Function(String text) parse,
}) => showDialog<double>(
  context: context,
  builder: (context) => _ValueDialog(
    title: title,
    label: label,
    invalidText: invalidText,
    initialText: initialText,
    parse: parse,
  ),
);

class _ValueDialog extends StatefulWidget {
  const new({
    required this.title,
    required this.label,
    required this.invalidText,
    required this.initialText,
    required this.parse,
  });

  final String title;
  final String label;
  final String invalidText;
  final String initialText;
  final double? Function(String text) parse;

  @override
  State<_ValueDialog> createState() => _ValueDialogState();
}

class _ValueDialogState extends State<_ValueDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  double? get _value =>
      widget.parse(_controller.text.trim().replaceAll(',', '.'));

  @override
  void initState() {
    super.initState();
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _value;
    if (value != null) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, _, _) => TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            errorText: _value == null ? widget.invalidText : null,
          ),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, _, _) => FilledButton(
            onPressed: _value == null ? null : _submit,
            child: Text(l10n.commonSave),
          ),
        ),
      ],
    );
  }
}

/// A labelled gradient slider row (VCLIP "Align" style): label on the left,
/// accent-gradient slider in the middle (snapping with haptics to
/// [snapPositions]), tappable value readout on the right, and an optional
/// [trailing] control (e.g. a keyframe toggle).
///
/// [position] is normalized in `[0, 1]`; callers map between domain values and
/// `[0, 1]` so both linear and non-linear scales share the same widget.
class GradientSliderRow extends StatefulWidget {
  /// Creates a slider row.
  const new({
    required this.label,
    required this.valueText,
    required this.position,
    required this.onChanged,
    required this.onChangeEnd,
    this.onTapValue,
    this.snapPositions = const [],
    this.snapThreshold = 0.025,
    this.trailing,
    super.key,
  });

  /// Short property name shown on the left.
  final String label;

  /// Formatted current value shown on the right (and read by TalkBack).
  final String valueText;

  /// Normalized slider position in `[0, 1]`.
  final double position;

  /// Called live while dragging with the (possibly snapped) position in
  /// `[0, 1]`.
  final ValueChanged<double> onChanged;

  /// Called when the drag finishes (to seal the undo step).
  final VoidCallback onChangeEnd;

  /// Called when the user taps the value readout to type an exact value.
  final VoidCallback? onTapValue;

  /// Normalized positions in `[0, 1]` that the thumb snaps to with a haptic
  /// click.
  final List<double> snapPositions;

  /// Maximum normalized distance from a snap position to snap to it.
  final double snapThreshold;

  /// Optional control at the far right (e.g. keyframe diamond).
  final Widget? trailing;

  @override
  State<GradientSliderRow> createState() => _GradientSliderRowState();
}

class _GradientSliderRowState extends State<GradientSliderRow> {
  double? _lastSnapped;

  double _applySnap(double raw) {
    for (final s in widget.snapPositions) {
      if ((raw - s).abs() <= widget.snapThreshold) {
        if (_lastSnapped != s) {
          _lastSnapped = s;
          unawaited(HapticFeedback.selectionClick());
        }
        return s;
      }
    }
    _lastSnapped = null;
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gradient = AccentGradient.of(context);
    final pos = widget.position.isFinite
        ? widget.position.clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        24,
        0,
        widget.trailing == null ? 24 : 12,
        0,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: scheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                trackShape: _PanelGradientTrackShape(gradient),
                inactiveTrackColor: scheme.outlineVariant,
                thumbColor: gradient.end,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(),
                overlayColor: gradient.end.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: pos,
                label: widget.label,
                semanticFormatterCallback: (_) => widget.valueText,
                onChanged: (v) => widget.onChanged(_applySnap(v)),
                onChangeEnd: (_) {
                  _lastSnapped = null;
                  widget.onChangeEnd();
                },
              ),
            ),
          ),
          Tooltip(
            message: l10n.tapToTypeHint,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onTapValue,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 4,
                    ),
                    child: Text(
                      widget.valueText,
                      maxLines: 1,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ?widget.trailing,
        ],
      ),
    );
  }
}

class _PanelGradientTrackShape extends RoundedRectSliderTrackShape {
  const new(this.gradient);

  final AccentGradient gradient;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final radius = Radius.circular(rect.height / 2);
    final activeLeft = textDirection == TextDirection.ltr
        ? rect.left
        : thumbCenter.dx;
    final activeRight = textDirection == TextDirection.ltr
        ? thumbCenter.dx
        : rect.right;
    context.canvas
      ..drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = sliderTheme.inactiveTrackColor!,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(activeLeft, rect.top, activeRight, rect.bottom),
          radius,
        ),
        Paint()..shader = gradient.linear.createShader(rect),
      );
  }
}

/// Curated user-selectable ARGB swatches for clip borders and canvas
/// backgrounds (data values, not UI theme tokens).
const List<int> styleColorSwatches = [
  0xFFFFFFFF,
  0xFF000000,
  0xFF1F232A,
  0xFF8E95A2,
  0xFFFF4D6D,
  0xFFFF8A5B,
  0xFFFFD166,
  0xFF2EC4B6,
  0xFF3A86FF,
  0xFF8338EC,
  0xFFF72585,
];

/// A horizontal row of circular color swatches with 48dp touch targets and an
/// accent-gradient selection ring.
class ColorSwatchRow extends StatelessWidget {
  /// Creates the swatch row.
  const new({
    required this.selectedArgb,
    required this.onSelect,
    this.colors = styleColorSwatches,
    super.key,
  });

  /// Currently selected color (0xAARRGGBB), or null when none is selected.
  final int? selectedArgb;

  /// Called with the tapped swatch's ARGB integer.
  final ValueChanged<int> onSelect;

  /// Swatch ARGB values in display order.
  final List<int> colors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final gradient = AccentGradient.of(context).linear;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
      child: Row(
        children: [
          for (final (i, argb) in colors.indexed)
            Semantics(
              button: true,
              selected: argb == selectedArgb,
              label: l10n.colorSwatchLabel(i + 1),
              child: InkResponse(
                onTap: () => onSelect(argb),
                radius: 24,
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: Container(
                      width: 34,
                      height: 34,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: argb == selectedArgb ? gradient : null,
                        border: argb == selectedArgb
                            ? null
                            : Border.all(color: scheme.outlineVariant),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // Data, not a design token: user-chosen style color.
                          color: Color(argb),
                          border: Border.all(
                            color: scheme.surface,
                            width: argb == selectedArgb ? 1.5 : 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A 48dp keyframe ◇/◆ toggle button for animatable slider rows.
///
/// Draws a muted hollow diamond when unanimated, a bright hollow diamond when
/// the property has keyframes elsewhere on the clip, and an accent-gradient
/// filled diamond when a keyframe sits at the playhead.
class KeyframeToggleButton extends StatelessWidget {
  /// Creates the toggle button.
  const new({
    required this.active,
    required this.animated,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  /// Whether a keyframe exists at the current playhead time.
  final bool active;

  /// Whether the property has any keyframes on the clip.
  final bool animated;

  /// Accessible tooltip and semantics label.
  final String tooltip;

  /// Toggles the keyframe at the playhead.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = AccentGradient.of(context);
    return Semantics(
      button: true,
      toggled: active,
      label: tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: () {
            unawaited(HapticFeedback.selectionClick());
            onPressed();
          },
          radius: 24,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: CustomPaint(
                size: const Size.square(14),
                painter: _KeyframeDiamondPainter(
                  active: active,
                  animated: animated,
                  mutedColor: scheme.outline,
                  animatedColor: scheme.onSurface,
                  gradient: gradient,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyframeDiamondPainter extends CustomPainter {
  new({
    required this.active,
    required this.animated,
    required this.mutedColor,
    required this.animatedColor,
    required this.gradient,
  });

  final bool active;
  final bool animated;
  final Color mutedColor;
  final Color animatedColor;
  final AccentGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide / 2 - 1;
    final diamond = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r, cy)
      ..close();
    if (active) {
      canvas.drawPath(
        diamond,
        Paint()
          ..style = PaintingStyle.fill
          ..shader = gradient.linear.createShader(Offset.zero & size),
      );
      return;
    }
    canvas.drawPath(
      diamond,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.miter
        ..color = animated ? animatedColor : mutedColor,
    );
  }

  @override
  bool shouldRepaint(_KeyframeDiamondPainter old) =>
      old.active != active ||
      old.animated != animated ||
      old.mutedColor != mutedColor ||
      old.animatedColor != animatedColor ||
      old.gradient != gradient;
}
