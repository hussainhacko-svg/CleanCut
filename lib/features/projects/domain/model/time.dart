/// Time helpers for the project model.
///
/// Every time and duration in the model is an integer number of
/// **microseconds** (µs). Never store `double` seconds or `Duration`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

/// Conversions between microseconds and other units.
abstract final class Micros {
  /// Microseconds in one millisecond.
  static const int perMillisecond = 1000;

  /// Microseconds in one second.
  static const int perSecond = 1000000;

  /// Converts whole [milliseconds] to microseconds.
  static int fromMilliseconds(int milliseconds) =>
      milliseconds * perMillisecond;

  /// Converts [seconds] to microseconds, rounded to the nearest µs.
  static int fromSeconds(num seconds) => (seconds * perSecond).round();

  /// Converts [micros] to fractional seconds (for display only).
  static double toSeconds(int micros) => micros / perSecond;

  /// Timeline duration of [sourceDurationUs] of media played at [speed].
  ///
  /// Throws an [ArgumentError] when [speed] is not positive.
  static int scaledBySpeed(int sourceDurationUs, double speed) {
    if (speed <= 0 || speed.isNaN) {
      throw ArgumentError.value(speed, 'speed', 'must be > 0');
    }
    return (sourceDurationUs / speed).round();
  }
}

/// A half-open time range `[startUs, endUs)` in microseconds.
@immutable
final class TimeRange {
  /// Creates a range. [endUs] must not be before [startUs].
  new(this.startUs, this.endUs) {
    if (endUs < startUs) {
      throw ArgumentError('endUs ($endUs) < startUs ($startUs)');
    }
  }

  /// Inclusive start.
  final int startUs;

  /// Exclusive end.
  final int endUs;

  /// Length of the range.
  int get durationUs => endUs - startUs;

  /// Whether the range has zero length.
  bool get isEmpty => durationUs == 0;

  /// Whether [timeUs] lies inside the range.
  bool contains(int timeUs) => timeUs >= startUs && timeUs < endUs;

  /// Whether this range and [other] share any time.
  ///
  /// Ranges that only touch (`a.endUs == b.startUs`) do not overlap.
  bool overlaps(TimeRange other) =>
      startUs < other.endUs && other.startUs < endUs;

  @override
  bool operator ==(Object other) =>
      other is TimeRange && other.startUs == startUs && other.endUs == endUs;

  @override
  int get hashCode => Object.hash(startUs, endUs);

  @override
  String toString() => 'TimeRange($startUs, $endUs)';
}
