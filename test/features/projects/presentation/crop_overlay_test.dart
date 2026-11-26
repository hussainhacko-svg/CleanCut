import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/presentation/editor/overlays/crop_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('CropOverlay', () {
    late List<CropRect> changes;
    late int ends;

    Future<void> pumpOverlay(
      WidgetTester tester, {
      CropRect crop = CropRect.full,
      double sourceRatio = 16 / 9,
      double rotationDegrees = 0,
      bool flipX = false,
      bool flipY = false,
      VoidCallback? onTapAround,
    }) async {
      changes = [];
      ends = 0;
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: GestureDetector(
              onTap: onTapAround,
              child: Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: CropOverlay(
                    crop: crop,
                    sourceRatio: sourceRatio,
                    rotationDegrees: rotationDegrees,
                    flipX: flipX,
                    flipY: flipY,
                    onChanged: changes.add,
                    onChangeEnd: () => ends++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('fits the overlay box to the source aspect ratio', (
      tester,
    ) async {
      await pumpOverlay(tester);
      final size = tester.getSize(find.byKey(CropOverlay.frameKey));
      expect(size.width, closeTo(320, 0.1));
      expect(size.height, closeTo(180, 0.1));
    });

    testWidgets('dragging a corner resizes the crop and seals on release', (
      tester,
    ) async {
      await pumpOverlay(tester);
      final rect = tester.getRect(find.byKey(CropOverlay.frameKey));
      final gesture = await tester.startGesture(
        rect.topLeft + const Offset(4, 4),
      );
      await gesture.moveBy(const Offset(32, 18));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(changes, isNotEmpty);
      expect(changes.last.left, closeTo(0.1, 0.02));
      expect(changes.last.top, closeTo(0.1, 0.02));
      expect(changes.last.right, 1);
      expect(changes.last.bottom, 1);
      expect(ends, 1);
    });

    testWidgets('picks the handle under the finger-down point, not the point '
        'where the drag was recognized', (tester) async {
      // A competing tap recognizer makes the drag wait for the touch slop.
      await pumpOverlay(tester, onTapAround: () {});
      final rect = tester.getRect(find.byKey(CropOverlay.frameKey));
      // 20dp below the top-left corner: inside the corner's 24dp target. The
      // touch slop is crossed ~35dp from the corner, where only the left
      // edge would be hit.
      final gesture = await tester.startGesture(
        rect.topLeft + const Offset(0, 20),
      );
      await gesture.moveBy(const Offset(30, 30));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(changes, isNotEmpty);
      expect(changes.last.left, greaterThan(0.05));
      expect(changes.last.top, greaterThan(0.05));
    });

    testWidgets('an outside crop change mid-drag still seals the undo step', (
      tester,
    ) async {
      await pumpOverlay(tester);
      final rect = tester.getRect(find.byKey(CropOverlay.frameKey));
      final gesture = await tester.startGesture(
        rect.topLeft + const Offset(4, 4),
      );
      await gesture.moveBy(const Offset(32, 18));
      await tester.pump();
      expect(ends, 0);

      // E.g. Undo while the finger is still down (resets the counters).
      await pumpOverlay(tester, crop: const CropRect(left: 0.3, right: 0.9));
      await tester.pump();
      expect(ends, 1);

      await gesture.up();
      await tester.pump();
      expect(ends, 1);
    });

    testWidgets('a rotation change mid-drag does not move the crop', (
      tester,
    ) async {
      // Control: the same drag with a fixed rotation.
      Future<CropRect> drag({required bool rotateMidway}) async {
        await pumpOverlay(tester);
        final rect = tester.getRect(find.byKey(CropOverlay.frameKey));
        final gesture = await tester.startGesture(
          rect.centerRight - const Offset(4, 0),
        );
        await gesture.moveBy(const Offset(-30, 0));
        await tester.pump();
        if (rotateMidway) {
          // Keyframed rotation while playing: the overlay gets a new angle.
          await pumpOverlay(tester, rotationDegrees: 30);
          await tester.pump();
        }
        await gesture.moveBy(const Offset(-10, 0));
        await tester.pump();
        await gesture.up();
        await tester.pump();
        return changes.last;
      }

      final steady = await drag(rotateMidway: false);
      final rotated = await drag(rotateMidway: true);
      expect(rotated.right, closeTo(steady.right, 1e-9));
      expect(rotated.top, closeTo(steady.top, 1e-9));
      expect(rotated.bottom, closeTo(steady.bottom, 1e-9));
    });

    testWidgets('removing the overlay mid-drag still seals the undo step', (
      tester,
    ) async {
      await pumpOverlay(tester);
      final rect = tester.getRect(find.byKey(CropOverlay.frameKey));
      final gesture = await tester.startGesture(
        rect.topLeft + const Offset(4, 4),
      );
      await gesture.moveBy(const Offset(32, 18));
      await tester.pump();
      expect(ends, 0);

      await tester.pumpWidget(localizedApp(const SizedBox()));
      await tester.pump();
      expect(ends, 1);
      await gesture.up();
      await tester.pump();
      expect(ends, 1);
    });

    testWidgets('dragging inside pans the crop rectangle', (tester) async {
      await pumpOverlay(
        tester,
        crop: const CropRect(left: 0.25, top: 0.25, right: 0.75, bottom: 0.75),
      );
      final rect = tester.getRect(find.byKey(CropOverlay.frameKey));
      await tester.dragFrom(rect.center, const Offset(32, 0));
      await tester.pump();

      expect(changes, isNotEmpty);
      expect(changes.last.left, closeTo(0.35, 0.02));
      expect(changes.last.right, closeTo(0.85, 0.02));
      expect(changes.last.width, closeTo(0.5, 1e-6));
      expect(ends, 1);
    });

    testWidgets('dragging a locked-aspect corner keeps the aspect ratio', (
      tester,
    ) async {
      final locked = CropRect.centered(CanvasAspect.square, 16 / 9);
      await pumpOverlay(tester, crop: locked);
      final rect = tester.getRect(find.byKey(CropOverlay.frameKey));
      final br = Offset(
        rect.left + locked.right * rect.width,
        rect.top + locked.bottom * rect.height,
      );
      await tester.dragFrom(br, const Offset(-40, -20));
      await tester.pump();

      expect(changes, isNotEmpty);
      final last = changes.last;
      expect(last.aspect, CanvasAspect.square);
      expect((last.width * (16 / 9)) / last.height, closeTo(1, 1e-3));
      expect(ends, 1);
    });
  });
}
