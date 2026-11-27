// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clip_effects.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClipMask {

 MaskShape get shape;@AnimatableVec2Converter() Animatable<Vec2> get center;@AnimatableVec2Converter() Animatable<Vec2> get size;@AnimatableDoubleConverter() Animatable<double> get rotation;@AnimatableDoubleConverter() Animatable<double> get feather; bool get invert;
/// Create a copy of ClipMask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClipMaskCopyWith<ClipMask> get copyWith => _$ClipMaskCopyWithImpl<ClipMask>(this as ClipMask, _$identity);

  /// Serializes this ClipMask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ClipMask;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClipMask&&(identical(other.shape, _this.shape) || other.shape == _this.shape)&&(identical(other.center, _this.center) || other.center == _this.center)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.rotation, _this.rotation) || other.rotation == _this.rotation)&&(identical(other.feather, _this.feather) || other.feather == _this.feather)&&(identical(other.invert, _this.invert) || other.invert == _this.invert));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ClipMask;
  return Object.hash(runtimeType,_this.shape,_this.center,_this.size,_this.rotation,_this.feather,_this.invert);
}

@override
String toString() {
  final _this = this as ClipMask;
  return 'ClipMask(shape: ${_this.shape}, center: ${_this.center}, size: ${_this.size}, rotation: ${_this.rotation}, feather: ${_this.feather}, invert: ${_this.invert})';
}


}

/// @nodoc
abstract mixin class $ClipMaskCopyWith<$Res>  {
  factory $ClipMaskCopyWith(ClipMask value, $Res Function(ClipMask) _then) = _$ClipMaskCopyWithImpl;
@useResult
$Res call({
 MaskShape shape,@AnimatableVec2Converter() Animatable<Vec2> center,@AnimatableVec2Converter() Animatable<Vec2> size,@AnimatableDoubleConverter() Animatable<double> rotation,@AnimatableDoubleConverter() Animatable<double> feather, bool invert
});




}
/// @nodoc
class _$ClipMaskCopyWithImpl<$Res>
    implements $ClipMaskCopyWith<$Res> {
  _$ClipMaskCopyWithImpl(this._self, this._then);

  final ClipMask _self;
  final $Res Function(ClipMask) _then;

/// Create a copy of ClipMask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shape = null,Object? center = null,Object? size = null,Object? rotation = null,Object? feather = null,Object? invert = null,}) {
  return _then(ClipMask(
shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as MaskShape,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as Animatable<Vec2>,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as Animatable<Vec2>,rotation: null == rotation ? _self.rotation : rotation // ignore: cast_nullable_to_non_nullable
as Animatable<double>,feather: null == feather ? _self.feather : feather // ignore: cast_nullable_to_non_nullable
as Animatable<double>,invert: null == invert ? _self.invert : invert // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ClipMask].
extension ClipMaskPatterns on ClipMask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClipMask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClipMask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClipMask value)  $default,){
final _that = this;
switch (_that) {
case _ClipMask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClipMask value)?  $default,){
final _that = this;
switch (_that) {
case _ClipMask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MaskShape shape, @AnimatableVec2Converter()  Animatable<Vec2> center, @AnimatableVec2Converter()  Animatable<Vec2> size, @AnimatableDoubleConverter()  Animatable<double> rotation, @AnimatableDoubleConverter()  Animatable<double> feather,  bool invert)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClipMask() when $default != null:
return $default(_that.shape,_that.center,_that.size,_that.rotation,_that.feather,_that.invert);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MaskShape shape, @AnimatableVec2Converter()  Animatable<Vec2> center, @AnimatableVec2Converter()  Animatable<Vec2> size, @AnimatableDoubleConverter()  Animatable<double> rotation, @AnimatableDoubleConverter()  Animatable<double> feather,  bool invert)  $default,) {final _that = this;
switch (_that) {
case _ClipMask():
return $default(_that.shape,_that.center,_that.size,_that.rotation,_that.feather,_that.invert);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MaskShape shape, @AnimatableVec2Converter()  Animatable<Vec2> center, @AnimatableVec2Converter()  Animatable<Vec2> size, @AnimatableDoubleConverter()  Animatable<double> rotation, @AnimatableDoubleConverter()  Animatable<double> feather,  bool invert)?  $default,) {final _that = this;
switch (_that) {
case _ClipMask() when $default != null:
return $default(_that.shape,_that.center,_that.size,_that.rotation,_that.feather,_that.invert);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClipMask extends ClipMask {
  const _ClipMask({required this.shape, @AnimatableVec2Converter() this.center = const Animatable<Vec2>.constant(Vec2.zero), @AnimatableVec2Converter() this.size = const Animatable<Vec2>.constant(MaskLimits.defaultSize), @AnimatableDoubleConverter() this.rotation = const Animatable<double>.constant(0), @AnimatableDoubleConverter() this.feather = const Animatable<double>.constant(0), this.invert = false}): super._();
  factory _ClipMask.fromJson(Map<String, dynamic> json) => _$ClipMaskFromJson(json);

@override final  MaskShape shape;
@override@JsonKey()@AnimatableVec2Converter() final  Animatable<Vec2> center;
@override@JsonKey()@AnimatableVec2Converter() final  Animatable<Vec2> size;
@override@JsonKey()@AnimatableDoubleConverter() final  Animatable<double> rotation;
@override@JsonKey()@AnimatableDoubleConverter() final  Animatable<double> feather;
@override@JsonKey() final  bool invert;

/// Create a copy of ClipMask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClipMaskCopyWith<_ClipMask> get copyWith => __$ClipMaskCopyWithImpl<_ClipMask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClipMaskToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClipMask&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.center, center) || other.center == center)&&(identical(other.size, size) || other.size == size)&&(identical(other.rotation, rotation) || other.rotation == rotation)&&(identical(other.feather, feather) || other.feather == feather)&&(identical(other.invert, invert) || other.invert == invert));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,shape,center,size,rotation,feather,invert);
}

@override
String toString() {
    return 'ClipMask(shape: $shape, center: $center, size: $size, rotation: $rotation, feather: $feather, invert: $invert)';
}


}

/// @nodoc
abstract mixin class _$ClipMaskCopyWith<$Res> implements $ClipMaskCopyWith<$Res> {
  factory _$ClipMaskCopyWith(_ClipMask value, $Res Function(_ClipMask) _then) = __$ClipMaskCopyWithImpl;
@override @useResult
$Res call({
 MaskShape shape,@AnimatableVec2Converter() Animatable<Vec2> center,@AnimatableVec2Converter() Animatable<Vec2> size,@AnimatableDoubleConverter() Animatable<double> rotation,@AnimatableDoubleConverter() Animatable<double> feather, bool invert
});




}
/// @nodoc
class __$ClipMaskCopyWithImpl<$Res>
    implements _$ClipMaskCopyWith<$Res> {
  __$ClipMaskCopyWithImpl(this._self, this._then);

  final _ClipMask _self;
  final $Res Function(_ClipMask) _then;

/// Create a copy of ClipMask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shape = null,Object? center = null,Object? size = null,Object? rotation = null,Object? feather = null,Object? invert = null,}) {
  return _then(_ClipMask(
shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as MaskShape,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as Animatable<Vec2>,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as Animatable<Vec2>,rotation: null == rotation ? _self.rotation : rotation // ignore: cast_nullable_to_non_nullable
as Animatable<double>,feather: null == feather ? _self.feather : feather // ignore: cast_nullable_to_non_nullable
as Animatable<double>,invert: null == invert ? _self.invert : invert // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
