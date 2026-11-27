import 'package:cleancut/features/projects/domain/model/canvas_background.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/panel_widgets.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/ratio_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('RatioPanel', () {
    late List<CanvasAspect> aspects;
    late List<CanvasBackground> bgDrags;
    late List<CanvasBackground> bgSets;
    late List<String> events;

    Future<void> pumpPanel(
      WidgetTester tester, {
      CanvasAspect aspect = CanvasAspect.landscape16x9,
      CanvasAspect? original,
      CanvasBackground background = CanvasBackground.black,
      RatioTab initialTab = RatioTab.ratio,
    }) async {
      aspects = [];
      bgDrags = [];
      bgSets = [];
      events = [];
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: RatioPanel(
                aspect: aspect,
                original: original,
                background: background,
                initialTab: initialTab,
                onAspect: aspects.add,
                onBackgroundDrag: bgDrags.add,
                onBackgroundDragEnd: () => events.add('bgDragEnd'),
                onBackgroundSet: bgSets.add,
                onPickImage: () => events.add('pickImage'),
                onClose: () => events.add('close'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows Ratio | Background tabs and selects aspects', (
      tester,
    ) async {
      await pumpPanel(tester, original: CanvasAspect.landscape16x9);
      expect(
        find.descendant(
          of: find.byType(PanelTabs),
          matching: find.text('Ratio'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(PanelTabs),
          matching: find.text('Background'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('9:16'));
      expect(aspects, [CanvasAspect.portrait9x16]);
    });

    testWidgets('Background tab switches Color, Gradient, Blur and Image', (
      tester,
    ) async {
      await pumpPanel(tester, initialTab: RatioTab.background);
      // Color swatch tap.
      await tester.tap(find.bySemanticsLabel('Color 1'));
      expect(
        bgSets.last,
        CanvasBackground.color(argb: styleColorSwatches.first),
      );

      // Gradient mode -> selects default gradient preset.
      await tester.tap(find.text('Gradient'));
      await tester.pump();
      expect(bgSets.last, isA<GradientBackground>());

      // Blur mode -> selects blur background and presets work.
      await tester.tap(find.text('Blur'));
      await tester.pump();
      expect(bgSets.last, const CanvasBackground.blur());
      await tester.tap(find.text('75%'));
      expect(bgSets.last, const CanvasBackground.blur(amount: 0.75));

      // Image mode -> Choose image triggers callback.
      await tester.tap(find.text('Image'));
      await tester.pump();
      await tester.tap(find.text('Choose image'));
      expect(events, contains('pickImage'));
    });

    testWidgets('Reset restores only the active tab', (tester) async {
      await pumpPanel(
        tester,
        aspect: CanvasAspect.square,
        original: CanvasAspect.landscape16x9,
        background: const CanvasBackground.blur(amount: 0.75),
      );
      // On Ratio tab: Reset restores Original (16:9), leaving background alone.
      await tester.tap(find.text('Reset'));
      expect(aspects, [CanvasAspect.landscape16x9]);
      expect(bgSets, isEmpty);

      // Switch to Background tab: Reset restores black background.
      await tester.tap(find.text('Background'));
      await tester.pump();
      await tester.tap(find.text('Reset'));
      expect(bgSets, [CanvasBackground.black]);
    });

    testWidgets('renders cleanly at 2x text scale across tabs', (tester) async {
      for (final tab in RatioTab.values) {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: localizedApp(
              Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: RatioPanel(
                    aspect: CanvasAspect.landscape16x9,
                    original: const CanvasAspect(width: 20, height: 9),
                    background: const CanvasBackground.image(
                      uri: 'content://bg',
                      blur: 0.25,
                    ),
                    initialTab: tab,
                    onAspect: (_) {},
                    onBackgroundDrag: (_) {},
                    onBackgroundDragEnd: () {},
                    onBackgroundSet: (_) {},
                    onPickImage: () {},
                    onClose: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$tab');
      }
    });
  });
}
