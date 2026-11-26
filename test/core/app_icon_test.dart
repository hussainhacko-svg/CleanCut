import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<SvgPicture> pump(WidgetTester tester, AppIcons icon) async {
    await tester.pumpWidget(
      MaterialApp(home: AppIcon(icon, color: Colors.red)),
    );
    return tester.widget<SvgPicture>(find.byType(SvgPicture));
  }

  testWidgets('single-color icons take the tint', (tester) async {
    final svg = await pump(tester, AppIcons.toolSplit);
    expect(svg.colorFilter, isNotNull);
  });

  testWidgets('two-color icons keep their own colors', (tester) async {
    for (final icon in [
      AppIcons.dockAdd,
      AppIcons.dockBack,
      AppIcons.transition,
    ]) {
      final svg = await pump(tester, icon);
      expect(svg.colorFilter, isNull, reason: icon.name);
    }
  });

  test('every icon points at an asset file', () {
    for (final icon in AppIcons.values) {
      expect(icon.asset, startsWith('assets/icons/'));
      expect(icon.asset, endsWith('.svg'));
    }
  });
}
