import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/tracks.dart';
import 'package:cleancut/features/projects/domain/timeline/ruler.dart';
import 'package:cleancut/features/projects/domain/timeline/snapping.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_scale.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_selection.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  group('TimelineScale', () {
    test('default matches the kit: 5 s span 114 px', () {
      expect(TimelineScale.initial.toPx(5000000), closeTo(114, 1e-9));
    });

    test('px and µs round-trip', () {
      final s = TimelineScale(50);
      expect(s.toUs(s.toPx(1234567)), 1234567);
      expect(s.toPx(0), 0);
    });

    test('zoom is clamped', () {
      expect(
        TimelineScale.initial.zoomed(1000000000).pxPerSecond,
        TimelineScale.maxPxPerSecond,
      );
      expect(
        TimelineScale.initial.zoomed(0).pxPerSecond,
        TimelineScale.minPxPerSecond,
      );
      expect(
        TimelineScale(double.nan).pxPerSecond,
        TimelineScale.defaultPxPerSecond,
      );
    });
  });

  group('ruler', () {
    test('kit zoom labels every 5 s with 4 dots between', () {
      final ticks = rulerTicks(
        TimelineScale.initial,
        fromUs: 0,
        toUs: 10000000,
      );
      expect(majorStepUs(TimelineScale.initial), 5000000);
      expect(ticks.where((t) => t.isMajor).map((t) => t.timeUs), [
        0,
        5000000,
        10000000,
      ]);
      expect(ticks, hasLength(11));
    });

    test('labels never closer than the minimum spacing', () {
      for (final px in [0.6, 3.0, 22.8, 100.0, 900.0, 1500.0]) {
        final scale = TimelineScale(px);
        final step = majorStepUs(scale);
        expect(scale.toPx(step), greaterThanOrEqualTo(minMajorSpacingPx));
      }
    });

    test('ticks start on a minor step and ignore negative time', () {
      final ticks = rulerTicks(
        TimelineScale.initial,
        fromUs: -3000000,
        toUs: 2500000,
      );
      expect(ticks.first, const RulerTick(0, isMajor: true));
      expect(ticks.last.timeUs, 2000000);
      final mid = rulerTicks(
        TimelineScale.initial,
        fromUs: 1500000,
        toUs: 1500000,
      );
      expect(mid.single.timeUs, 1000000);
    });

    test('labels', () {
      expect(rulerLabel(0), '0s');
      expect(rulerLabel(5000000), '5s');
      expect(rulerLabel(500000), '0.5s');
      expect(rulerLabel(65000000), '1:05');
      expect(rulerLabel(3661000000), '1:01:01');
    });
  });

  group('snapping', () {
    test('targets are the start, clip boundaries and layer edges', () {
      final p = project(mainSeconds: [2, 3]).copyWith(
        overlayTracks: [
          LayerTrack(
            id: 'o',
            items: [
              PlacedClip(
                startUs: 1000000,
                clip: Clip.fromMedia(id: 'x', media: image()),
              ),
            ],
          ),
        ],
      );
      expect(snapTargets(p), [0, 1000000, 2000000, 4000000, 5000000]);
    });

    test('snaps to the nearest target within tolerance', () {
      const targets = [0, 1000, 5000];
      expect(snapTo(1080, targets, toleranceUs: 100), 1000);
      expect(snapTo(4950, targets, toleranceUs: 100), 5000);
      expect(snapTo(3000, targets, toleranceUs: 100), isNull);
      expect(snapTo(-50, targets, toleranceUs: 100), 0);
      expect(snapTo(9999, targets, toleranceUs: 100), isNull);
    });

    test('ties go to the earlier target; empty and negative tolerance', () {
      expect(snapTo(500, const [0, 1000], toleranceUs: 500), 0);
      expect(snapTo(5, const [], toleranceUs: 10), isNull);
      expect(snapTo(5, const [5], toleranceUs: -1), isNull);
      expect(snapTo(5, const [5], toleranceUs: 0), 5);
    });

    test('an empty project only snaps to zero', () {
      expect(snapTargets(project()), [0]);
    });
  });

  group('TimelineSelection', () {
    test('stays valid while its item exists', () {
      final p = project(mainSeconds: [1]);
      final id = p.mainTrack.clips.single.id;
      expect(MainClipSelection(id).validIn(p), MainClipSelection(id));
      expect(TimelineSelection.none.validIn(p), TimelineSelection.none);
    });

    test('becomes none when its item is gone', () {
      final p = project(mainSeconds: [1]);
      expect(
        const MainClipSelection('gone').validIn(p),
        TimelineSelection.none,
      );
      expect(
        const OverlaySelection(trackId: 't', clipId: 'c').validIn(p),
        TimelineSelection.none,
      );
      expect(
        const AudioSelection(trackId: 't', clipId: 'c').validIn(p),
        TimelineSelection.none,
      );
    });

    test('an overlay selection follows its clip to another lane', () {
      final clip = Clip.fromMedia(id: 'o', media: video(seconds: 2));
      final p = project(mainSeconds: [5]).copyWith(
        overlayTracks: [
          LayerTrack(
            id: 'top',
            items: [PlacedClip(startUs: 0, clip: clip)],
          ),
          const LayerTrack(id: 'bottom'),
        ],
      );
      // e.g. undo of a lane move, or a speed change that bumped the clip.
      expect(
        const OverlaySelection(trackId: 'bottom', clipId: 'o').validIn(p),
        const OverlaySelection(trackId: 'top', clipId: 'o'),
      );
      expect(
        const OverlaySelection(trackId: 'top', clipId: 'o').validIn(p),
        const OverlaySelection(trackId: 'top', clipId: 'o'),
      );
    });

    test('equality by value', () {
      expect(const MainClipSelection('a'), const MainClipSelection('a'));
      expect(
        const OverlaySelection(trackId: 't', clipId: 'c'),
        isNot(const AudioSelection(trackId: 't', clipId: 'c')),
      );
    });
  });
}
