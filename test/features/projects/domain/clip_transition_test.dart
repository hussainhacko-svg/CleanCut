import 'package:cleancut/features/projects/domain/commands/clip_commands.dart';
import 'package:cleancut/features/projects/domain/commands/transition_commands.dart';
import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/history/history.dart';
import 'package:cleancut/features/projects/domain/model/clip_transition.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/timeline/snapping.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_selection.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('TransitionLimits & ClipTransition', () {
    test('maxBetween caps at half the shorter clip and 3 s max', () {
      expect(TransitionLimits.maxBetween(2000000, 4000000), 1000000);
      expect(TransitionLimits.maxBetween(10000000, 10000000), 3000000);
      expect(TransitionLimits.maxBetween(0, 2000000), 0);
    });

    test('effectiveDurationUs caps requested overlap cleanly', () {
      expect(
        TransitionLimits.effectiveDurationUs(500000, 2000000, 2000000),
        500000,
      );
      expect(
        TransitionLimits.effectiveDurationUs(1500000, 1000000, 4000000),
        500000,
      );
      expect(TransitionLimits.effectiveDurationUs(0, 2000000, 2000000), 0);
    });

    test('validate rejects durations outside allowed range', () {
      expect(
        const ClipTransition(type: TransitionType.dissolve).validate(),
        isEmpty,
      );
      expect(
        const ClipTransition(
          type: TransitionType.dissolve,
          durationUs: 50000,
        ).validate(),
        isNotEmpty,
      );
      expect(
        const ClipTransition(
          type: TransitionType.dissolve,
          durationUs: 4000000,
        ).validate(),
        isNotEmpty,
      );
    });

    test('every TransitionType belongs to a category', () {
      final categorized = [
        for (final c in TransitionCategory.values)
          ...TransitionType.inCategory(c),
      ];
      expect(categorized.toSet(), TransitionType.values.toSet());
      expect(categorized.length, TransitionType.values.length);
    });
  });

  group('MainTrack overlapping timeline math', () {
    test('overlaps shorten duration and shift downstream clip starts', () {
      // Three 4 s clips: 1 s dissolve after m0, 0.5 s slideLeft after m1.
      final p = project(mainSeconds: [4, 4, 4]).copyWith(
        mainTrack: project(mainSeconds: [4, 4, 4]).mainTrack.copyWith(
          transitions: const {
            'm0': ClipTransition(
              type: TransitionType.dissolve,
              durationUs: 1000000,
            ),
            'm1': ClipTransition(type: TransitionType.slideLeft),
          },
        ),
      );
      final main = p.mainTrack;
      expect(main.overlapAfter(0), 1000000);
      expect(main.overlapAfter(1), 500000);
      expect(main.overlapAfter(2), 0);

      // Starts: 0, 3s, 6.5s; ends: 4s, 7s, 10.5s.
      expect(main.startOf(0), 0);
      expect(main.endOf(0), 4000000);
      expect(main.startOf(1), 3000000);
      expect(main.endOf(1), 7000000);
      expect(main.startOf(2), 6500000);
      expect(main.endOf(2), 10500000);
      expect(main.durationUs, 10500000);
      expect(p.durationUs, 10500000);

      // Boundary centers: 3.5s, 6.75s.
      expect(main.boundaryCenterOf(0), 3500000);
      expect(main.boundaryCenterOf(1), 6750000);

      // Visual slots partition [0, 10.5s) cleanly.
      expect(main.visualSlotOf(0), (0, 3500000));
      expect(main.visualSlotOf(1), (3500000, 6750000));
      expect(main.visualSlotOf(2), (6750000, 10500000));

      // indexAt switches at boundary centers.
      expect(main.indexAt(3499999), 0);
      expect(main.indexAt(3500000), 1);
      expect(main.indexAt(6749999), 1);
      expect(main.indexAt(6750000), 2);
      expect(main.indexAt(10500000), isNull);
    });

    test('adjacent transitions never collide on a short middle clip', () {
      final p = project(mainSeconds: [4, 1, 4]);
      final main = p.mainTrack.copyWith(
        transitions: const {
          'm0': ClipTransition(
            type: TransitionType.dissolve,
            durationUs: 2000000,
          ),
          'm1': ClipTransition(
            type: TransitionType.wipeLeft,
            durationUs: 2000000,
          ),
        },
      );
      // Capped to half of 1 s = 0.5 s on each side, so m0 and m2 never touch.
      expect(main.overlapAfter(0), 500000);
      expect(main.overlapAfter(1), 500000);
      expect(main.endOf(0), 4000000);
      expect(main.startOf(2), 4000000);
      expect(main.durationUs, 8000000);
    });

    test('a cap below the 0.1 s minimum plays as a hard cut', () {
      // Half of a 0.15 s clip is 75 ms, below the 0.1 s minimum.
      expect(TransitionLimits.effectiveDurationUs(500000, 150000, 4000000), 0);
      // Exactly the minimum still plays.
      expect(
        TransitionLimits.effectiveDurationUs(500000, 200000, 4000000),
        TransitionLimits.minDurationUs,
      );
      final p = project(mainSeconds: [4, 0.15]);
      final main = p.mainTrack.copyWith(
        transitions: const {
          'm0': ClipTransition(type: TransitionType.dissolve),
        },
      );
      expect(main.overlapAfter(0), 0);
      expect(main.durationUs, 4150000);
      // The transition stays stored, so it comes back if the clip grows.
      expect(main.transitionAfter(0), isNotNull);
    });

    test('validate catches orphaned or trailing transitions', () {
      final base = project(mainSeconds: [2, 2]);
      final trailing = base.copyWith(
        mainTrack: base.mainTrack.copyWith(
          transitions: const {
            'm1': ClipTransition(type: TransitionType.dissolve),
          },
        ),
      );
      expect(trailing.validate(), isNotEmpty);

      final ghost = base.copyWith(
        mainTrack: base.mainTrack.copyWith(
          transitions: const {
            'nope': ClipTransition(type: TransitionType.dissolve),
          },
        ),
      );
      expect(ghost.validate(), isNotEmpty);
    });
  });

  group('Transition commands & clip edit interactions', () {
    test('SetTransitionCommand sets, coalesces drags, clears and undoes', () {
      var h = History.initial(project(mainSeconds: [3, 3]))
          .apply(
            const SetTransitionCommand(
              'm0',
              ClipTransition(type: TransitionType.dissolve, durationUs: 400000),
              coalesce: true,
            ),
          )
          .apply(
            const SetTransitionCommand(
              'm0',
              ClipTransition(type: TransitionType.dissolve, durationUs: 800000),
              coalesce: true,
            ),
          )
          .seal();
      expect(h.present.mainTrack.transitionAfter(0)?.durationUs, 800000);
      // Coalesced into a single undo step.
      h = h.undo();
      expect(h.present.mainTrack.transitionAfter(0), isNull);
      h = h.redo();
      expect(h.present.mainTrack.transitionAfter(0)?.durationUs, 800000);

      // Clear transition.
      h = h.apply(const SetTransitionCommand('m0', null));
      expect(h.present.mainTrack.transitions, isEmpty);
    });

    test('SetTransitionCommand rejects last clip and invalid durations', () {
      final p = project(mainSeconds: [3, 3]);
      expect(
        () => const SetTransitionCommand(
          'm1',
          ClipTransition(type: TransitionType.dissolve),
        ).apply(p),
        throwsA(isA<InvalidEditException>()),
      );
      expect(
        () => const SetTransitionCommand(
          'm0',
          ClipTransition(type: TransitionType.dissolve, durationUs: 5000),
        ).apply(p),
        throwsA(isA<InvalidEditException>()),
      );
    });

    test('ApplyTransitionToAllCommand sets and clears all boundaries', () {
      const tr = ClipTransition(
        type: TransitionType.zoomIn,
        durationUs: 600000,
      );
      var h = History.initial(project(mainSeconds: [3, 3, 3]))
          .apply(const ApplyTransitionToAllCommand(tr));
      expect(h.present.mainTrack.transitions, {'m0': tr, 'm1': tr});

      h = h.apply(const ApplyTransitionToAllCommand(null));
      expect(h.present.mainTrack.transitions, isEmpty);

      h = h.undo();
      expect(h.present.mainTrack.transitions, {'m0': tr, 'm1': tr});
    });

    test(
      'split moves outgoing transition to second half and leaves new cut clear',
      () {
        const tr = ClipTransition(type: TransitionType.fadeBlack);
        final p = const SetTransitionCommand(
          'm0',
          tr,
        ).apply(project(mainSeconds: [4, 4]));
        final split = SplitClipCommand(
          'm0',
          timeUs: 2000000,
          newId: sequentialIds('s'),
        ).apply(p);
        expect(split.mainTrack.transitionAfter(0), isNull);
        expect(split.mainTrack.transitionAfter(1), tr);
        expect(split.validate(), isEmpty);
      },
    );

    group('split never shortens a transition', () {
      // m0 [0, 4s], m1 [3s, 7s] (1 s in), m2 [6s, 10s] (1 s out of m1).
      Project withBothSides() {
        const tr = ClipTransition(
          type: TransitionType.dissolve,
          durationUs: 1000000,
        );
        return const ApplyTransitionToAllCommand(tr)
            .apply(project(mainSeconds: [4, 4, 4]));
      }

      test('rejects a cut that would shrink the outgoing overlap', () {
        final p = withBothSides();
        // m1 at 5.5 s leaves a 1.5 s second piece: cap 0.75 s < 1 s.
        expect(canSplitAt(p, 'm1', 5500000), isFalse);
        expect(
          () => SplitClipCommand(
            'm1',
            timeUs: 5500000,
            newId: sequentialIds('s'),
          ).apply(p),
          throwsA(isA<InvalidEditException>()),
        );
      });

      test('rejects a cut that would shrink the incoming overlap', () {
        final p = withBothSides();
        // m1 at 4.5 s leaves a 1.5 s first piece: cap 0.75 s < 1 s.
        expect(canSplitAt(p, 'm1', 4500000), isFalse);
      });

      test('allows a cut that keeps both overlaps and the length', () {
        final p = withBothSides();
        expect(canSplitAt(p, 'm1', 5000000), isTrue);
        final split = SplitClipCommand(
          'm1',
          timeUs: 5000000,
          newId: sequentialIds('s'),
        ).apply(p);
        expect(split.mainTrack.durationUs, p.mainTrack.durationUs);
        expect(split.mainTrack.overlapAfter(0), 1000000);
        expect(split.mainTrack.overlapAfter(1), 0);
        expect(split.mainTrack.overlapAfter(2), 1000000);
      });
    });

    test('duplicate moves outgoing transition onto the copy', () {
      const tr = ClipTransition(type: TransitionType.circle);
      final p = const SetTransitionCommand(
        'm0',
        tr,
      ).apply(project(mainSeconds: [3, 3]));
      final dup = DuplicateClipCommand(
        'm0',
        newId: sequentialIds('d'),
      ).apply(p);
      expect(dup.mainTrack.transitionAfter(0), isNull);
      expect(dup.mainTrack.transitionAfter(1), tr);
      expect(dup.validate(), isEmpty);
    });

    test('delete drops transitions touching the removed clip', () {
      const tr = ClipTransition(type: TransitionType.dissolve);
      final p = const ApplyTransitionToAllCommand(tr)
          .apply(project(mainSeconds: [3, 3, 3]));
      final deleted = const DeleteClipCommand('m1').apply(p);
      expect(deleted.mainTrack.transitions, isEmpty);
      expect(deleted.validate(), isEmpty);
    });

    test('reorder preserves transitions only for unchanged adjacent pairs', () {
      const t0 = ClipTransition(type: TransitionType.dissolve);
      const t1 = ClipTransition(type: TransitionType.wipeRight);
      const t2 = ClipTransition(type: TransitionType.slideUp);
      var p = project(mainSeconds: [3, 3, 3, 3]);
      p = const SetTransitionCommand('m0', t0).apply(p);
      p = const SetTransitionCommand('m1', t1).apply(p);
      p = const SetTransitionCommand('m2', t2).apply(p);
      // Move m0 to end -> [m1, m2, m3, m0]: (m1,m2) and (m2,m3) stay adjacent.
      final moved = const MoveClipCommand('m0', toIndex: 3).apply(p);
      expect(moved.mainTrack.transitions, {'m1': t1, 'm2': t2});
      expect(moved.validate(), isEmpty);
    });
  });

  group('TransitionSelection & snapping', () {
    test(
      'TransitionSelection drops when its clip becomes last or is deleted',
      () {
        final p = project(mainSeconds: [3, 3]);
        const sel = TransitionSelection('m0');
        expect(sel.validIn(p), sel);
        final oneClip = const DeleteClipCommand('m1').apply(p);
        expect(sel.validIn(oneClip), TimelineSelection.none);
      },
    );

    test('snapTargets includes overlap starts, ends and boundary centers', () {
      final p = const SetTransitionCommand(
        'm0',
        ClipTransition(type: TransitionType.dissolve, durationUs: 1000000),
      ).apply(project(mainSeconds: [4, 4]));
      // m0: [0, 4s], m1: [3s, 7s], center: 3.5s.
      expect(snapTargets(p), [0, 3000000, 3500000, 4000000, 7000000]);
    });
  });
}
