import 'dart:convert';

import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/easing.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:cleancut/features/projects/domain/model/tracks.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('Micros', () {
    test('converts units', () {
      expect(Micros.fromMilliseconds(1500), 1500000);
      expect(Micros.fromSeconds(1.25), 1250000);
      expect(Micros.toSeconds(2500000), 2.5);
    });

    test('scales by speed and rounds', () {
      expect(Micros.scaledBySpeed(1000000, 2), 500000);
      expect(Micros.scaledBySpeed(1000000, 0.5), 2000000);
      expect(Micros.scaledBySpeed(1000000, 3), 333333);
    });

    test('rejects non-positive speed', () {
      expect(() => Micros.scaledBySpeed(1, 0), throwsArgumentError);
      expect(() => Micros.scaledBySpeed(1, -1), throwsArgumentError);
    });
  });

  group('TimeRange', () {
    test('is half-open', () {
      final r = TimeRange(10, 20);
      expect(r.contains(10), isTrue);
      expect(r.contains(19), isTrue);
      expect(r.contains(20), isFalse);
      expect(r.durationUs, 10);
    });

    test('touching ranges do not overlap', () {
      expect(TimeRange(0, 10).overlaps(TimeRange(10, 20)), isFalse);
      expect(TimeRange(0, 11).overlaps(TimeRange(10, 20)), isTrue);
    });

    test('zero-length range', () {
      final r = TimeRange(5, 5);
      expect(r.isEmpty, isTrue);
      expect(r.contains(5), isFalse);
    });

    test('rejects end before start', () {
      expect(() => TimeRange(5, 4), throwsArgumentError);
    });
  });

  group('Easing', () {
    test('linear is identity', () {
      for (final t in [0.0, 0.25, 0.5, 0.9, 1.0]) {
        expect(Easing.linear.transform(t), t);
      }
    });

    test('end points are fixed and input is clamped', () {
      for (final e in [Easing.easeIn, Easing.easeOut, Easing.easeInOut]) {
        expect(e.transform(0), 0);
        expect(e.transform(1), 1);
        expect(e.transform(-1), 0);
        expect(e.transform(2), 1);
      }
    });

    test('ease-in is slow at start, ease-out fast', () {
      expect(Easing.easeIn.transform(0.25), lessThan(0.25));
      expect(Easing.easeOut.transform(0.25), greaterThan(0.25));
      expect(Easing.easeInOut.transform(0.5), closeTo(0.5, 1e-6));
    });

    test('is monotonic for standard curves', () {
      var previous = 0.0;
      for (var i = 1; i <= 100; i++) {
        final v = Easing.easeInOut.transform(i / 100);
        expect(v, greaterThanOrEqualTo(previous));
        previous = v;
      }
    });
  });

  group('Animatable', () {
    test('constant returns its value everywhere', () {
      const a = Animatable<double>.constant(3);
      expect(a.valueAt(-5, lerpDouble), 3);
      expect(a.valueAt(1 << 40, lerpDouble), 3);
      expect(a.isAnimated, isFalse);
    });

    test('keyframes are sorted and interpolated', () {
      final a = Animatable<double>.keyframed([
        Keyframe(timeUs: 1000, value: 10),
        Keyframe(timeUs: 0, value: 0),
      ]);
      expect(a.valueAt(0, lerpDouble), 0);
      expect(a.valueAt(500, lerpDouble), 5);
      expect(a.valueAt(1000, lerpDouble), 10);
    });

    test('holds first and last values outside the keyframes', () {
      final a = Animatable<double>.keyframed([
        Keyframe(timeUs: 100, value: 1),
        Keyframe(timeUs: 200, value: 2),
      ]);
      expect(a.valueAt(0, lerpDouble), 1);
      expect(a.valueAt(999, lerpDouble), 2);
    });

    test('single keyframe acts like a constant', () {
      final a = Animatable<double>.keyframed([Keyframe(timeUs: 50, value: 7)]);
      expect(a.valueAt(0, lerpDouble), 7);
      expect(a.valueAt(100, lerpDouble), 7);
    });

    test('uses the easing of the earlier keyframe', () {
      final a = Animatable<double>.keyframed([
        Keyframe(timeUs: 0, value: 0, easing: Easing.easeIn),
        Keyframe(timeUs: 100, value: 1),
      ]);
      expect(a.valueAt(50, lerpDouble), Easing.easeIn.transform(0.5));
    });

    test('picks the right segment among many keyframes', () {
      final a = Animatable<double>.keyframed([
        for (var i = 0; i <= 10; i++)
          Keyframe(timeUs: i * 100, value: (i * i).toDouble()),
      ]);
      expect(a.valueAt(750, lerpDouble), closeTo((49 + 64) / 2, 1e-9));
    });

    test('rejects empty and duplicate keyframes', () {
      expect(() => Animatable<double>.keyframed(const []), throwsArgumentError);
      expect(
        () => Animatable<double>.keyframed([
          Keyframe(timeUs: 5, value: 1),
          Keyframe(timeUs: 5, value: 2),
        ]),
        throwsArgumentError,
      );
    });

    test('rejects negative keyframe time', () {
      expect(() => Keyframe(timeUs: -1, value: 0), throwsArgumentError);
    });

    test('value equality', () {
      expect(
        Animatable<double>.keyframed([Keyframe(timeUs: 0, value: 1)]),
        Animatable<double>.keyframed([Keyframe(timeUs: 0, value: 1)]),
      );
      expect(
        const Animatable<double>.constant(1),
        isNot(Animatable<double>.keyframed([Keyframe(timeUs: 0, value: 1)])),
      );
    });

    test('JSON round-trip of keyframed Vec2', () {
      const converter = AnimatableVec2Converter();
      final a = Animatable<Vec2>.keyframed([
        Keyframe(timeUs: 0, value: Vec2.zero, easing: Easing.easeOut),
        Keyframe(timeUs: 10, value: const Vec2(x: 0.5, y: -0.25)),
      ]);
      final json = jsonDecode(jsonEncode(converter.toJson(a)));
      expect(converter.fromJson(json as Map<String, dynamic>), a);
    });

    test('reads integer JSON numbers as doubles', () {
      const converter = AnimatableDoubleConverter();
      expect(
        converter.fromJson({'value': 2}),
        const Animatable<double>.constant(2),
      );
    });

    test('rejects JSON without value or keyframes', () {
      expect(
        () => const AnimatableDoubleConverter().fromJson({}),
        throwsFormatException,
      );
    });
  });

  group('MediaRef', () {
    test('display size swaps for quarter turns', () {
      const m = MediaRef(
        uri: 'content://x',
        kind: MediaKind.video,
        width: 1920,
        height: 1080,
        rotationDegrees: 90,
      );
      expect(m.displayWidth, 1080);
      expect(m.displayHeight, 1920);
    });
  });

  group('Clip', () {
    test('fromMedia covers the whole video', () {
      final c = Clip.fromMedia(id: 'a', media: video(seconds: 4));
      expect(c.sourceInUs, 0);
      expect(c.sourceOutUs, 4 * Micros.perSecond);
      expect(c.validate(), isEmpty);
    });

    test('fromMedia gives images the default duration', () {
      final c = Clip.fromMedia(id: 'a', media: image());
      expect(c.durationUs, defaultImageDurationUs);
    });

    test('fromMedia rejects audio and zero-length media', () {
      expect(
        () => Clip.fromMedia(id: 'a', media: audio(seconds: 1)),
        throwsArgumentError,
      );
      expect(
        () => Clip.fromMedia(id: 'a', media: video(seconds: 0)),
        throwsArgumentError,
      );
    });

    test('duration follows speed != 1', () {
      final c = Clip.fromMedia(id: 'a', media: video(seconds: 10));
      expect(c.copyWith(speed: 2).durationUs, 5 * Micros.perSecond);
      expect(c.copyWith(speed: 0.5).durationUs, 20 * Micros.perSecond);
    });

    test('validate flags broken invariants', () {
      final c = Clip.fromMedia(id: 'a', media: video(seconds: 2));
      expect(c.copyWith(sourceOutUs: 0).validate(), isNotEmpty);
      expect(c.copyWith(sourceInUs: -1).validate(), isNotEmpty);
      expect(c.copyWith(sourceOutUs: 3 * Micros.perSecond).validate(), [
        'sourceOutUs beyond media duration',
      ]);
      expect(c.copyWith(speed: 0.05).validate(), ['speed out of range']);
      expect(c.copyWith(speed: 11).validate(), ['speed out of range']);
      expect(c.copyWith(speed: 10).validate(), isEmpty);
      expect(c.copyWith(volume: -0.1).validate(), ['volume < 0']);
    });

    test('image clips may be any length', () {
      final c = Clip.fromMedia(id: 'a', media: image());
      expect(
        c.copyWith(sourceOutUs: 60 * Micros.perSecond).validate(),
        isEmpty,
      );
    });
  });

  group('AudioClip', () {
    test('fades must fit in the clip', () {
      final a = AudioClip(
        id: 'a',
        media: audio(seconds: 2),
        sourceInUs: 0,
        sourceOutUs: 2 * Micros.perSecond,
      );
      expect(a.validate(), isEmpty);
      expect(
        a.copyWith(fadeInUs: Micros.perSecond, fadeOutUs: Micros.perSecond),
        isA<AudioClip>().having((c) => c.validate(), 'validate', isEmpty),
      );
      expect(
        a.copyWith(fadeInUs: 2 * Micros.perSecond, fadeOutUs: 1).validate(),
        ['fades longer than clip'],
      );
      expect(a.copyWith(speed: 2, fadeInUs: Micros.perSecond + 1).validate(), [
        'fades longer than clip',
      ]);
    });
  });

  group('MainTrack', () {
    final track = MainTrack(
      clips: [
        Clip.fromMedia(id: 'a', media: video(seconds: 2)),
        Clip.fromMedia(id: 'b', media: video(seconds: 4)).copyWith(speed: 2),
        Clip.fromMedia(id: 'c', media: image()),
      ],
    );

    test('duration sums speed-adjusted clips', () {
      expect(track.durationUs, (2 + 2 + 3) * Micros.perSecond);
    });

    test('startOf is cumulative', () {
      expect(track.startOf(0), 0);
      expect(track.startOf(1), 2 * Micros.perSecond);
      expect(track.startOf(2), 4 * Micros.perSecond);
      expect(() => track.startOf(3), throwsRangeError);
    });

    test('indexAt resolves boundaries to the later clip', () {
      expect(track.indexAt(0), 0);
      expect(track.indexAt(2 * Micros.perSecond - 1), 0);
      expect(track.indexAt(2 * Micros.perSecond), 1);
      expect(track.indexAt(7 * Micros.perSecond - 1), 2);
      expect(track.indexAt(7 * Micros.perSecond), isNull);
      expect(track.indexAt(-1), isNull);
    });

    test('empty track', () {
      const empty = MainTrack();
      expect(empty.durationUs, 0);
      expect(empty.indexAt(0), isNull);
    });
  });

  group('findOverlaps', () {
    test('reports overlapping layers only', () {
      final overlaps = findOverlaps([
        TimeRange(0, 10),
        TimeRange(10, 20),
        TimeRange(15, 30),
        TimeRange(40, 50),
      ]);
      expect(overlaps, [(1, 2)]);
    });

    test('handles unsorted input', () {
      expect(findOverlaps([TimeRange(5, 15), TimeRange(0, 10)]), [(1, 0)]);
    });
  });

  group('CanvasAspect', () {
    test('reduces fractions', () {
      expect(CanvasAspect.reduced(1920, 1080), CanvasAspect.landscape16x9);
      expect(CanvasAspect.reduced(1080, 1350), CanvasAspect.portrait4x5);
      expect(() => CanvasAspect.reduced(0, 1), throwsArgumentError);
    });

    test('pixel sizes are even', () {
      expect(CanvasAspect.landscape16x9.pixelSize(1080), (
        width: 1920,
        height: 1080,
      ));
      expect(CanvasAspect.portrait9x16.pixelSize(720), (
        width: 720,
        height: 1280,
      ));
      final odd = const CanvasAspect(width: 21, height: 9).pixelSize(1081);
      expect(odd.width.isEven && odd.height.isEven, isTrue);
    });
  });

  group('Project', () {
    test('duration is the latest track end', () {
      final p = project(mainSeconds: [2]).copyWith(
        overlayTracks: [
          LayerTrack(
            id: 'o1',
            items: [
              PlacedClip(
                startUs: Micros.perSecond,
                clip: Clip.fromMedia(id: 'o', media: video()),
              ),
            ],
          ),
        ],
      );
      expect(p.durationUs, 6 * Micros.perSecond);
      expect(p.clipCount, 2);
    });

    test('valid project has no problems', () {
      expect(project(mainSeconds: [1, 2, 3]).validate(), isEmpty);
    });

    test('flags overlapping layers and duplicate ids', () {
      final clip = Clip.fromMedia(id: 'x', media: video(seconds: 2));
      final p = project(mainSeconds: [1]).copyWith(
        name: ' ',
        overlayTracks: [
          LayerTrack(
            id: 't',
            items: [
              PlacedClip(startUs: 0, clip: clip),
              PlacedClip(
                startUs: Micros.perSecond,
                clip: clip.copyWith(id: 'm0'),
              ),
            ],
          ),
        ],
      );
      expect(
        p.validate(),
        unorderedEquals([
          'name: empty',
          'overlayTracks[0].items[1]: duplicate clip id m0',
          'overlayTracks[0]: items 0 and 1 overlap',
        ]),
      );
    });

    test('JSON round-trip keeps every field', () {
      final p = project(mainSeconds: [2]).copyWith(
        canvas: const ProjectCanvas(
          aspect: CanvasAspect.portrait9x16,
          fps: 60,
          shortSidePx: 720,
          backgroundArgb: 0xFF112233,
        ),
        mainTrack: MainTrack(
          clips: [
            Clip.fromMedia(id: 'a', media: video(seconds: 3)).copyWith(
              speed: 1.5,
              keepPitch: false,
              muted: true,
              fitMode: FitMode.fill,
              transform: ClipTransform(
                scale: Animatable.keyframed([
                  Keyframe(timeUs: 0, value: 1, easing: Easing.easeInOut),
                  Keyframe(timeUs: 500000, value: 2),
                ]),
                flipX: true,
              ),
            ),
            Clip.fromMedia(id: 'b', media: image()),
          ],
        ),
        audioTracks: [
          AudioTrack(
            id: 'a1',
            items: [
              PlacedAudioClip(
                startUs: 10,
                clip: AudioClip(
                  id: 'au',
                  media: audio(seconds: 9),
                  sourceInUs: 5,
                  sourceOutUs: 900,
                  fadeInUs: 3,
                ),
              ),
            ],
          ),
        ],
      );
      final decoded = Project.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );
      expect(decoded, p);
      expect(decoded.schemaVersion, Project.currentSchemaVersion);
    });

    test('model collections are unmodifiable', () {
      final p = project(mainSeconds: [1]);
      expect(
        () => p.mainTrack.clips.add(p.mainTrack.clips.first),
        throwsUnsupportedError,
      );
    });
  });
}
