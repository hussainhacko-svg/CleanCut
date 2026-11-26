import 'package:freezed_annotation/freezed_annotation.dart';

part 'easing.freezed.dart';
part 'easing.g.dart';

/// Easing curve between two keyframes, expressed as a CSS-style cubic
/// Bézier with fixed end points `(0, 0)` and `(1, 1)`.
@freezed
abstract class Easing with _$Easing {
  /// Creates a cubic Bézier easing. `x1` and `x2` must be within `[0, 1]`.
  @Assert('x1 >= 0 && x1 <= 1', 'x1 must be within [0, 1]')
  @Assert('x2 >= 0 && x2 <= 1', 'x2 must be within [0, 1]')
  const factory({
    required double x1,
    required double y1,
    required double x2,
    required double y2,
  }) = _Easing;

  const new _();

  /// Parses an easing from JSON.
  factory fromJson(Map<String, dynamic> json) => _$EasingFromJson(json);

  /// Constant speed.
  static const linear = Easing(x1: 0, y1: 0, x2: 1, y2: 1);

  /// Starts slow.
  static const easeIn = Easing(x1: 0.42, y1: 0, x2: 1, y2: 1);

  /// Ends slow.
  static const easeOut = Easing(x1: 0, y1: 0, x2: 0.58, y2: 1);

  /// Starts and ends slow.
  static const easeInOut = Easing(x1: 0.42, y1: 0, x2: 0.58, y2: 1);

  /// Whether this is exactly [linear].
  bool get isLinear => x1 == y1 && x2 == y2;

  /// Maps linear progress [t] in `[0, 1]` to eased progress.
  ///
  /// [t] is clamped to `[0, 1]`. The result may leave `[0, 1]` when `y1`
  /// or `y2` do (overshoot curves).
  double transform(double t) {
    final x = t.clamp(0.0, 1.0);
    if (x == 0 || x == 1 || isLinear) return x;
    return _sampleY(_solveForParameter(x));
  }

  // Bézier coordinate for control values a, b at parameter s.
  static double _bezier(double a, double b, double s) {
    final inv = 1 - s;
    return 3 * inv * inv * s * a + 3 * inv * s * s * b + s * s * s;
  }

  static double _bezierSlope(double a, double b, double s) {
    final inv = 1 - s;
    return 3 * inv * inv * a + 6 * inv * s * (b - a) + 3 * s * s * (1 - b);
  }

  double _sampleY(double s) => _bezier(y1, y2, s);

  /// Finds the curve parameter whose x equals [x]: Newton first, then
  /// bisection if Newton does not converge (flat slopes).
  double _solveForParameter(double x) {
    var s = x;
    for (var i = 0; i < 8; i++) {
      // Stay on the curve's [0, 1] segment; a root outside it is wrong.
      if (s < 0 || s > 1) break;
      final error = _bezier(x1, x2, s) - x;
      if (error.abs() < 1e-7) return s;
      final slope = _bezierSlope(x1, x2, s);
      if (slope.abs() < 1e-6) break;
      s -= error / slope;
    }
    var lo = 0.0;
    var hi = 1.0;
    s = x;
    for (var i = 0; i < 50; i++) {
      final value = _bezier(x1, x2, s);
      if ((value - x).abs() < 1e-7) break;
      if (value < x) {
        lo = s;
      } else {
        hi = s;
      }
      s = (lo + hi) / 2;
    }
    return s;
  }
}
