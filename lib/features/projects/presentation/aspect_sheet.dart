import 'package:cleancut/app/l10n/gen/app_localizations.dart';
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.aspectSheetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (aspect, label) in options)
                  _AspectOption(
                    aspect: aspect,
                    label: label,
                    onTap: () => Navigator.of(context).pop(aspect),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AspectOption extends StatelessWidget {
  const new({required this.aspect, required this.label, required this.onTap});

  final CanvasAspect aspect;
  final String label;
  final VoidCallback onTap;

  static const double _box = 40;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = aspect.ratio.clamp(0.25, 4.0);
    final width = ratio >= 1 ? _box : _box * ratio;
    final height = ratio >= 1 ? _box / ratio : _box;
    return SizedBox(
      width: 80,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
          child: Column(
            children: [
              SizedBox.square(
                dimension: _box,
                child: Center(
                  child: Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.primary, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
