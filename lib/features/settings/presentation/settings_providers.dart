import 'dart:io';

import 'package:cleancut/core/storage/app_directories.dart';
import 'package:cleancut/features/settings/data/file_settings_repository.dart';
import 'package:cleancut/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

/// Where settings are stored.
@Riverpod(keepAlive: true)
Future<SettingsRepository> settingsRepository(Ref ref) async {
  final docs = await ref.watch(appDocumentsDirectoryProvider.future);
  return FileSettingsRepository(File(joinPath(docs, ['settings.json'])));
}

/// The current [AppSettings], persisted on change.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  Future<AppSettings> build() async {
    final repo = await ref.watch(settingsRepositoryProvider.future);
    return await repo.load();
  }

  /// Selects the app theme.
  Future<void> setTheme(ThemePreference theme) async {
    final current = state.value ?? const AppSettings();
    final next = current.copyWith(theme: theme);
    state = AsyncData(next);
    await (await ref.read(settingsRepositoryProvider.future)).save(next);
  }
}

/// The [ThemeMode] for `MaterialApp`; dark until settings have loaded.
@riverpod
ThemeMode themeMode(Ref ref) {
  final theme = ref.watch(
    settingsControllerProvider.select(
      (s) => s.value?.theme ?? ThemePreference.dark,
    ),
  );
  return switch (theme) {
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.system => ThemeMode.system,
  };
}
