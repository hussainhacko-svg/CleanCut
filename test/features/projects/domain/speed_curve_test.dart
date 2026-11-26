import 'package:cleancut/features/projects/data/project_codec.dart';
import 'package:cleancut/features/projects/domain/commands/clip_commands.dart';
import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/history/history.dart';
import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/speed_curve.dart';
import 'package:cleancut/features/projects/domain/model/tracks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

const s = 1000000;

SpeedCurve flat(double speed) =>
    SpeedCurve.evenly(SpeedCurvePreset.custom, [speed, speed]);

Project withCurve(Project p, SpeedCurve? curve, {int index = 0}) {
  final clips = [...p.mainTrack.clips];
  clips[index] = clips[index].copyWith(speedCurve: curve);
  return p.copyWith(mainTrack: MainTrack(clips: clips));
}

void main() {
  group('presets', () {
    test('have the owner-approved shapes and are valid', () {
      List<double> speeds(SpeedCurvePreset p) => [
        for (final point in p.curve.points) point.speed,
      ];
      expect(speeds(SpeedCurvePreset.montage), [1, 2, 0.5, 2, 1]);
      expect(speeds(SpeedCurvePreset.hero), [1, 1, 0.25, 1, 1]);
      expect(speeds(SpeedCurvePreset.bullet), [2, 0.25, 0.25, 0.25, 2]);
      expect(speeds(SpeedCurvePreset.flashIn), [5, 2, 1, 1, 1]);
      expect(speeds(SpeedCurvePreset.flashOut), [1, 1, 1, 2, 5]);
      expect(speeds(SpeedCurvePreset.custom), everyElement(1));
      for (final p in SpeedCurvePreset.values) {
        expect(p.curve.validate(), isEmpty, reason: '$p');
        expect(p.curve.points.map((e) => e.x), [0, 0.25, 0.5, 0.75, 1]);
        expect(p.curve.preset, p);
      }
    });
  });

  group('SpeedCurve', () {
    test('passes through its points', () {
      final c = SpeedCurvePreset.montage.curve;
      for (final p in c.points) {
        expect(c.speedAt(p.x), closeTo(p.speed, 1e-9), reason: '${p.x}');
      }
    });

    test('never overshoots between points (monotone)', () {
      final c = SpeedCurvePreset.montage.curve;
      for (var x = 0.0; x <= 0.25; x += 0.01) {
        expect(c.speedAt(x), inInclusiveRange(1 - 1e-9, 2 + 1e-9));
      }
      for (var x = 0.25; x <= 0.5; x += 0.01) {
        expect(c.speedAt(x), inInclusiveRange(0.5 - 1e-9, 2 + 1e-9));
      }
      final hero = SpeedCurvePreset.hero.curve;
      for (var x = 0.0; x <= 0.25; x += 0.01) {
        // Flat stretch stays exactly flat.
        expect(hero.speedAt(x), closeTo(1, 1e-9));
      }
    });

    test('a flat curve plays like a constant speed', () {
      expect(flat(1).timePerSource, closeTo(1, 1e-12));
      expect(flat(2).timelineDurationUs(4 * s), 2 * s);
      expect(flat(0.5).timelineDurationUs(4 * s), 8 * s);
    });

    test('length scales linearly with the source (trim stretches)', () {
      final c = SpeedCurvePreset.bullet.curve;
      final a = c.timelineDurationUs(4 * s);
      final b = c.timelineDurationUs(8 * s);
      expect(b, closeTo(2 * a, 1));
      // Bullet is mostly 0.25x: much longer than its source.
      expect(a, greaterThan(8 * s));
    });

    test('steps cover the source and match the length', () {
      final c = SpeedCurvePreset.flashIn.curve;
      const source = 6 * s;
      final steps = c.steps(source);
      expect(steps, hasLength(SpeedCurve.stepCount));
      expect(steps.first.startUs, 0);
      var total = 0.0;
      for (var i = 0; i < steps.length; i++) {
        final end = i + 1 < steps.length ? steps[i + 1].startUs : source;
        expect(end, greaterThan(steps[i].startUs));
        total += (end - steps[i].startUs) / steps[i].speed;
      }
      expect(total, closeTo(c.timelineDurationUs(source), 2));
      // Flash in: fast first, 1x at the end.
      expect(steps.first.speed, greaterThan(3));
      expect(steps.last.speed, closeTo(1, 1e-9));
    });

    test('timeline and source progress map to each other', () {
      final c = SpeedCurvePreset.hero.curve;
      for (final t in [0.0, 0.1, 0.33, 0.5, 0.8, 1.0]) {
        expect(c.timelineFractionAt(c.progressAt(t)), closeTo(t, 1e-9));
      }
      expect(c.progressAt(0), 0);
      expect(c.progressAt(1), closeTo(1, 1e-12));
      // The slow middle takes up more than half of the time.
      expect(
        c.timelineFractionAt(0.75) - c.timelineFractionAt(0.25),
        greaterThan(0.5),
      );
    });

    test('splitting keeps the speed at the cut and about the same length', () {
      final c = SpeedCurvePreset.montage.curve;
      final (left, right) = c.splitAt(0.4);
      expect(left.validate(), isEmpty);
      expect(right.validate(), isEmpty);
      expect(left.points.last.speed, closeTo(c.speedAt(0.4), 1e-9));
      expect(right.points.first.speed, closeTo(c.speedAt(0.4), 1e-9));
      expect(left.preset, SpeedCurvePreset.custom);
      const source = 10 * s;
      final whole = c.timelineDurationUs(source);
      final parts =
          left.timelineDurationUs(4 * s) + right.timelineDurationUs(6 * s);
      expect(parts / whole, closeTo(1, 0.01));
    });

    test('splitting next to a point drops the squeezed point', () {
      final c = SpeedCurvePreset.montage.curve;
      final (left, right) = c.splitAt(0.255);
      expect(left.validate(), isEmpty);
      expect(right.validate(), isEmpty);
    });

    test('validate reports broken curves', () {
      expect(
        const SpeedCurve(
          preset: SpeedCurvePreset.custom,
          points: [CurvePoint(x: 0, speed: 1)],
        ).validate(),
        isNotEmpty,
      );
      expect(
        SpeedCurve.evenly(SpeedCurvePreset.custom, [1, 20]).validate(),
        isNotEmpty,
      );
      expect(
        const SpeedCurve(
          preset: SpeedCurvePreset.custom,
          points: [
            CurvePoint(x: 0, speed: 1),
            CurvePoint(x: 0.01, speed: 1),
            CurvePoint(x: 1, speed: 1),
          ],
        ).validate(),
        isNotEmpty,
      );
      expect(
        const SpeedCurve(
          preset: SpeedCurvePreset.custom,
          points: [CurvePoint(x: 0.1, speed: 1), CurvePoint(x: 1, speed: 1)],
        ).validate(),
        isNotEmpty,
      );
    });
  });

  group('Clip with a curve', () {
    final clip = project(mainSeconds: [8]).mainTrack.clips.single
        .copyWith(speedCurve: SpeedCurvePreset.hero.curve);

    test('length, average speed and offsets follow the curve', () {
      expect(
        clip.durationUs,
        SpeedCurvePreset.hero.curve.timelineDurationUs(8 * s),
      );
      expect(clip.averageSpeed, closeTo(8 * s / clip.durationUs, 1e-6));
      for (final t in [0, s, 3 * s, clip.durationUs]) {
        expect(
          clip.timelineOffsetOf(clip.sourceOffsetAt(t)),
          closeTo(t, 2),
          reason: '$t',
        );
      }
      expect(clip.validate(), isEmpty);
    });

    test('an invalid curve makes the clip invalid', () {
      expect(
        clip
            .copyWith(
              speedCurve: SpeedCurve.evenly(SpeedCurvePreset.custom, [1, 50]),
            )
            .validate(),
        isNotEmpty,
      );
    });
  });

  group('SetClipSpeedCurveCommand', () {
    test('sets and removes a curve; each is one undo step', () {
      final start = project(mainSeconds: [4]);
      final h = History.initial(start)
          .apply(SetClipSpeedCurveCommand('m0', SpeedCurvePreset.bullet.curve))
          .apply(const SetClipSpeedCurveCommand('m0', null));
      expect(h.undoDepth, 2);
      expect(h.present.mainTrack.clips.single.speedCurve, isNull);
      expect(h.present.durationUs, 4 * s);
      final withCurve = h.undo().present;
      expect(
        withCurve.mainTrack.clips.single.speedCurve,
        SpeedCurvePreset.bullet.curve,
      );
      expect(withCurve.durationUs, greaterThan(8 * s));
    });

    test('rejects invalid curves and unknown clips', () {
      final p = project(mainSeconds: [4]);
      expect(
        () => SetClipSpeedCurveCommand(
          'm0',
          SpeedCurve.evenly(SpeedCurvePreset.custom, [1, 50]),
        ).apply(p),
        throwsA(isA<InvalidEditException>()),
      );
      expect(
        () => SetClipSpeedCurveCommand('x', flat(1)).apply(p),
        throwsA(isA<InvalidEditException>()),
      );
    });

    test('the same curve is a no-op', () {
      final p = withCurve(project(mainSeconds: [4]), flat(2));
      expect(SetClipSpeedCurveCommand('m0', flat(2)).apply(p), same(p));
    });

    test('re-times keyframes by the change in length', () {
      final p = project(mainSeconds: [4]);
      final keyed = p.copyWith(
        mainTrack: MainTrack(
          clips: [
            p.mainTrack.clips.single.copyWith(
              transform: ClipTransform(
                opacity: Animatable<double>.keyframed([
                  Keyframe(timeUs: 0, value: 0),
                  Keyframe(timeUs: 2 * s, value: 1),
                ]),
              ),
            ),
          ],
        ),
      );
      final fast = SetClipSpeedCurveCommand('m0', flat(2)).apply(keyed);
      final opacity =
          fast.mainTrack.clips.single.transform.opacity
              as KeyframedAnimatable<double>;
      expect(opacity.keyframes.last.timeUs, s);
    });
  });

  group('other commands on curved clips', () {
    final curved = withCurve(
      project(mainSeconds: [8]),
      SpeedCurvePreset.montage.curve,
    );

    test('a constant speed replaces the curve', () {
      final p = const SetClipSpeedCommand('m0', speed: 1).apply(curved);
      expect(p.mainTrack.clips.single.speedCurve, isNull);
      expect(p.durationUs, 8 * s);
    });

    test('keep pitch leaves the curve alone', () {
      final p = const SetClipKeepPitchCommand(
        'm0',
        keepPitch: false,
      ).apply(curved);
      final clip = p.mainTrack.clips.single;
      expect(clip.keepPitch, isFalse);
      expect(clip.speedCurve, SpeedCurvePreset.montage.curve);
      expect(
        const SetClipKeepPitchCommand('m0', keepPitch: false).apply(p),
        same(p),
      );
    });

    test('split divides the curve between the parts', () {
      final mid = curved.durationUs ~/ 2;
      final p = SplitClipCommand(
        'm0',
        timeUs: mid,
        newId: sequentialIds(),
      ).apply(curved);
      final [a, b] = p.mainTrack.clips;
      expect(a.speedCurve, isNotNull);
      expect(b.speedCurve, isNotNull);
      expect(a.sourceOutUs, b.sourceInUs);
      expect(a.validate(), isEmpty);
      expect(b.validate(), isEmpty);
      // The cut lands at the playhead: the first part lasts about `mid`.
      expect(a.durationUs / mid, closeTo(1, 0.01));
      expect(p.durationUs / curved.durationUs, closeTo(1, 0.01));
    });

    test('trim keeps the curve (stretched) and its clamps are accepted', () {
      final clip = curved.mainTrack.clips.single;
      final end = clampTrimEnd(clip, 0);
      final trimmed = TrimClipCommand(
        'm0',
        sourceInUs: 0,
        sourceOutUs: end,
      ).apply(curved);
      final short = trimmed.mainTrack.clips.single;
      expect(short.speedCurve, clip.speedCurve);
      expect(short.durationUs, greaterThanOrEqualTo(minClipDurationUs));
      final start = clampTrimStart(clip, 8 * s);
      TrimClipCommand(
        'm0',
        sourceInUs: start,
        sourceOutUs: 8 * s,
      ).apply(curved);
    });

    test('duplicate copies the curve', () {
      final p = DuplicateClipCommand(
        'm0',
        newId: sequentialIds(),
      ).apply(curved);
      expect(p.mainTrack.clips[1].speedCurve, SpeedCurvePreset.montage.curve);
    });
  });

  group('storage', () {
    const codec = ProjectCodec();

    test('a curve survives a save and load', () {
      final p = withCurve(
        project(mainSeconds: [4]),
        SpeedCurvePreset.flashOut.curve,
      );
      expect(codec.decode(codec.encode(p)), p);
    });

    test('version 1 files load with no curves', () {
      final v1 = project(mainSeconds: [4]).toJson()..['schemaVersion'] = 1;
      final migrated = codec.migrate(v1);
      expect(migrated['schemaVersion'], Project.currentSchemaVersion);
      final loaded = Project.fromJson(migrated);
      expect(loaded.mainTrack.clips.single.speedCurve, isNull);
      expect(loaded.mainTrack.clips.single.durationUs, 4 * s);
    });
  });
}
