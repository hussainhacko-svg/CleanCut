import 'dart:math' as math;

import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'speed_curve.freezed.dart';
part 'speed_curve.g.dart';

/// Ready-made speed ramps (Flow curves). [custom] marks a curve the user
/// edited.
enum SpeedCurvePreset {
  /// Edited by hand (starts flat at 1×).
  custom,

  /// Speeds up, slows in the middle, speeds up again.
  montage,

  /// A slow-motion moment in the middle.
  hero,

  /// Fast in, long slow middle, fast out.
  bullet,

  /// Starts fast and settles to 1×.
  flashIn,

  /// Ends fast.
  flashOut;

  /// The preset's points (owner-approved shapes: speed at the start, 25%,
  /// 50%, 75% and the end of the clip).
  SpeedCurve get curve => SpeedCurve.evenly(this, switch (this) {
    custom => const [1, 1, 1, 1, 1],
    montage => const [1, 2, 0.5, 2, 1],
    hero => const [1, 1, 0.25, 1, 1],
    bullet => const [2, 0.25, 0.25, 0.25, 2],
    flashIn => const [5, 2, 1, 1, 1],
    flashOut => const [1, 1, 1, 2, 5],
  });
}

/// A point of a [SpeedCurve]: [speed] at [x], the clip's progress through
/// its source range (0 = first frame, 1 = last).
@freezed
abstract class CurvePoint with _$CurvePoint {
  /// Creates a point.
  const factory({required double x, required double speed}) = _CurvePoint;

  /// Parses a point from JSON.
  factory fromJson(Map<String, dynamic> json) => _$CurvePointFromJson(json);
}

/// One constant-speed piece of a curve as the engine plays it: from
/// `startUs` (into the clip's source range) to the next step, at `speed`.
typedef SpeedStep = ({int startUs, double speed});

/// A speed ramp over a clip ("Flow" curve).
///
/// The curve is defined over the clip's *progress* (0–1 of its used source
/// range), so trimming stretches it and splitting divides it (owner
/// decision). Between points the speed follows a smooth monotone cubic in
/// log-speed space, so it never overshoots the points or [SpeedLimits].
///
/// For playback the curve is cut into [stepCount] equal source pieces of
/// constant speed ([steps]); timeline lengths are computed from the same
/// pieces, so the model and the engine agree.
@freezed
abstract class SpeedCurve with _$SpeedCurve {
  /// Creates a curve. Use [validate] to check its invariants.
  const factory({
    required SpeedCurvePreset preset,
    required List<CurvePoint> points,
  }) = _SpeedCurve;

  const new _();

  /// A curve through [speeds] at even distances.
  factory evenly(SpeedCurvePreset preset, List<double> speeds) => SpeedCurve(
    preset: preset,
    points: [
      for (final (i, s) in speeds.indexed)
        CurvePoint(x: i / (speeds.length - 1), speed: s),
    ],
  );

  /// Parses a curve from JSON.
  factory fromJson(Map<String, dynamic> json) => _$SpeedCurveFromJson(json);

  /// Constant-speed pieces used for playback and length.
  static const int stepCount = 64;

  /// Most points a curve may have.
  static const int maxPoints = 10;

  /// Smallest distance between two points' [CurvePoint.x].
  static const double minGap = 0.02;

  /// Broken invariants, empty when the curve is valid.
  List<String> validate() => [
    if (points.length < 2) 'fewer than 2 points',
    if (points.length > maxPoints) 'more than $maxPoints points',
    if (points.isNotEmpty && points.first.x != 0) 'first point not at 0',
    if (points.isNotEmpty && points.last.x != 1) 'last point not at 1',
    for (var i = 1; i < points.length; i++)
      if (points[i].x - points[i - 1].x < minGap - 1e-9)
        'points $i-1 and $i closer than $minGap',
    for (final p in points)
      if (!SpeedLimits.contains(p.speed)) 'speed ${p.speed} out of range',
  ];

  /// The speed at progress [x] (clamped to 0–1).
  double speedAt(double x) {
    final logSpeed = _MonotoneCubic.of(points).at(x.clamp(0.0, 1.0));
    return math
        .pow(2, logSpeed)
        .toDouble()
        .clamp(SpeedLimits.min, SpeedLimits.max);
  }

  /// Speed of each of the [stepCount] pieces (sampled at its middle).
  List<double> get stepSpeeds {
    final spline = _MonotoneCubic.of(points);
    return [
      for (var i = 0; i < stepCount; i++)
        math
            .pow(2, spline.at((i + 0.5) / stepCount))
            .toDouble()
            .clamp(SpeedLimits.min, SpeedLimits.max),
    ];
  }

  /// Timeline length of one unit of source (the mean of 1 / speed): a
  /// clip using `L` µs of source lasts `round(L * timePerSource)` µs.
  double get timePerSource {
    var sum = 0.0;
    for (final s in stepSpeeds) {
      sum += 1 / s;
    }
    return sum / stepCount;
  }

  /// Timeline length of [sourceDurationUs] of source played on this curve.
  int timelineDurationUs(int sourceDurationUs) =>
      (sourceDurationUs * timePerSource).round();

  /// The engine's constant-speed pieces for [sourceDurationUs] of source.
  List<SpeedStep> steps(int sourceDurationUs) {
    final speeds = stepSpeeds;
    return [
      for (var i = 0; i < stepCount; i++)
        (startUs: (sourceDurationUs * i / stepCount).round(), speed: speeds[i]),
    ];
  }

  /// Source progress (0–1) reached after [timelineFraction] (0–1) of the
  /// clip's timeline length.
  double progressAt(double timelineFraction) {
    final speeds = stepSpeeds;
    final total = timePerSource * stepCount;
    var target = timelineFraction.clamp(0.0, 1.0) * total;
    for (var i = 0; i < stepCount; i++) {
      final piece = 1 / speeds[i];
      if (target <= piece) return (i + target / piece) / stepCount;
      target -= piece;
    }
    return 1;
  }

  /// Timeline fraction (0–1) at which source [progress] (0–1) plays.
  double timelineFractionAt(double progress) {
    final speeds = stepSpeeds;
    final p = progress.clamp(0.0, 1.0) * stepCount;
    var time = 0.0;
    for (var i = 0; i < stepCount; i++) {
      if (p <= i) break;
      time += math.min(1, p - i) / speeds[i];
    }
    return time / (timePerSource * stepCount);
  }

  /// The two halves of this curve when its clip is cut at source progress
  /// [x] (0 < x < 1), each stretched back to 0–1. Both halves meet at the
  /// speed at the cut.
  (SpeedCurve, SpeedCurve) splitAt(double x) => (_part(0, x), _part(x, 1));

  /// This curve between progress [from] and [to], stretched to 0–1.
  ///
  /// A smooth curve through fewer points would bend differently, so the
  /// part also gets points sampled from this curve (filling its widest
  /// gaps, up to [maxPoints]); it then keeps the original shape and length
  /// closely.
  SpeedCurve _part(double from, double to) {
    final xs = <double>[
      from,
      for (final p in points)
        if (p.x > from + minGap / 2 && p.x < to - minGap / 2) p.x,
      to,
    ];
    while (xs.length < maxPoints) {
      var widest = 0;
      for (var i = 1; i < xs.length - 1; i++) {
        if (xs[i + 1] - xs[i] > xs[widest + 1] - xs[widest]) widest = i;
      }
      final gap = xs[widest + 1] - xs[widest];
      if (gap / (to - from) < 2 * minGap) break;
      xs.insert(widest + 1, xs[widest] + gap / 2);
    }
    return SpeedCurve(
      preset: SpeedCurvePreset.custom,
      points: _spaced([
        for (final x in xs)
          CurvePoint(x: (x - from) / (to - from), speed: speedAt(x)),
      ]),
    );
  }

  /// Drops inner points that came closer than [minGap] (after a split
  /// squeezed them), keeping both ends and the point count ≤ [maxPoints].
  static List<CurvePoint> _spaced(List<CurvePoint> points) {
    final result = <CurvePoint>[points.first];
    for (var i = 1; i < points.length - 1; i++) {
      if (points[i].x - result.last.x >= minGap &&
          points.last.x - points[i].x >= minGap) {
        result.add(points[i]);
      }
    }
    result.add(points.last);
    return result.length <= maxPoints
        ? result
        : [...result.take(maxPoints - 1), result.last];
  }
}

/// Fritsch–Carlson monotone cubic through (x, log2 speed): smooth, and
/// never above or below its neighbouring points.
final class _MonotoneCubic {
  new _(this._xs, this._ys, this._ms);

  factory of(List<CurvePoint> points) {
    final xs = [for (final p in points) p.x];
    final ys = [for (final p in points) math.log(p.speed) / math.ln2];
    final n = xs.length;
    if (n < 2) return _MonotoneCubic._(xs, ys, List.filled(n, 0));
    final d = [
      for (var i = 0; i < n - 1; i++) (ys[i + 1] - ys[i]) / (xs[i + 1] - xs[i]),
    ];
    final m = List<double>.filled(n, 0);
    m[0] = d.first;
    m[n - 1] = d.last;
    for (var i = 1; i < n - 1; i++) {
      m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2;
    }
    for (var i = 0; i < n - 1; i++) {
      if (d[i] == 0) {
        m[i] = 0;
        m[i + 1] = 0;
        continue;
      }
      final a = m[i] / d[i];
      final b = m[i + 1] / d[i];
      final h = a * a + b * b;
      if (h > 9) {
        final t = 3 / math.sqrt(h);
        m[i] = t * a * d[i];
        m[i + 1] = t * b * d[i];
      }
    }
    return _MonotoneCubic._(xs, ys, m);
  }

  final List<double> _xs;
  final List<double> _ys;
  final List<double> _ms;

  double at(double x) {
    if (_xs.isEmpty) return 0;
    if (_xs.length == 1 || x <= _xs.first) return _ys.first;
    if (x >= _xs.last) return _ys.last;
    var i = 0;
    while (i < _xs.length - 2 && x > _xs[i + 1]) {
      i++;
    }
    final h = _xs[i + 1] - _xs[i];
    final t = (x - _xs[i]) / h;
    final t2 = t * t;
    final t3 = t2 * t;
    return (2 * t3 - 3 * t2 + 1) * _ys[i] +
        (t3 - 2 * t2 + t) * h * _ms[i] +
        (-2 * t3 + 3 * t2) * _ys[i + 1] +
        (t3 - t2) * h * _ms[i + 1];
  }
}
