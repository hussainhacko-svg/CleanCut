import 'dart:io';

import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<SvgPicture> pump(
    WidgetTester tester,
    AppIcons icon, {
    Color? color,
  }) async {
    await tester.pumpWidget(MaterialApp(home: AppIcon(icon, color: color)));
    return tester.widget<SvgPicture>(find.byType(SvgPicture));
  }

  testWidgets('untinted icons keep their Clipcraft category colors', (
    tester,
  ) async {
    for (final icon in [
      AppIcons.toolSplit,
      AppIcons.dockMusic,
      AppIcons.transition,
    ]) {
      final svg = await pump(tester, icon);
      expect(svg.colorFilter, isNull, reason: icon.name);
    }
  });

  testWidgets('neutral icons take the ambient icon color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IconTheme(
          data: IconThemeData(color: Colors.green),
          child: AppIcon(AppIcons.settings),
        ),
      ),
    );
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      svg.colorFilter,
      const ColorFilter.mode(Colors.green, BlendMode.srcIn),
    );
  });

  testWidgets('explicit color tints the icon', (tester) async {
    final svg = await pump(tester, AppIcons.play, color: Colors.white);
    expect(svg.colorFilter, isNotNull);
  });

  test('every icon points to an existing SVG asset file', () {
    for (final icon in AppIcons.values) {
      expect(icon.asset, startsWith('assets/icons/'));
      expect(icon.asset, endsWith('.svg'));
      expect(File(icon.asset).existsSync(), isTrue, reason: icon.asset);
    }
  });
}
