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

/// How a clip is sized into the canvas before its transform.
enum SpecFitMode { fit, fill, stretch }

/// A clip's placement and whole-clip blur at clip-relative timeline time
/// [timeUs]; the engine interpolates linearly between samples. Positions are
/// canvas-normalized center offsets (x = 1 is the right edge, y = 1 the bottom
/// edge), [rotation] is clockwise degrees, [blur] is in `0..1`.
class TransformSampleSpec {
  TransformSampleSpec({
    required this.timeUs,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    required this.opacity,
    required this.blur,
  });

  final int timeUs;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final double opacity;
  final double blur;
}

/// Geometric shape of a clip mask (Phase 6B).
enum SpecMaskShape { linear, mirror, circle, rect, heart, star }

/// A clip mask's geometry at clip-relative timeline time [timeUs]; the engine
/// interpolates linearly between samples.
class MaskSampleSpec {
  MaskSampleSpec({
    required this.timeUs,
    required this.centerX,
    required this.centerY,
    required this.sizeX,
    required this.sizeY,
    required this.rotation,
    required this.feather,
  });

  final int timeUs;

  /// Normalized center offset relative to the clip's half-extents.
  final double centerX;
  final double centerY;

  /// Half-extents as multiples of the clip's shorter half-side.
  final double sizeX;
  final double sizeY;

  /// Clockwise degrees in clip space.
  final double rotation;

  /// Softness in `0..1` (fraction of the clip's shorter half-side).
  final double feather;
}

/// Shape mask applied to a clip (Phase 6B).
class MaskSpec {
  MaskSpec({required this.shape, required this.invert, required this.samples});

  final SpecMaskShape shape;
  final bool invert;

  /// At least one sample; one sample means a constant mask.
  final List<MaskSampleSpec> samples;
}

/// Per-clip color and tone adjustments (Phase 6); 0 means no change.
class ColorAdjustmentsSpec {
  ColorAdjustmentsSpec({
    required this.exposure,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.tint,
    required this.highlights,
    required this.shadows,
    required this.sharpen,
    required this.vignette,
  });

  final double exposure;
  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double tint;
  final double highlights;
  final double shadows;
  final double sharpen;
  final double vignette;
}

/// Everything about how a clip looks on the canvas (Phases 5–6).
class ClipStyleSpec {
  ClipStyleSpec({
    required this.fitMode,
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
    required this.flipX,
    required this.flipY,
    required this.transform,
    required this.borderWidth,
    required this.borderArgb,
    required this.borderRadius,
    required this.filterId,
    required this.filterIntensity,
    required this.adjustments,
    required this.mask,
  });

  final SpecFitMode fitMode;

  /// Crop in normalized displayed-frame coordinates (0–1, y down).
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;

  /// Mirror left-right / flip upside down, before the rotation.
  final bool flipX;
  final bool flipY;

  /// At least one sample; one sample means a constant transform.
  final List<TransformSampleSpec> transform;

  /// Stroke width as a fraction of the canvas short side (0 = none).
  final double borderWidth;
  final int borderArgb;

  /// Corner radius as a fraction of the clip's shorter displayed side.
  final double borderRadius;

  /// Bundled LUT id (`luts/<filterId>.cube`), or null for none.
  final String? filterId;

  /// Blend strength of [filterId] in `0..1`.
  final double filterIntensity;

  /// Per-clip color and tone adjustments.
  final ColorAdjustmentsSpec adjustments;

  /// Optional shape mask (null = unmasked).
  final MaskSpec? mask;
}

/// What fills the canvas behind the clips.
enum SpecBackgroundKind { color, gradient, blur, image }

class BackgroundSpec {
  BackgroundSpec({
    required this.kind,
    required this.argb,
    required this.endArgb,
    required this.angleDegrees,
    required this.blur,
    required this.imageUri,
  });

  final SpecBackgroundKind kind;

  /// Solid color, or the gradient's start color (0xAARRGGBB).
  final int argb;

  /// The gradient's end color.
  final int endArgb;

  /// Gradient direction, clockwise from "towards the top".
  final double angleDegrees;

  /// Blur strength 0–1 (blurred clip or image backgrounds).
  final double blur;

  /// Image backgrounds: content URI of the picture.
  final String? imageUri;
}

/// Visual transition played across the overlap between two adjacent clips
/// (Phase 6C).
enum SpecTransitionType {
  dissolve,
  fadeBlack,
  fadeWhite,
  circle,
  slideLeft,
  slideRight,
  slideUp,
  slideDown,
  wipeLeft,
  wipeRight,
  wipeUp,
  wipeDown,
  zoomIn,
  zoomOut,
}

/// Transition played between a clip and the clip immediately following it.
class TransitionSpec {
  TransitionSpec({required this.type, required this.durationUs});

  final SpecTransitionType type;

  /// Effective overlap length in microseconds.
  final int durationUs;
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
    required this.style,
    this.transitionOut,
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

  /// Fit, crop, transform and border.
  final ClipStyleSpec style;

  /// Optional transition into the next clip (null for a hard cut or last clip).
  final TransitionSpec? transitionOut;
}

/// What the preview plays: the main track, fitted into the canvas.
class CompositionSpec {
  CompositionSpec({
    required this.clips,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.frameRate,
    required this.background,
  });

  /// Main-track clips in timeline order.
  final List<ClipSpec> clips;

  /// Preview output size in pixels (canvas aspect).
  final int canvasWidth;
  final int canvasHeight;

  /// Frames per second used for still images.
  final int frameRate;

  /// What fills the canvas behind the clips.
  final BackgroundSpec background;
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

  /// Renders small JPEG preview thumbnails of a frame of [uri] at [timeUs]
  /// (scaled to [heightPx] tall) with each bundled LUT in [filterIds],
  /// cached on disk. Returns a map of filterId -> cached file path (or null).
  @async
  Map<String, String?> filterPreviews(
    String uri,
    int timeUs,
    int heightPx,
    List<String> filterIds,
  );
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
