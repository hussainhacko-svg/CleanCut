import 'dart:async';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart'
    show SpeedLimits;
import 'package:cleancut/features/projects/presentation/editor/panels/speed_scale.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/tool_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The kit's "Speed" panel: a value bubble riding over a tick ruler with
/// the labelled speeds underneath, plus a keep-pitch switch for video.
///
/// Dragging updates the bubble live and reports the speed once, on
/// release ([onChanged]); tapping the ruler jumps there; tapping the bubble
/// types an exact value; Reset returns to 1×. Ticks at the labels snap with
/// a haptic click.
class SpeedPanel extends StatefulWidget {
  /// Creates the panel.
  const new({
    required this.speed,
    required this.keepPitch,
    required this.onChanged,
    required this.onClose,
    this.onKeepPitchChanged,
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
    if (speed != widget.speed) widget.onChanged(speed);
  }

  Future<void> _type() async {
    final typed = await showDialog<double>(
      context: context,
      builder: (context) => _SpeedDialog(initial: widget.speed),
    );
    if (typed != null && mounted) _commit(typed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final speed = _speed;
    final onKeepPitch = widget.onKeepPitchChanged;
    return ToolPanel(
      title: l10n.toolSpeed,
      onClose: widget.onClose,
      onReset: widget.speed == SpeedScale.normal && _dragSpeed == null
          ? null
          : () => _commit(SpeedScale.normal),
      child: LayoutBuilder(
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
                  onHorizontalDragCancel: () =>
                      setState(() => _dragSpeed = null),
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
                            ),
                          ),
                        ),
                        Positioned(
                          left: bubbleX - 24,
                          top: 10,
                          width: 48,
                          child: Center(
                            child: _Bubble(text: l10n.speedValue(speed)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 20,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final (i, mark) in SpeedScale.marks.indexed)
                      Positioned(
                        left: xOf(SpeedScale.markPosition(i)) - 30,
                        width: 60,
                        child: _MarkLabel(
                          text: l10n.speedValue(mark),
                          selected: mark == speed,
                        ),
                      ),
                  ],
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
          );
        },
      ),
    );
  }
}

/// The white value bubble over the ruler (kit "1/4×").
class _Bubble extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      height: 26,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 5),
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
            color: scheme.surface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// A speed label under the ruler; the current one in the accent gradient.
class _MarkLabel extends StatelessWidget {
  const new({required this.text, required this.selected});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      color: theme.colorScheme.onSurface,
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

/// Ticks: a tall one at every label, three short ones between (kit).
class _RulerPainter extends CustomPainter {
  new({required this.inset, required this.color});

  final double inset;
  final Color color;

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
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.inset != inset || old.color != color;
}

/// Types an exact speed; completes with it, or null when cancelled.
class _SpeedDialog extends StatefulWidget {
  const new({required this.initial});

  final double initial;

  @override
  State<_SpeedDialog> createState() => _SpeedDialogState();
}

class _SpeedDialogState extends State<_SpeedDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: _format(widget.initial),
  );

  static String _format(double speed) => speed == speed.roundToDouble()
      ? speed.toStringAsFixed(0)
      : speed.toString();

  double? get _value {
    final parsed = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    if (parsed == null || !SpeedLimits.contains(parsed)) return null;
    return SpeedScale.round(parsed);
  }

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
      title: Text(l10n.speedTypeTitle),
      content: ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, _, _) => TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.speedTypeLabel,
            errorText: _value == null ? l10n.speedTypeInvalid : null,
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
