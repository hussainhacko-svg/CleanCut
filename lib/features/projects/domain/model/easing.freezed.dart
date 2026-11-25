// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'easing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Easing {

 double get x1; double get y1; double get x2; double get y2;
/// Create a copy of Easing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EasingCopyWith<Easing> get copyWith => _$EasingCopyWithImpl<Easing>(this as Easing, _$identity);

  /// Serializes this Easing to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Easing;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Easing&&(identical(other.x1, _this.x1) || other.x1 == _this.x1)&&(identical(other.y1, _this.y1) || other.y1 == _this.y1)&&(identical(other.x2, _this.x2) || other.x2 == _this.x2)&&(identical(other.y2, _this.y2) || other.y2 == _this.y2));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Easing;
  return Object.hash(runtimeType,_this.x1,_this.y1,_this.x2,_this.y2);
}

@override
String toString() {
  final _this = this as Easing;
  return 'Easing(x1: ${_this.x1}, y1: ${_this.y1}, x2: ${_this.x2}, y2: ${_this.y2})';
}


}

/// @nodoc
abstract mixin class $EasingCopyWith<$Res>  {
  factory $EasingCopyWith(Easing value, $Res Function(Easing) _then) = _$EasingCopyWithImpl;
@useResult
$Res call({
 double x1, double y1, double x2, double y2
});




}
/// @nodoc
class _$EasingCopyWithImpl<$Res>
    implements $EasingCopyWith<$Res> {
  _$EasingCopyWithImpl(this._self, this._then);

  final Easing _self;
  final $Res Function(Easing) _then;

/// Create a copy of Easing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x1 = null,Object? y1 = null,Object? x2 = null,Object? y2 = null,}) {
  return _then(Easing(
x1: null == x1 ? _self.x1 : x1 // ignore: cast_nullable_to_non_nullable
as double,y1: null == y1 ? _self.y1 : y1 // ignore: cast_nullable_to_non_nullable
as double,x2: null == x2 ? _self.x2 : x2 // ignore: cast_nullable_to_non_nullable
as double,y2: null == y2 ? _self.y2 : y2 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Easing].
extension EasingPatterns on Easing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Easing value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Easing() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Easing value)  $default,){
final _that = this;
switch (_that) {
case _Easing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Easing value)?  $default,){
final _that = this;
switch (_that) {
case _Easing() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x1,  double y1,  double x2,  double y2)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Easing() when $default != null:
return $default(_that.x1,_that.y1,_that.x2,_that.y2);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x1,  double y1,  double x2,  double y2)  $default,) {final _that = this;
switch (_that) {
case _Easing():
return $default(_that.x1,_that.y1,_that.x2,_that.y2);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x1,  double y1,  double x2,  double y2)?  $default,) {final _that = this;
switch (_that) {
case _Easing() when $default != null:
return $default(_that.x1,_that.y1,_that.x2,_that.y2);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Easing extends Easing {
  const _Easing({required this.x1, required this.y1, required this.x2, required this.y2}): assert(x1 >= 0 && x1 <= 1, 'x1 must be within [0, 1]'),assert(x2 >= 0 && x2 <= 1, 'x2 must be within [0, 1]'),super._();
  factory _Easing.fromJson(Map<String, dynamic> json) => _$EasingFromJson(json);

@override final  double x1;
@override final  double y1;
@override final  double x2;
@override final  double y2;

/// Create a copy of Easing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EasingCopyWith<_Easing> get copyWith => __$EasingCopyWithImpl<_Easing>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EasingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Easing&&(identical(other.x1, x1) || other.x1 == x1)&&(identical(other.y1, y1) || other.y1 == y1)&&(identical(other.x2, x2) || other.x2 == x2)&&(identical(other.y2, y2) || other.y2 == y2));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,x1,y1,x2,y2);
}

@override
String toString() {
    return 'Easing(x1: $x1, y1: $y1, x2: $x2, y2: $y2)';
}


}

/// @nodoc
abstract mixin class _$EasingCopyWith<$Res> implements $EasingCopyWith<$Res> {
  factory _$EasingCopyWith(_Easing value, $Res Function(_Easing) _then) = __$EasingCopyWithImpl;
@override @useResult
$Res call({
 double x1, double y1, double x2, double y2
});




}
/// @nodoc
class __$EasingCopyWithImpl<$Res>
    implements _$EasingCopyWith<$Res> {
  __$EasingCopyWithImpl(this._self, this._then);

  final _Easing _self;
  final $Res Function(_Easing) _then;

/// Create a copy of Easing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x1 = null,Object? y1 = null,Object? x2 = null,Object? y2 = null,}) {
  return _then(_Easing(
x1: null == x1 ? _self.x1 : x1 // ignore: cast_nullable_to_non_nullable
as double,y1: null == y1 ? _self.y1 : y1 // ignore: cast_nullable_to_non_nullable
as double,x2: null == x2 ? _self.x2 : x2 // ignore: cast_nullable_to_non_nullable
as double,y2: null == y2 ? _self.y2 : y2 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
