import 'package:flutter/material.dart';

/// Category and timeline lane colors from the Clipcraft palette, registered
/// by the app theme.
@immutable
final class TimelineColors extends ThemeExtension<TimelineColors> {
  /// Creates the palette.
  const new({
    required this.video,
    required this.effect,
    required this.text,
    required this.overlay,
    required this.audio,
    required this.music,
    required this.selectionTint,
  });

  /// Video / timeline category color (`#36C5F0`).
  final Color video;

  /// Effect lane pills (`#A35CFF`).
  final Color effect;

  /// Text lane pills (`#FF9F43`).
  final Color text;

  /// Overlay lane pills (`#FF5D73`).
  final Color overlay;

  /// Audio lane bars (`#1DD1A1`).
  final Color audio;

  /// Music / file category accent (`#5B8CFF`).
  final Color music;

  /// Tint laid over a selected main-track clip (`#36C5F0`).
  final Color selectionTint;

  /// Six category accents cycled for project card placeholders.
  List<Color> get cardAccents => [video, audio, text, effect, overlay, music];

  /// Opacity of [selectionTint] over a selected main clip so its thumbnails
  /// stay legible.
  static const double selectedClipTint = 0.28;

  /// Opacity of the fill of an unselected lane pill (Clipcraft Timeline T1).
  static const double unselectedPillFill = 0.30;

  /// Opacity of the fill of a selected lane pill (outline stays full color).
  static const double selectedPillFill = 0.58;

  /// Opacity of the other lanes while a main-track clip is selected.
  static const double dimmedLane = 0.6;

  /// Reads the palette from [context]'s theme.
  static TimelineColors of(BuildContext context) =>
      Theme.of(context).extension<TimelineColors>() ??
      (throw StateError('AppTheme must register TimelineColors'));

  @override
  TimelineColors copyWith({
    Color? video,
    Color? effect,
    Color? text,
    Color? overlay,
    Color? audio,
    Color? music,
    Color? selectionTint,
  }) => TimelineColors(
    video: video ?? this.video,
    effect: effect ?? this.effect,
    text: text ?? this.text,
    overlay: overlay ?? this.overlay,
    audio: audio ?? this.audio,
    music: music ?? this.music,
    selectionTint: selectionTint ?? this.selectionTint,
  );

  @override
  TimelineColors lerp(TimelineColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return TimelineColors(
      video: mix(video, other.video),
      effect: mix(effect, other.effect),
      text: mix(text, other.text),
      overlay: mix(overlay, other.overlay),
      audio: mix(audio, other.audio),
      music: mix(music, other.music),
      selectionTint: mix(selectionTint, other.selectionTint),
    );
  }
}
