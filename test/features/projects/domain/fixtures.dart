import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:cleancut/features/projects/domain/model/tracks.dart';

/// A fixed timestamp for deterministic tests.
final testTime = DateTime.utc(2026, 11, 26, 12);

/// A 1920x1080 video lasting [seconds].
MediaRef video({num seconds = 5, String uri = 'content://media/video/1'}) =>
    MediaRef(
      uri: uri,
      kind: MediaKind.video,
      durationUs: Micros.fromSeconds(seconds),
      width: 1920,
      height: 1080,
      displayName: 'clip.mp4',
    );

/// A 1080x1350 still image.
MediaRef image({String uri = 'content://media/image/1'}) =>
    MediaRef(uri: uri, kind: MediaKind.image, width: 1080, height: 1350);

/// An audio file lasting [seconds].
MediaRef audio({num seconds = 30}) => MediaRef(
  uri: 'content://media/audio/1',
  kind: MediaKind.audio,
  durationUs: Micros.fromSeconds(seconds),
);

/// A project whose main track holds one video per entry of [mainSeconds],
/// with clip ids `m0`, `m1`, ...
Project project({String id = 'p1', List<num> mainSeconds = const []}) =>
    Project(
      id: id,
      name: 'Test project',
      createdAt: testTime,
      updatedAt: testTime,
      mainTrack: MainTrack(
        clips: [
          for (final (i, s) in mainSeconds.indexed)
            Clip.fromMedia(
              id: 'm$i',
              media: video(seconds: s),
            ),
        ],
      ),
    );

/// Sequential ids `id0`, `id1`, ... for commands that create clips.
String Function() sequentialIds([String prefix = 'id']) {
  var next = 0;
  return () => '$prefix${next++}';
}
