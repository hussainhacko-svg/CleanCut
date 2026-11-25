import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
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

/// Grid of canvas aspect ratios to start a project with.
class AspectSheet extends StatelessWidget {
  /// Creates the sheet.
  const new({super.key, this.original});

  /// Aspect of the first picked media, offered as "Original".
  final CanvasAspect? original;

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
                  const CloseButton(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 26),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (aspect, label) in options)
                    _AspectOption(
                      aspect: aspect,
                      label: label,
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

/// A 70dp preset tile with the aspect's shape and a caption, like the VCLIP
/// filter presets.
class _AspectOption extends StatelessWidget {
  const new({required this.aspect, required this.label, required this.onTap});

  final CanvasAspect aspect;
  final String label;
  final VoidCallback onTap;

  static const double _tile = 70;
  static const double _shape = 34;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ratio = aspect.ratio.clamp(0.25, 4.0);
    final width = ratio >= 1 ? _shape : _shape * ratio;
    final height = ratio >= 1 ? _shape / ratio : _shape;
    const radius = BorderRadius.all(Radius.circular(AppTokens.cardRadius));
    return InkWell(
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
                borderRadius: radius,
                border: Border.all(color: scheme.outline),
              ),
              alignment: Alignment.center,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.onSurface, width: 1.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
