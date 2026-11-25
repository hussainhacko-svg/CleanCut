import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// Which theme the app uses.
enum ThemePreference {
  /// Dark theme (default).
  dark,

  /// Light theme.
  light,

  /// Follow the device setting.
  system,
}

/// User preferences that apply to the whole app.
@freezed
abstract class AppSettings with _$AppSettings {
  /// Creates settings; defaults match a fresh install.
  const factory({@Default(ThemePreference.dark) ThemePreference theme}) =
      _AppSettings;

  /// Parses settings from JSON. Unknown values fall back to defaults.
  factory fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);
}

/// Loads and stores [AppSettings].
abstract interface class SettingsRepository {
  /// The stored settings, or defaults when none or unreadable.
  Future<AppSettings> load();

  /// Stores [settings].
  Future<void> save(AppSettings settings);
}
