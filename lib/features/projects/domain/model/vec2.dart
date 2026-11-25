import 'package:freezed_annotation/freezed_annotation.dart';

part 'vec2.freezed.dart';
part 'vec2.g.dart';

/// A 2D vector, used for canvas-normalized positions.
///
/// Positions use the canvas center as origin; `x = 1` is the right edge
/// and `y = 1` the bottom edge.
@freezed
abstract class Vec2 with _$Vec2 {
  /// Creates a vector.
  const factory({required double x, required double y}) = _Vec2;

  const new _();

  /// Parses a vector from JSON.
  factory fromJson(Map<String, dynamic> json) => _$Vec2FromJson(json);

  /// Linear interpolation between [a] and [b] by [t].
  factory lerp(Vec2 a, Vec2 b, double t) =>
      Vec2(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t);

  /// The origin.
  static const zero = Vec2(x: 0, y: 0);
}
