import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_ref.freezed.dart';
part 'media_ref.g.dart';

/// What kind of media a [MediaRef] points to.
enum MediaKind {
  /// A video file (may contain audio).
  video,

  /// A still image.
  image,

  /// An audio-only file.
  audio,
}

/// A reference to a media file on the device.
///
/// Media is never copied: [uri] is a content URI whose read permission
/// was persisted when it was picked.
@freezed
abstract class MediaRef with _$MediaRef {
  /// Creates a media reference.
  ///
  /// [durationUs] is `null` for still images. [width] and [height] are the
  /// encoded size, before [rotationDegrees] (0, 90, 180 or 270, clockwise)
  /// is applied for display.
  const factory({
    required String uri,
    required MediaKind kind,
    int? durationUs,
    @Default(0) int width,
    @Default(0) int height,
    @Default(0) int rotationDegrees,
    String? displayName,
  }) = _MediaRef;

  const new _();

  /// Parses a media reference from JSON.
  factory fromJson(Map<String, dynamic> json) => _$MediaRefFromJson(json);

  /// Whether the display is rotated a quarter turn.
  bool get isQuarterTurned => rotationDegrees % 180 != 0;

  /// Width as displayed, after rotation.
  int get displayWidth => isQuarterTurned ? height : width;

  /// Height as displayed, after rotation.
  int get displayHeight => isQuarterTurned ? width : height;
}
