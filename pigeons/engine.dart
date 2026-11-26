// Pigeon definition for the native media engine (Media3).
// Regenerate: fvm dart run pigeon --input pigeons/engine.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/engine/engine_api.g.dart',
    dartPackageName: 'cleancut',
    kotlinOut: 'android/app/src/main/kotlin/com/hussainhacko/cleancut/engine/EngineApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.hussainhacko.cleancut.engine'),
  ),
)
/// Kind of a clip's source file.
enum SpecMediaKind { video, image }

/// A constant-speed piece of a speed curve: from [startUs] (measured from
/// the clip's trim start, in source time) until the next step's start.
class SpeedStepSpec {
  SpeedStepSpec({required this.startUs, required this.speed});

  final int startUs;
  final double speed;
}

/// One clip of the main sequence. Times are microseconds.
class ClipSpec {
  ClipSpec({
    required this.uri,
    required this.kind,
    required this.sourceDurationUs,
    required this.sourceInUs,
    required this.sourceOutUs,
    required this.speed,
    required this.keepPitch,
    required this.speedSteps,
  });

  /// Content URI of the source.
  final String uri;
  final SpecMediaKind kind;

  /// Full length of the source file; for images, how long the image shows.
  final int sourceDurationUs;

  /// Trim start within the source.
  final int sourceInUs;

  /// Trim end within the source (exclusive).
  final int sourceOutUs;

  /// Constant playback speed (0.1–10); the clip lasts
  /// `(sourceOutUs - sourceInUs) / speed` on the timeline. Always 1 for
  /// images, whose trim already is their display length.
  final double speed;

  /// Whether sped-up or slowed-down audio keeps its pitch.
  final bool keepPitch;

  /// A speed curve as constant-speed steps (sorted, the first at 0); when
  /// not empty it replaces [speed]. Empty for images.
  final List<SpeedStepSpec> speedSteps;
}

/// What the preview plays: the main track, fitted into the canvas.
class CompositionSpec {
  CompositionSpec({
    required this.clips,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.frameRate,
  });

  /// Main-track clips in timeline order.
  final List<ClipSpec> clips;

  /// Preview output size in pixels (canvas aspect).
  final int canvasWidth;
  final int canvasHeight;

  /// Frames per second used for still images.
  final int frameRate;
}

/// Player status, mirroring Media3's `Player.STATE_*`.
enum PlaybackStatus { idle, buffering, ready, ended }

/// Snapshot sent whenever the player's status changes.
class PlayerStateEvent {
  PlayerStateEvent({
    required this.textureId,
    required this.status,
    required this.isPlaying,
    required this.durationUs,
    required this.positionUs,
  });

  /// The preview this event belongs to.
  final int textureId;
  final PlaybackStatus status;
  final bool isPlaying;

  /// Length of the composition; 0 while unknown.
  final int durationUs;
  final int positionUs;
}

/// Audio peaks of a file, one byte (0–255) per bucket.
class WaveformData {
  WaveformData({
    required this.peaks,
    required this.peaksPerSecond,
    required this.durationUs,
  });

  final Uint8List peaks;
  final int peaksPerSecond;
  final int durationUs;
}

@HostApi()
abstract class EngineHostApi {
  /// Creates the preview player and its Flutter texture. Returns the
  /// texture id. Calling it again first disposes the previous preview.
  int createPreview();

  /// Replaces what the preview plays, keeping the position when possible.
  void setComposition(CompositionSpec spec);

  void play();
  void pause();

  /// Seeks exactly to [positionUs] (frame-accurate).
  void seekTo(int positionUs);

  /// Releases the player and the texture, if [textureId] is still the
  /// current preview (a newer preview is left alone).
  void disposePreview(int textureId);

  /// Extracts frames at [timesUs] scaled to [heightPx] tall and caches them
  /// as JPEG files. Returns one file path per time, or null when a frame
  /// could not be read. Images return the image itself for every time.
  @async
  List<String?> thumbnails(String uri, List<int> timesUs, int heightPx);

  /// Decodes the audio of [uri] into peaks, cached on disk. Returns null
  /// when the file has no audio track.
  @async
  WaveformData? waveform(String uri, int peaksPerSecond);
}

@FlutterApi()
abstract class EngineFlutterApi {
  /// The player's status or playing flag changed.
  void onPlayerState(PlayerStateEvent state);

  /// Playback position of preview [textureId] while playing (about 30
  /// times a second).
  void onPosition(int textureId, int positionUs);

  /// A playback error of preview [textureId]; the player stops.
  void onError(int textureId, String code, String message);
}
