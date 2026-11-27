import 'dart:convert';

import 'package:cleancut/features/projects/data/project_codec.dart';
import 'package:cleancut/features/projects/domain/commands/clip_commands.dart';
import 'package:cleancut/features/projects/domain/commands/style_commands.dart';
import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/canvas_background.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/easing.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

Animatable<double> _keyed(Map<int, double> values) => Animatable.keyframed([
  for (final e in values.entries) Keyframe(timeUs: e.key, value: e.value),
]);

void main() {
  group('CropRect', () {
    test('full crop is valid and full', () {
      expect(CropRect.full.isFull, isTrue);
      expect(CropRect.full.validate(), isEmpty);
    });

    test('centered crop of a narrower aspect spans the full height', () {
      // 1:1 in a 16:9 source.
      final crop = CropRect.centered(CanvasAspect.square, 16 / 9);
      expect(crop.top, 0);
      expect(crop.bottom, 1);
      expect(crop.width, closeTo(9 / 16, 1e-9));
      expect(crop.left, closeTo((1 - 9 / 16) / 2, 1e-9));
      expect(crop.aspect, CanvasAspect.square);
    });

    test('centered crop of a wider aspect spans the full width', () {
      // 16:9 in a 9:16 source.
      final crop = CropRect.centered(CanvasAspect.landscape16x9, 9 / 16);
      expect(crop.left, 0);
      expect(crop.right, 1);
      expect(crop.height, closeTo((9 / 16) * (9 / 16), 1e-9));
    });

    test('same aspect as the source is the full frame', () {
      final crop = CropRect.centered(CanvasAspect.landscape16x9, 16 / 9);
      expect(crop.width, closeTo(1, 1e-9));
      expect(crop.height, closeTo(1, 1e-9));
    });

    test('centered rejects a non-positive source ratio', () {
      expect(
        () => CropRect.centered(CanvasAspect.square, 0),
        throwsArgumentError,
      );
      expect(
        () => CropRect.centered(CanvasAspect.square, double.nan),
        throwsArgumentError,
      );
    });

    test('centered clamps extreme aspect ratios to minSide', () {
      // Very wide panorama cropped to 9:16.
      final narrow = CropRect.centered(CanvasAspect.portrait9x16, 100);
      expect(narrow.width, closeTo(CropRect.minSide, 1e-9));
      expect(narrow.validate(), isEmpty);

      // Very tall scrolling screenshot cropped to 16:9.
      final wide = CropRect.centered(CanvasAspect.landscape16x9, 0.04);
      expect(wide.height, closeTo(CropRect.minSide, 1e-9));
      expect(wide.validate(), isEmpty);
    });

    test('validate catches out-of-frame, NaN and tiny crops', () {
      expect(const CropRect(left: -0.1).validate(), isNotEmpty);
      expect(const CropRect(bottom: 1.1).validate(), isNotEmpty);
      expect(const CropRect(left: double.nan).validate(), isNotEmpty);
      expect(const CropRect(top: double.nan).validate(), isNotEmpty);
      expect(const CropRect(right: double.nan).validate(), isNotEmpty);
      expect(const CropRect(bottom: double.nan).validate(), isNotEmpty);
      expect(const CropRect(left: 0.5, right: 0.52).validate(), isNotEmpty);
      expect(const CropRect(left: 0.5, right: 0.55).validate(), isEmpty);
      // Inverted rectangles are too small (negative size).
      expect(const CropRect(left: 0.8, right: 0.2).validate(), isNotEmpty);
    });
  });

  group('ClipBorder', () {
    test('default draws nothing', () {
      expect(const ClipBorder().isNone, isTrue);
      expect(const ClipBorder().validate(), isEmpty);
    });

    test('validate checks ranges, including NaN', () {
      expect(const ClipBorder(width: -0.01).validate(), isNotEmpty);
      expect(const ClipBorder(width: 0.06).validate(), isNotEmpty);
      expect(const ClipBorder(radius: 0.51).validate(), isNotEmpty);
      expect(const ClipBorder(radius: double.nan).validate(), isNotEmpty);
      expect(const ClipBorder(width: 0.05, radius: 0.5).validate(), isEmpty);
    });
  });

  group('CanvasBackground', () {
    const all = <CanvasBackground>[
      CanvasBackground.color(argb: 0xFF102030),
      CanvasBackground.gradient(
        startArgb: 0xFF000000,
        endArgb: 0xFFFFFFFF,
        angleDegrees: 30,
      ),
      CanvasBackground.blur(amount: 0.75),
      CanvasBackground.image(uri: 'content://media/image/9', blur: 0.25),
    ];

    test('every kind survives a JSON round-trip', () {
      for (final background in all) {
        final json = jsonDecode(jsonEncode(background.toJson()));
        expect(
          CanvasBackground.fromJson(json as Map<String, dynamic>),
          background,
        );
        expect(background.validate(), isEmpty);
      }
    });

    test('validate checks blur ranges, gradient angles and the image uri', () {
      expect(const CanvasBackground.blur(amount: 1.5).validate(), isNotEmpty);
      expect(
        const CanvasBackground.gradient(
          startArgb: 0xFF000000,
          endArgb: 0xFFFFFFFF,
          angleDegrees: double.nan,
        ).validate(),
        isNotEmpty,
      );
      expect(
        const CanvasBackground.gradient(
          startArgb: 0xFF000000,
          endArgb: 0xFFFFFFFF,
          angleDegrees: double.infinity,
        ).validate(),
        isNotEmpty,
      );
      expect(const CanvasBackground.image(uri: '').validate(), isNotEmpty);
      expect(const CanvasBackground.image(uri: '   ').validate(), isNotEmpty);
      expect(
        const CanvasBackground.image(uri: 'u', blur: -1).validate(),
        isNotEmpty,
      );
    });
  });

  group('Animatable editing', () {
    test('withValueAt replaces a constant', () {
      const a = Animatable<double>.constant(1);
      expect(a.withValueAt(500, 2), const Animatable<double>.constant(2));
    });

    test('withValueAt adds a keyframe to an animated property', () {
      final a = _keyed({0: 1, 1000: 3});
      final b = a.withValueAt(500, 7);
      expect(b.keyframeTimes, [0, 500, 1000]);
      expect(b.valueAt(500, lerpDouble), 7);
    });

    test('withValueAt updates a keyframe within the tolerance in place', () {
      final a = Animatable<double>.keyframed([
        Keyframe(timeUs: 0, value: 1),
        Keyframe(timeUs: 1000, value: 3, easing: Easing.easeIn),
      ]);
      final b = a.withValueAt(990, 9, toleranceUs: 20);
      expect(b.keyframeTimes, [0, 1000]);
      final last = (b as KeyframedAnimatable<double>).keyframes.last;
      expect(last.value, 9);
      expect(last.easing, Easing.easeIn);
    });

    test('keyframeNear picks the closest keyframe', () {
      final a = _keyed({0: 1, 100: 2, 130: 3});
      expect(a.keyframeNear(120, toleranceUs: 50)?.timeUs, 130);
      expect(a.keyframeNear(60, toleranceUs: 10), isNull);
      expect(
        const Animatable<double>.constant(1).keyframeNear(0, toleranceUs: 9),
        isNull,
      );
    });

    test('toggling on a constant pins the current value', () {
      const a = Animatable<double>.constant(4);
      final b = a.toggledKeyframeAt(300, lerpDouble);
      expect(b.isAnimated, isTrue);
      expect(b.keyframeTimes, [300]);
      expect(b.valueAt(0, lerpDouble), 4);
    });

    test('toggling between keyframes adds one with the in-between value', () {
      final a = _keyed({0: 0, 1000: 10});
      final b = a.toggledKeyframeAt(250, lerpDouble);
      expect(b.keyframeTimes, [0, 250, 1000]);
      expect(b.valueAt(250, lerpDouble), 2.5);
    });

    test('toggling at a keyframe removes it; the last one leaves a '
        'constant of its value', () {
      final a = _keyed({0: 1, 1000: 5});
      final b = a.toggledKeyframeAt(1005, lerpDouble, toleranceUs: 10);
      expect(b.keyframeTimes, [0]);
      final c = b.toggledKeyframeAt(0, lerpDouble);
      expect(c, const Animatable<double>.constant(1));
    });
  });

  group('ClipTransform', () {
    test('withValuesAt clamps values into range', () {
      final t = const ClipTransform().withValuesAt(
        0,
        scale: 100,
        opacity: -1,
        position: const Vec2(x: 5, y: double.nan),
        rotation: double.infinity,
      );
      final r = t.at(0);
      expect(r.scale, TransformLimits.maxScale);
      expect(r.opacity, 0);
      expect(r.position, const Vec2(x: TransformLimits.maxOffset, y: 0));
      expect(r.rotation, 0);
      expect(t.validate(), isEmpty);
    });

    test('keyframeTimes merges every property, sorted and distinct', () {
      final t = ClipTransform(
        scale: _keyed({500: 1, 0: 2}),
        opacity: _keyed({500: 1, 200: 0}),
      );
      expect(t.keyframeTimes, [0, 200, 500]);
      expect(t.isAnimated, isTrue);
      expect(t.isAnimatedProperty(TransformProperty.rotation), isFalse);
      expect(t.hasKeyframeNear(TransformProperty.opacity, 210), isFalse);
      expect(
        t.hasKeyframeNear(TransformProperty.opacity, 210, toleranceUs: 10),
        isTrue,
      );
    });

    test('editableAt reads back what withValuesAt wrote near a keyframe', () {
      // Regression: the gizmo read values at the playhead, half a frame from
      // the keyframe the edit updated, saw an interpolated value and
      // cancelled its own drag.
      final t = ClipTransform(
        position: Animatable.keyframed([
          Keyframe(timeUs: 0, value: Vec2.zero),
          Keyframe(timeUs: 2000000, value: const Vec2(x: 0.5, y: 0)),
        ]),
        scale: _keyed({0: 1, 2000000: 2}),
      );
      const at = 2000000 - 5000;
      final edited = t.withValuesAt(
        at,
        position: const Vec2(x: 0.7, y: 0.1),
        scale: 3,
        toleranceUs: 16000,
      );
      final r = edited.editableAt(at, toleranceUs: 16000);
      expect(r.position, const Vec2(x: 0.7, y: 0.1));
      expect(r.scale, 3);
      expect(edited.at(at).position, isNot(const Vec2(x: 0.7, y: 0.1)));
      // Away from keyframes (and for constants) it is the plain value.
      expect(
        edited.editableAt(1000000, toleranceUs: 16000),
        edited.at(1000000),
      );
      expect(
        const ClipTransform().editableAt(5, toleranceUs: 16000),
        const ClipTransform().at(5),
      );
    });

    test('a constant rotation is stored wrapped into [-180, 180]', () {
      double stored(double degrees) => const ClipTransform()
          .withValuesAt(0, rotation: degrees)
          .at(0)
          .rotation;
      expect(stored(190), closeTo(-170, 1e-9));
      expect(stored(360), 0);
      expect(stored(-180), -180);
      expect(stored(180), 180);
      expect(stored(-450), closeTo(-90, 1e-9));
    });

    test('a keyframed rotation keeps the turn nearest its current value', () {
      // Regression: a twist from 170° to 190° stored as -170° spun the clip
      // 340° backwards between keyframes.
      final t = ClipTransform(rotation: _keyed({0: 170, 1000000: 170}));
      final twisted = t.withValuesAt(1000000, rotation: -170);
      expect(twisted.at(1000000).rotation, closeTo(190, 1e-9));
      expect(twisted.at(500000).rotation, closeTo(180, 1e-9));
      // Unwrapped input near the current value stays as it is.
      expect(
        t.withValuesAt(1000000, rotation: 190).at(1000000).rotation,
        closeTo(190, 1e-9),
      );
      // A new keyframe between others follows the interpolated value.
      final spin = ClipTransform(rotation: _keyed({0: 0, 1000000: 720}));
      expect(
        spin.withValuesAt(500000, rotation: 10).at(500000).rotation,
        closeTo(370, 1e-9),
      );
    });

    test('sameAngle compares orientations modulo 360°', () {
      expect(sameAngle(190, -170), isTrue);
      expect(sameAngle(0, 360), isTrue);
      expect(sameAngle(-180, 180), isTrue);
      expect(sameAngle(10, 11), isFalse);
      expect(wrapDegrees(double.nan), 0);
    });

    test('validate rejects out-of-range keyframe values', () {
      expect(ClipTransform(scale: _keyed({0: 1, 9: 0})).validate(), [
        'scale out of range',
      ]);
      expect(ClipTransform(opacity: _keyed({0: 2})).validate(), [
        'opacity out of range',
      ]);
    });
  });

  group('style commands', () {
    Project base() => project(mainSeconds: [2, 3]);
    String firstId(Project p) => p.mainTrack.clips.first.id;

    test('fit mode', () {
      final p = base();
      final q = SetClipFitModeCommand(firstId(p), FitMode.fill).apply(p);
      expect(q.mainTrack.clips.first.fitMode, FitMode.fill);
      expect(q.mainTrack.clips.last, p.mainTrack.clips.last);
    });

    test('setting the same value returns the project unchanged', () {
      final p = base();
      expect(
        identical(SetClipFitModeCommand(firstId(p), FitMode.fit).apply(p), p),
        isTrue,
      );
    });

    test('unknown clips are rejected', () {
      expect(
        () => const SetClipFitModeCommand('nope', FitMode.fill).apply(base()),
        throwsA(isA<InvalidEditException>()),
      );
    });

    test('crop is validated and coalesces per clip', () {
      final p = base();
      const crop = CropRect(left: 0.2, right: 0.8);
      final q = SetClipCropCommand(firstId(p), crop).apply(p);
      expect(q.mainTrack.clips.first.crop, crop);
      expect(
        () => SetClipCropCommand(
          firstId(p),
          const CropRect(left: 0.5, right: 0.5),
        ).apply(p),
        throwsA(isA<InvalidEditException>()),
      );
      expect(
        const SetClipCropCommand('a', crop).coalesceKey,
        const SetClipCropCommand('a', CropRect.full).coalesceKey,
      );
      expect(
        const SetClipCropCommand('a', crop).coalesceKey,
        isNot(const SetClipCropCommand('b', crop).coalesceKey),
      );
      expect(
        const SetClipCropCommand('a', crop, coalesce: false).coalesceKey,
        isNull,
      );
    });

    test('border is validated and supports non-coalescing taps', () {
      final p = base();
      const border = ClipBorder(width: 0.02, radius: 0.1);
      expect(
        SetClipBorderCommand(
          firstId(p),
          border,
        ).apply(p).mainTrack.clips.first.border,
        border,
      );
      expect(
        () => SetClipBorderCommand(
          firstId(p),
          const ClipBorder(width: 1),
        ).apply(p),
        throwsA(isA<InvalidEditException>()),
      );
      expect(
        const SetClipBorderCommand('a', border, coalesce: false).coalesceKey,
        isNull,
      );
    });

    test('transform commands separate different timestamps and opt-out', () {
      expect(
        const SetClipTransformValuesCommand('a', atUs: 0, scale: 2).coalesceKey,
        const SetClipTransformValuesCommand('a', atUs: 0, scale: 3).coalesceKey,
      );
      expect(
        const SetClipTransformValuesCommand('a', atUs: 0, scale: 2).coalesceKey,
        isNot(
          const SetClipTransformValuesCommand(
            'a',
            atUs: 500000,
            scale: 2,
          ).coalesceKey,
        ),
      );
      expect(
        const SetClipTransformValuesCommand(
          'a',
          atUs: 0,
          scale: 2,
          coalesce: false,
        ).coalesceKey,
        isNull,
      );
    });

    test('transform values change a constant for the whole clip', () {
      final p = base();
      final q = SetClipTransformValuesCommand(
        firstId(p),
        atUs: 1000000,
        scale: 2,
        opacity: 0.5,
      ).apply(p);
      final t = q.mainTrack.clips.first.transform;
      expect(t.scale, const Animatable<double>.constant(2));
      expect(t.opacity, const Animatable<double>.constant(0.5));
    });

    test('transform values on an animated property add a keyframe at the '
        'playhead, clamped into the clip', () {
      final p = base();
      final id = firstId(p);
      var q = ToggleClipKeyframeCommand(
        id,
        TransformProperty.scale,
        atUs: 0,
      ).apply(p);
      q = SetClipTransformValuesCommand(id, atUs: 99000000, scale: 3).apply(q);
      final clip = q.mainTrack.clips.first;
      expect(clip.transform.scale.keyframeTimes, [0, clip.durationUs]);
      expect(clip.transform.at(clip.durationUs).scale, 3);
      expect(clip.transform.at(0).scale, 1);
    });

    test('a keyframe within half a frame is updated, not duplicated', () {
      final p = base(); // 30 fps: tolerance 16 666 µs.
      final id = firstId(p);
      var q = ToggleClipKeyframeCommand(
        id,
        TransformProperty.opacity,
        atUs: 500000,
      ).apply(p);
      q = SetClipTransformValuesCommand(
        id,
        atUs: 510000,
        opacity: 0.2,
      ).apply(q);
      final opacity = q.mainTrack.clips.first.transform.opacity;
      expect(opacity.keyframeTimes, [500000]);
      expect(opacity.valueAt(0, lerpDouble), 0.2);
      // Toggling near it removes it again.
      q = ToggleClipKeyframeCommand(
        id,
        TransformProperty.opacity,
        atUs: 490000,
      ).apply(q);
      expect(
        q.mainTrack.clips.first.transform.opacity,
        const Animatable<double>.constant(0.2),
      );
    });

    test('quarter rotation snaps to the next multiple of 90°', () {
      final p = base();
      final id = firstId(p);
      double rotate(double from) {
        final start = SetClipTransformValuesCommand(
          id,
          atUs: 0,
          rotation: from,
        ).apply(p);
        return RotateClipQuarterCommand(
          id,
          atUs: 0,
        ).apply(start).mainTrack.clips.first.transform.at(0).rotation;
      }

      expect(rotate(0), 90);
      expect(rotate(45), 90);
      expect(rotate(90), 180);
      // Constants stay within [-180, 180] (180 + 90 → -90).
      expect(rotate(180), -90);
      expect(rotate(270), 0);
      expect(rotate(-90), 0);
      expect(rotate(-30), 0);
    });

    test('four quarter turns come back to 0° without growing', () {
      // Regression: repeated taps stored 360°, 450°, … so Reset stayed on.
      final p = base();
      final id = firstId(p);
      var q = p;
      final seen = <double>[];
      for (var i = 0; i < 4; i++) {
        q = RotateClipQuarterCommand(id, atUs: 0).apply(q);
        seen.add(q.mainTrack.clips.first.transform.at(0).rotation);
      }
      expect(seen, [90, 180, -90, 0]);
    });

    test('a quarter turn of a keyframed rotation keeps turning clockwise', () {
      final p = base();
      final id = firstId(p);
      final keyed = p.copyWith(
        mainTrack: p.mainTrack.copyWith(
          clips: [
            p.mainTrack.clips.first.copyWith(
              transform: ClipTransform(rotation: _keyed({0: 0, 1000000: 180})),
            ),
            ...p.mainTrack.clips.skip(1),
          ],
        ),
      );
      final q = RotateClipQuarterCommand(id, atUs: 1000000).apply(keyed);
      expect(q.mainTrack.clips.first.transform.at(1000000).rotation, 270);
    });

    test('mirror and flip toggle independently', () {
      final p = base();
      final id = firstId(p);
      final mirrored = ToggleClipFlipCommand(id, horizontal: true).apply(p);
      expect(mirrored.mainTrack.clips.first.transform.flipX, isTrue);
      expect(mirrored.mainTrack.clips.first.transform.flipY, isFalse);
      final both = ToggleClipFlipCommand(id, horizontal: false).apply(mirrored);
      expect(both.mainTrack.clips.first.transform.flipY, isTrue);
      final back = ToggleClipFlipCommand(id, horizontal: true).apply(both);
      expect(back.mainTrack.clips.first.transform.flipX, isFalse);
    });

    test('crop reset clears crop, mirror, flip and rotation in one step', () {
      final p = base();
      final id = firstId(p);
      var q = SetClipCropCommand(
        id,
        const CropRect(left: 0.1, right: 0.9),
      ).apply(p);
      q = ToggleClipFlipCommand(id, horizontal: true).apply(q);
      q = ToggleClipFlipCommand(id, horizontal: false).apply(q);
      q = SetClipTransformValuesCommand(
        id,
        atUs: 0,
        rotation: 30,
        scale: 2,
      ).apply(q);
      final reset = ResetClipCropCommand(id, atUs: 0).apply(q);
      final clip = reset.mainTrack.clips.first;
      expect(clip.crop, CropRect.full);
      expect(clip.transform.flipX, isFalse);
      expect(clip.transform.flipY, isFalse);
      expect(clip.transform.rotation, const Animatable<double>.constant(0));
      // Not a crop-panel property: left alone.
      expect(clip.transform.scale, const Animatable<double>.constant(2));
      expect(ResetClipCropCommand(id, atUs: 0).coalesceKey, isNull);
    });

    test('crop reset of a keyframed rotation zeroes it at the playhead, '
        'clamped into the clip', () {
      final p = base();
      final id = firstId(p);
      var q = SetClipTransformValuesCommand(id, atUs: 0, rotation: 45).apply(p);
      q = ToggleClipKeyframeCommand(
        id,
        TransformProperty.rotation,
        atUs: 0,
      ).apply(q);
      q = ResetClipCropCommand(id, atUs: 99000000).apply(q);
      final clip = q.mainTrack.clips.first;
      expect(clip.transform.rotation.keyframeTimes, [0, clip.durationUs]);
      expect(clip.transform.at(0).rotation, 45);
      expect(clip.transform.at(clip.durationUs).rotation, 0);
    });

    test('crop reset of an untouched clip changes nothing', () {
      final p = base();
      expect(
        identical(ResetClipCropCommand(firstId(p), atUs: 0).apply(p), p),
        isTrue,
      );
    });

    test('background is validated; only slider drags coalesce', () {
      final p = base();
      const blur = CanvasBackground.blur(amount: 0.25);
      expect(
        const SetCanvasBackgroundCommand(blur).apply(p).canvas.background,
        blur,
      );
      expect(
        () =>
            const SetCanvasBackgroundCommand(CanvasBackground.blur(amount: 3))
                .apply(p),
        throwsA(isA<InvalidEditException>()),
      );
      expect(const SetCanvasBackgroundCommand(blur).coalesceKey, isNull);
      expect(
        const SetCanvasBackgroundCommand(blur, coalesce: true).coalesceKey,
        isNotNull,
      );
    });

    test('split keeps crop, border and fit mode on both halves', () {
      final p = base();
      final id = firstId(p);
      var q = SetClipCropCommand(
        id,
        const CropRect(left: 0.1, right: 0.9),
      ).apply(p);
      q = SetClipBorderCommand(id, const ClipBorder(radius: 0.2)).apply(q);
      q = SetClipFitModeCommand(id, FitMode.stretch).apply(q);
      q = SplitClipCommand(id, timeUs: 1000000, newId: () => 'half').apply(q);
      final [left, right, ...] = q.mainTrack.clips;
      for (final clip in [left, right]) {
        expect(clip.crop, const CropRect(left: 0.1, right: 0.9));
        expect(clip.border, const ClipBorder(radius: 0.2));
        expect(clip.fitMode, FitMode.stretch);
      }
    });

    test('keyframes stay on their frames when the speed changes', () {
      final p = base();
      final id = firstId(p);
      var q = ToggleClipKeyframeCommand(
        id,
        TransformProperty.scale,
        atUs: 1000000,
      ).apply(p);
      q = SetClipSpeedCommand(id, speed: 2).apply(q);
      expect(q.mainTrack.clips.first.transform.keyframeTimes, [500000]);
    });
  });

  group('schema 2 -> 3 migration', () {
    test('the canvas color becomes a color background', () {
      final v2 = project(mainSeconds: [1]).toJson()
        ..['schemaVersion'] = 2
        ..['canvas'] = {
          'aspect': {'width': 9, 'height': 16},
          'shortSidePx': 1080,
          'fps': 30,
          'backgroundArgb': 0xFF223344,
        };
      final decoded = const ProjectCodec().decode(jsonEncode(v2));
      expect(decoded.schemaVersion, Project.currentSchemaVersion);
      expect(
        decoded.canvas.background,
        const CanvasBackground.color(argb: 0xFF223344),
      );
      expect(decoded.canvas.aspect, CanvasAspect.portrait9x16);
      expect(decoded.mainTrack.clips.single.crop, CropRect.full);
      expect(decoded.mainTrack.clips.single.border, const ClipBorder());
    });

    test('a v2 canvas without a color gets the default background', () {
      final v2 = project().toJson()
        ..['schemaVersion'] = 2
        ..['canvas'] = <String, dynamic>{'fps': 24};
      final decoded = const ProjectCodec().decode(jsonEncode(v2));
      expect(decoded.canvas.background, CanvasBackground.black);
      expect(decoded.canvas.fps, 24);
    });
  });
}
