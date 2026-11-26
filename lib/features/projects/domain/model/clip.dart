import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/speed_curve.dart';
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
/// The clip plays `[sourceInUs, sourceOutUs)` of its [media] at [speed],
/// or along [speedCurve] when it has one (the curve then replaces [speed]).
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
    SpeedCurve? speedCurve,
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

  /// Length on the timeline, after [speed] or [speedCurve].
  int get durationUs => timelineLengthOf(sourceDurationUs);

  /// Timeline length this clip would have using [sourceUs] of source (a
  /// curve stretches with the clip).
  int timelineLengthOf(int sourceUs) => switch (speedCurve) {
    null => Micros.scaledBySpeed(sourceUs, speed),
    final curve => curve.timelineDurationUs(sourceUs),
  };

  /// Source played per timeline µs on average; equals [speed] without a
  /// curve.
  double get averageSpeed => switch (speedCurve) {
    null => speed,
    final curve => 1 / curve.timePerSource,
  };

  /// Source offset (from [sourceInUs]) shown [timelineOffsetUs] into the
  /// clip on the timeline.
  int sourceOffsetAt(int timelineOffsetUs) => switch (speedCurve) {
    null => (timelineOffsetUs * speed).round(),
    _ when durationUs <= 0 => 0,
    final curve =>
      (sourceDurationUs * curve.progressAt(timelineOffsetUs / durationUs))
          .round(),
  };

  /// Timeline offset (into the clip) at which [sourceOffsetUs] (from
  /// [sourceInUs]) plays.
  int timelineOffsetOf(int sourceOffsetUs) => switch (speedCurve) {
    null => Micros.scaledBySpeed(sourceOffsetUs, speed),
    _ when sourceDurationUs <= 0 => 0,
    final curve =>
      (durationUs * curve.timelineFractionAt(sourceOffsetUs / sourceDurationUs))
          .round(),
  };

  /// Broken invariants, empty when the clip is valid.
  List<String> validate() => [
    if (sourceInUs < 0) 'sourceInUs < 0',
    if (sourceOutUs <= sourceInUs) 'zero or negative length',
    if (media.durationUs case final d? when sourceOutUs > d)
      'sourceOutUs beyond media duration',
    if (!SpeedLimits.contains(speed)) 'speed out of range',
    if (speedCurve case final c?) ...[
      for (final problem in c.validate()) 'speedCurve: $problem',
    ],
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
    // Only measure the clip when its length and speed are valid;
    // scaledBySpeed throws on a speed <= 0.
    if (sourceOutUs > sourceInUs &&
        SpeedLimits.contains(speed) &&
        fadeInUs + fadeOutUs > Micros.scaledBySpeed(sourceDurationUs, speed))
      'fades longer than clip',
  ];
}
