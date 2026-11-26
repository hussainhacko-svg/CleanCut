import 'dart:async';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/features/settings/domain/app_settings.dart';
import 'package:cleancut/features/settings/presentation/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide preferences.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme =
        ref.watch(settingsControllerProvider).value?.theme ??
        ThemePreference.dark;

    String label(ThemePreference p) => switch (p) {
      ThemePreference.dark => l10n.themeDark,
      ThemePreference.light => l10n.themeLight,
      ThemePreference.system => l10n.themeSystem,
    };

    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppTokens.gutter,
          16,
          AppTokens.gutter,
          24,
        ),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 6, 12),
            child: Semantics(
              header: true,
              child: Text(
                l10n.settingsThemeSection,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: RadioGroup<ThemePreference>(
              groupValue: theme,
              onChanged: (value) {
                if (value != null) {
                  unawaited(
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setTheme(value),
                  );
                }
              },
              child: Column(
                children: [
                  for (final p in ThemePreference.values)
                    RadioListTile<ThemePreference>(
                      value: p,
                      title: Text(label(p)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
