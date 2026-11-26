import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/data/composition_mapper.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
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

  test('an empty project maps to no clips', () {
    expect(compositionSpecOf(project()).clips, isEmpty);
  });
}
