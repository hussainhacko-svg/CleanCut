import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/transform_editing.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fittedClipSize', () {
    test('fits, fills, and stretches a 16:9 clip inside a 200×200 square', () {
      final fit = fittedClipSize(
        canvasWidth: 200,
        canvasHeight: 200,
        sourceRatio: 16 / 9,
        crop: CropRect.full,
        fitMode: FitMode.fit,
      );
      expect(fit.width, closeTo(200, 1e-6));
      expect(fit.height, closeTo(112.5, 1e-6));

      final fill = fittedClipSize(
        canvasWidth: 200,
        canvasHeight: 200,
        sourceRatio: 16 / 9,
        crop: CropRect.full,
        fitMode: FitMode.fill,
      );
      expect(fill.height, closeTo(200, 1e-6));
      expect(fill.width, closeTo(200 * 16 / 9, 1e-6));

      final stretch = fittedClipSize(
        canvasWidth: 200,
        canvasHeight: 200,
        sourceRatio: 16 / 9,
        crop: CropRect.full,
        fitMode: FitMode.stretch,
      );
      expect(stretch, (width: 200, height: 200));
    });

    test('accounts for crop aspect ratio', () {
      // Cropping half the width of a 2:1 source yields a 1:1 square.
      final fit = fittedClipSize(
        canvasWidth: 200,
        canvasHeight: 200,
        sourceRatio: 2,
        crop: const CropRect(left: 0.25, right: 0.75),
        fitMode: FitMode.fit,
      );
      expect(fit.width, closeTo(200, 1e-6));
      expect(fit.height, closeTo(200, 1e-6));
    });

    test('handles zero canvas and invalid sourceRatio safely', () {
      expect(
        fittedClipSize(
          canvasWidth: 0,
          canvasHeight: 200,
          sourceRatio: 1,
          crop: CropRect.full,
          fitMode: FitMode.fit,
        ),
        (width: 0, height: 0),
      );
      final fallback = fittedClipSize(
        canvasWidth: 180,
        canvasHeight: 320,
        sourceRatio: double.nan,
        crop: CropRect.full,
        fitMode: FitMode.fit,
      );
      expect(fallback.width, closeTo(180, 1e-6));
      expect(fallback.height, closeTo(320, 1e-6));
    });
  });

  group('snapClipTransform', () {
    test('snaps position to canvas center within 8px and leaves outside', () {
      // 200×200 canvas => 100px per normalized unit => 8px == 0.08.
      final near = snapClipTransform(
        rawPosition: const Vec2(x: 0.06, y: -0.05),
        rawScale: 0.5,
        rawRotation: 0,
        canvasWidth: 200,
        canvasHeight: 200,
        sourceRatio: 1,
        crop: CropRect.full,
        fitMode: FitMode.fit,
      );
      expect(near.position, Vec2.zero);
      expect(near.snap.centerX, isTrue);
      expect(near.snap.centerY, isTrue);

      final far = snapClipTransform(
        rawPosition: const Vec2(x: 0.2, y: -0.2),
        rawScale: 0.5,
        rawRotation: 0,
        canvasWidth: 200,
        canvasHeight: 200,
        sourceRatio: 1,
        crop: CropRect.full,
        fitMode: FitMode.fit,
      );
      expect(far.position, const Vec2(x: 0.2, y: -0.2));
      expect(far.snap.hasAny, isFalse);
    });

    test('snaps scaled clip edges to canvas left, right, top, and bottom', () {
      // 50% square clip on 200×200 canvas => normHalfW = 0.5 =>
      // left edge aligns at x = -0.5, right at +0.5, top at -0.5, bottom +0.5.
      final topLeft = snapClipTransform(
        rawPosition: const Vec2(x: -0.46, y: -0.54),
        rawScale: 0.5,
        rawRotation: 0,
        canvasWidth: 200,
        canvasHeight: 200,
        sourceRatio: 1,
        crop: CropRect.full,
        fitMode: FitMode.fit,
      );
      expect(topLeft.position.x, closeTo(-0.5, 1e-9));
      expect(topLeft.position.y, closeTo(-0.5, 1e-9));
      expect(topLeft.snap.leftEdge, isTrue);
      expect(topLeft.snap.topEdge, isTrue);

      final bottomRight = snapClipTransform(
        rawPosition: const Vec2(x: 0.47, y: 0.53),
        rawScale: 0.5,
        rawRotation: 0,
        canvasWidth: 200,
        canvasHeight: 200,
        sourceRatio: 1,
        crop: CropRect.full,
        fitMode: FitMode.fit,
      );
      expect(bottomRight.position.x, closeTo(0.5, 1e-9));
      expect(bottomRight.position.y, closeTo(0.5, 1e-9));
      expect(bottomRight.snap.rightEdge, isTrue);
      expect(bottomRight.snap.bottomEdge, isTrue);
    });

    test('prefers center guide on ties for a full-width clip', () {
      final res = snapClipTransform(
        rawPosition: const Vec2(x: 0.02, y: 0.02),
        rawScale: 1,
        rawRotation: 0,
        canvasWidth: 200,
        canvasHeight: 200,
        sourceRatio: 1,
        crop: CropRect.full,
        fitMode: FitMode.fit,
      );
      expect(res.position, Vec2.zero);
      expect(res.snap.centerX, isTrue);
      expect(res.snap.centerY, isTrue);
      expect(res.snap.leftEdge, isFalse);
      expect(res.snap.rightEdge, isFalse);
    });

    test('uses rotated bounding box for edge snapping', () {
      // 2:1 clip fitted in 200×200 => base 200×100. At scale 0.5 => 100×50.
      // Rotated 90° => visual size 50×100 => normHalfW = 0.25, normHalfH = 0.5.
      // Right edge aligns at x = 1 - 0.25 = 0.75.
      final res = snapClipTransform(
        rawPosition: const Vec2(x: 0.73, y: 0.2),
        rawScale: 0.5,
        rawRotation: 90,
        canvasWidth: 200,
        canvasHeight: 200,
        sourceRatio: 2,
        crop: CropRect.full,
        fitMode: FitMode.fit,
      );
      expect(res.position.x, closeTo(0.75, 1e-9));
      expect(res.snap.rightEdge, isTrue);
    });

    test('snaps rotation to 0/90/180/270° only when snapRotation is true', () {
      for (final (raw, expected, badge) in [
        (3.5, 0.0, 0),
        (-4.0, 0.0, 0),
        (93.0, 90.0, 90),
        (-92.0, -90.0, 270),
        (177.0, 180.0, 180),
        (-178.0, -180.0, 180),
        (274.0, -90.0, 270),
        (362.0, 0.0, 0),
      ]) {
        final res = snapClipTransform(
          rawPosition: const Vec2(x: 0.3, y: 0.3),
          rawScale: 0.5,
          rawRotation: raw,
          canvasWidth: 200,
          canvasHeight: 200,
          sourceRatio: 1,
          crop: CropRect.full,
          fitMode: FitMode.fit,
          snapRotation: true,
        );
        expect(res.rotation, expected);
        expect(res.snap.rotationDegrees, badge);
      }

      // Does not snap rotation when snapRotation is false (e.g. 1-finger pan).
      final noRotSnap = snapClipTransform(
        rawPosition: const Vec2(x: 0.3, y: 0.3),
        rawScale: 0.5,
        rawRotation: 3,
        canvasWidth: 200,
        canvasHeight: 200,
        sourceRatio: 1,
        crop: CropRect.full,
        fitMode: FitMode.fit,
      );
      expect(noRotSnap.rotation, 3);
      expect(noRotSnap.snap.rotationDegrees, isNull);
    });

    test('clamps extreme positions, scales, and NaN values', () {
      final res = snapClipTransform(
        rawPosition: const Vec2(x: 9, y: -9),
        rawScale: 50,
        rawRotation: double.nan,
        canvasWidth: 200,
        canvasHeight: 200,
        sourceRatio: 1,
        crop: CropRect.full,
        fitMode: FitMode.fit,
      );
      expect(res.position, const Vec2(x: 2, y: -2));
      expect(res.scale, TransformLimits.maxScale);
      expect(res.rotation, 0);
    });

    test('TransformSnap.hasNewSnapSince detects newly engaged targets', () {
      const prev = TransformSnap(centerX: true);
      expect(prev.hasNewSnapSince(prev), isFalse);
      expect(
        const TransformSnap(centerX: true, centerY: true).hasNewSnapSince(prev),
        isTrue,
      );
      expect(
        const TransformSnap(rotationDegrees: 90).hasNewSnapSince(prev),
        isTrue,
      );
      expect(TransformSnap.none.hasNewSnapSince(prev), isFalse);
    });
  });

  test('rotation comes back wrapped into [-180, 180]', () {
    SnappedTransform at(double degrees) => snapClipTransform(
      rawPosition: Vec2.zero,
      rawScale: 1,
      rawRotation: degrees,
      canvasWidth: 100,
      canvasHeight: 100,
      sourceRatio: 1,
      crop: CropRect.full,
      fitMode: FitMode.fit,
    );
    expect(at(400).rotation, closeTo(40, 1e-9));
    expect(at(-200).rotation, closeTo(160, 1e-9));
    expect(at(180).rotation, 180);
    expect(at(-180).rotation, -180);
    expect(at(540).rotation, 180);
  });
}
