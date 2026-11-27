import 'package:cleancut/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('the app is dark only and settings offer no theme choice', (
    tester,
  ) async {
    final env = TestEnv();
    await env.pumpApp(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    final context = tester.element(find.byType(SettingsScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(find.text('Light'), findsNothing);
    expect(find.byType(RadioListTile<Object>), findsNothing);
  });

  testWidgets('Open source licenses opens the license page', (tester) async {
    final env = TestEnv();
    await env.pumpApp(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open source licenses'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
