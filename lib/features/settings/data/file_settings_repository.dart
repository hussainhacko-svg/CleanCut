import 'dart:convert';
import 'dart:io';

import 'package:cleancut/core/storage/atomic_file.dart';

import 'package:cleancut/features/settings/domain/app_settings.dart';

/// Stores [AppSettings] as a JSON file.
final class FileSettingsRepository implements SettingsRepository {
  /// Creates a repository backed by [file].
  const new(this.file);

  /// The settings file.
  final File file;

  @override
  Future<AppSettings> load() async {
    if (!file.existsSync()) return const AppSettings();
    try {
      final json = jsonDecode(await file.readAsString());
      return AppSettings.fromJson(json as Map<String, dynamic>);
    } on Object {
      // Settings are not worth crashing for; fall back to defaults.
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    await AtomicFile.writeString(file, jsonEncode(settings.toJson()));
  }
}
