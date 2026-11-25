import 'dart:async';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              l10n.settingsThemeSection,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          RadioGroup<ThemePreference>(
            groupValue: theme,
            onChanged: (value) {
              if (value != null) {
                unawaited(
                  ref.read(settingsControllerProvider.notifier).setTheme(value),
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
        ],
      ),
    );
  }
}
