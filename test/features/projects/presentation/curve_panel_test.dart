import 'package:cleancut/features/projects/domain/model/speed_curve.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/curve_widgets.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/speed_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('Speed panel tabs', () {
    late List<SpeedCurve?> curves;
    late List<double> speeds;
    late List<bool> pitch;

    Future<void> pumpPanel(
      WidgetTester tester, {
      SpeedCurve? curve,
      double? playhead,
      bool video = true,
    }) async {
      curves = [];
      speeds = [];
      pitch = [];
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                child: SpeedPanel(
                  speed: 1,
                  keepPitch: true,
                  curve: curve,
                  playheadProgress: playhead,
                  onChanged: speeds.add,
                  onCurveChanged: curves.add,
                  onKeepPitchChanged: video ? pitch.add : null,
                  onClose: () {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('starts on Normal without a curve, Curve with one', (
      tester,
    ) async {
      await pumpPanel(tester);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Curve'), findsOneWidget);
      expect(find.byKey(SpeedPanel.rulerKey), findsOneWidget);
      expect(find.byType(CurvePresetRow), findsNothing);

      // A fresh panel (selecting another clip closes and reopens it).
      await tester.pumpWidget(const SizedBox());
      await pumpPanel(tester, curve: SpeedCurvePreset.hero.curve);
      expect(find.byType(CurvePresetRow), findsOneWidget);
      expect(find.byKey(SpeedPanel.rulerKey), findsNothing);
    });

    testWidgets('the Curve tab lists the presets; tapping applies them', (
      tester,
    ) async {
      await pumpPanel(tester);
      await tester.tap(find.text('Curve'));
      await tester.pump();
      for (final label in ['None', 'Custom', 'Montage', 'Hero', 'Bullet']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      await tester.tap(find.text('Montage'));
      expect(curves, [SpeedCurvePreset.montage.curve]);
    });

    testWidgets('None removes the curve; keep pitch stays on both tabs', (
      tester,
    ) async {
      await pumpPanel(tester, curve: SpeedCurvePreset.bullet.curve);
      expect(find.text('Keep pitch'), findsOneWidget);
      await tester.tap(find.text('None'));
      expect(curves, [null]);
      await tester.tap(find.byType(Switch));
      expect(pitch, [false]);
    });

    testWidgets('tapping the selected preset opens the editor', (tester) async {
      await pumpPanel(tester, curve: SpeedCurvePreset.hero.curve);
      await tester.tap(find.text('Hero'));
      await tester.pump();
      expect(curves, isEmpty);
      expect(find.byType(CurveEditor), findsOneWidget);
      await tester.tap(find.text('Presets'));
      await tester.pump();
      expect(find.byType(CurveEditor), findsNothing);
    });

    testWidgets('Reset restores an edited preset, and is off otherwise', (
      tester,
    ) async {
      await pumpPanel(tester, curve: SpeedCurvePreset.hero.curve);
      await tester.tap(find.text('Reset'));
      expect(curves, isEmpty);

      final edited = SpeedCurvePreset.hero.curve.copyWith(
        points: [
          ...SpeedCurvePreset.hero.curve.points.take(2),
          const CurvePoint(x: 0.5, speed: 4),
          ...SpeedCurvePreset.hero.curve.points.skip(3),
        ],
      );
      await pumpPanel(tester, curve: edited);
      await tester.tap(find.text('Reset'));
      expect(curves, [SpeedCurvePreset.hero.curve]);
    });

    testWidgets('Normal tab clears a curve even at the stored speed', (
      tester,
    ) async {
      await pumpPanel(tester, curve: SpeedCurvePreset.montage.curve);
      await tester.tap(find.text('Normal'));
      await tester.pump();
      // Reset must be enabled because a curve is active.
      await tester.tap(find.text('Reset'));
      expect(speeds, [1]);
      // Tapping the 1x label directly must also clear the curve.
      await tester.tap(find.text('1×').last);
      expect(speeds, [1, 1]);
    });

    testWidgets('CurvePresetRow does not overflow at 2x text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedApp(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: CurvePresetRow(
                curve: SpeedCurvePreset.hero.curve,
                onSelect: (_) {},
                onEdit: () {},
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('CurveEditor', () {
    late List<SpeedCurve> changes;

    Future<void> pumpEditor(
      WidgetTester tester,
      SpeedCurve curve, {
      double? playhead,
    }) async {
      changes = [];
      var shown = curve;
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) => CurveEditor(
                  curve: shown,
                  playheadProgress: playhead,
                  onChanged: (c) => setState(() {
                    changes.add(c);
                    shown = c;
                  }),
                  onBack: () {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    /// Global position of [point] on the graph.
    Offset pointAt(WidgetTester tester, CurvePoint point) {
      final rect = tester.getRect(find.byKey(CurveEditor.graphKey));
      const inset = CurveEditor.graphInset;
      const pad = 12.0;
      return Offset(
        rect.left + inset + point.x * (rect.width - 2 * inset),
        rect.top +
            pad +
            (1 - CurveAxis.heightOf(point.speed)) *
                (CurveEditor.graphHeight - 2 * pad),
      );
    }

    testWidgets('dragging a point changes its speed once, on release', (
      tester,
    ) async {
      final curve = SpeedCurvePreset.custom.curve;
      await pumpEditor(tester, curve);
      final middle = curve.points[2];
      final gesture = await tester.startGesture(pointAt(tester, middle));
      await gesture.moveBy(const Offset(0, -20));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      expect(changes, isEmpty);
      await gesture.up();
      expect(changes, hasLength(1));
      final moved = changes.single.points[2];
      expect(moved.speed, greaterThan(1.5));
      expect(moved.x, closeTo(0.5, 1e-9));
      expect(changes.single.preset, SpeedCurvePreset.custom);
      expect(changes.single.validate(), isEmpty);
    });

    testWidgets('end points move only up and down; near 1x snaps', (
      tester,
    ) async {
      final curve = SpeedCurvePreset.flashIn.curve;
      await pumpEditor(tester, curve);
      final first = curve.points.first;
      // Drag the 5x start point down to just above the 1x line.
      final target = pointAt(tester, const CurvePoint(x: 0, speed: 1.05));
      final gesture = await tester.startGesture(pointAt(tester, first));
      await gesture.moveTo(target.translate(30, 0));
      await gesture.up();
      final moved = changes.single.points.first;
      expect(moved.x, 0);
      expect(moved.speed, 1);
    });

    testWidgets('Add point adds one at the playhead and selects it', (
      tester,
    ) async {
      await pumpEditor(tester, SpeedCurvePreset.custom.curve, playhead: 0.6);
      await tester.tap(find.text('Add point'));
      await tester.pump();
      final added = changes.single.points;
      expect(added, hasLength(6));
      expect(added[3].x, 0.6);
      // The new point is selected, so it can be deleted again.
      await tester.tap(find.text('Delete point'));
      await tester.pump();
      expect(changes.last.points, hasLength(5));
    });

    testWidgets('Add point is off without a playhead or on a point', (
      tester,
    ) async {
      await pumpEditor(tester, SpeedCurvePreset.custom.curve);
      final add = find.ancestor(
        of: find.text('Add point'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(tester.widget<ButtonStyleButton>(add).onPressed, isNull);
      await pumpEditor(tester, SpeedCurvePreset.custom.curve, playhead: 0.5);
      expect(tester.widget<ButtonStyleButton>(add).onPressed, isNull);
    });

    testWidgets('end points cannot be deleted', (tester) async {
      final curve = SpeedCurvePreset.custom.curve;
      await pumpEditor(tester, curve);
      await tester.tapAt(pointAt(tester, curve.points.last));
      await tester.pump();
      expect(find.text('Delete point'), findsNothing);
      await tester.tapAt(pointAt(tester, curve.points[1]));
      await tester.pump();
      expect(find.text('Delete point'), findsOneWidget);
    });

    testWidgets('a point drags inside a scrolling panel; the panel stays', (
      tester,
    ) async {
      // Regression (emulator): on a phone the open panel scrolls, and its
      // scroll view took vertical point drags, scrolling instead of editing.
      final curve = SpeedCurvePreset.hero.curve;
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      var shown = curve;
      changes = [];
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 150,
                child: SingleChildScrollView(
                  controller: scroll,
                  child: Column(
                    children: [
                      StatefulBuilder(
                        builder: (context, setState) => CurveEditor(
                          curve: shown,
                          playheadProgress: null,
                          onChanged: (c) => setState(() {
                            changes.add(c);
                            shown = c;
                          }),
                          onBack: () {},
                        ),
                      ),
                      const SizedBox(height: 200),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final start = pointAt(tester, curve.points[2]);
      final gesture = await tester.startGesture(start);
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(0, -10));
        await tester.pump();
      }
      await gesture.up();
      await tester.pump();
      expect(scroll.offset, 0);
      expect(changes, hasLength(1));
      expect(changes.single.points[2].speed, greaterThan(0.25));
    });

    testWidgets('tapping a point selects it without an edit', (tester) async {
      final curve = SpeedCurvePreset.custom.curve;
      await pumpEditor(tester, curve);
      await tester.tapAt(pointAt(tester, curve.points[2]));
      await tester.pump();
      expect(changes, isEmpty);
      expect(find.text('Delete point'), findsOneWidget);
      // A tap off the points clears the selection.
      final rect = tester.getRect(find.byKey(CurveEditor.graphKey));
      await tester.tapAt(rect.topLeft + const Offset(10, 10));
      await tester.pump();
      expect(find.text('Delete point'), findsNothing);
    });

    testWidgets('buttons are 48dp targets', (tester) async {
      await pumpEditor(tester, SpeedCurvePreset.custom.curve, playhead: 0.6);
      expect(tester.getSize(find.text('Add point')).height, lessThan(48));
      final button = find.ancestor(
        of: find.text('Add point'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    });

    testWidgets('dragging a point tightly between neighbors does not throw', (
      tester,
    ) async {
      // IEEE 754: 0.54 + 0.02 > 0.58 - 0.02, which previously crashed clamp().
      const tight = SpeedCurve(
        preset: SpeedCurvePreset.custom,
        points: [
          CurvePoint(x: 0, speed: 1),
          CurvePoint(x: 0.54, speed: 1),
          CurvePoint(x: 0.56, speed: 1),
          CurvePoint(x: 0.58, speed: 1),
          CurvePoint(x: 1, speed: 1),
        ],
      );
      expect(tight.validate(), isEmpty);
      await pumpEditor(tester, tight);
      final gesture = await tester.startGesture(
        pointAt(tester, tight.points[2]),
      );
      await gesture.moveBy(const Offset(5, -20));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(changes, hasLength(1));
      expect(changes.single.points[2].x, 0.56);
      expect(changes.single.points[2].speed, greaterThan(1.2));
    });

    testWidgets('cancelling a point drag discards the edit', (tester) async {
      final curve = SpeedCurvePreset.custom.curve;
      await pumpEditor(tester, curve);
      final gesture = await tester.startGesture(
        pointAt(tester, curve.points[2]),
      );
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();
      await gesture.cancel();
      await tester.pump();
      expect(changes, isEmpty);
    });

    testWidgets('external curve update mid-drag cancels the active drag', (
      tester,
    ) async {
      var shown = SpeedCurvePreset.hero.curve;
      late StateSetter rebuild;
      changes = [];
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return CurveEditor(
                    curve: shown,
                    playheadProgress: null,
                    onChanged: changes.add,
                    onBack: () {},
                  );
                },
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        pointAt(tester, shown.points[2]),
      );
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();
      // External Reset/Undo swaps in a different curve mid-drag.
      rebuild(() => shown = SpeedCurvePreset.custom.curve);
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(changes, isEmpty);
    });
  });
}
