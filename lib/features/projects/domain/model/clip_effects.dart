import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'clip_effects.freezed.dart';
part 'clip_effects.g.dart';

/// Allowed range of a clip's whole-clip blur (`0..1`).
abstract final class BlurLimits {
  /// No blur.
  static const double min = 0;

  /// Strongest blur.
  static const double max = 1;

  /// Quick preset levels offered in the Blur panel.
  static const List<double> presets = [0.25, 0.5, 0.75, 1];

  /// Clamps [amount] into `[min, max]`, turning non-finite values into 0.
  static double clamp(double amount) {
    if (!amount.isFinite) return 0;
    final clamped = amount.clamp(min, max);
    return clamped == 0 ? 0 : clamped;
  }
}

/// Geometric shape of a [ClipMask].
enum MaskShape {
  /// Half-plane split along a rotatable line.
  linear,

  /// Parallel band centered on a rotatable line.
  mirror,

  /// Circle or ellipse.
  circle,

  /// Rectangle.
  rect,

  /// Heart silhouette.
  heart,

  /// Five-pointed star.
  star,
}

/// The animatable properties of a [ClipMask].
enum MaskProperty {
  /// Mask center in clip-normalized coordinates.
  center,

  /// Mask width and height relative to the clip's shorter half-side.
  size,

  /// Clockwise rotation in degrees.
  rotation,

  /// Edge softness (`0..1`).
  feather,
}

/// Allowed ranges and defaults of [ClipMask] parameters.
abstract final class MaskLimits {
  /// Maximum normalized center offset relative to the clip's half-extents.
  static const double maxCenterOffset = 1.5;

  /// Smallest allowed mask half-extent, as a fraction of the clip's shorter
  /// half-side.
  static const double minSize = 0.05;

  /// Largest allowed mask half-extent, as a fraction of the clip's shorter
  /// half-side (large enough to span wide or tall clips).
  static const double maxSize = 4;

  /// Softest edge feather.
  static const double maxFeather = 1;

  /// Default half-extents for closed shapes (circle, rect, heart, star).
  static const Vec2 defaultSize = Vec2(x: 0.7, y: 0.7);

  /// Default half-extents for [MaskShape.mirror] (`y` is the band half-width).
  static const Vec2 defaultMirrorSize = Vec2(x: 0.7, y: 0.45);

  /// Clamps a center offset into `[-maxCenterOffset, maxCenterOffset]`.
  static Vec2 clampCenter(Vec2 p) => Vec2(
    x: p.x.isFinite
        ? _cleanZero(p.x.clamp(-maxCenterOffset, maxCenterOffset))
        : 0,
    y: p.y.isFinite
        ? _cleanZero(p.y.clamp(-maxCenterOffset, maxCenterOffset))
        : 0,
  );

  /// Clamps mask half-extents into `[minSize, maxSize]`.
  static Vec2 clampSize(Vec2 s) => Vec2(
    x: s.x.isFinite ? s.x.clamp(minSize, maxSize) : defaultSize.x,
    y: s.y.isFinite ? s.y.clamp(minSize, maxSize) : defaultSize.y,
  );

  /// Clamps feather into `[0, maxFeather]`.
  static double clampFeather(double feather) =>
      feather.isFinite ? _cleanZero(feather.clamp(0.0, maxFeather)) : 0;

  static double _cleanZero(double value) => value == 0 ? 0.0 : value;
}

/// A [ClipMask] evaluated at one moment.
typedef ResolvedMask = ({
  Vec2 center,
  Vec2 size,
  double rotation,
  double feather,
});

/// Shape mask applied to a clip (Phase 6B).
///
/// - `center`: clip-normalized center offset (`Vec2.zero` is clip center;
///   `±1` reaches the clip's edges).
/// - `size`: half-extents `(x, y)` as multiples of the clip's shorter
///   half-side, so `size.x == size.y` is visually square/circular regardless of
///   the clip's aspect ratio. For [MaskShape.mirror], `size.y` is the band's
///   half-width. [MaskShape.linear] ignores `size`.
/// - `rotation`: clockwise degrees in clip space.
/// - `feather`: edge softness in `[0, 1]` (fraction of the clip's shorter
///   half-side).
/// - `invert`: flips inside and outside.
@freezed
abstract class ClipMask with _$ClipMask {
  /// Creates a clip mask. Use [validate] to check its invariants.
  const factory({
    required MaskShape shape,
    @AnimatableVec2Converter()
    @Default(Animatable<Vec2>.constant(Vec2.zero))
    Animatable<Vec2> center,
    @AnimatableVec2Converter()
    @Default(Animatable<Vec2>.constant(MaskLimits.defaultSize))
    Animatable<Vec2> size,
    @AnimatableDoubleConverter()
    @Default(Animatable<double>.constant(0))
    Animatable<double> rotation,
    @AnimatableDoubleConverter()
    @Default(Animatable<double>.constant(0))
    Animatable<double> feather,
    @Default(false) bool invert,
  }) = _ClipMask;

  const new _();

  /// Parses a mask from JSON.
  factory fromJson(Map<String, dynamic> json) => _$ClipMaskFromJson(json);

  /// Default mask for [shape] centered on the clip.
  factory defaultFor(MaskShape shape) => ClipMask(
    shape: shape,
    size: Animatable.constant(
      shape == MaskShape.mirror
          ? MaskLimits.defaultMirrorSize
          : MaskLimits.defaultSize,
    ),
  );

  /// Whether [shape] uses width and height handles (all except linear).
  bool get hasSize => shape != MaskShape.linear;

  /// This mask switched to [next], keeping center, rotation, feather, invert
  /// and (where it still means the same thing) size:
  /// - linear has no size and mirror only uses `size.y` (the band), so a shape
  ///   made from them starts at [next]'s default size;
  /// - heart and star are uniform, so each size value evens out to the mean
  ///   of its width and height (keyframes stay keyframes).
  ClipMask withShape(MaskShape next) {
    if (next == shape) return this;
    final Animatable<Vec2> nextSize;
    if (next == MaskShape.linear || (next == MaskShape.mirror && hasSize)) {
      nextSize = size;
    } else if (!hasSize || shape == MaskShape.mirror) {
      nextSize = ClipMask.defaultFor(next).size;
    } else if (next == MaskShape.heart || next == MaskShape.star) {
      nextSize = _mapValues(size, (s) {
        final mean = (s.x + s.y) / 2;
        return MaskLimits.clampSize(Vec2(x: mean, y: mean));
      });
    } else {
      nextSize = size;
    }
    return copyWith(shape: next, size: nextSize);
  }

  static Animatable<Vec2> _mapValues(
    Animatable<Vec2> property,
    Vec2 Function(Vec2) f,
  ) => switch (property) {
    ConstantAnimatable<Vec2>(:final value) => Animatable.constant(f(value)),
    KeyframedAnimatable<Vec2>(:final keyframes) => Animatable.keyframed([
      for (final k in keyframes) k.copyWith(value: f(k.value)),
    ]),
  };

  /// Every property evaluated at clip-relative [timeUs].
  ResolvedMask at(int timeUs) => (
    center: center.valueAt(timeUs, Vec2.lerp),
    size: size.valueAt(timeUs, Vec2.lerp),
    rotation: rotation.valueAt(timeUs, lerpDouble),
    feather: feather.valueAt(timeUs, lerpDouble),
  );

  /// Values an edit at [timeUs] replaces (reads a nearby keyframe's value so
  /// edits never look like outside changes beside a keyframe).
  ResolvedMask editableAt(int timeUs, {int toleranceUs = 0}) {
    T read<T>(Animatable<T> property, Lerp<T> lerp) =>
        property.keyframeNear(timeUs, toleranceUs: toleranceUs)?.value ??
        property.valueAt(timeUs, lerp);
    return (
      center: read(center, Vec2.lerp),
      size: read(size, Vec2.lerp),
      rotation: read(rotation, lerpDouble),
      feather: read(feather, lerpDouble),
    );
  }

  /// Sorted, distinct times of all mask keyframes.
  List<int> get keyframeTimes => {
    ...center.keyframeTimes,
    ...size.keyframeTimes,
    ...rotation.keyframeTimes,
    ...feather.keyframeTimes,
  }.toList()..sort();

  Animatable<Object?> _property(MaskProperty property) => switch (property) {
    MaskProperty.center => center,
    MaskProperty.size => size,
    MaskProperty.rotation => rotation,
    MaskProperty.feather => feather,
  };

  /// Whether [property] is keyframed.
  bool isAnimatedProperty(MaskProperty property) =>
      _property(property).isAnimated;

  /// Whether [property] has a keyframe within [toleranceUs] of [timeUs].
  bool hasKeyframeNear(
    MaskProperty property,
    int timeUs, {
    int toleranceUs = 0,
  }) =>
      _property(property).keyframeNear(timeUs, toleranceUs: toleranceUs) !=
      null;

  /// Updates whichever values are non-null at clip-relative [timeUs].
  ClipMask withValuesAt(
    int timeUs, {
    Vec2? center,
    Vec2? size,
    double? rotation,
    double? feather,
    bool? invert,
    int toleranceUs = 0,
  }) => copyWith(
    center: center == null
        ? this.center
        : this.center.withValueAt(
            timeUs,
            MaskLimits.clampCenter(center),
            toleranceUs: toleranceUs,
          ),
    size: size == null
        ? this.size
        : this.size.withValueAt(
            timeUs,
            MaskLimits.clampSize(size),
            toleranceUs: toleranceUs,
          ),
    rotation: rotation == null || !rotation.isFinite
        ? this.rotation
        : this.rotation.withValueAt(
            timeUs,
            _rotationToStore(timeUs, rotation, toleranceUs),
            toleranceUs: toleranceUs,
          ),
    feather: feather == null
        ? this.feather
        : this.feather.withValueAt(
            timeUs,
            MaskLimits.clampFeather(feather),
            toleranceUs: toleranceUs,
          ),
    invert: invert ?? this.invert,
  );

  double _rotationToStore(int timeUs, double degrees, int toleranceUs) {
    if (!rotation.isAnimated) return wrapDegrees(degrees);
    final current =
        rotation.keyframeNear(timeUs, toleranceUs: toleranceUs)?.value ??
        rotation.valueAt(timeUs, lerpDouble);
    final turns = ((current - degrees) / 360).roundToDouble();
    final stored = degrees + 360 * turns;
    return stored == 0 ? 0 : stored;
  }

  /// Adds or removes a keyframe of [property] at [timeUs].
  ClipMask toggledKeyframe(
    MaskProperty property,
    int timeUs, {
    int toleranceUs = 0,
  }) => switch (property) {
    MaskProperty.center => copyWith(
      center: center.toggledKeyframeAt(
        timeUs,
        Vec2.lerp,
        toleranceUs: toleranceUs,
      ),
    ),
    MaskProperty.size => copyWith(
      size: size.toggledKeyframeAt(timeUs, Vec2.lerp, toleranceUs: toleranceUs),
    ),
    MaskProperty.rotation => copyWith(
      rotation: rotation.toggledKeyframeAt(
        timeUs,
        lerpDouble,
        toleranceUs: toleranceUs,
      ),
    ),
    MaskProperty.feather => copyWith(
      feather: feather.toggledKeyframeAt(
        timeUs,
        lerpDouble,
        toleranceUs: toleranceUs,
      ),
    ),
  };

  /// Broken invariants, empty when valid.
  List<String> validate() => [
    if (center.allValues.any(
      (p) =>
          !p.x.isFinite ||
          !p.y.isFinite ||
          p.x.abs() > MaskLimits.maxCenterOffset ||
          p.y.abs() > MaskLimits.maxCenterOffset,
    ))
      'center out of range',
    if (size.allValues.any(
      (s) =>
          !(s.x >= MaskLimits.minSize &&
              s.x <= MaskLimits.maxSize &&
              s.y >= MaskLimits.minSize &&
              s.y <= MaskLimits.maxSize),
    ))
      'size out of range',
    if (rotation.allValues.any((r) => !r.isFinite)) 'rotation not finite',
    if (feather.allValues.any((f) => !(f >= 0 && f <= MaskLimits.maxFeather)))
      'feather out of range',
  ];
}
