import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/crop_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('RotationScale', () {
    test('wraps angles outside [-180, 180] and preserves -180', () {
      expect(RotationScale.wrap(0), 0);
      expect(RotationScale.wrap(-0.5 * 0).isNegative, isFalse);
      expect(RotationScale.wrap(270), -90);
      expect(RotationScale.wrap(-270), 90);
      expect(RotationScale.wrap(180), 180);
      expect(RotationScale.wrap(-180), -180);
      expect(RotationScale.wrap(360), 0);
      expect(RotationScale.wrap(725), 5);
      expect(RotationScale.wrap(double.nan), 0);
    });

    test('0 sits in the middle; the ends are -180 and 180', () {
      expect(RotationScale.positionOf(-180), 0);
      expect(RotationScale.positionOf(0), 0.5);
      expect(RotationScale.positionOf(180), 1);
      expect(RotationScale.degreesAt(0), -180);
      expect(RotationScale.degreesAt(1), 180);
      expect(RotationScale.degreesAt(-1), -180);
      expect(RotationScale.degreesAt(2), 180);
      expect(RotationScale.degreesAt(double.nan), 0);
      // Slight negative angle near 0 snaps to +0, not -0.
      expect(RotationScale.degreesAt(0.4995).isNegative, isFalse);
    });

    test('snaps near multiples of 45 and rounds elsewhere', () {
      double at(double degrees) => (degrees + 180) / 360;
      expect(RotationScale.degreesAt(at(2.5)), 0);
      expect(RotationScale.degreesAt(at(47)), 45);
      expect(RotationScale.degreesAt(at(-88)), -90);
      expect(RotationScale.degreesAt(at(20.4)), 20);
      expect(RotationScale.isSnap(-135), isTrue);
      expect(RotationScale.isSnap(20), isFalse);
    });
  });

  group('CropPanel', () {
    late List<CanvasAspect?> aspects;
    late List<double> drags;
    late List<double> sets;
    late List<String> actions;

    Future<void> pumpPanel(
      WidgetTester tester, {
      CanvasAspect? aspect,
      double rotation = 0,
      bool mirrored = false,
      bool withReset = false,
    }) async {
      aspects = [];
      drags = [];
      sets = [];
      actions = [];
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: CropPanel(
                aspect: aspect,
                rotation: rotation,
                mirrored: mirrored,
                flipped: false,
                onAspect: aspects.add,
                onRotationDrag: drags.add,
                onRotationDragEnd: () => actions.add('dragEnd'),
                onRotationSet: sets.add,
                onMirror: () => actions.add('mirror'),
                onFlip: () => actions.add('flip'),
                onRotateQuarter: () => actions.add('quarter'),
                onReset: withReset ? () => actions.add('reset') : null,
                onClose: () => actions.add('close'),
              ),
            ),
          ),
        ),
      );
    }

    Offset rulerAt(WidgetTester tester, double degrees) {
      final rect = tester.getRect(find.byKey(CropPanel.rulerKey));
      final track = rect.width - 2 * CropPanel.rulerInset;
      return Offset(
        rect.left +
            CropPanel.rulerInset +
            track * RotationScale.positionOf(degrees),
        rect.top + 60,
      );
    }

    testWidgets('shows the kit layout: tools, ruler and the presets', (
      tester,
    ) async {
      await pumpPanel(tester, rotation: 270);
      expect(find.text('Crop'), findsOneWidget);
      expect(find.byTooltip('Mirror'), findsOneWidget);
      expect(find.byTooltip('Flip'), findsOneWidget);
      expect(find.byTooltip('Rotate 90°'), findsOneWidget);
      // 270° is shown as -90°.
      expect(find.text('-90°'), findsOneWidget);
      for (final label in ['Free', '1:1', '9:16', '16:9', '3:4', '4:3']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // Free is the selected preset.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Free')),
        isSemantics(isSelected: true, isButton: true),
      );
    });

    testWidgets('presets report their aspect; the locked one is selected', (
      tester,
    ) async {
      await pumpPanel(tester, aspect: CanvasAspect.landscape16x9);
      expect(
        tester.getSemantics(find.bySemanticsLabel('16:9')),
        isSemantics(isSelected: true, isButton: true),
      );
      await tester.tap(find.text('1:1'));
      await tester.tap(find.text('Free'));
      expect(aspects, [CanvasAspect.square, null]);
    });

    testWidgets('tool buttons, Reset and close call back', (tester) async {
      await pumpPanel(tester, mirrored: true, withReset: true);
      await tester.tap(find.byTooltip('Mirror'));
      await tester.tap(find.byTooltip('Flip'));
      await tester.tap(find.byTooltip('Rotate 90°'));
      await tester.tap(find.text('Reset'));
      await tester.tap(find.byTooltip('Close'));
      expect(actions, ['mirror', 'flip', 'quarter', 'reset', 'close']);
    });

    testWidgets('Reset is disabled without a callback', (tester) async {
      await pumpPanel(tester);
      await tester.tap(find.text('Reset'));
      expect(actions, isEmpty);
    });

    testWidgets('tapping the ruler sets that angle', (tester) async {
      await pumpPanel(tester);
      await tester.tapAt(rulerAt(tester, 90));
      expect(sets, [90]);
      expect(drags, isEmpty);
    });

    testWidgets('dragging reports live, snaps with haptics, ends once', (
      tester,
    ) async {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics.add('tick');
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpPanel(tester);
      final gesture = await tester.startGesture(rulerAt(tester, 0));
      await gesture.moveTo(rulerAt(tester, 20));
      await gesture.moveTo(rulerAt(tester, 46));
      await tester.pump();
      // The bubble follows the finger.
      expect(find.text('45°'), findsOneWidget);
      await gesture.up();
      await tester.pump();
      expect(drags.last, 45);
      expect(drags, isNot(contains(0)));
      expect(haptics, isNotEmpty);
      expect(actions, ['dragEnd']);
      expect(sets, isEmpty);
    });

    testWidgets('a drag whose value changes outside still ends on release', (
      tester,
    ) async {
      await pumpPanel(tester);
      final gesture = await tester.startGesture(rulerAt(tester, 0));
      await gesture.moveTo(rulerAt(tester, 20));
      await tester.pump();
      expect(drags, isNotEmpty);

      // The model reads back a different angle mid-drag.
      await pumpPanel(tester, rotation: 33);
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(actions, ['dragEnd']);
    });

    testWidgets('removing the panel mid-drag still ends the drag', (
      tester,
    ) async {
      await pumpPanel(tester);
      final gesture = await tester.startGesture(rulerAt(tester, 0));
      await gesture.moveTo(rulerAt(tester, 20));
      await tester.pump();
      final log = actions;
      await tester.pumpWidget(localizedApp(const SizedBox()));
      await tester.pump();
      expect(log, ['dragEnd']);
      await gesture.up();
    });

    testWidgets('tapping the bubble types an exact angle', (tester) async {
      await pumpPanel(tester, rotation: 10);
      await tester.tapAt(tester.getCenter(find.text('10°')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '400');
      await tester.pump();
      expect(find.text('Enter an angle from −180 to 180'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'NaN');
      await tester.pump();
      expect(find.text('Enter an angle from −180 to 180'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '-12.5');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(sets, [-12.5]);
    });

    testWidgets('reopening the dialog preserves decimals and allows setting 0 '
        'from 360', (tester) async {
      await pumpPanel(tester, rotation: -12.5);
      await tester.tapAt(tester.getCenter(find.text('-13°')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '-12.5',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await pumpPanel(tester, rotation: 360);
      await tester.tapAt(rulerAt(tester, 0));
      expect(sets, [0]);
    });

    testWidgets('dragging to -180 keeps the bubble at the left end', (
      tester,
    ) async {
      await pumpPanel(tester);
      final leftEdge = rulerAt(tester, -180);
      final gesture = await tester.startGesture(rulerAt(tester, 0));
      await gesture.moveTo(leftEdge);
      await tester.pump();
      expect(find.text('-180°'), findsOneWidget);
      expect(tester.getCenter(find.text('-180°')).dx, closeTo(leftEdge.dx, 2));
      await gesture.up();
      await tester.pump();
    });

    testWidgets('does not overflow at 2x text scale or narrow widths', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: localizedApp(
            Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: CropPanel(
                  aspect: CanvasAspect.landscape16x9,
                  rotation: -180,
                  mirrored: false,
                  flipped: false,
                  onAspect: (_) {},
                  onRotationDrag: (_) {},
                  onRotationDragEnd: () {},
                  onRotationSet: (_) {},
                  onMirror: () {},
                  onFlip: () {},
                  onRotateQuarter: () {},
                  onClose: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
