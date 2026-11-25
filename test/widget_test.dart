import 'package:cleancut/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shell renders with dark theme by default', (tester) async {
    await tester.pumpWidget(const CleanCutApp());

    expect(find.text('CleanCut'), findsOneWidget);
    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
