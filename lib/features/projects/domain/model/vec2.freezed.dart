// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vec2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Vec2 {

 double get x; double get y;
/// Create a copy of Vec2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Vec2CopyWith<Vec2> get copyWith => _$Vec2CopyWithImpl<Vec2>(this as Vec2, _$identity);

  /// Serializes this Vec2 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Vec2;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Vec2&&(identical(other.x, _this.x) || other.x == _this.x)&&(identical(other.y, _this.y) || other.y == _this.y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Vec2;
  return Object.hash(runtimeType,_this.x,_this.y);
}

@override
String toString() {
  final _this = this as Vec2;
  return 'Vec2(x: ${_this.x}, y: ${_this.y})';
}


}

/// @nodoc
abstract mixin class $Vec2CopyWith<$Res>  {
  factory $Vec2CopyWith(Vec2 value, $Res Function(Vec2) _then) = _$Vec2CopyWithImpl;
@useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class _$Vec2CopyWithImpl<$Res>
    implements $Vec2CopyWith<$Res> {
  _$Vec2CopyWithImpl(this._self, this._then);

  final Vec2 _self;
  final $Res Function(Vec2) _then;

/// Create a copy of Vec2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,}) {
  return _then(Vec2(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Vec2].
extension Vec2Patterns on Vec2 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Vec2 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Vec2() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Vec2 value)  $default,){
final _that = this;
switch (_that) {
case _Vec2():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Vec2 value)?  $default,){
final _that = this;
switch (_that) {
case _Vec2() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  double y)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Vec2() when $default != null:
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  double y)  $default,) {final _that = this;
switch (_that) {
case _Vec2():
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  double y)?  $default,) {final _that = this;
switch (_that) {
case _Vec2() when $default != null:
return $default(_that.x,_that.y);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Vec2 extends Vec2 {
  const _Vec2({required this.x, required this.y}): super._();
  factory _Vec2.fromJson(Map<String, dynamic> json) => _$Vec2FromJson(json);

@override final  double x;
@override final  double y;

/// Create a copy of Vec2
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Vec2CopyWith<_Vec2> get copyWith => __$Vec2CopyWithImpl<_Vec2>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Vec2ToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Vec2&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,x,y);
}

@override
String toString() {
    return 'Vec2(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class _$Vec2CopyWith<$Res> implements $Vec2CopyWith<$Res> {
  factory _$Vec2CopyWith(_Vec2 value, $Res Function(_Vec2) _then) = __$Vec2CopyWithImpl;
@override @useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class __$Vec2CopyWithImpl<$Res>
    implements _$Vec2CopyWith<$Res> {
  __$Vec2CopyWithImpl(this._self, this._then);

  final _Vec2 _self;
  final $Res Function(_Vec2) _then;

/// Create a copy of Vec2
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,}) {
  return _then(_Vec2(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
