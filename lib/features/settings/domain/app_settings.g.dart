// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  theme:
      $enumDecodeNullable(_$ThemePreferenceEnumMap, json['theme']) ??
      ThemePreference.dark,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{'theme': _$ThemePreferenceEnumMap[instance.theme]!};

const _$ThemePreferenceEnumMap = {
  ThemePreference.dark: 'dark',
  ThemePreference.light: 'light',
  ThemePreference.system: 'system',
};
