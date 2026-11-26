import 'package:flutter/material.dart';

/// The VCLIP accent gradient (orange → pink), used for selected tabs, the
/// scrub bar and premium highlights. Registered by the app theme.
@immutable
final class AccentGradient extends ThemeExtension<AccentGradient> {
  /// Creates the gradient from [start] to [end].
  const new({required this.start, required this.end});

  /// First color (top-left).
  final Color start;

  /// Last color (bottom-right).
  final Color end;

  /// The gradient at the kit's 135° angle.
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
