import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'clip.freezed.dart';
part 'clip.g.dart';

/// Allowed playback speed range for clips ("Flow").
abstract final class SpeedLimits {
  /// Slowest speed.
  static const double min = 0.1;

  /// Fastest speed.
  static const double max = 10;

  /// Whether [speed] is allowed.
  static bool contains(double speed) => speed >= min && speed <= max;
}

/// Default length of a still image placed on the timeline.
const int defaultImageDurationUs = 3 * Micros.perSecond;

/// A visual (video or image) clip.
///
/// The clip plays `[sourceInUs, sourceOutUs)` of its [media] at [speed].
/// For images the source range is just the display length.
@freezed
abstract class Clip with _$Clip {
  /// Creates a clip. Use [validate] to check its invariants.
  const factory({
    required String id,
    required MediaRef media,
    required int sourceInUs,
    required int sourceOutUs,
    @Default(1.0) double speed,
    @Default(true) bool keepPitch,
    @Default(ClipTransform()) ClipTransform transform,
    @Default(FitMode.fit) FitMode fitMode,
    @Default(1.0) double volume,
    @Default(false) bool muted,
  }) = _Clip;

  const new _();

  /// A clip covering all of [media]; images get [imageDurationUs].
  ///
  /// Throws an [ArgumentError] for audio media or a non-positive length.
  factory fromMedia({
    required String id,
    required MediaRef media,
    int imageDurationUs = defaultImageDurationUs,
  }) {
    if (media.kind == MediaKind.audio) {
      throw ArgumentError.value(media.kind, 'media', 'audio is not visual');
    }
    final length = media.durationUs ?? imageDurationUs;
    if (length <= 0) {
      throw ArgumentError.value(length, 'duration', 'must be > 0');
    }
    return Clip(id: id, media: media, sourceInUs: 0, sourceOutUs: length);
  }

  /// Parses a clip from JSON.
  factory fromJson(Map<String, dynamic> json) => _$ClipFromJson(json);

  /// Length of the used source range.
  int get sourceDurationUs => sourceOutUs - sourceInUs;

  /// Length on the timeline, after [speed].
  int get durationUs => Micros.scaledBySpeed(sourceDurationUs, speed);

  /// Broken invariants, empty when the clip is valid.
  List<String> validate() => [
    if (sourceInUs < 0) 'sourceInUs < 0',
    if (sourceOutUs <= sourceInUs) 'zero or negative length',
    if (media.durationUs case final d? when sourceOutUs > d)
      'sourceOutUs beyond media duration',
    if (!SpeedLimits.contains(speed)) 'speed out of range',
    if (volume < 0) 'volume < 0',
    if (media.kind == MediaKind.audio) 'audio media in a visual clip',
  ];
}

/// An audio clip on an audio track.
@freezed
abstract class AudioClip with _$AudioClip {
  /// Creates an audio clip. Use [validate] to check its invariants.
  const factory({
    required String id,
    required MediaRef media,
    required int sourceInUs,
    required int sourceOutUs,
    @Default(1.0) double speed,
    @Default(1.0) double volume,
    @Default(0) int fadeInUs,
    @Default(0) int fadeOutUs,
  }) = _AudioClip;

  const new _();

  /// Parses an audio clip from JSON.
  factory fromJson(Map<String, dynamic> json) => _$AudioClipFromJson(json);

  /// Length of the used source range.
  int get sourceDurationUs => sourceOutUs - sourceInUs;

  /// Length on the timeline, after [speed].
  int get durationUs => Micros.scaledBySpeed(sourceDurationUs, speed);

  /// Broken invariants, empty when the clip is valid.
  List<String> validate() => [
    if (sourceInUs < 0) 'sourceInUs < 0',
    if (sourceOutUs <= sourceInUs) 'zero or negative length',
    if (media.durationUs case final d? when sourceOutUs > d)
      'sourceOutUs beyond media duration',
    if (media.kind == MediaKind.image) 'image media in an audio clip',
    if (!SpeedLimits.contains(speed)) 'speed out of range',
    if (volume < 0) 'volume < 0',
    if (fadeInUs < 0 || fadeOutUs < 0) 'negative fade',
    if (sourceOutUs > sourceInUs &&
        fadeInUs + fadeOutUs > Micros.scaledBySpeed(sourceDurationUs, speed))
      'fades longer than clip',
  ];
}
