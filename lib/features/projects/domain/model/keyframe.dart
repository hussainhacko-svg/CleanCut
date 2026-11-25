import 'package:cleancut/features/projects/domain/model/easing.dart';

import 'package:freezed_annotation/freezed_annotation.dart';

/// Interpolates between two values of [T] by progress `t`.
typedef Lerp<T> = T Function(T a, T b, double t);

/// Interpolates doubles linearly.
double lerpDouble(double a, double b, double t) => a + (b - a) * t;

/// A value pinned at a time on a clip.
///
/// [timeUs] is relative to the start of the clip on the timeline.
/// [easing] shapes the transition from this keyframe to the next one.
@immutable
final class Keyframe<T> {
  /// Creates a keyframe. [timeUs] must not be negative.
  new({
    required this.timeUs,
    required this.value,
    this.easing = Easing.linear,
  }) {
    if (timeUs < 0) {
      throw ArgumentError.value(timeUs, 'timeUs', 'must be >= 0');
    }
  }

  /// Clip-relative time in microseconds.
  final int timeUs;

  /// The value at [timeUs].
  final T value;

  /// Curve towards the next keyframe.
  final Easing easing;

  /// Returns a copy with the given fields replaced.
  Keyframe<T> copyWith({int? timeUs, T? value, Easing? easing}) => Keyframe(
    timeUs: timeUs ?? this.timeUs,
    value: value ?? this.value,
    easing: easing ?? this.easing,
  );

  @override
  bool operator ==(Object other) =>
      other is Keyframe<T> &&
      other.timeUs == timeUs &&
      other.value == value &&
      other.easing == easing;

  @override
  int get hashCode => Object.hash(timeUs, value, easing);

  @override
  String toString() => 'Keyframe($timeUs, $value, $easing)';
}
