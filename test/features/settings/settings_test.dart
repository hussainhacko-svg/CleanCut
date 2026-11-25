import 'dart:io';

import 'package:cleancut/features/settings/data/file_settings_repository.dart';
import 'package:cleancut/features/settings/domain/app_settings.dart';
import 'package:cleancut/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('choosing Light switches the app theme and saves', (
    tester,
  ) async {
    final env = TestEnv();
    await env.pumpApp(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(SettingsScreen));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(env.settings.stored.theme, ThemePreference.light);
  });

  group('FileSettingsRepository', () {
    late Directory dir;

    setUp(() async => dir = await Directory.systemTemp.createTemp('cc_set'));
    tearDown(() => dir.delete(recursive: true));

    test('round-trips settings', () async {
      final repo = FileSettingsRepository(File('${dir.path}/s.json'));
      expect(await repo.load(), const AppSettings());
      await repo.save(const AppSettings(theme: ThemePreference.system));
      expect(
        await repo.load(),
        const AppSettings(theme: ThemePreference.system),
      );
    });

    test('falls back to defaults for unreadable files', () async {
      final file = File('${dir.path}/s.json');
      await file.writeAsString('{"theme": "neon"}');
      expect(await FileSettingsRepository(file).load(), const AppSettings());
    });
  });
}
