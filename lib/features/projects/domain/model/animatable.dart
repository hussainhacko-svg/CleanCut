import 'package:cleancut/features/projects/domain/model/easing.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// A property that is either a constant or animated by keyframes.
@immutable
sealed class Animatable<T> {
  const new();

  /// A property that never changes.
  const factory constant(T value) = ConstantAnimatable<T>;

  /// A property animated by [keyframes]; they are sorted by time.
  ///
  /// Throws an [ArgumentError] when [keyframes] is empty or two keyframes
  /// share a time.
  factory keyframed(Iterable<Keyframe<T>> keyframes) = KeyframedAnimatable<T>;

  /// Whether the value changes over time.
  bool get isAnimated;

  /// The value at clip-relative [timeUs].
  ///
  /// Before the first keyframe the first value holds; after the last
  /// keyframe the last value holds.
  T valueAt(int timeUs, Lerp<T> lerp);
}

/// An [Animatable] with a single fixed value.
@immutable
final class ConstantAnimatable<T> extends Animatable<T> {
  /// Creates a constant.
  const new(this.value);

  /// The value at every time.
  final T value;

  @override
  bool get isAnimated => false;

  @override
  T valueAt(int timeUs, Lerp<T> lerp) => value;

  @override
  bool operator ==(Object other) =>
      other is ConstantAnimatable<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Animatable.constant($value)';
}

/// An [Animatable] driven by one or more keyframes.
@immutable
final class KeyframedAnimatable<T> extends Animatable<T> {
  /// Creates a keyframed animatable; see [Animatable.keyframed].
  new(Iterable<Keyframe<T>> keyframes)
    : keyframes = List.unmodifiable(
        keyframes.toList()..sort((a, b) => a.timeUs.compareTo(b.timeUs)),
      ) {
    if (this.keyframes.isEmpty) {
      throw ArgumentError.value(keyframes, 'keyframes', 'must not be empty');
    }
    for (var i = 1; i < this.keyframes.length; i++) {
      if (this.keyframes[i].timeUs == this.keyframes[i - 1].timeUs) {
        throw ArgumentError('Two keyframes at ${this.keyframes[i].timeUs}us');
      }
    }
  }

  /// Keyframes, sorted by time, never empty.
  final List<Keyframe<T>> keyframes;

  @override
  bool get isAnimated => true;

  @override
  T valueAt(int timeUs, Lerp<T> lerp) {
    final first = keyframes.first;
    if (timeUs <= first.timeUs) return first.value;
    final last = keyframes.last;
    if (timeUs >= last.timeUs) return last.value;

    // Binary search for the last keyframe at or before timeUs.
    var lo = 0;
    var hi = keyframes.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (keyframes[mid].timeUs <= timeUs) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final from = keyframes[lo];
    final to = keyframes[hi];
    final progress = (timeUs - from.timeUs) / (to.timeUs - from.timeUs);
    return lerp(from.value, to.value, from.easing.transform(progress));
  }

  @override
  bool operator ==(Object other) {
    if (other is! KeyframedAnimatable<T>) return false;
    if (other.keyframes.length != keyframes.length) return false;
    for (var i = 0; i < keyframes.length; i++) {
      if (other.keyframes[i] != keyframes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(keyframes);

  @override
  String toString() => 'Animatable.keyframed($keyframes)';
}

/// Converts an [Animatable] to JSON.
///
/// Constants are `{"value": v}`; keyframed values are
/// `{"keyframes": [{"t": us, "v": v, "easing": {...}}]}`.
Map<String, dynamic> animatableToJson<T>(
  Animatable<T> animatable,
  Object? Function(T value) toJsonT,
) => switch (animatable) {
  ConstantAnimatable<T>(:final value) => {'value': toJsonT(value)},
  KeyframedAnimatable<T>(:final keyframes) => {
    'keyframes': [
      for (final k in keyframes)
        {'t': k.timeUs, 'v': toJsonT(k.value), 'easing': k.easing.toJson()},
    ],
  },
};

/// Parses an [Animatable] written by [animatableToJson].
///
/// Throws a [FormatException] when neither `value` nor `keyframes` exist.
Animatable<T> animatableFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) {
  final keyframes = json['keyframes'];
  if (keyframes is List) {
    return Animatable.keyframed([
      for (final raw in keyframes.cast<Map<String, dynamic>>())
        Keyframe(
          timeUs: raw['t'] as int,
          value: fromJsonT(raw['v']),
          easing: Easing.fromJson(raw['easing'] as Map<String, dynamic>),
        ),
    ]);
  }
  if (!json.containsKey('value')) {
    throw const FormatException('Animatable needs "value" or "keyframes"');
  }
  return Animatable.constant(fromJsonT(json['value']));
}

/// JSON converter for `Animatable<double>` fields.
final class AnimatableDoubleConverter
    implements JsonConverter<Animatable<double>, Map<String, dynamic>> {
  /// Creates the converter.
  const new();

  @override
  Animatable<double> fromJson(Map<String, dynamic> json) =>
      animatableFromJson(json, (v) => (v! as num).toDouble());

  @override
  Map<String, dynamic> toJson(Animatable<double> object) =>
      animatableToJson(object, (v) => v);
}

/// JSON converter for `Animatable<Vec2>` fields.
final class AnimatableVec2Converter
    implements JsonConverter<Animatable<Vec2>, Map<String, dynamic>> {
  /// Creates the converter.
  const new();

  @override
  Animatable<Vec2> fromJson(Map<String, dynamic> json) => animatableFromJson(
    json,
    (v) => Vec2.fromJson(v! as Map<String, dynamic>),
  );

  @override
  Map<String, dynamic> toJson(Animatable<Vec2> object) =>
      animatableToJson(object, (v) => v.toJson());
}
