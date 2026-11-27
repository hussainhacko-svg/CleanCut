import 'dart:math' as math;

import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:cleancut/features/projects/presentation/editor/overlays/transform_gizmo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('TransformGizmo', () {
    late List<({Vec2? position, double? scale, double? rotation})> changes;
    late int ends;
    late int starts;

    Future<void> pumpGizmo(
      WidgetTester tester, {
      Vec2 position = Vec2.zero,
      double scale = 1,
      double rotation = 0,
      double sourceRatio = 1,
      CropRect crop = CropRect.full,
      FitMode fitMode = FitMode.fit,
      bool showFrame = false,
    }) async {
      changes = [];
      ends = 0;
      starts = 0;
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: TransformGizmo(
                  position: position,
                  scale: scale,
                  rotation: rotation,
                  sourceRatio: sourceRatio,
                  crop: crop,
                  fitMode: fitMode,
                  showFrame: showFrame,
                  onChanged: ({position, scale, rotation}) => changes.add((
                    position: position,
                    scale: scale,
                    rotation: rotation,
                  )),
                  onChangeStart: () => starts++,
                  onChangeEnd: () => ends++,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('1-finger drag moves position and seals once on release', (
      tester,
    ) async {
      await pumpGizmo(tester);
      final center = tester.getCenter(find.byKey(TransformGizmo.canvasKey));
      final gesture = await tester.startGesture(center);
      // 200×200 canvas => 50px right = +0.5 normalized X, 40px down = +0.4 Y.
      await gesture.moveBy(const Offset(25, 20));
      await tester.pump();
      await gesture.moveBy(const Offset(25, 20));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(changes, isNotEmpty);
      expect(changes.last.position?.x, closeTo(0.5, 0.02));
      expect(changes.last.position?.y, closeTo(0.4, 0.02));
      expect(changes.every((c) => c.scale == null && c.rotation == null), true);
      expect(ends, 1);
    });

    testWidgets('1-finger drag snaps to canvas center when dragged near 0', (
      tester,
    ) async {
      await pumpGizmo(tester, position: const Vec2(x: 0.4, y: 0.4), scale: 0.5);
      final center = tester.getCenter(find.byKey(TransformGizmo.canvasKey));
      final gesture = await tester.startGesture(center);
      // 0.4 * 100px = 40px; moving by (-36, -37) lands within 8px of center.
      await gesture.moveBy(const Offset(-36, -37));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(changes, isNotEmpty);
      expect(changes.last.position, Vec2.zero);
      expect(ends, 1);
    });

    testWidgets('2-finger pinch scales and rotates with 90° snap badge', (
      tester,
    ) async {
      await pumpGizmo(tester);
      final center = tester.getCenter(find.byKey(TransformGizmo.canvasKey));
      // Start two fingers horizontally 40px apart (radius 20).
      final p1 = await tester.startGesture(center + const Offset(-20, 0));
      final p2 = await tester.startGesture(center + const Offset(20, 0));
      await tester.pump();

      // Scale to 2× (radius 40) and rotate ~88° clockwise (snaps to 90°).
      const rad = 88 * math.pi / 180;
      final dx = math.cos(rad) * 40;
      final dy = math.sin(rad) * 40;
      await p1.moveTo(center + Offset(-dx, -dy));
      await p2.moveTo(center + Offset(dx, dy));
      await tester.pump();

      expect(find.byKey(TransformGizmo.rotationBadgeKey), findsOneWidget);
      expect(find.text('90°'), findsOneWidget);

      await p1.up();
      await p2.up();
      await tester.pump();

      expect(find.byKey(TransformGizmo.rotationBadgeKey), findsNothing);
      final scaled = changes.where((c) => c.scale != null).toList();
      final rotated = changes.where((c) => c.rotation != null).toList();
      expect(scaled, isNotEmpty);
      expect(scaled.last.scale, closeTo(2, 0.1));
      expect(rotated, isNotEmpty);
      expect(rotated.last.rotation, 90);
      expect(ends, 1);
    });

    testWidgets('2-finger counter-clockwise twist snaps cleanly to -90°', (
      tester,
    ) async {
      await pumpGizmo(tester);
      final center = tester.getCenter(find.byKey(TransformGizmo.canvasKey));
      final p1 = await tester.startGesture(center + const Offset(-30, 0));
      final p2 = await tester.startGesture(center + const Offset(30, 0));
      await tester.pump();

      // Rotate counter-clockwise by 88° in two steps.
      for (final deg in [-44.0, -88.0]) {
        final rad = deg * math.pi / 180;
        final dx = math.cos(rad) * 30;
        final dy = math.sin(rad) * 30;
        await p1.moveTo(center + Offset(-dx, -dy));
        await p2.moveTo(center + Offset(dx, dy));
        await tester.pump();
      }

      expect(find.text('270°'), findsOneWidget);
      await p1.up();
      await p2.up();
      await tester.pump();

      final rotated = changes.where((c) => c.rotation != null).toList();
      expect(rotated, isNotEmpty);
      expect(rotated.last.rotation, -90);
      expect(ends, 1);
    });

    testWidgets('tap without dragging emits no edits; start and end pair up', (
      tester,
    ) async {
      await pumpGizmo(tester);
      final center = tester.getCenter(find.byKey(TransformGizmo.canvasKey));
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(changes, isEmpty);
      expect(ends, starts);
    });

    testWidgets('an outside change mid-gesture still ends the gesture', (
      tester,
    ) async {
      await pumpGizmo(tester);
      final center = tester.getCenter(find.byKey(TransformGizmo.canvasKey));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(changes, isNotEmpty);
      expect(ends, 0);

      // E.g. Undo while the finger is still down (resets the counters).
      await pumpGizmo(tester, position: const Vec2(x: -0.5, y: 0));
      await tester.pump();
      expect(ends, 1);

      // The rest of the drag is ignored and doesn't end it a second time.
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(changes, isEmpty);
      expect(ends, 1);
    });

    testWidgets('the same angle stored a turn apart is not an outside change', (
      tester,
    ) async {
      // The model may store a twist to 190° as -170° (or the reverse); the
      // gizmo must keep the gesture going.
      await pumpGizmo(tester, rotation: 170);
      final center = tester.getCenter(find.byKey(TransformGizmo.canvasKey));
      final p1 = await tester.startGesture(center + const Offset(-40, 0));
      final p2 = await tester.startGesture(center + const Offset(40, 0));
      await tester.pump();
      const rad = 20 * math.pi / 180;
      for (var i = 1; i <= 4; i++) {
        final a = rad * i / 4;
        final o = Offset(40 * math.cos(a), 40 * math.sin(a));
        await p1.moveTo(center - o);
        await p2.moveTo(center + o);
        await tester.pump();
      }
      expect(changes.last.rotation, isNotNull);
      final emitted = changes.last.rotation!;
      // Parent rebuilds with the equivalent angle a turn away.
      await pumpGizmo(
        tester,
        rotation: emitted > 0 ? emitted - 360 : emitted + 360,
      );
      await tester.pump();
      expect(ends, 0);
      await p1.up();
      await p2.up();
      await tester.pump();
      expect(ends, 1);
    });

    testWidgets('removing the gizmo mid-gesture still ends the gesture', (
      tester,
    ) async {
      await pumpGizmo(tester);
      final center = tester.getCenter(find.byKey(TransformGizmo.canvasKey));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(ends, 0);

      // E.g. another panel opens and replaces the gizmo.
      await tester.pumpWidget(localizedApp(const SizedBox()));
      await tester.pump();
      expect(ends, 1);
      await gesture.up();
      await tester.pump();
      expect(ends, 1);
    });
  });
}
