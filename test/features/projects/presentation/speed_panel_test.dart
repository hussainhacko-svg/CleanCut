import 'package:cleancut/features/projects/presentation/editor/panels/speed_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/speed_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('SpeedScale', () {
    test('labels sit at even distances, 1x in the middle', () {
      for (final (i, mark) in SpeedScale.marks.indexed) {
        expect(
          SpeedScale.positionOf(mark),
          closeTo(i / (SpeedScale.marks.length - 1), 1e-9),
          reason: '$mark',
        );
      }
      expect(SpeedScale.positionOf(1), 0.5);
    });

    test('covers 0.1x-10x and clamps beyond', () {
      expect(SpeedScale.speedAt(0), 0.1);
      expect(SpeedScale.speedAt(1), 10);
      expect(SpeedScale.speedAt(-1), 0.1);
      expect(SpeedScale.speedAt(2), 10);
      expect(SpeedScale.positionOf(50), 1);
      expect(SpeedScale.positionOf(0.01), 0);
    });

    test('snaps to labels and rounds in between', () {
      expect(SpeedScale.speedAt(0.5 + SpeedScale.snapDistance / 2), 1);
      // Halfway between 1x and 2x is sqrt(2) = 1.414 -> 1.4.
      expect(SpeedScale.speedAt(7 / 12), 1.4);
      // Halfway between 0.5x and 1x is 0.707 -> 0.71.
      expect(SpeedScale.speedAt(5 / 12), 0.71);
    });

    test('positions and speeds round-trip', () {
      for (final speed in [0.13, 0.4, 0.71, 1.4, 3.3, 7.5]) {
        expect(
          SpeedScale.speedAt(SpeedScale.positionOf(speed)),
          closeTo(speed, 0.011),
          reason: '$speed',
        );
      }
    });
  });

  group('SpeedPanel', () {
    late List<double> changes;
    late List<bool> pitch;
    late int closed;

    Future<void> pumpPanel(
      WidgetTester tester, {
      double speed = 1,
      bool withPitch = true,
    }) async {
      changes = [];
      pitch = [];
      closed = 0;
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SpeedPanel(
                speed: speed,
                keepPitch: true,
                onChanged: changes.add,
                onKeepPitchChanged: withPitch ? pitch.add : null,
                onClose: () => closed++,
              ),
            ),
          ),
        ),
      );
    }

    /// Global point on the ruler at the scale's [position].
    Offset rulerAt(WidgetTester tester, double position) {
      final rect = tester.getRect(find.byKey(SpeedPanel.rulerKey));
      final track = rect.width - 2 * SpeedPanel.rulerInset;
      return Offset(
        rect.left + SpeedPanel.rulerInset + track * position,
        rect.top + 60,
      );
    }

    testWidgets('shows the kit layout: title, Reset, close and labels', (
      tester,
    ) async {
      await pumpPanel(tester);
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
      for (final label in ['0.1×', '0.25×', '0.5×', '2×', '5×', '10×']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // 1x is both the bubble and a label.
      expect(find.text('1×'), findsNWidgets(2));
      expect(find.text('Keep pitch'), findsOneWidget);
    });

    testWidgets('tapping the ruler picks that speed', (tester) async {
      await pumpPanel(tester);
      await tester.tapAt(rulerAt(tester, SpeedScale.markPosition(5)));
      expect(changes, [5]);
    });

    testWidgets('dragging reports once, on release, with haptic snaps', (
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
      final gesture = await tester.startGesture(rulerAt(tester, 0.5));
      await gesture.moveTo(rulerAt(tester, 0.6));
      await gesture.moveTo(rulerAt(tester, SpeedScale.markPosition(4)));
      await tester.pump();
      expect(changes, isEmpty);
      // The bubble follows the finger.
      expect(find.text('2×'), findsNWidgets(2));
      await gesture.up();
      expect(changes, [2]);
      expect(haptics, isNotEmpty);
    });

    testWidgets('tapping the bubble types an exact speed', (tester) async {
      await pumpPanel(tester);
      await tester.tapAt(rulerAt(tester, 0.5).translate(0, -35));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();
      expect(find.text('Enter a speed from 0.1 to 10'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '3.5');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(changes, [3.5]);
    });

    testWidgets('Reset is disabled at 1x and returns to 1x otherwise', (
      tester,
    ) async {
      await pumpPanel(tester);
      await tester.tap(find.text('Reset'));
      expect(changes, isEmpty);

      await pumpPanel(tester, speed: 2);
      await tester.tap(find.text('Reset'));
      expect(changes, [1]);
    });

    testWidgets('keep pitch toggles, and is hidden for stills', (tester) async {
      await pumpPanel(tester);
      await tester.tap(find.byType(Switch));
      expect(pitch, [false]);

      await pumpPanel(tester, withPitch: false);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('close and touch targets', (tester) async {
      await pumpPanel(tester);
      await tester.tap(find.byTooltip('Close'));
      expect(closed, 1);
      expect(
        tester.getSize(find.byTooltip('Close')).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(SpeedPanel.rulerKey)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('tapping a speed label picks that speed', (tester) async {
      await pumpPanel(tester);
      await tester.tap(find.text('2×'));
      await tester.tap(find.text('0.25×'));
      expect(changes, [2, 0.25]);
    });

    testWidgets('labels do not overlap at tablet panel width', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: SpeedPanel(
                  speed: 1,
                  keepPitch: true,
                  onChanged: (_) {},
                  onKeepPitchChanged: (_) {},
                  onClose: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final labels = ['0.1×', '0.25×', '0.5×', '1×', '2×', '5×', '10×'];
      // Pick the lower of the two '1×' widgets (mark label, not the bubble).
      final rects = [
        for (final label in labels)
          tester
              .widgetList(find.text(label))
              .indexed
              .map((e) => tester.getRect(find.text(label).at(e.$1)))
              .reduce((a, b) => a.top > b.top ? a : b),
      ];
      for (var i = 0; i < rects.length - 1; i++) {
        expect(
          rects[i].right,
          lessThanOrEqualTo(rects[i + 1].left),
          reason: '${labels[i]} overlaps ${labels[i + 1]}',
        );
      }
    });
  });
}
