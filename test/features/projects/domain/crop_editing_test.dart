import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/crop_editing.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CropRectEditing', () {
    test('free drag resizes corners and edges within [0, 1] and minSide', () {
      const start = CropRect(left: 0.2, top: 0.2, right: 0.8, bottom: 0.8);
      final br = start.dragged(
        CropHandle.bottomRight,
        dx: 0.1,
        dy: -0.1,
        sourceRatio: 16 / 9,
      );
      expect(br.right, closeTo(0.9, 1e-9));
      expect(br.bottom, closeTo(0.7, 1e-9));
      expect((br.left, br.top), (0.2, 0.2));

      // Dragging past the opposite edge clamps at minSide.
      final tiny = start.dragged(
        CropHandle.left,
        dx: 1,
        dy: 0,
        sourceRatio: 16 / 9,
      );
      expect(tiny.width, closeTo(CropRect.minSide, 1e-9));
      expect(tiny.validate(), isEmpty);

      // Dragging past 0 clamps at 0.
      final clamped = start.dragged(
        CropHandle.topLeft,
        dx: -5,
        dy: -5,
        sourceRatio: 16 / 9,
      );
      expect((clamped.left, clamped.top), (0, 0));
    });

    test('move pans without resizing and clamps inside [0, 1]', () {
      const start = CropRect(left: 0.2, top: 0.3, right: 0.6, bottom: 0.7);
      final moved = start.dragged(
        CropHandle.move,
        dx: 0.5,
        dy: -0.5,
        sourceRatio: 1,
      );
      expect(moved.left, closeTo(0.6, 1e-9));
      expect(moved.right, closeTo(1, 1e-9));
      expect(moved.top, closeTo(0, 1e-9));
      expect(moved.bottom, closeTo(0.4, 1e-9));
      expect(moved.width, closeTo(start.width, 1e-9));
      expect(moved.height, closeTo(start.height, 1e-9));
    });

    test('locked aspect preserves ratio across corners and edges', () {
      // 1:1 crop inside a 16:9 source => normalized width / height = 9/16.
      const sourceRatio = 16 / 9;
      final start = CropRect.centered(CanvasAspect.square, sourceRatio);
      for (final handle in [
        CropHandle.topLeft,
        CropHandle.topRight,
        CropHandle.bottomLeft,
        CropHandle.bottomRight,
        CropHandle.left,
        CropHandle.right,
        CropHandle.top,
        CropHandle.bottom,
      ]) {
        final next = start.dragged(
          handle,
          dx: -0.1,
          dy: -0.1,
          sourceRatio: sourceRatio,
        );
        expect(next.validate(), isEmpty, reason: '$handle');
        expect(next.aspect, CanvasAspect.square, reason: '$handle');
        final visualRatio = (next.width * sourceRatio) / next.height;
        expect(visualRatio, closeTo(1, 1e-6), reason: '$handle');
      }
    });

    test(
      'locked aspect handles extreme source ratios without invalidating',
      () {
        final start = CropRect.centered(CanvasAspect.portrait9x16, 100);
        for (final handle in CropHandle.values) {
          final next = start.dragged(
            handle,
            dx: -0.5,
            dy: -0.5,
            sourceRatio: 100,
          );
          expect(next.validate(), isEmpty, reason: '$handle');
        }
      },
    );

    test('flips map visual drags back to source coordinates', () {
      const start = CropRect(left: 0.1, top: 0.2, right: 0.6, bottom: 0.8);
      // With flipX, visual left edge corresponds to source right edge.
      final next = start.dragged(
        CropHandle.left,
        dx: 0.1,
        dy: 0,
        sourceRatio: 1,
        flipX: true,
      );
      expect(next.left, closeTo(0.1, 1e-9));
      expect(next.right, closeTo(0.5, 1e-9));
    });

    test('non-finite inputs return the original crop', () {
      const start = CropRect(left: 0.1, right: 0.9);
      expect(
        start.dragged(CropHandle.right, dx: double.nan, dy: 0, sourceRatio: 1),
        start,
      );
    });
  });
}
