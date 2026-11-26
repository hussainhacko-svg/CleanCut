import 'package:cleancut/features/projects/domain/commands/clip_commands.dart';
import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/history/history.dart';
import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/tracks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

const s = 1000000;

final Matcher throwsInvalidEdit = throwsA(isA<InvalidEditException>());

/// Opacity keyframed 0 → 1 over the first [endUs] of the clip.
ClipTransform fadeIn(int endUs) => ClipTransform(
  opacity: Animatable<double>.keyframed([
    Keyframe(timeUs: 0, value: 0),
    Keyframe(timeUs: endUs, value: 1),
  ]),
);

Project withClip(Project p, int index, Clip Function(Clip) change) {
  final clips = [...p.mainTrack.clips];
  clips[index] = change(clips[index]);
  return p.copyWith(mainTrack: MainTrack(clips: clips));
}

List<String> ids(Project p) => [for (final c in p.mainTrack.clips) c.id];

void main() {
  group('TrimClipCommand', () {
    test('sets the source range and changes the timeline length', () {
      final p = const TrimClipCommand(
        'm0',
        sourceInUs: s,
        sourceOutUs: 3 * s,
      ).apply(project(mainSeconds: [5, 2]));
      final clip = p.mainTrack.clips.first;
      expect((clip.sourceInUs, clip.sourceOutUs), (s, 3 * s));
      expect(p.durationUs, 4 * s);
    });

    test('rejects ranges outside the media or shorter than the minimum', () {
      final p = project(mainSeconds: [5]);
      for (final (i, o) in [
        (-1, s),
        (0, 5 * s + 1),
        (s, s),
        (s, s + minClipDurationUs - 1),
      ]) {
        expect(
          () => TrimClipCommand('m0', sourceInUs: i, sourceOutUs: o).apply(p),
          throwsInvalidEdit,
          reason: '[$i, $o)',
        );
      }
      expect(
        () => const TrimClipCommand(
          'nope',
          sourceInUs: 0,
          sourceOutUs: s,
        ).apply(p),
        throwsInvalidEdit,
      );
    });

    test('allows the minimum length exactly, measured after speed', () {
      final p = withClip(
        project(mainSeconds: [5]),
        0,
        (c) => c.copyWith(speed: 2),
      );
      // 0.2 s of source at 2x is 0.1 s on the timeline.
      final trimmed = const TrimClipCommand(
        'm0',
        sourceInUs: 0,
        sourceOutUs: 2 * minClipDurationUs,
      ).apply(p);
      expect(trimmed.mainTrack.clips.single.durationUs, minClipDurationUs);
    });

    test('images can be lengthened beyond their initial duration', () {
      final p = project().copyWith(
        mainTrack: MainTrack(
          clips: [Clip.fromMedia(id: 'i0', media: image())],
        ),
      );
      final trimmed = const TrimClipCommand(
        'i0',
        sourceInUs: 0,
        sourceOutUs: 10 * s,
      ).apply(p);
      expect(trimmed.durationUs, 10 * s);
    });

    test('moving the start keeps keyframes on the same frames', () {
      final p = withClip(
        project(mainSeconds: [5]),
        0,
        (c) => c.copyWith(speed: 2, transform: fadeIn(2 * s)),
      );
      // 1 s of source in at 2x = 0.5 s earlier on the timeline.
      final trimmed = const TrimClipCommand(
        'm0',
        sourceInUs: s,
        sourceOutUs: 5 * s,
      ).apply(p);
      final opacity =
          trimmed.mainTrack.clips.single.transform.opacity
              as KeyframedAnimatable<double>;
      expect(
        [for (final k in opacity.keyframes) (k.timeUs, k.value)],
        [(0, 0.25), (1500000, 1.0)],
      );
    });

    test('a whole drag is one undo step', () {
      final start = project(mainSeconds: [5]);
      final h = History.initial(start)
          .apply(const TrimClipCommand('m0', sourceInUs: 0, sourceOutUs: 4 * s))
          .apply(
            const TrimClipCommand('m0', sourceInUs: 0, sourceOutUs: 3 * s),
          );
      expect(h.undoDepth, 1);
      expect(h.undo().present, start);
    });

    test('an unchanged range is a no-op', () {
      final p = project(mainSeconds: [5]);
      expect(
        const TrimClipCommand('m0', sourceInUs: 0, sourceOutUs: 5 * s).apply(p),
        same(p),
      );
    });
  });

  group('clampTrimStart / clampTrimEnd', () {
    final clip = project(mainSeconds: [5]).mainTrack.clips.single;

    test('keep the range inside the media', () {
      expect(clampTrimStart(clip, -s), 0);
      expect(clampTrimEnd(clip, 9 * s), 5 * s);
      expect(clampTrimStart(clip, 2 * s), 2 * s);
      expect(clampTrimEnd(clip, 2 * s), 2 * s);
    });

    test('keep the minimum length, after speed', () {
      expect(clampTrimStart(clip, 5 * s), 5 * s - minClipDurationUs);
      expect(clampTrimEnd(clip, 0), minClipDurationUs);
      final fast = clip.copyWith(speed: 4);
      expect(clampTrimEnd(fast, 0), 4 * minClipDurationUs);
    });

    test('let images grow without limit', () {
      final still = Clip.fromMedia(id: 'i', media: image());
      expect(clampTrimEnd(still, 60 * s), 60 * s);
    });

    test('results are always accepted by TrimClipCommand', () {
      final p = withClip(
        project(mainSeconds: [5]),
        0,
        (c) => c.copyWith(speed: 3),
      );
      final c = p.mainTrack.clips.single;
      for (final raw in [-s, 0, 4999999, 5 * s, 6 * s]) {
        TrimClipCommand(
          'm0',
          sourceInUs: clampTrimStart(c, raw),
          sourceOutUs: c.sourceOutUs,
        ).apply(p);
        TrimClipCommand(
          'm0',
          sourceInUs: c.sourceInUs,
          sourceOutUs: clampTrimEnd(c, raw),
        ).apply(p);
      }
    });

    test('short fast clips can extend without crashing TrimClipCommand', () {
      // 0.5 s clip at 10x speed (50 ms full) trimmed to [200ms, 500ms) = 30 ms.
      final startTrimmed = withClip(
        project(mainSeconds: [0.5]),
        0,
        (c) => c.copyWith(sourceInUs: 200000, sourceOutUs: 500000, speed: 10),
      );
      final c1 = startTrimmed.mainTrack.clips.single;
      // Dragging right cannot shorten it further; dragging left extends to 0.
      expect(clampTrimStart(c1, 400000), 200000);
      expect(clampTrimStart(c1, 0), 0);
      for (final raw in [-s, 0, 100000, 200000, 400000, 500000]) {
        TrimClipCommand(
          'm0',
          sourceInUs: clampTrimStart(c1, raw),
          sourceOutUs: c1.sourceOutUs,
        ).apply(startTrimmed);
      }
      // Shortening an already-below-minimum clip further is still rejected.
      expect(
        () => const TrimClipCommand(
          'm0',
          sourceInUs: 250000,
          sourceOutUs: 500000,
        ).apply(startTrimmed),
        throwsInvalidEdit,
      );

      // Same from the end: [0, 300ms) at 10x = 30 ms.
      final endTrimmed = withClip(
        project(mainSeconds: [0.5]),
        0,
        (c) => c.copyWith(sourceInUs: 0, sourceOutUs: 300000, speed: 10),
      );
      final c2 = endTrimmed.mainTrack.clips.single;
      expect(clampTrimEnd(c2, 100000), 300000);
      expect(clampTrimEnd(c2, 500000), 500000);
      for (final raw in [0, 100000, 300000, 450000, 500000, s]) {
        TrimClipCommand(
          'm0',
          sourceInUs: c2.sourceInUs,
          sourceOutUs: clampTrimEnd(c2, raw),
        ).apply(endTrimmed);
      }
    });
  });

  group('SplitClipCommand', () {
    test('cuts the clip under the time into two parts', () {
      final p = SplitClipCommand(
        'm1',
        timeUs: 3 * s,
        newId: sequentialIds(),
      ).apply(project(mainSeconds: [2, 4]));
      expect(ids(p), ['m0', 'm1', 'id0']);
      final [_, a, b] = p.mainTrack.clips;
      expect((a.sourceInUs, a.sourceOutUs), (0, s));
      expect((b.sourceInUs, b.sourceOutUs), (s, 4 * s));
      expect(p.durationUs, 6 * s);
    });

    test('maps the cut through the clip speed and trim', () {
      final p = withClip(
        project(mainSeconds: [10]),
        0,
        (c) => c.copyWith(sourceInUs: 2 * s, speed: 2),
      );
      // 4 s on the timeline into a 2x clip that starts at 2 s of source.
      final split = SplitClipCommand(
        'm0',
        timeUs: 2 * s,
        newId: sequentialIds(),
      ).apply(p);
      final [a, b] = split.mainTrack.clips;
      expect(a.sourceOutUs, 6 * s);
      expect(b.sourceInUs, 6 * s);
      expect(b.speed, 2);
      expect(split.durationUs, p.durationUs);
    });

    test('rejects cuts at or near a clip edge', () {
      final p = project(mainSeconds: [2, 4]);
      for (final t in [
        2 * s,
        2 * s + minClipDurationUs - 1,
        6 * s - minClipDurationUs + 1,
        6 * s,
        0,
      ]) {
        expect(
          () => SplitClipCommand(
            'm1',
            timeUs: t,
            newId: sequentialIds(),
          ).apply(p),
          throwsInvalidEdit,
          reason: '$t',
        );
        expect(canSplitAt(p, 'm1', t), isFalse, reason: '$t');
      }
      expect(canSplitAt(p, 'm1', 2 * s + minClipDurationUs), isTrue);
      expect(canSplitAt(p, 'gone', 3 * s), isFalse);
    });

    test('partitions keyframes at the cut', () {
      final p = withClip(
        project(mainSeconds: [4]),
        0,
        (c) => c.copyWith(transform: fadeIn(2 * s)),
      );
      final [a, b] = SplitClipCommand(
        'm0',
        timeUs: s,
        newId: sequentialIds(),
      ).apply(p).mainTrack.clips;
      List<(int, double)> frames(Clip c) => [
        for (final k
            in (c.transform.opacity as KeyframedAnimatable<double>).keyframes)
          (k.timeUs, k.value),
      ];
      expect(frames(a), [(0, 0.0), (s, 0.5)]);
      expect(frames(b), [(0, 0.5), (s, 1.0)]);
    });
  });

  group('DeleteClipCommand', () {
    test('removes the clip and closes the gap', () {
      final p = const DeleteClipCommand('m1')
          .apply(project(mainSeconds: [1, 2, 3]));
      expect(ids(p), ['m0', 'm2']);
      expect(p.durationUs, 4 * s);
    });

    test('can empty the track and is undoable', () {
      final start = project(mainSeconds: [1]);
      final h = History.initial(start).apply(const DeleteClipCommand('m0'));
      expect(h.present.mainTrack.clips, isEmpty);
      expect(h.undo().present, start);
    });

    test('rejects an unknown clip', () {
      expect(
        () => const DeleteClipCommand('x').apply(project(mainSeconds: [1])),
        throwsInvalidEdit,
      );
    });
  });

  group('DuplicateClipCommand', () {
    test('inserts an identical copy right after the clip', () {
      final p = withClip(
        project(mainSeconds: [1, 2]),
        0,
        (c) => c.copyWith(speed: 0.5, sourceInUs: 200000),
      );
      final d = DuplicateClipCommand('m0', newId: sequentialIds()).apply(p);
      expect(ids(d), ['m0', 'id0', 'm1']);
      expect(d.mainTrack.clips[1], p.mainTrack.clips[0].copyWith(id: 'id0'));
    });
  });

  group('MoveClipCommand', () {
    final p = project(mainSeconds: [1, 2, 3]);

    test('reorders clips', () {
      expect(ids(const MoveClipCommand('m0', toIndex: 2).apply(p)), [
        'm1',
        'm2',
        'm0',
      ]);
      expect(ids(const MoveClipCommand('m2', toIndex: 0).apply(p)), [
        'm2',
        'm0',
        'm1',
      ]);
      expect(p.durationUs, 6 * s);
    });

    test('same index is a no-op; out of range is rejected', () {
      expect(const MoveClipCommand('m1', toIndex: 1).apply(p), same(p));
      expect(
        () => const MoveClipCommand('m1', toIndex: 3).apply(p),
        throwsInvalidEdit,
      );
      expect(
        () => const MoveClipCommand('m1', toIndex: -1).apply(p),
        throwsInvalidEdit,
      );
    });
  });

  group('SetClipSpeedCommand', () {
    test('changes the timeline length, not the source range', () {
      final p = const SetClipSpeedCommand(
        'm0',
        speed: 2,
      ).apply(project(mainSeconds: [4]));
      final clip = p.mainTrack.clips.single;
      expect(clip.speed, 2);
      expect((clip.sourceInUs, clip.sourceOutUs), (0, 4 * s));
      expect(p.durationUs, 2 * s);
    });

    test('accepts the limits and rejects outside them', () {
      final p = project(mainSeconds: [4]);
      expect(
        const SetClipSpeedCommand(
          'm0',
          speed: SpeedLimits.min,
        ).apply(p).durationUs,
        40 * s,
      );
      const SetClipSpeedCommand('m0', speed: SpeedLimits.max).apply(p);
      for (final bad in [0.0, 0.09, 10.1, double.nan, -1.0]) {
        expect(
          () => SetClipSpeedCommand('m0', speed: bad).apply(p),
          throwsInvalidEdit,
          reason: '$bad',
        );
      }
    });

    test('sets keep pitch, or leaves it when null', () {
      final p = project(mainSeconds: [4]);
      final off = const SetClipSpeedCommand(
        'm0',
        speed: 1,
        keepPitch: false,
      ).apply(p);
      expect(off.mainTrack.clips.single.keepPitch, isFalse);
      final faster = const SetClipSpeedCommand('m0', speed: 3).apply(off);
      expect(faster.mainTrack.clips.single.keepPitch, isFalse);
    });

    test('re-times keyframes to stay on the same frames', () {
      final p = withClip(
        project(mainSeconds: [4]),
        0,
        (c) => c.copyWith(transform: fadeIn(2 * s)),
      );
      final fast = const SetClipSpeedCommand('m0', speed: 4).apply(p);
      final opacity =
          fast.mainTrack.clips.single.transform.opacity
              as KeyframedAnimatable<double>;
      expect(opacity.keyframes.last.timeUs, 500000);
    });

    test('a slider drag is one undo step', () {
      final start = project(mainSeconds: [4]);
      final h = History.initial(start)
          .apply(const SetClipSpeedCommand('m0', speed: 1.5))
          .apply(const SetClipSpeedCommand('m0', speed: 2));
      expect(h.undoDepth, 1);
      expect(h.undo().present, start);
    });

    test('an unchanged speed is a no-op', () {
      final p = project(mainSeconds: [4]);
      expect(const SetClipSpeedCommand('m0', speed: 1).apply(p), same(p));
    });
  });
}
