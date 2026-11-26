import 'dart:math' as math;

import 'package:cleancut/features/projects/domain/model/clip.dart';

/// Maps the Speed panel's ruler (0–1, left to right) to a playback speed.
///
/// Like the kit's Speed frame, the labelled speeds sit at even distances;
/// between two labels the speed grows geometrically, so 1× is the middle
/// and halving or doubling feel the same size. Covers [SpeedLimits].
abstract final class SpeedScale {
  /// Labelled speeds, slowest first (owner decision: 0.1×–10×).
  static const List<double> marks = [0.1, 0.25, 0.5, 1, 2, 5, 10];

  /// The default speed.
  static const double normal = 1;

  /// Ruler distance (0–1) within which a drag snaps to a mark.
  static const double snapDistance = 0.02;

  static int get _segments => marks.length - 1;

  /// Ruler position of [speed], clamped to the scale.
  static double positionOf(double speed) {
    final s = speed.clamp(marks.first, marks.last);
    for (var i = 0; i < _segments; i++) {
      final lo = marks[i];
      final hi = marks[i + 1];
      if (s <= hi) {
        final f = math.log(s / lo) / math.log(hi / lo);
        return (i + f) / _segments;
      }
    }
    return 1;
  }

  /// Ruler position of mark [index].
  static double markPosition(int index) => index / _segments;

  /// Speed at ruler [position], rounded for display (0.01 below 1×, 0.1
  /// from 1×) and snapped to a mark within [snapDistance].
  static double speedAt(double position) {
    final p = position.clamp(0.0, 1.0);
    for (var i = 0; i < marks.length; i++) {
      if ((p - markPosition(i)).abs() <= snapDistance) return marks[i];
    }
    final scaled = p * _segments;
    final seg = scaled.floor().clamp(0, _segments - 1);
    final lo = marks[seg];
    final hi = marks[seg + 1];
    final raw = lo * math.pow(hi / lo, scaled - seg);
    return round(raw);
  }

  /// [speed] rounded to the panel's precision and clamped to the limits.
  static double round(double speed) {
    final step = speed < 1 ? 100 : 10;
    final rounded = (speed * step).round() / step;
    return rounded.clamp(SpeedLimits.min, SpeedLimits.max);
  }

  /// The mark equal to [speed], if any (for haptics and the label tint).
  static int? markIndexOf(double speed) {
    final i = marks.indexOf(speed);
    return i < 0 ? null : i;
  }
}
