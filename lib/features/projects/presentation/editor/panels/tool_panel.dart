import 'dart:ui' show ImageFilter;

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';

/// The VCLIP tool panel (kit "Speed", "Filters", "Alignment"): a blurred
/// `surfaceContainer` sheet with a bold title, a muted Reset and a ✕.
///
/// On phones it replaces the dock; on tablets it fills the properties
/// panel (DESIGN.md §2).
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
    const radius = BorderRadius.vertical(
      top: Radius.circular(AppTokens.sheetRadius),
    );
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: ColoredBox(
          color: scheme.surfaceContainer.withValues(alpha: 0.85),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(34, 0, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onReset,
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.onSurfaceVariant,
                          disabledForegroundColor: scheme.outline,
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
        ),
      ),
    );
  }
}
