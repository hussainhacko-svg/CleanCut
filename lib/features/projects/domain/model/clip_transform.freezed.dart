// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clip_transform.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClipTransform {

@AnimatableVec2Converter() Animatable<Vec2> get position;@AnimatableDoubleConverter() Animatable<double> get scale;@AnimatableDoubleConverter() Animatable<double> get rotation;@AnimatableDoubleConverter() Animatable<double> get opacity; bool get flipX; bool get flipY;
/// Create a copy of ClipTransform
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClipTransformCopyWith<ClipTransform> get copyWith => _$ClipTransformCopyWithImpl<ClipTransform>(this as ClipTransform, _$identity);

  /// Serializes this ClipTransform to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ClipTransform;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClipTransform&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.scale, _this.scale) || other.scale == _this.scale)&&(identical(other.rotation, _this.rotation) || other.rotation == _this.rotation)&&(identical(other.opacity, _this.opacity) || other.opacity == _this.opacity)&&(identical(other.flipX, _this.flipX) || other.flipX == _this.flipX)&&(identical(other.flipY, _this.flipY) || other.flipY == _this.flipY));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ClipTransform;
  return Object.hash(runtimeType,_this.position,_this.scale,_this.rotation,_this.opacity,_this.flipX,_this.flipY);
}

@override
String toString() {
  final _this = this as ClipTransform;
  return 'ClipTransform(position: ${_this.position}, scale: ${_this.scale}, rotation: ${_this.rotation}, opacity: ${_this.opacity}, flipX: ${_this.flipX}, flipY: ${_this.flipY})';
}


}

/// @nodoc
abstract mixin class $ClipTransformCopyWith<$Res>  {
  factory $ClipTransformCopyWith(ClipTransform value, $Res Function(ClipTransform) _then) = _$ClipTransformCopyWithImpl;
@useResult
$Res call({
@AnimatableVec2Converter() Animatable<Vec2> position,@AnimatableDoubleConverter() Animatable<double> scale,@AnimatableDoubleConverter() Animatable<double> rotation,@AnimatableDoubleConverter() Animatable<double> opacity, bool flipX, bool flipY
});




}
/// @nodoc
class _$ClipTransformCopyWithImpl<$Res>
    implements $ClipTransformCopyWith<$Res> {
  _$ClipTransformCopyWithImpl(this._self, this._then);

  final ClipTransform _self;
  final $Res Function(ClipTransform) _then;

/// Create a copy of ClipTransform
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? scale = null,Object? rotation = null,Object? opacity = null,Object? flipX = null,Object? flipY = null,}) {
  return _then(ClipTransform(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Animatable<Vec2>,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as Animatable<double>,rotation: null == rotation ? _self.rotation : rotation // ignore: cast_nullable_to_non_nullable
as Animatable<double>,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as Animatable<double>,flipX: null == flipX ? _self.flipX : flipX // ignore: cast_nullable_to_non_nullable
as bool,flipY: null == flipY ? _self.flipY : flipY // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ClipTransform].
extension ClipTransformPatterns on ClipTransform {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClipTransform value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClipTransform() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClipTransform value)  $default,){
final _that = this;
switch (_that) {
case _ClipTransform():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClipTransform value)?  $default,){
final _that = this;
switch (_that) {
case _ClipTransform() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@AnimatableVec2Converter()  Animatable<Vec2> position, @AnimatableDoubleConverter()  Animatable<double> scale, @AnimatableDoubleConverter()  Animatable<double> rotation, @AnimatableDoubleConverter()  Animatable<double> opacity,  bool flipX,  bool flipY)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClipTransform() when $default != null:
return $default(_that.position,_that.scale,_that.rotation,_that.opacity,_that.flipX,_that.flipY);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@AnimatableVec2Converter()  Animatable<Vec2> position, @AnimatableDoubleConverter()  Animatable<double> scale, @AnimatableDoubleConverter()  Animatable<double> rotation, @AnimatableDoubleConverter()  Animatable<double> opacity,  bool flipX,  bool flipY)  $default,) {final _that = this;
switch (_that) {
case _ClipTransform():
return $default(_that.position,_that.scale,_that.rotation,_that.opacity,_that.flipX,_that.flipY);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@AnimatableVec2Converter()  Animatable<Vec2> position, @AnimatableDoubleConverter()  Animatable<double> scale, @AnimatableDoubleConverter()  Animatable<double> rotation, @AnimatableDoubleConverter()  Animatable<double> opacity,  bool flipX,  bool flipY)?  $default,) {final _that = this;
switch (_that) {
case _ClipTransform() when $default != null:
return $default(_that.position,_that.scale,_that.rotation,_that.opacity,_that.flipX,_that.flipY);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClipTransform extends ClipTransform {
  const _ClipTransform({@AnimatableVec2Converter() this.position = const Animatable<Vec2>.constant(Vec2.zero), @AnimatableDoubleConverter() this.scale = const Animatable<double>.constant(1), @AnimatableDoubleConverter() this.rotation = const Animatable<double>.constant(0), @AnimatableDoubleConverter() this.opacity = const Animatable<double>.constant(1), this.flipX = false, this.flipY = false}): super._();
  factory _ClipTransform.fromJson(Map<String, dynamic> json) => _$ClipTransformFromJson(json);

@override@JsonKey()@AnimatableVec2Converter() final  Animatable<Vec2> position;
@override@JsonKey()@AnimatableDoubleConverter() final  Animatable<double> scale;
@override@JsonKey()@AnimatableDoubleConverter() final  Animatable<double> rotation;
@override@JsonKey()@AnimatableDoubleConverter() final  Animatable<double> opacity;
@override@JsonKey() final  bool flipX;
@override@JsonKey() final  bool flipY;

/// Create a copy of ClipTransform
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClipTransformCopyWith<_ClipTransform> get copyWith => __$ClipTransformCopyWithImpl<_ClipTransform>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClipTransformToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClipTransform&&(identical(other.position, position) || other.position == position)&&(identical(other.scale, scale) || other.scale == scale)&&(identical(other.rotation, rotation) || other.rotation == rotation)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&(identical(other.flipX, flipX) || other.flipX == flipX)&&(identical(other.flipY, flipY) || other.flipY == flipY));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,position,scale,rotation,opacity,flipX,flipY);
}

@override
String toString() {
    return 'ClipTransform(position: $position, scale: $scale, rotation: $rotation, opacity: $opacity, flipX: $flipX, flipY: $flipY)';
}


}

/// @nodoc
abstract mixin class _$ClipTransformCopyWith<$Res> implements $ClipTransformCopyWith<$Res> {
  factory _$ClipTransformCopyWith(_ClipTransform value, $Res Function(_ClipTransform) _then) = __$ClipTransformCopyWithImpl;
@override @useResult
$Res call({
@AnimatableVec2Converter() Animatable<Vec2> position,@AnimatableDoubleConverter() Animatable<double> scale,@AnimatableDoubleConverter() Animatable<double> rotation,@AnimatableDoubleConverter() Animatable<double> opacity, bool flipX, bool flipY
});




}
/// @nodoc
class __$ClipTransformCopyWithImpl<$Res>
    implements _$ClipTransformCopyWith<$Res> {
  __$ClipTransformCopyWithImpl(this._self, this._then);

  final _ClipTransform _self;
  final $Res Function(_ClipTransform) _then;

/// Create a copy of ClipTransform
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? scale = null,Object? rotation = null,Object? opacity = null,Object? flipX = null,Object? flipY = null,}) {
  return _then(_ClipTransform(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Animatable<Vec2>,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as Animatable<double>,rotation: null == rotation ? _self.rotation : rotation // ignore: cast_nullable_to_non_nullable
as Animatable<double>,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as Animatable<double>,flipX: null == flipX ? _self.flipX : flipX // ignore: cast_nullable_to_non_nullable
as bool,flipY: null == flipY ? _self.flipY : flipY // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
