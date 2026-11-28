import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/data/composition_mapper.dart';
import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/canvas_background.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/clip_transition.dart';
import 'package:cleancut/features/projects/domain/model/easing.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/domain/model/speed_curve.dart';
import 'package:cleancut/features/projects/domain/model/tracks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fixtures.dart';

void main() {
  test('maps main-track clips with their trims in order', () {
    final p = project(mainSeconds: [5, 3]);
    final trimmed = p.copyWith(
      mainTrack: MainTrack(
        clips: [
          p.mainTrack.clips[0].copyWith(sourceInUs: 1000000),
          p.mainTrack.clips[1],
        ],
      ),
    );
    final spec = compositionSpecOf(trimmed);
    expect(spec.clips, hasLength(2));
    final first = spec.clips.first;
    expect(first.kind, SpecMediaKind.video);
    expect(first.sourceInUs, 1000000);
    expect(first.sourceOutUs, 5000000);
    expect(first.sourceDurationUs, trimmed.mainTrack.clips[0].media.durationUs);
  });

  test('stills use their trim end as source length', () {
    final still = Clip.fromMedia(id: 'i', media: image());
    final spec = compositionSpecOf(
      project().copyWith(mainTrack: MainTrack(clips: [still])),
    );
    final clip = spec.clips.single;
    expect(clip.kind, SpecMediaKind.image);
    expect(clip.sourceDurationUs, still.sourceOutUs);
    expect(clip.sourceInUs, 0);
  });

  test('preview size follows the canvas aspect at 720p', () {
    final p = project().copyWith(
      canvas: const ProjectCanvas(aspect: CanvasAspect.portrait9x16, fps: 24),
    );
    final spec = compositionSpecOf(p);
    expect((spec.canvasWidth, spec.canvasHeight), (720, 1280));
    expect(spec.frameRate, 24);
  });

  test('videos carry their speed and keep-pitch setting', () {
    final p = project(mainSeconds: [4]);
    final fast = p.copyWith(
      mainTrack: MainTrack(
        clips: [p.mainTrack.clips.single.copyWith(speed: 2, keepPitch: false)],
      ),
    );
    final clip = compositionSpecOf(fast).clips.single;
    expect(clip.speed, 2);
    expect(clip.keepPitch, isFalse);
    expect((clip.sourceInUs, clip.sourceOutUs), (0, 4000000));
  });

  test('a sped-up still shows for its timeline length at speed 1', () {
    final still = Clip.fromMedia(
      id: 'i',
      media: image(),
    ).copyWith(sourceInUs: 1000000, sourceOutUs: 5000000, speed: 2);
    final clip = compositionSpecOf(
      project().copyWith(mainTrack: MainTrack(clips: [still])),
    ).clips.single;
    expect(clip.speed, 1);
    expect((clip.sourceInUs, clip.sourceOutUs), (0, 2000000));
    expect(clip.sourceDurationUs, 2000000);
  });

  test('a curved video sends its steps; constant speed sends none', () {
    final p = project(mainSeconds: [4, 2]);
    final curved = p.copyWith(
      mainTrack: MainTrack(
        clips: [
          p.mainTrack.clips[0].copyWith(
            sourceInUs: 1000000,
            speedCurve: SpeedCurvePreset.hero.curve,
          ),
          p.mainTrack.clips[1],
        ],
      ),
    );
    final [a, b] = compositionSpecOf(curved).clips;
    expect(a.speedSteps, hasLength(SpeedCurve.stepCount));
    // Steps are measured from the trim start, over the trimmed 3 s.
    expect(a.speedSteps.first.startUs, 0);
    expect(a.speedSteps.last.startUs, lessThan(3000000));
    expect(
      a.speedSteps.map((s) => s.speed),
      SpeedCurvePreset.hero.curve.stepSpeeds,
    );
    expect(b.speedSteps, isEmpty);
  });

  test('a curved still shows for its timeline length, without steps', () {
    final still = Clip.fromMedia(
      id: 'i',
      media: image(),
    ).copyWith(speedCurve: SpeedCurvePreset.bullet.curve);
    final clip = compositionSpecOf(
      project().copyWith(mainTrack: MainTrack(clips: [still])),
    ).clips.single;
    expect(clip.speedSteps, isEmpty);
    expect(clip.sourceOutUs, still.durationUs);
  });

  test('an empty project maps to no clips', () {
    expect(compositionSpecOf(project()).clips, isEmpty);
  });

  group('looks (Phase 5)', () {
    Project withFirst(Clip Function(Clip) update) {
      final p = project(mainSeconds: [2]);
      return p.copyWith(
        mainTrack: MainTrack(clips: [update(p.mainTrack.clips.single)]),
      );
    }

    test('a default clip maps to no crop, no border and one identity '
        'sample', () {
      final style = compositionSpecOf(project(mainSeconds: [2]))
          .clips
          .single
          .style;
      expect(style.fitMode, SpecFitMode.fit);
      expect(
        [style.cropLeft, style.cropTop, style.cropRight, style.cropBottom],
        [0, 0, 1, 1],
      );
      expect(style.borderWidth, 0);
      expect(style.borderRadius, 0);
      final sample = style.transform.single;
      expect(sample.timeUs, 0);
      expect(
        [sample.x, sample.y, sample.scale, sample.rotation, sample.opacity],
        [0, 0, 1, 0, 1],
      );
    });

    test('fit, crop, flips and border are passed through', () {
      final p = withFirst(
        (c) => c.copyWith(
          fitMode: FitMode.stretch,
          crop: const CropRect(left: 0.1, top: 0.2, right: 0.7, bottom: 0.9),
          border: const ClipBorder(width: 0.02, argb: 0xFF00FF00, radius: 0.3),
          transform: const ClipTransform(flipX: true),
        ),
      );
      final style = compositionSpecOf(p).clips.single.style;
      expect(style.fitMode, SpecFitMode.stretch);
      expect(
        [style.cropLeft, style.cropTop, style.cropRight, style.cropBottom],
        [0.1, 0.2, 0.7, 0.9],
      );
      expect(style.flipX, isTrue);
      expect(style.flipY, isFalse);
      expect(style.borderWidth, 0.02);
      expect(style.borderArgb, 0xFF00FF00);
      expect(style.borderRadius, 0.3);
    });

    test('keyframes sample per frame on eased spans, not flat/linear ones', () {
      final p = withFirst(
        (c) => c.copyWith(
          transform: ClipTransform(
            scale: Animatable.keyframed([
              Keyframe(timeUs: 0, value: 1, easing: Easing.easeInOut),
              Keyframe(timeUs: 1010000, value: 3),
            ]),
          ),
        ),
      );
      final samples = compositionSpecOf(p).clips.single.style.transform;
      final times = [for (final s in samples) s.timeUs];
      expect(times.first, 0);
      expect(times, contains(1010000));
      expect(times.last, 2000000);
      expect(times, orderedEquals([...times]..sort()));
      // 31 frame times across the eased span [0, 1.01 s), the keyframe, and
      // the clip end (no redundant frames on the flat tail).
      expect(times.length, 33);
      final atKeyframe = samples.firstWhere((s) => s.timeUs == 1010000);
      expect(atKeyframe.scale, 3);
      // Eased, not linear: a quarter of the way in is below a quarter.
      final quarter = samples.firstWhere((s) => s.timeUs >= 250000);
      expect(quarter.scale, lessThan(1 + 2 * quarter.timeUs / 1010000));
    });

    test('linear keyframes emit only endpoints and keyframe times', () {
      final t = ClipTransform(
        scale: Animatable.keyframed([
          Keyframe(timeUs: 1000000, value: 1),
          Keyframe(timeUs: 5000000, value: 2),
        ]),
      );
      expect(transformSampleTimes(t, 600000000, 60), [
        0,
        1000000,
        5000000,
        600000000,
      ]);
    });

    test('huge fps is clamped instead of looping forever', () {
      final t = ClipTransform(
        scale: Animatable.keyframed([
          Keyframe(timeUs: 0, value: 1, easing: Easing.easeInOut),
          Keyframe(timeUs: 100000, value: 2),
        ]),
      );
      final times = transformSampleTimes(t, 100000, 10000000);
      expect(times.first, 0);
      expect(times.last, 100000);
      // 240 fps cap => ~25 samples for 0.1 s.
      expect(times.length, lessThan(30));
    });

    test('sample times ignore keyframes past the clip end', () {
      final t = ClipTransform(
        opacity: Animatable.keyframed([Keyframe(timeUs: 9000000, value: 1)]),
      );
      expect(transformSampleTimes(t, 100000, 30).last, 100000);
      expect(transformSampleTimes(const ClipTransform(), 100000, 30), [0]);
    });

    test('every background kind maps', () {
      BackgroundSpec map(CanvasBackground b) => compositionSpecOf(
        project().copyWith(canvas: ProjectCanvas(background: b)),
      ).background;

      final color = map(const CanvasBackground.color(argb: 0xFF123456));
      expect(color.kind, SpecBackgroundKind.color);
      expect(color.argb, 0xFF123456);

      final gradient = map(
        const CanvasBackground.gradient(
          startArgb: 1,
          endArgb: 2,
          angleDegrees: 45,
        ),
      );
      expect(gradient.kind, SpecBackgroundKind.gradient);
      expect([gradient.argb, gradient.endArgb], [1, 2]);
      expect(gradient.angleDegrees, 45);

      final blur = map(const CanvasBackground.blur(amount: 0.75));
      expect(blur.kind, SpecBackgroundKind.blur);
      expect(blur.blur, 0.75);

      final image = map(
        const CanvasBackground.image(uri: 'content://bg', blur: 0.5),
      );
      expect(image.kind, SpecBackgroundKind.image);
      expect(image.imageUri, 'content://bg');
      expect(image.blur, 0.5);
    });

    test('uncroppedClipId renders that clip full-frame fitted, keeping flip '
        'and rotation', () {
      final p = withFirst(
        (c) => c.copyWith(
          fitMode: FitMode.fill,
          crop: const CropRect(left: 0.2, top: 0.2, right: 0.8, bottom: 0.8),
          border: const ClipBorder(width: 0.02, radius: 0.3),
          transform: const ClipTransform(
            flipX: true,
            rotation: Animatable<double>.constant(45),
            scale: Animatable<double>.constant(2),
            opacity: Animatable<double>.constant(0.5),
          ),
        ),
      );
      final clipId = p.mainTrack.clips.single.id;
      final style = compositionSpecOf(
        p,
        uncroppedClipId: clipId,
      ).clips.single.style;
      expect(style.fitMode, SpecFitMode.fit);
      expect(
        [style.cropLeft, style.cropTop, style.cropRight, style.cropBottom],
        [0, 0, 1, 1],
      );
      expect(style.borderWidth, 0);
      expect(style.borderRadius, 0);
      expect(style.flipX, isTrue);
      expect(style.transform.single.rotation, 45);
      expect(style.transform.single.scale, 1);
      expect(style.transform.single.opacity, 1);
    });
  });

  group('transitions (Phase 6C)', () {
    test('maps every TransitionType and caps effective overlap duration', () {
      for (final type in TransitionType.values) {
        final base = project(mainSeconds: [1, 4]);
        final p = base.copyWith(
          mainTrack: base.mainTrack.copyWith(
            transitions: {
              'm0': ClipTransition(type: type, durationUs: 1200000),
            },
          ),
        );
        final spec = compositionSpecOf(p);
        final tr = spec.clips.first.transitionOut;
        expect(tr, isNotNull);
        expect(tr!.type, specTransitionTypeOf(type));
        // Capped at half of the shorter 1 s clip = 0.5 s.
        expect(tr.durationUs, 500000);
        // Last clip never carries an outgoing transition.
        expect(spec.clips.last.transitionOut, isNull);
      }
    });

    test('hard cuts map to null transitionOut', () {
      final spec = compositionSpecOf(project(mainSeconds: [2, 2]));
      expect(spec.clips[0].transitionOut, isNull);
      expect(spec.clips[1].transitionOut, isNull);
    });
  });
}
