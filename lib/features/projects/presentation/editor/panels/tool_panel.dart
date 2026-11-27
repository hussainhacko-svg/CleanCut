import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';

/// The Clipcraft tool panel: a `surfaceContainer` sheet section with a hairline
/// top divider, a bold Manrope title, a muted Reset button and a close button.
///
/// On phones it replaces the tool tray inside the bottom sheet; on tablets it
/// fills the floating right-side Inspector card (DESIGN.md §2).
class ToolPanel extends StatelessWidget {
  /// Creates a panel.
  const new({
    required this.title,
    required this.onClose,
    required this.child,
    this.onReset,
    super.key,
  });

  /// Bold title at the top left.
  final String title;

  /// Closes the panel.
  final VoidCallback onClose;

  /// Restores the default; null shows Reset disabled.
  final VoidCallback? onReset;

  /// The panel's controls.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 0, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation.weight(700)],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onReset,
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onSurfaceVariant,
                      disabledForegroundColor: scheme.outline.withValues(
                        alpha: 0.5,
                      ),
                      textStyle: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                      ),
                      minimumSize: const Size(48, 48),
                    ),
                    child: Text(l10n.commonReset),
                  ),
                  IconButton(
                    tooltip: l10n.commonClose,
                    onPressed: onClose,
                    icon: AppIcon(
                      AppIcons.close,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
