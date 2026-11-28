import 'package:cleancut/features/projects/domain/commands/clip_commands.dart';
import 'package:cleancut/features/projects/domain/commands/overlay_commands.dart';
import 'package:cleancut/features/projects/domain/commands/style_commands.dart';
import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/history/history.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_color.dart';
import 'package:cleancut/features/projects/domain/model/clip_effects.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:cleancut/features/projects/domain/model/tracks.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:cleancut/features/projects/domain/timeline/clip_lookup.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

const int s = Micros.perSecond;

void main() {
  group('AddOverlayCommand', () {
    test('adds photo (3 s, 50% scale) and muted video (50% scale)', () {
      final base = project(mainSeconds: [10]);
      final ids = sequentialIds('o');
      final trackIds = sequentialIds('t');

      final p1 = AddOverlayCommand(
        [image(), video(seconds: 4)],
        atUs: 2 * s,
        newId: ids,
        newTrackId: trackIds,
      ).apply(base);

      expect(p1.validate(), isEmpty);
      expect(p1.overlayTracks, hasLength(1));
      final items = p1.overlayTracks.single.items;
      expect(items, hasLength(2));

      // First item: still image at 2s..5s, 50% scale, not muted.
      expect(items[0].startUs, 2 * s);
      expect(items[0].clip.durationUs, 3 * s);
      expect(items[0].clip.transform.at(0).scale, defaultOverlayScale);
      expect(items[0].clip.muted, isFalse);

      // Second item: video placed back-to-back at 5s..9s, 50% scale, muted.
      expect(items[1].startUs, 5 * s);
      expect(items[1].clip.durationUs, 4 * s);
      expect(items[1].clip.transform.at(0).scale, defaultOverlayScale);
      expect(items[1].clip.muted, isTrue);
    });

    test('stacks overlapping overlay onto a new top track (index 0)', () {
      final base = project(mainSeconds: [10]);
      final p1 = AddOverlayCommand(
        [image(uri: 'content://img/1')],
        atUs: 1 * s,
        newId: sequentialIds('a'),
        newTrackId: sequentialIds('t1_'),
      ).apply(base);

      // Overlaps 1s..4s -> creates a new track at index 0 (frontmost).
      final p2 = AddOverlayCommand(
        [image(uri: 'content://img/2')],
        atUs: 2 * s,
        newId: sequentialIds('b'),
        newTrackId: sequentialIds('t2_'),
      ).apply(p1);

      expect(p2.validate(), isEmpty);
      expect(p2.overlayTracks, hasLength(2));
      expect(
        p2.overlayTracks[0].items.single.clip.media.uri,
        'content://img/2',
      );
      expect(
        p2.overlayTracks[1].items.single.clip.media.uri,
        'content://img/1',
      );

      // Non-overlapping at 6s reuses the bottom track (index 1).
      final p3 = AddOverlayCommand(
        [image(uri: 'content://img/3')],
        atUs: 6 * s,
        newId: sequentialIds('c'),
        newTrackId: sequentialIds('t3_'),
      ).apply(p2);

      expect(p3.validate(), isEmpty);
      expect(p3.overlayTracks, hasLength(2));
      expect(p3.overlayTracks[1].items, hasLength(2));
      expect(p3.overlayTracks[1].items[1].startUs, 6 * s);
    });

    test('clamps negative atUs to 0 and rejects audio media', () {
      final base = project(mainSeconds: [5]);
      final p = AddOverlayCommand(
        [image()],
        atUs: -5 * s,
        newId: sequentialIds('o'),
      ).apply(base);
      expect(p.overlayTracks.single.items.single.startUs, 0);

      expect(
        () => AddOverlayCommand(
          [audio()],
          atUs: 0,
          newId: sequentialIds('o'),
        ).apply(base),
        throwsA(isA<InvalidEditException>()),
      );
    });
  });

  group('MoveOverlayCommand', () {
    test(
      'moves in time, switches lanes, creates new lanes and prunes empty ones',
      () {
        var p = project(mainSeconds: [10]);
        p = AddOverlayCommand(
          [image(uri: 'content://1')],
          atUs: 1 * s,
          newId: sequentialIds('o1_'),
          newTrackId: sequentialIds('t1_'),
        ).apply(p);
        p = AddOverlayCommand(
          [image(uri: 'content://2')],
          atUs: 2 * s,
          newId: sequentialIds('o2_'),
          newTrackId: sequentialIds('t2_'),
        ).apply(p);
        // Track 0 has o2_0 [2..5s], track 1 has o1_0 [1..4s].
        expect(p.overlayTracks, hasLength(2));

        // Move o2_0 onto track 1 at 5s (no overlap) -> track 0 pruned.
        p = const MoveOverlayCommand(
          'o2_0',
          startUs: 5 * s,
          trackIndex: 1,
        ).apply(p);
        expect(p.validate(), isEmpty);
        expect(p.overlayTracks, hasLength(1));
        expect(p.overlayTracks.single.items.map((i) => i.clip.id), [
          'o1_0',
          'o2_0',
        ]);

        // Move o2_0 to trackIndex -1 -> creates new top track at index 0.
        p = MoveOverlayCommand(
          'o2_0',
          startUs: 1 * s,
          trackIndex: -1,
          newTrackId: () => 'topTrack',
        ).apply(p);
        expect(p.validate(), isEmpty);
        expect(p.overlayTracks, hasLength(2));
        expect(p.overlayTracks[0].id, 'topTrack');
        expect(p.overlayTracks[0].items.single.clip.id, 'o2_0');
      },
    );

    test('rejects overlapping destination and negative start', () {
      var p = project(mainSeconds: [10]);
      p = AddOverlayCommand(
        [image(), image()],
        atUs: 0,
        newId: sequentialIds('o'),
        newTrackId: () => 't0',
      ).apply(p);
      // o0 [0..3s], o1 [3..6s] on track 0.
      expect(
        () => const MoveOverlayCommand(
          'o1',
          startUs: 2 * s,
          trackIndex: 0,
        ).apply(p),
        throwsA(isA<InvalidEditException>()),
      );
      expect(
        () =>
            const MoveOverlayCommand('o0', startUs: -1, trackIndex: 0).apply(p),
        throwsA(isA<InvalidEditException>()),
      );
    });
  });

  group('TrimOverlayCommand', () {
    test('trims video overlay start and end and shifts keyframes', () {
      var p = project(mainSeconds: [10]);
      p = AddOverlayCommand(
        [video(seconds: 6)],
        atUs: 2 * s,
        newId: sequentialIds('o'),
        newTrackId: () => 't0',
      ).apply(p);
      // Add opacity keyframe at clip-relative 2s (timeline 4s).
      p = const ToggleClipKeyframeCommand(
        'o0',
        TransformProperty.opacity,
        atUs: 2 * s,
      ).apply(p);
      p = const SetClipTransformValuesCommand(
        'o0',
        atUs: 2 * s,
        opacity: 0.4,
      ).apply(p);

      // Trim 1s off the left edge -> starts at timeline 3s, sourceIn = 1s.
      p = const TrimOverlayCommand(
        'o0',
        startUs: 3 * s,
        sourceInUs: 1 * s,
        sourceOutUs: 6 * s,
      ).apply(p);
      expect(p.validate(), isEmpty);
      final item = p.overlayTracks.single.items.single;
      expect(item.startUs, 3 * s);
      expect(item.clip.durationUs, 5 * s);
      // Keyframe shifted from 2s to 1s (still at timeline 4s).
      expect(item.clip.transform.at(1 * s).opacity, closeTo(0.4, 1e-6));
    });

    test('clampOverlayTrimStart extends still left and stops at sibling', () {
      final track = LayerTrack(
        id: 't0',
        items: [
          PlacedClip(
            startUs: 0,
            clip: Clip.fromMedia(id: 'a', media: image()),
          ),
          PlacedClip(
            startUs: 5 * s,
            clip: Clip.fromMedia(id: 'b', media: image()),
          ),
        ],
      );
      // Dragging left by 3s hits sibling ending at 3s -> clamped to 3s..8s.
      final clamped = clampOverlayTrimStart(track, 1, deltaTimelineUs: -3 * s);
      expect(clamped.startUs, 3 * s);
      expect(clamped.sourceInUs, 0);
      expect(clamped.sourceOutUs, 5 * s);

      // End trim of item 0 stops at item 1's start (5s).
      final clampedEnd = clampOverlayTrimEnd(track, 0, sourceOutUs: 9 * s);
      expect(clampedEnd, 5 * s);
    });
  });

  group('Generalized clip & style commands on overlays', () {
    test(
      'split, duplicate, delete, speed, and style commands work on overlays',
      () {
        var history = History.initial(project(mainSeconds: [10]));
        history = history
            .apply(
              AddOverlayCommand(
                [video(seconds: 6)],
                atUs: 1 * s,
                newId: sequentialIds('o'),
                newTrackId: () => 't0',
              ),
            )
            .seal();

        // Style commands on overlay clip o0: opacity, filter, blur, mask, crop.
        history = history
            .apply(
              const SetClipTransformValuesCommand(
                'o0',
                atUs: 0,
                opacity: 0.6,
                position: Vec2(x: 0.2, y: -0.1),
                coalesce: false,
              ),
            )
            .apply(
              const SetClipFilterCommand(
                'o0',
                ClipFilter(id: 'gold', intensity: 0.8),
              ),
            )
            .apply(
              const SetClipBlurCommand(
                'o0',
                atUs: 0,
                amount: 0.3,
                coalesce: false,
              ),
            )
            .apply(const SetClipMaskShapeCommand('o0', MaskShape.circle))
            .apply(
              const SetClipCropCommand(
                'o0',
                CropRect(left: 0.1, top: 0.1, right: 0.9, bottom: 0.9),
                coalesce: false,
              ),
            );

        final styled = locateClip(history.present, 'o0')!.clip;
        expect(styled.transform.at(0).opacity, closeTo(0.6, 1e-6));
        expect(styled.filter?.id, 'gold');
        expect(styled.blur.valueAt(0, lerpDouble), closeTo(0.3, 1e-6));
        expect(styled.mask?.shape, MaskShape.circle);
        expect(styled.crop.left, closeTo(0.1, 1e-6));

        // Split at timeline 4s (3s into [1s..7s]).
        expect(canSplitAt(history.present, 'o0', 4 * s), isTrue);
        expect(splitTooCloseToEdge(history.present, 'o0', 1 * s), isTrue);
        history = history.apply(
          SplitClipCommand('o0', timeUs: 4 * s, newId: () => 'o_half'),
        );
        expect(history.present.validate(), isEmpty);
        expect(history.present.overlayTracks.single.items, hasLength(2));
        expect(
          history.present.overlayTracks.single.items[0].range,
          TimeRange(1 * s, 4 * s),
        );
        expect(
          history.present.overlayTracks.single.items[1].range,
          TimeRange(4 * s, 7 * s),
        );

        // Slowing down first half (0.5x -> 6s long) collides with o_half at 4s,
        // so it relocates cleanly to a free overlay lane.
        history = history.apply(const SetClipSpeedCommand('o0', speed: 0.5));
        expect(history.present.validate(), isEmpty);
        expect(history.present.overlayTracks, hasLength(2));

        // Duplicate o_half places copy right after it (7s..10s).
        history = history.apply(
          DuplicateClipCommand('o_half', newId: () => 'o_copy'),
        );
        expect(history.present.validate(), isEmpty);
        final copyLoc = locateClip(history.present, 'o_copy');
        expect(copyLoc, isNotNull);
        expect(copyLoc!.startUs, 7 * s);

        // Delete o0 prunes its lane cleanly.
        history = history.apply(const DeleteClipCommand('o0'));
        expect(history.present.validate(), isEmpty);
        expect(locateClip(history.present, 'o0'), isNull);
        expect(history.present.overlayTracks, hasLength(1));

        // Undo restores o0 cleanly.
        history = history.undo();
        expect(locateClip(history.present, 'o0'), isNotNull);
        expect(history.present.validate(), isEmpty);
      },
    );
  });
}
