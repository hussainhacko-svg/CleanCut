import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'clip_transform.freezed.dart';
part 'clip_transform.g.dart';

/// How a clip is sized into the canvas before its [ClipTransform] applies.
enum FitMode {
  /// Whole frame visible, letterboxed.
  fit,

  /// Canvas covered, edges cropped.
  fill,

  /// Canvas covered, aspect ratio ignored.
  stretch,
}

/// Placement of a visual clip on the canvas. The defaults are the identity.
///
/// - `position`: center offset, canvas-normalized (see [Vec2]).
/// - `scale`: uniform factor; 1 is the fitted size.
/// - `rotation`: clockwise degrees.
/// - `opacity`: `[0, 1]`.
@freezed
abstract class ClipTransform with _$ClipTransform {
  /// Creates a transform.
  const factory({
    @AnimatableVec2Converter()
    @Default(Animatable<Vec2>.constant(Vec2.zero))
    Animatable<Vec2> position,
    @AnimatableDoubleConverter()
    @Default(Animatable<double>.constant(1))
    Animatable<double> scale,
    @AnimatableDoubleConverter()
    @Default(Animatable<double>.constant(0))
    Animatable<double> rotation,
    @AnimatableDoubleConverter()
    @Default(Animatable<double>.constant(1))
    Animatable<double> opacity,
    @Default(false) bool flipX,
    @Default(false) bool flipY,
  }) = _ClipTransform;

  /// Parses a transform from JSON.
  factory fromJson(Map<String, dynamic> json) => _$ClipTransformFromJson(json);
}
