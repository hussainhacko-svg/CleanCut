import 'package:flutter/material.dart';

/// The Clipcraft accent gradient (indigo → purple), used for selected tabs,
/// sliders, keyframe indicators and highlights. Registered by the app theme.
@immutable
final class AccentGradient extends ThemeExtension<AccentGradient> {
  /// Creates the gradient from [start] to [end].
  const new({required this.start, required this.end});

  /// First color (top-left).
  final Color start;

  /// Last color (bottom-right).
  final Color end;

  /// The gradient at a 135° diagonal angle.
  LinearGradient get linear => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [start, end],
  );

  /// Reads the gradient from [context]'s theme.
  static AccentGradient of(BuildContext context) =>
      Theme.of(context).extension<AccentGradient>() ??
      (throw StateError('AppTheme must register AccentGradient'));

  @override
  AccentGradient copyWith({Color? start, Color? end}) =>
      AccentGradient(start: start ?? this.start, end: end ?? this.end);

  @override
  AccentGradient lerp(AccentGradient? other, double t) => other == null
      ? this
      : AccentGradient(
          start: Color.lerp(start, other.start, t) ?? start,
          end: Color.lerp(end, other.end, t) ?? end,
        );
}
