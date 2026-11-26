import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
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

/// The animatable properties of a [ClipTransform].
enum TransformProperty {
  /// Center offset.
  position,

  /// Uniform size factor.
  scale,

  /// Clockwise degrees.
  rotation,

  /// Transparency.
  opacity,
}

/// Allowed ranges of [ClipTransform] values.
abstract final class TransformLimits {
  /// Smallest size factor.
  static const double minScale = 0.05;

  /// Largest size factor.
  static const double maxScale = 10;

  /// How far the center may leave the canvas center, in canvas halves
  /// (2 = a full canvas width/height off-center).
  static const double maxOffset = 2;

  /// Clamps a scale into range (NaN becomes 1).
  static double clampScale(double scale) =>
      scale.isNaN ? 1 : scale.clamp(minScale, maxScale);

  /// Clamps an opacity into `[0, 1]` (NaN becomes 1).
  static double clampOpacity(double opacity) =>
      opacity.isNaN ? 1 : opacity.clamp(0.0, 1.0);

  /// Clamps a position into range (NaN becomes 0).
  static Vec2 clampPosition(Vec2 p) => Vec2(
    x: p.x.isNaN ? 0 : p.x.clamp(-maxOffset, maxOffset),
    y: p.y.isNaN ? 0 : p.y.clamp(-maxOffset, maxOffset),
  );
}

/// [degrees] wrapped into `[-180, 180]`. Values already inside stay as they
/// are (so −180° stays −180°); non-finite values become 0.
double wrapDegrees(double degrees) {
  if (!degrees.isFinite) return 0;
  if (degrees >= -180 && degrees <= 180) return degrees == 0 ? 0 : degrees;
  final w = degrees % 360;
  final wrapped = w > 180 ? w - 360 : w;
  return wrapped == 0 ? 0 : wrapped;
}

/// Whether [a] and [b] are the same orientation (equal modulo 360°).
bool sameAngle(double a, double b) => wrapDegrees(a - b).abs() < 1e-6;

/// A [ClipTransform] evaluated at one moment.
typedef ResolvedTransform = ({
  Vec2 position,
  double scale,
  double rotation,
  double opacity,
});

/// Placement of a visual clip on the canvas. The defaults are the identity.
///
/// - `position`: center offset, canvas-normalized (see [Vec2]).
/// - `scale`: uniform factor; 1 is the fitted size.
/// - `rotation`: clockwise degrees. Edits keep a constant within
///   `[-180, 180]`; keyframes are not wrapped, so they can spin more than a
///   turn.
/// - `opacity`: `[0, 1]`.
/// - `flipX` mirrors left-right, `flipY` flips upside down; both apply to
///   the picture before the rotation.
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

  const new _();

  /// Parses a transform from JSON.
  factory fromJson(Map<String, dynamic> json) => _$ClipTransformFromJson(json);

  /// Every property at clip-relative [timeUs].
  ResolvedTransform at(int timeUs) => (
    position: position.valueAt(timeUs, Vec2.lerp),
    scale: scale.valueAt(timeUs, lerpDouble),
    rotation: rotation.valueAt(timeUs, lerpDouble),
    opacity: opacity.valueAt(timeUs, lerpDouble),
  );

  /// The values an edit at [timeUs] replaces: a property with a keyframe
  /// within [toleranceUs] reads that keyframe's value (the one
  /// [withValuesAt] updates), any other property its value at [timeUs].
  ///
  /// Editors read this back, so a value they just wrote never looks like
  /// an outside change just because the playhead sits beside the keyframe.
  ResolvedTransform editableAt(int timeUs, {int toleranceUs = 0}) {
    T read<T>(Animatable<T> property, Lerp<T> lerp) =>
        property.keyframeNear(timeUs, toleranceUs: toleranceUs)?.value ??
        property.valueAt(timeUs, lerp);
    return (
      position: read(position, Vec2.lerp),
      scale: read(scale, lerpDouble),
      rotation: read(rotation, lerpDouble),
      opacity: read(opacity, lerpDouble),
    );
  }

  /// Whether any property is keyframed.
  bool get isAnimated =>
      position.isAnimated ||
      scale.isAnimated ||
      rotation.isAnimated ||
      opacity.isAnimated;

  /// Sorted, distinct times of all keyframes (for the clip's markers).
  List<int> get keyframeTimes => {
    ...position.keyframeTimes,
    ...scale.keyframeTimes,
    ...rotation.keyframeTimes,
    ...opacity.keyframeTimes,
  }.toList()..sort();

  Animatable<Object?> _property(TransformProperty property) =>
      switch (property) {
        TransformProperty.position => position,
        TransformProperty.scale => scale,
        TransformProperty.rotation => rotation,
        TransformProperty.opacity => opacity,
      };

  /// Whether [property] is keyframed.
  bool isAnimatedProperty(TransformProperty property) =>
      _property(property).isAnimated;

  /// Whether [property] has a keyframe within [toleranceUs] of [timeUs].
  bool hasKeyframeNear(
    TransformProperty property,
    int timeUs, {
    int toleranceUs = 0,
  }) =>
      _property(property).keyframeNear(timeUs, toleranceUs: toleranceUs) !=
      null;

  /// Sets the values seen at [timeUs] (see `Animatable.withValueAt`):
  /// constants change everywhere, animated properties get or update a
  /// keyframe. Values are clamped into [TransformLimits]; a non-finite
  /// rotation is ignored, a constant one is wrapped into `[-180, 180]`, and
  /// a keyframed one keeps the turn nearest the value it replaces.
  ClipTransform withValuesAt(
    int timeUs, {
    Vec2? position,
    double? scale,
    double? rotation,
    double? opacity,
    int toleranceUs = 0,
  }) => copyWith(
    position: position == null
        ? this.position
        : this.position.withValueAt(
            timeUs,
            TransformLimits.clampPosition(position),
            toleranceUs: toleranceUs,
          ),
    scale: scale == null
        ? this.scale
        : this.scale.withValueAt(
            timeUs,
            TransformLimits.clampScale(scale),
            toleranceUs: toleranceUs,
          ),
    rotation: rotation == null || !rotation.isFinite
        ? this.rotation
        : this.rotation.withValueAt(
            timeUs,
            _rotationToStore(timeUs, rotation, toleranceUs),
            toleranceUs: toleranceUs,
          ),
    opacity: opacity == null
        ? this.opacity
        : this.opacity.withValueAt(
            timeUs,
            TransformLimits.clampOpacity(opacity),
            toleranceUs: toleranceUs,
          ),
  );

  /// The angle stored for [degrees] set at [timeUs]: a constant is wrapped
  /// into `[-180, 180]`; a keyframed rotation takes the equivalent angle
  /// (± whole turns) nearest the value it replaces, so wrapping never makes
  /// the clip spin the long way round between keyframes.
  double _rotationToStore(int timeUs, double degrees, int toleranceUs) {
    if (!rotation.isAnimated) return wrapDegrees(degrees);
    final current =
        rotation.keyframeNear(timeUs, toleranceUs: toleranceUs)?.value ??
        rotation.valueAt(timeUs, lerpDouble);
    final turns = ((current - degrees) / 360).roundToDouble();
    final stored = degrees + 360 * turns;
    return stored == 0 ? 0 : stored;
  }

  /// Adds or removes a keyframe of [property] at [timeUs] (see
  /// `Animatable.toggledKeyframeAt`).
  ClipTransform toggledKeyframe(
    TransformProperty property,
    int timeUs, {
    int toleranceUs = 0,
  }) => switch (property) {
    TransformProperty.position => copyWith(
      position: position.toggledKeyframeAt(
        timeUs,
        Vec2.lerp,
        toleranceUs: toleranceUs,
      ),
    ),
    TransformProperty.scale => copyWith(
      scale: scale.toggledKeyframeAt(
        timeUs,
        lerpDouble,
        toleranceUs: toleranceUs,
      ),
    ),
    TransformProperty.rotation => copyWith(
      rotation: rotation.toggledKeyframeAt(
        timeUs,
        lerpDouble,
        toleranceUs: toleranceUs,
      ),
    ),
    TransformProperty.opacity => copyWith(
      opacity: opacity.toggledKeyframeAt(
        timeUs,
        lerpDouble,
        toleranceUs: toleranceUs,
      ),
    ),
  };

  /// Broken invariants, empty when the transform is valid.
  List<String> validate() => [
    if (scale.allValues.any(
      (s) => !(s >= TransformLimits.minScale && s <= TransformLimits.maxScale),
    ))
      'scale out of range',
    if (opacity.allValues.any((o) => !(o >= 0 && o <= 1)))
      'opacity out of range',
    if (rotation.allValues.any((r) => !r.isFinite)) 'rotation not finite',
    if (position.allValues.any(
      (p) =>
          !(p.x.abs() <= TransformLimits.maxOffset &&
              p.y.abs() <= TransformLimits.maxOffset),
    ))
      'position out of range',
  ];
}
