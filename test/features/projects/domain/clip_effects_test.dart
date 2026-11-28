import 'dart:convert';

import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/data/composition_mapper.dart';
import 'package:cleancut/features/projects/data/project_codec.dart';
import 'package:cleancut/features/projects/domain/commands/clip_commands.dart';
import 'package:cleancut/features/projects/domain/commands/style_commands.dart';
import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/history/history.dart';
import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/clip_effects.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/easing.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/mask_editing.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('BlurLimits & ClipMask model', () {
    test('BlurLimits clamps out-of-range and non-finite values', () {
      expect(BlurLimits.clamp(-0.5), 0);
      expect(BlurLimits.clamp(0.42), 0.42);
      expect(BlurLimits.clamp(2.5), 1);
      expect(BlurLimits.clamp(double.nan), 0);
      expect(BlurLimits.clamp(double.infinity), 0);
    });

    test('ClipMask.defaultFor creates valid defaults for every shape', () {
      for (final shape in MaskShape.values) {
        final mask = ClipMask.defaultFor(shape);
        expect(mask.shape, shape);
        expect(mask.validate(), isEmpty);
        expect(mask.invert, isFalse);
        expect(mask.hasSize, shape != MaskShape.linear);
      }
      expect(
        ClipMask.defaultFor(MaskShape.mirror).at(0).size,
        MaskLimits.defaultMirrorSize,
      );
    });

    test('ClipMask validates ranges and wraps constant rotation', () {
      const base = ClipMask(shape: MaskShape.circle);
      expect(base.validate(), isEmpty);

      expect(
        base
            .copyWith(center: const Animatable.constant(Vec2(x: 2, y: 0)))
            .validate(),
        isNotEmpty,
      );
      expect(
        base
            .copyWith(size: const Animatable.constant(Vec2(x: 0.01, y: 0.5)))
            .validate(),
        isNotEmpty,
      );
      expect(
        base.copyWith(feather: const Animatable.constant(1.5)).validate(),
        isNotEmpty,
      );
      expect(
        base
            .copyWith(rotation: const Animatable.constant(double.nan))
            .validate(),
        isNotEmpty,
      );

      // Constant rotation wraps into [-180, 180].
      final wrapped = base.withValuesAt(0, rotation: 270);
      expect(wrapped.at(0).rotation, -90);

      // Keyframed rotation keeps the nearest turn.
      final kf = base
          .toggledKeyframe(MaskProperty.rotation, 0)
          .withValuesAt(0, rotation: 170)
          .withValuesAt(1000000, rotation: 190);
      expect(kf.at(1000000).rotation, closeTo(190, 1e-9));
    });

    test('Clip.keyframeTimes merges transform, blur and mask keyframes', () {
      final c = project(mainSeconds: [4]).mainTrack.clips.first.copyWith(
        transform: ClipTransform(
          opacity: Animatable.keyframed([Keyframe(timeUs: 500000, value: 1)]),
        ),
        blur: Animatable.keyframed([
          Keyframe(timeUs: 0, value: 0),
          Keyframe(timeUs: 1000000, value: 0.5),
        ]),
        mask: ClipMask(
          shape: MaskShape.star,
          feather: Animatable.keyframed([
            Keyframe(timeUs: 500000, value: 0.2),
            Keyframe(timeUs: 2000000, value: 0.6),
          ]),
        ),
      );
      expect(c.keyframeTimes, [0, 500000, 1000000, 2000000]);
    });
  });

  group('Blur & Mask commands, retiming, schema v5 and mapper', () {
    test('SetClipBlurCommand supports coalescing, keyframes and undo', () {
      var h = History.initial(project(mainSeconds: [4]));

      h = h
          .apply(const SetClipBlurCommand('m0', atUs: 0, amount: 0.2))
          .apply(const SetClipBlurCommand('m0', atUs: 0, amount: 0.6))
          .seal();
      expect(h.present.mainTrack.clips.first.blur.valueAt(0, lerpDouble), 0.6);

      // Keyframe at 0, then add a keyframe at 2s.
      h = h.apply(const ToggleClipBlurKeyframeCommand('m0', atUs: 0));
      h = h
          .apply(
            const SetClipBlurCommand(
              'm0',
              atUs: 2000000,
              amount: 0.1,
              coalesce: false,
            ),
          )
          .seal();
      final animated = h.present.mainTrack.clips.first.blur;
      expect(animated.isAnimated, isTrue);
      expect(animated.valueAt(1000000, lerpDouble), closeTo(0.35, 1e-9));

      // Undo reverts the 2s keyframe, the toggle, and the coalesced drag.
      h = h.undo().undo().undo();
      expect(h.present.mainTrack.clips.first.blur.valueAt(0, lerpDouble), 0);
    });

    test(
      'Mask commands switch shapes preserving params and reject unmasked',
      () {
        var h = History.initial(project(mainSeconds: [4]));

        expect(
          () => const SetClipMaskValuesCommand(
            'm0',
            atUs: 0,
            feather: 0.3,
          ).apply(h.present),
          throwsA(isA<InvalidEditException>()),
        );
        expect(
          () => const ToggleClipMaskKeyframeCommand(
            'm0',
            MaskProperty.feather,
            atUs: 0,
          ).apply(h.present),
          throwsA(isA<InvalidEditException>()),
        );

        h = h.apply(const SetClipMaskShapeCommand('m0', MaskShape.circle));
        h = h
            .apply(
              const SetClipMaskValuesCommand(
                'm0',
                atUs: 0,
                center: Vec2(x: 0.2, y: -0.1),
                feather: 0.35,
                invert: true,
                coalesce: false,
              ),
            )
            .seal();

        // Switching shape preserves center, feather, and invert.
        h = h.apply(const SetClipMaskShapeCommand('m0', MaskShape.heart));
        final mask = h.present.mainTrack.clips.first.mask!;
        expect(mask.shape, MaskShape.heart);
        expect(mask.at(0).center, const Vec2(x: 0.2, y: -0.1));
        expect(mask.at(0).feather, 0.35);
        expect(mask.invert, isTrue);

        // Clearing sets mask to null; undo restores it.
        h = h.apply(const SetClipMaskShapeCommand('m0', null));
        expect(h.present.mainTrack.clips.first.mask, isNull);
        h = h.undo();
        expect(h.present.mainTrack.clips.first.mask?.shape, MaskShape.heart);
      },
    );

    test('Switching mask shapes keeps sizes valid for the new shape', () {
      Vec2 sizeOf(Project p) => p.mainTrack.clips.first.mask!.at(0).size;
      var p = project(mainSeconds: [4]);
      p = const SetClipMaskShapeCommand('m0', MaskShape.rect).apply(p);
      p = const SetClipMaskValuesCommand(
        'm0',
        atUs: 0,
        size: Vec2(x: 1.2, y: 0.4),
      ).apply(p);

      // Rect -> heart: heart and star are uniform, so the size evens out.
      final heart = const SetClipMaskShapeCommand(
        'm0',
        MaskShape.heart,
      ).apply(p);
      expect(sizeOf(heart).x, closeTo(0.8, 1e-9));
      expect(sizeOf(heart).y, closeTo(0.8, 1e-9));

      // Rect -> circle keeps the non-uniform size (an ellipse is valid).
      final circle = const SetClipMaskShapeCommand(
        'm0',
        MaskShape.circle,
      ).apply(p);
      expect(sizeOf(circle), const Vec2(x: 1.2, y: 0.4));

      // Mirror only uses the band half-width, so a closed shape made from it
      // starts at the default size.
      var mirror = const SetClipMaskShapeCommand(
        'm0',
        MaskShape.mirror,
      ).apply(p);
      mirror = const SetClipMaskValuesCommand(
        'm0',
        atUs: 0,
        size: Vec2(x: 1.2, y: 0.2),
      ).apply(mirror);
      final fromMirror = const SetClipMaskShapeCommand(
        'm0',
        MaskShape.circle,
      ).apply(mirror);
      expect(sizeOf(fromMirror), MaskLimits.defaultSize);

      // Linear has no size, so mirror made from it gets the default band.
      var linear = project(mainSeconds: [4]);
      linear = const SetClipMaskShapeCommand(
        'm0',
        MaskShape.linear,
      ).apply(linear);
      final band = const SetClipMaskShapeCommand(
        'm0',
        MaskShape.mirror,
      ).apply(linear);
      expect(sizeOf(band), MaskLimits.defaultMirrorSize);

      // Keyframed sizes are evened out keyframe by keyframe.
      var kf = const ToggleClipMaskKeyframeCommand(
        'm0',
        MaskProperty.size,
        atUs: 0,
      ).apply(p);
      kf = const SetClipMaskValuesCommand(
        'm0',
        atUs: 4000000,
        size: Vec2(x: 0.2, y: 0.6),
      ).apply(kf);
      final star = const SetClipMaskShapeCommand(
        'm0',
        MaskShape.star,
      ).apply(kf).mainTrack.clips.first.mask!;
      expect(star.size.keyframeTimes, [0, 4000000]);
      expect(star.at(0).size.x, closeTo(0.8, 1e-9));
      expect(star.at(4000000).size.x, closeTo(0.4, 1e-9));
      expect(star.at(4000000).size.y, closeTo(0.4, 1e-9));
    });

    test('Split, trim and speed retime blur and mask keyframes', () {
      var p = project(mainSeconds: [4]);
      p = const ToggleClipBlurKeyframeCommand('m0', atUs: 0).apply(p);
      p = const SetClipBlurCommand('m0', atUs: 0, amount: 0).apply(p);
      p = const SetClipBlurCommand('m0', atUs: 4000000, amount: 0.8).apply(p);
      p = const SetClipMaskShapeCommand('m0', MaskShape.rect).apply(p);
      p = const ToggleClipMaskKeyframeCommand(
        'm0',
        MaskProperty.feather,
        atUs: 0,
      ).apply(p);
      p = const SetClipMaskValuesCommand(
        'm0',
        atUs: 4000000,
        feather: 0.6,
      ).apply(p);

      // Split at 2s partitions keyframes with pinned cut values.
      final split = SplitClipCommand(
        'm0',
        timeUs: 2000000,
        newId: sequentialIds('s'),
      ).apply(p);
      final first = split.mainTrack.clips[0];
      final second = split.mainTrack.clips[1];
      expect(first.blur.valueAt(2000000, lerpDouble), closeTo(0.4, 1e-9));
      expect(second.blur.valueAt(0, lerpDouble), closeTo(0.4, 1e-9));
      expect(second.blur.valueAt(2000000, lerpDouble), closeTo(0.8, 1e-9));
      expect(first.mask!.at(2000000).feather, closeTo(0.3, 1e-9));
      expect(second.mask!.at(0).feather, closeTo(0.3, 1e-9));

      // Trim start by 1s shifts keyframes left by 1s.
      final trimmed = const TrimClipCommand(
        'm0',
        sourceInUs: 1000000,
        sourceOutUs: 4000000,
      ).apply(p);
      final tc = trimmed.mainTrack.clips.first;
      expect(tc.blur.valueAt(0, lerpDouble), closeTo(0.2, 1e-9));
      expect(tc.mask!.at(0).feather, closeTo(0.15, 1e-9));

      // 2x speed halves keyframe times.
      final fast = const SetClipSpeedCommand('m0', speed: 2).apply(p);
      final fc = fast.mainTrack.clips.first;
      expect(fc.blur.keyframeTimes, [0, 2000000]);
      expect(fc.mask!.feather.keyframeTimes, [0, 2000000]);
    });

    test('schema v5 round-trips blur & mask and migrates v4', () {
      const codec = ProjectCodec();
      var p = project(mainSeconds: [4]);
      p = const SetClipBlurCommand('m0', atUs: 0, amount: 0.45).apply(p);
      p = const SetClipMaskShapeCommand('m0', MaskShape.star).apply(p);
      p = const SetClipMaskValuesCommand(
        'm0',
        atUs: 0,
        center: Vec2(x: -0.25, y: 0.15),
        size: Vec2(x: 0.9, y: 0.8),
        rotation: 30,
        feather: 0.25,
        invert: true,
      ).apply(p);

      final decoded = codec.decode(codec.encode(p));
      expect(decoded, p);
      expect(decoded.schemaVersion, Project.currentSchemaVersion);
      expect(decoded.mainTrack.clips.first.blur.valueAt(0, lerpDouble), 0.45);
      expect(decoded.mainTrack.clips.first.mask?.shape, MaskShape.star);
      expect(decoded.mainTrack.clips.first.mask?.invert, isTrue);

      // v4 project without blur/mask migrates cleanly to v5.
      final v4Json = project(mainSeconds: [3]).toJson()..['schemaVersion'] = 4;
      final track = v4Json['mainTrack'] as Map<String, dynamic>;
      ((track['clips'] as List<dynamic>).first as Map<String, dynamic>)
        ..remove('blur')
        ..remove('mask');
      final migrated = codec.decode(jsonEncode(v4Json));
      expect(migrated.schemaVersion, Project.currentSchemaVersion);
      expect(migrated.mainTrack.clips.first.blur.valueAt(0, lerpDouble), 0);
      expect(migrated.mainTrack.clips.first.mask, isNull);
    });

    test('compositionSpecOf maps blur & mask and hides mask during Crop', () {
      var p = project(mainSeconds: [2]);
      p = p.copyWith(
        mainTrack: p.mainTrack.copyWith(
          clips: [
            p.mainTrack.clips.first.copyWith(
              blur: Animatable.keyframed([
                Keyframe(timeUs: 0, value: 0, easing: Easing.easeInOut),
                Keyframe(timeUs: 2000000, value: 0.8),
              ]),
              mask: ClipMask(
                shape: MaskShape.mirror,
                invert: true,
                feather: Animatable.keyframed([
                  Keyframe(timeUs: 0, value: 0),
                  Keyframe(timeUs: 2000000, value: 0.5),
                ]),
              ),
            ),
          ],
        ),
      );

      final spec = compositionSpecOf(p);
      final style = spec.clips.first.style;
      // Eased blur produces per-frame samples.
      expect(style.transform.length, greaterThan(2));
      expect(style.transform.first.blur, 0);
      expect(style.transform.last.blur, 0.8);
      expect(style.mask, isNotNull);
      expect(style.mask!.shape, SpecMaskShape.mirror);
      expect(style.mask!.invert, isTrue);
      expect(style.mask!.samples.map((s) => s.timeUs), [0, 2000000]);
      expect(style.mask!.samples.last.feather, 0.5);

      // While Crop is open, mask is hidden so the full clip is visible.
      final cropSpec = compositionSpecOf(p, uncroppedClipId: 'm0');
      expect(cropSpec.clips.first.style.mask, isNull);
    });
  });

  group('Mask editing geometry', () {
    final frame = MaskClipFrame.fromClip(
      canvasWidth: 400,
      canvasHeight: 200,
      sourceRatio: 16 / 9,
      crop: CropRect.full,
      fitMode: FitMode.fit,
      transform: (
        position: const Vec2(x: 0.1, y: -0.2),
        scale: 1,
        rotation: 30,
        opacity: 1,
      ),
    );
    const resolved = (
      center: Vec2(x: 0.2, y: -0.1),
      size: Vec2(x: 0.7, y: 0.5),
      rotation: 20.0,
      feather: 0.25,
    );

    test('canvas <-> mask local coordinate conversions round-trip', () {
      const sample = (x: 245.0, y: 92.0);
      final local = frame.canvasToMaskLocal(resolved, sample);
      final back = frame.maskLocalToCanvas(resolved, local);
      expect(back.x, closeTo(sample.x, 1e-6));
      expect(back.y, closeTo(sample.y, 1e-6));
    });

    test(
      'snapMaskCenter snaps near axes and snapMaskRotation snaps 90 deg',
      () {
        final snapped = snapMaskCenter(
          rawCenter: const Vec2(x: 0.01, y: 0.5),
          frame: frame,
        );
        expect(snapped.snapX, isTrue);
        expect(snapped.snapY, isFalse);
        expect(snapped.center.x, 0);
        expect(snapped.center.y, 0.5);

        final rotSnap = snapMaskRotation(87);
        expect(rotSnap.rotation, 90);
        expect(rotSnap.snappedDegrees, 90);

        final rotFree = snapMaskRotation(42);
        expect(rotFree.rotation, 42);
        expect(rotFree.snappedDegrees, isNull);
      },
    );

    test(
      'dragMaskHandle resizes rect/heart and adjusts feather & rotation',
      () {
        final flat = MaskClipFrame.fromClip(
          canvasWidth: 400,
          canvasHeight: 400,
          sourceRatio: 1,
          crop: CropRect.full,
          fitMode: FitMode.fit,
          transform: (position: Vec2.zero, scale: 1, rotation: 0, opacity: 1),
        );
        const centered = (
          center: Vec2.zero,
          size: Vec2(x: 0.5, y: 0.5),
          rotation: 0.0,
          feather: 0.0,
        );

        // Rect width handle changes only X.
        final rectW = dragMaskHandle(
          shape: MaskShape.rect,
          handle: MaskHandle.width,
          startMask: centered,
          frame: flat,
          canvasPoint: (x: 200 + 160, y: 200),
        );
        expect(rectW.size!.x, closeTo(0.8, 1e-6));
        expect(rectW.size!.y, closeTo(0.5, 1e-6));

        // Heart width handle scales uniformly.
        final heartW = dragMaskHandle(
          shape: MaskShape.heart,
          handle: MaskHandle.width,
          startMask: centered,
          frame: flat,
          canvasPoint: (x: 200 + 160, y: 200),
        );
        expect(heartW.size!.x, closeTo(0.8, 1e-6));
        expect(heartW.size!.y, closeTo(0.8, 1e-6));

        // Feather handle past bottom edge increases feather.
        final f = dragMaskHandle(
          shape: MaskShape.circle,
          handle: MaskHandle.feather,
          startMask: centered,
          frame: flat,
          canvasPoint: (x: 200, y: 200 + 100 + 24 + 50),
        );
        expect(f.feather, closeTo(0.5, 1e-6));

        // Linear rotate handle snaps near 90 deg.
        final rot = dragMaskHandle(
          shape: MaskShape.linear,
          handle: MaskHandle.rotate,
          startMask: centered,
          frame: flat,
          canvasPoint: (x: 202, y: 300),
        );
        expect(rot.rotation, 90);
        expect(rot.snappedDegrees, 90);
      },
    );
  });
}
