import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:flutter/material.dart';

/// Shows the canvas aspect picker. Completes with the chosen aspect, or
/// `null` when dismissed. [original] adds an "Original" choice first.
Future<CanvasAspect?> showAspectSheet(
  BuildContext context, {
  CanvasAspect? original,
}) => showModalBottomSheet<CanvasAspect>(
  context: context,
  builder: (context) => AspectSheet(original: original),
);

/// Canvas aspect ratios to start a project with, styled like the kit's
/// "Ratio" frame: a row of bare aspect outlines with captions, the selected
/// one outlined in the accent gradient.
class AspectSheet extends StatelessWidget {
  /// Creates the sheet.
  const new({super.key, this.original, this.selected});

  /// Aspect of the first picked media, offered as "Original".
  final CanvasAspect? original;

  /// The highlighted aspect, if any (none when starting a project).
  final CanvasAspect? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final original = this.original;
    final options = <(CanvasAspect, String)>[
      if (original != null) (original, l10n.aspectOriginal),
      for (final a in CanvasAspect.presets)
        (a, l10n.aspectRatioLabel(a.width, a.height)),
    ];
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0, 18, 0, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Panel header (VCLIP tool panel): title left, close right.
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(32, 0, 26, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.aspectSheetTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // VCLIP panel close mark.
                  IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: AppIcon(
                      AppIcons.close,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, (aspect, label)) in options.indexed)
                    _AspectOption(
                      aspect: aspect,
                      label: label,
                      // "Original" is the kit's "Fit": a corners glyph.
                      isOriginal: original != null && i == 0,
                      selected: (original != null && i == 0)
                          ? selected == original &&
                                !CanvasAspect.presets.contains(selected)
                          : aspect == selected,
                      onTap: () => Navigator.of(context).pop(aspect),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One ratio choice (kit "Ratio"): the aspect drawn as a rounded outline,
/// caption underneath. Selected: accent-gradient outline, bold white
/// caption.
class _AspectOption extends StatelessWidget {
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

  /// Width of one choice (kit: 62 apart) and the shape's bounding box.
  static const double _width = 64;
  static const double _shape = 44;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
        child: SizedBox(
          width: _width,
          child: Column(
            children: [
              SizedBox(
                height: _shape + 12,
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
                                  size: 34,
                                  color: scheme.onSurface,
                                ),
                              )
                            : AppIcon(
                                AppIcons.fullscreen,
                                size: 34,
                                color: scheme.onSurfaceVariant,
                              )
                      : CustomPaint(
                          size: Size(width, height),
                          painter: _ShapePainter(
                            color: scheme.onSurfaceVariant,
                            gradient: selected
                                ? AccentGradient.of(context).linear
                                : null,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
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

/// A rounded rectangle outline, in [gradient] when given, else [color].
class _ShapePainter extends CustomPainter {
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
  bool shouldRepaint(_ShapePainter old) =>
      old.color != color || old.gradient != gradient;
}
