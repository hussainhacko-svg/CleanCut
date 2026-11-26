import 'dart:async';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/domain/model/canvas_background.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/panel_widgets.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/tool_panel.dart';
import 'package:flutter/material.dart';

/// Tabs of [RatioPanel].
enum RatioTab {
  /// Canvas aspect ratio presets (kit "Ratio").
  ratio,

  /// Canvas background (color, gradient, blur, image).
  background,
}

enum _BackgroundMode { color, gradient, blur, image }

/// Curated user-selectable gradient presets (data colors, not theme tokens).
const List<({int startArgb, int endArgb})> backgroundGradientPresets = [
  (startArgb: 0xFFFF6B6B, endArgb: 0xFF5F27CD),
  (startArgb: 0xFF00D2FF, endArgb: 0xFF3A7BD5),
  (startArgb: 0xFFF7971E, endArgb: 0xFFFFD200),
  (startArgb: 0xFF11998E, endArgb: 0xFF38EF7D),
  (startArgb: 0xFFFC466B, endArgb: 0xFF3F5EFB),
  (startArgb: 0xFF232526, endArgb: 0xFF414345),
  (startArgb: 0xFFEE9CA7, endArgb: 0xFFFFDDE1),
  (startArgb: 0xFF0F2027, endArgb: 0xFF2C5364),
];

/// Phase 5 Ratio & Background panel: `Ratio | Background` tabs.
///
/// Reset restores only the active tab's property (original/16:9 ratio or black
/// background) in one undo step.
class RatioPanel extends StatefulWidget {
  /// Creates the panel.
  const new({
    required this.aspect,
    required this.background,
    required this.onAspect,
    required this.onBackgroundDrag,
    required this.onBackgroundDragEnd,
    required this.onBackgroundSet,
    required this.onPickImage,
    required this.onClose,
    this.original,
    this.initialTab = RatioTab.ratio,
    super.key,
  });

  /// Current canvas aspect ratio.
  final CanvasAspect aspect;

  /// Aspect of the first clip, offered as "Original" when known.
  final CanvasAspect? original;

  /// Current canvas background.
  final CanvasBackground background;

  /// Initial tab.
  final RatioTab initialTab;

  /// Sets the canvas aspect ratio (one undo step).
  final ValueChanged<CanvasAspect> onAspect;

  /// Live background slider drag (coalescing).
  final ValueChanged<CanvasBackground> onBackgroundDrag;

  /// Ends a background slider drag (seals undo step).
  final VoidCallback onBackgroundDragEnd;

  /// Discrete background choice (swatch, preset, typed value, reset).
  final ValueChanged<CanvasBackground> onBackgroundSet;

  /// Opens the device image picker for an image background.
  final VoidCallback onPickImage;

  /// Closes the panel.
  final VoidCallback onClose;

  @override
  State<RatioPanel> createState() => _RatioPanelState();
}

class _RatioPanelState extends State<RatioPanel> {
  late RatioTab _tab = widget.initialTab;
  late _BackgroundMode _mode = _modeOf(widget.background);

  int _lastColorArgb = 0xFF000000;
  GradientBackground _lastGradient = GradientBackground(
    startArgb: backgroundGradientPresets.first.startArgb,
    endArgb: backgroundGradientPresets.first.endArgb,
  );
  double _lastBlur = 0.5;
  ImageBackground? _lastImage;

  static _BackgroundMode _modeOf(CanvasBackground bg) => switch (bg) {
    ColorBackground() => _BackgroundMode.color,
    GradientBackground() => _BackgroundMode.gradient,
    BlurBackground() => _BackgroundMode.blur,
    ImageBackground() => _BackgroundMode.image,
  };

  @override
  void initState() {
    super.initState();
    _remember(widget.background);
  }

  @override
  void didUpdateWidget(RatioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.background != oldWidget.background) {
      _remember(widget.background);
      _mode = _modeOf(widget.background);
    }
  }

  void _remember(CanvasBackground bg) {
    switch (bg) {
      case ColorBackground(:final argb):
        _lastColorArgb = argb;
      case GradientBackground():
        _lastGradient = bg;
      case BlurBackground(:final amount):
        _lastBlur = amount;
      case ImageBackground():
        _lastImage = bg;
    }
  }

  void _selectMode(_BackgroundMode mode) {
    setState(() => _mode = mode);
    switch (mode) {
      case _BackgroundMode.color:
        if (widget.background is! ColorBackground) {
          widget.onBackgroundSet(CanvasBackground.color(argb: _lastColorArgb));
        }
      case _BackgroundMode.gradient:
        if (widget.background is! GradientBackground) {
          widget.onBackgroundSet(_lastGradient);
        }
      case _BackgroundMode.blur:
        if (widget.background is! BlurBackground) {
          widget.onBackgroundSet(CanvasBackground.blur(amount: _lastBlur));
        }
      case _BackgroundMode.image:
        if (widget.background is! ImageBackground && _lastImage != null) {
          widget.onBackgroundSet(_lastImage!);
        }
    }
  }

  VoidCallback? _resetCallback() {
    if (_tab == RatioTab.ratio) {
      final target = widget.original ?? CanvasAspect.landscape16x9;
      return widget.aspect == target ? null : () => widget.onAspect(target);
    }
    return widget.background == CanvasBackground.black
        ? null
        : () => widget.onBackgroundSet(CanvasBackground.black);
  }

  Future<void> _typeNumber({
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
        final parsed = double.tryParse(text.replaceAll('−', '-'));
        if (parsed == null || !(parsed >= min && parsed <= max)) return null;
        return parsed == 0 ? 0 : parsed;
      },
    );
    if (typed != null && mounted) onSubmit(typed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ToolPanel(
      title: l10n.toolRatio,
      onClose: widget.onClose,
      onReset: _resetCallback(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelTabs(
            labels: [l10n.ratioTabRatio, l10n.ratioTabBackground],
            selected: _tab.index,
            onSelect: (i) => setState(() => _tab = RatioTab.values[i]),
          ),
          const SizedBox(height: 8),
          switch (_tab) {
            RatioTab.ratio => _buildRatioTab(context),
            RatioTab.background => _buildBackgroundTab(context),
          },
        ],
      ),
    );
  }

  Widget _buildRatioTab(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final original = widget.original;
    final options = <(CanvasAspect, String)>[
      if (original != null) (original, l10n.aspectOriginal),
      for (final a in CanvasAspect.presets)
        (a, l10n.aspectRatioLabel(a.width, a.height)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, (aspect, label)) in options.indexed)
            _RatioChoice(
              aspect: aspect,
              label: label,
              isOriginal: original != null && i == 0,
              selected: (original != null && i == 0)
                  ? widget.aspect == original &&
                        !CanvasAspect.presets.contains(widget.aspect)
                  : aspect == widget.aspect,
              onTap: () => widget.onAspect(aspect),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundTab(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modes = <(_BackgroundMode, String)>[
      (_BackgroundMode.color, l10n.backgroundColor),
      (_BackgroundMode.gradient, l10n.backgroundGradient),
      (_BackgroundMode.blur, l10n.backgroundBlur),
      (_BackgroundMode.image, l10n.backgroundImage),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final (mode, label) in modes)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _ModePill(
                    label: label,
                    selected: _mode == mode,
                    onTap: () => _selectMode(mode),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        switch (_mode) {
          _BackgroundMode.color => ColorSwatchRow(
            selectedArgb: widget.background is ColorBackground
                ? (widget.background as ColorBackground).argb
                : null,
            onSelect: (argb) =>
                widget.onBackgroundSet(CanvasBackground.color(argb: argb)),
          ),
          _BackgroundMode.gradient => _buildGradientControls(context),
          _BackgroundMode.blur => _buildBlurControls(context),
          _BackgroundMode.image => _buildImageControls(context),
        },
      ],
    );
  }

  Widget _buildGradientControls(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ring = AccentGradient.of(context).linear;
    final current = widget.background is GradientBackground
        ? widget.background as GradientBackground
        : _lastGradient;
    final angle = current.angleDegrees % 360;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
          child: Row(
            children: [
              for (final (i, preset) in backgroundGradientPresets.indexed)
                Semantics(
                  button: true,
                  selected:
                      current.startArgb == preset.startArgb &&
                      current.endArgb == preset.endArgb,
                  label: l10n.gradientSwatchLabel(i + 1),
                  child: InkResponse(
                    onTap: () => widget.onBackgroundSet(
                      CanvasBackground.gradient(
                        startArgb: preset.startArgb,
                        endArgb: preset.endArgb,
                        angleDegrees: angle,
                      ),
                    ),
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
                            gradient:
                                current.startArgb == preset.startArgb &&
                                    current.endArgb == preset.endArgb
                                ? ring
                                : null,
                            border:
                                current.startArgb == preset.startArgb &&
                                    current.endArgb == preset.endArgb
                                ? null
                                : Border.all(color: scheme.outlineVariant),
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // Data, not a design token: user colors.
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(preset.startArgb),
                                  Color(preset.endArgb),
                                ],
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
        ),
        GradientSliderRow(
          label: l10n.backgroundAngle,
          valueText: l10n.rotationValue(angle.round()),
          position: angle / 360,
          snapPositions: const [0, 0.25, 0.5, 0.75, 1],
          onChanged: (p) => widget.onBackgroundDrag(
            current.copyWith(angleDegrees: (p * 360).roundToDouble()),
          ),
          onChangeEnd: widget.onBackgroundDragEnd,
          onTapValue: () => unawaited(
            _typeNumber(
              title: l10n.backgroundAngle,
              current: angle,
              min: 0,
              max: 360,
              onSubmit: (deg) =>
                  widget.onBackgroundSet(current.copyWith(angleDegrees: deg)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlurControls(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amount = widget.background is BlurBackground
        ? (widget.background as BlurBackground).amount
        : _lastBlur;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final level in CanvasBackground.blurLevels)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _ModePill(
                      label: l10n.percentValue((level * 100).round()),
                      selected: (amount - level).abs() < 0.01,
                      onTap: () => widget.onBackgroundSet(
                        CanvasBackground.blur(amount: level),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        GradientSliderRow(
          label: l10n.backgroundBlurAmount,
          valueText: l10n.percentValue((amount * 100).round()),
          position: amount,
          snapPositions: const [0.5],
          onChanged: (p) => widget.onBackgroundDrag(
            CanvasBackground.blur(amount: (p * 100).roundToDouble() / 100),
          ),
          onChangeEnd: widget.onBackgroundDragEnd,
          onTapValue: () => unawaited(
            _typeNumber(
              title: l10n.backgroundBlurAmount,
              current: amount * 100,
              min: 0,
              max: 100,
              onSubmit: (pct) => widget.onBackgroundSet(
                CanvasBackground.blur(amount: pct / 100),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageControls(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = widget.background is ImageBackground
        ? widget.background as ImageBackground
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
          child: OutlinedButton(
            onPressed: widget.onPickImage,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(
              current == null
                  ? l10n.backgroundPickImage
                  : l10n.backgroundChangeImage,
            ),
          ),
        ),
        if (current != null) ...[
          const SizedBox(height: 4),
          GradientSliderRow(
            label: l10n.backgroundBlurAmount,
            valueText: l10n.percentValue((current.blur * 100).round()),
            position: current.blur,
            snapPositions: const [0],
            onChanged: (p) => widget.onBackgroundDrag(
              current.copyWith(blur: (p * 100).roundToDouble() / 100),
            ),
            onChangeEnd: widget.onBackgroundDragEnd,
            onTapValue: () => unawaited(
              _typeNumber(
                title: l10n.backgroundBlurAmount,
                current: current.blur * 100,
                min: 0,
                max: 100,
                onSubmit: (pct) =>
                    widget.onBackgroundSet(current.copyWith(blur: pct / 100)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.onSurface.withValues(alpha: 0.14)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? scheme.onSurface : scheme.outlineVariant,
                ),
              ),
              child: PanelLabel(
                text: label,
                selected: selected,
                fontSize: 12,
                muted: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatioChoice extends StatelessWidget {
  const new({
    required this.aspect,
    required this.label,
    required this.isOriginal,
    required this.selected,
    required this.onTap,
  });

  final CanvasAspect aspect;
  final String label;
  final bool isOriginal;
  final bool selected;
  final VoidCallback onTap;

  static const double _shape = 42;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = aspect.ratio.clamp(0.25, 4.0);
    final width = ratio >= 1 ? _shape : _shape * ratio;
    final height = ratio >= 1 ? _shape / ratio : _shape;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: _shape + 8,
                  child: Center(
                    child: isOriginal
                        ? selected
                              ? ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) =>
                                      AccentGradient.of(context).linear
                                          .createShader(bounds),
                                  child: AppIcon(
                                    AppIcons.fullscreen,
                                    size: 32,
                                    color: scheme.onSurface,
                                  ),
                                )
                              : AppIcon(
                                  AppIcons.fullscreen,
                                  size: 32,
                                  color: scheme.onSurfaceVariant,
                                )
                        : CustomPaint(
                            size: Size(width, height),
                            painter: _RatioOutlinePainter(
                              color: scheme.onSurfaceVariant,
                              gradient: selected
                                  ? AccentGradient.of(context).linear
                                  : null,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
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

class _RatioOutlinePainter extends CustomPainter {
  new({required this.color, this.gradient});

  final Color color;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = gradient == null ? 1.5 : 2
      ..color = color;
    if (gradient case final g?) paint.shader = g.createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RatioOutlinePainter old) =>
      old.color != color || old.gradient != gradient;
}
