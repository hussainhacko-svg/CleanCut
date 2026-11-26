/// Re-timing of clip-relative keyframes when a clip's timeline changes
/// (split, trim of the start, speed change).
library;

import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';

/// Moves every keyframe of [animatable] by [deltaUs].
///
/// Keyframes that would land before 0 are dropped; the value they produced
/// at the new start is pinned by a keyframe at 0, so the visible animation
/// doesn't jump. Constants are returned unchanged.
Animatable<T> shiftKeyframes<T>(
  Animatable<T> animatable,
  int deltaUs,
  Lerp<T> lerp,
) {
  if (deltaUs == 0) return animatable;
  switch (animatable) {
    case ConstantAnimatable<T>():
      return animatable;
    case KeyframedAnimatable<T>(:final keyframes):
      final kept = [
        for (final k in keyframes)
          if (k.timeUs + deltaUs >= 0) k.copyWith(timeUs: k.timeUs + deltaUs),
      ];
      if (kept.length == keyframes.length) return Animatable.keyframed(kept);
      final pinned = Keyframe(
        timeUs: 0,
        value: animatable.valueAt(-deltaUs, lerp),
      );
      if (kept.isEmpty) return Animatable.constant(pinned.value);
      return Animatable.keyframed([
        if (kept.first.timeUs != 0) pinned,
        ...kept,
      ]);
  }
}

/// Drops keyframes after [endUs], pinning the value at [endUs] so the
/// animation up to there is unchanged.
Animatable<T> clipKeyframes<T>(
  Animatable<T> animatable,
  int endUs,
  Lerp<T> lerp,
) {
  switch (animatable) {
    case ConstantAnimatable<T>():
      return animatable;
    case KeyframedAnimatable<T>(:final keyframes):
      final kept = [
        for (final k in keyframes)
          if (k.timeUs <= endUs) k,
      ];
      if (kept.length == keyframes.length) return animatable;
      final value = animatable.valueAt(endUs, lerp);
      if (kept.isEmpty) return Animatable.constant(value);
      return Animatable.keyframed([
        ...kept,
        if (kept.last.timeUs != endUs) Keyframe(timeUs: endUs, value: value),
      ]);
  }
}

/// Multiplies every keyframe time by [factor] (e.g. old speed / new speed),
/// so keyframes stay on the same source frames. Keyframes that round onto
/// the same microsecond keep the later one.
Animatable<T> scaleKeyframes<T>(Animatable<T> animatable, double factor) {
  if (factor == 1) return animatable;
  switch (animatable) {
    case ConstantAnimatable<T>():
      return animatable;
    case KeyframedAnimatable<T>(:final keyframes):
      final byTime = <int, Keyframe<T>>{
        for (final k in keyframes)
          (k.timeUs * factor).round(): k.copyWith(
            timeUs: (k.timeUs * factor).round(),
          ),
      };
      return Animatable.keyframed(byTime.values);
  }
}

/// Keyframe re-timing applied to every property of a [ClipTransform].
extension ClipTransformRetiming on ClipTransform {
  /// See [shiftKeyframes].
  ClipTransform shifted(int deltaUs) => copyWith(
    position: shiftKeyframes(position, deltaUs, Vec2.lerp),
    scale: shiftKeyframes(scale, deltaUs, lerpDouble),
    rotation: shiftKeyframes(rotation, deltaUs, lerpDouble),
    opacity: shiftKeyframes(opacity, deltaUs, lerpDouble),
  );

  /// See [clipKeyframes].
  ClipTransform clipped(int endUs) => copyWith(
    position: clipKeyframes(position, endUs, Vec2.lerp),
    scale: clipKeyframes(scale, endUs, lerpDouble),
    rotation: clipKeyframes(rotation, endUs, lerpDouble),
    opacity: clipKeyframes(opacity, endUs, lerpDouble),
  );

  /// See [scaleKeyframes].
  ClipTransform scaledInTime(double factor) => copyWith(
    position: scaleKeyframes(position, factor),
    scale: scaleKeyframes(scale, factor),
    rotation: scaleKeyframes(rotation, factor),
    opacity: scaleKeyframes(opacity, factor),
  );
}
