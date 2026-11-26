import 'package:flutter/material.dart';

/// Lane colors of the VCLIP "Timeline" frame, registered by the app theme.
@immutable
final class TimelineColors extends ThemeExtension<TimelineColors> {
  /// Creates the palette.
  const new({
    required this.effect,
    required this.text,
    required this.overlay,
    required this.audio,
    required this.selectionTint,
  });

  /// Effect lane pills.
  final Color effect;

  /// Text lane pills.
  final Color text;

  /// Overlay lane pills.
  final Color overlay;

  /// Audio lane bars.
  final Color audio;

  /// Cream tint laid over a selected main-track clip.
  final Color selectionTint;

  /// Opacity of [selectionTint] over a selected main clip: a light wash,
  /// so its thumbnails stay visible (kit "Video").
  static const double selectedClipTint = 0.5;

  /// Opacity of the fill of a selected pill (outline stays full color).
  static const double selectedPillFill = 0.5;

  /// Opacity of the other lanes while a main-track clip is selected.
  static const double dimmedLane = 0.6;

  /// Reads the palette from [context]'s theme.
  static TimelineColors of(BuildContext context) =>
      Theme.of(context).extension<TimelineColors>() ??
      (throw StateError('AppTheme must register TimelineColors'));

  @override
  TimelineColors copyWith({
    Color? effect,
    Color? text,
    Color? overlay,
    Color? audio,
    Color? selectionTint,
  }) => TimelineColors(
    effect: effect ?? this.effect,
    text: text ?? this.text,
    overlay: overlay ?? this.overlay,
    audio: audio ?? this.audio,
    selectionTint: selectionTint ?? this.selectionTint,
  );

  @override
  TimelineColors lerp(TimelineColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return TimelineColors(
      effect: mix(effect, other.effect),
      text: mix(text, other.text),
      overlay: mix(overlay, other.overlay),
      audio: mix(audio, other.audio),
      selectionTint: mix(selectionTint, other.selectionTint),
    );
  }
}
