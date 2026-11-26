// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'speed_curve.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CurvePoint {

 double get x; double get speed;
/// Create a copy of CurvePoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurvePointCopyWith<CurvePoint> get copyWith => _$CurvePointCopyWithImpl<CurvePoint>(this as CurvePoint, _$identity);

  /// Serializes this CurvePoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CurvePoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CurvePoint&&(identical(other.x, _this.x) || other.x == _this.x)&&(identical(other.speed, _this.speed) || other.speed == _this.speed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CurvePoint;
  return Object.hash(runtimeType,_this.x,_this.speed);
}

@override
String toString() {
  final _this = this as CurvePoint;
  return 'CurvePoint(x: ${_this.x}, speed: ${_this.speed})';
}


}

/// @nodoc
abstract mixin class $CurvePointCopyWith<$Res>  {
  factory $CurvePointCopyWith(CurvePoint value, $Res Function(CurvePoint) _then) = _$CurvePointCopyWithImpl;
@useResult
$Res call({
 double x, double speed
});




}
/// @nodoc
class _$CurvePointCopyWithImpl<$Res>
    implements $CurvePointCopyWith<$Res> {
  _$CurvePointCopyWithImpl(this._self, this._then);

  final CurvePoint _self;
  final $Res Function(CurvePoint) _then;

/// Create a copy of CurvePoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? speed = null,}) {
  return _then(CurvePoint(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CurvePoint].
extension CurvePointPatterns on CurvePoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CurvePoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CurvePoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CurvePoint value)  $default,){
final _that = this;
switch (_that) {
case _CurvePoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CurvePoint value)?  $default,){
final _that = this;
switch (_that) {
case _CurvePoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  double speed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CurvePoint() when $default != null:
return $default(_that.x,_that.speed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  double speed)  $default,) {final _that = this;
switch (_that) {
case _CurvePoint():
return $default(_that.x,_that.speed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  double speed)?  $default,) {final _that = this;
switch (_that) {
case _CurvePoint() when $default != null:
return $default(_that.x,_that.speed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CurvePoint implements CurvePoint {
  const _CurvePoint({required this.x, required this.speed});
  factory _CurvePoint.fromJson(Map<String, dynamic> json) => _$CurvePointFromJson(json);

@override final  double x;
@override final  double speed;

/// Create a copy of CurvePoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CurvePointCopyWith<_CurvePoint> get copyWith => __$CurvePointCopyWithImpl<_CurvePoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CurvePointToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CurvePoint&&(identical(other.x, x) || other.x == x)&&(identical(other.speed, speed) || other.speed == speed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,x,speed);
}

@override
String toString() {
    return 'CurvePoint(x: $x, speed: $speed)';
}


}

/// @nodoc
abstract mixin class _$CurvePointCopyWith<$Res> implements $CurvePointCopyWith<$Res> {
  factory _$CurvePointCopyWith(_CurvePoint value, $Res Function(_CurvePoint) _then) = __$CurvePointCopyWithImpl;
@override @useResult
$Res call({
 double x, double speed
});




}
/// @nodoc
class __$CurvePointCopyWithImpl<$Res>
    implements _$CurvePointCopyWith<$Res> {
  __$CurvePointCopyWithImpl(this._self, this._then);

  final _CurvePoint _self;
  final $Res Function(_CurvePoint) _then;

/// Create a copy of CurvePoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? speed = null,}) {
  return _then(_CurvePoint(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$SpeedCurve {

 SpeedCurvePreset get preset; List<CurvePoint> get points;
/// Create a copy of SpeedCurve
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedCurveCopyWith<SpeedCurve> get copyWith => _$SpeedCurveCopyWithImpl<SpeedCurve>(this as SpeedCurve, _$identity);

  /// Serializes this SpeedCurve to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SpeedCurve;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedCurve&&(identical(other.preset, _this.preset) || other.preset == _this.preset)&&const DeepCollectionEquality().equals(other.points, _this.points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SpeedCurve;
  return Object.hash(runtimeType,_this.preset,const DeepCollectionEquality().hash(_this.points));
}

@override
String toString() {
  final _this = this as SpeedCurve;
  return 'SpeedCurve(preset: ${_this.preset}, points: ${_this.points})';
}


}

/// @nodoc
abstract mixin class $SpeedCurveCopyWith<$Res>  {
  factory $SpeedCurveCopyWith(SpeedCurve value, $Res Function(SpeedCurve) _then) = _$SpeedCurveCopyWithImpl;
@useResult
$Res call({
 SpeedCurvePreset preset, List<CurvePoint> points
});




}
/// @nodoc
class _$SpeedCurveCopyWithImpl<$Res>
    implements $SpeedCurveCopyWith<$Res> {
  _$SpeedCurveCopyWithImpl(this._self, this._then);

  final SpeedCurve _self;
  final $Res Function(SpeedCurve) _then;

/// Create a copy of SpeedCurve
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? preset = null,Object? points = null,}) {
  return _then(SpeedCurve(
preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as SpeedCurvePreset,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<CurvePoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [SpeedCurve].
extension SpeedCurvePatterns on SpeedCurve {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeedCurve value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeedCurve() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeedCurve value)  $default,){
final _that = this;
switch (_that) {
case _SpeedCurve():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeedCurve value)?  $default,){
final _that = this;
switch (_that) {
case _SpeedCurve() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SpeedCurvePreset preset,  List<CurvePoint> points)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedCurve() when $default != null:
return $default(_that.preset,_that.points);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SpeedCurvePreset preset,  List<CurvePoint> points)  $default,) {final _that = this;
switch (_that) {
case _SpeedCurve():
return $default(_that.preset,_that.points);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SpeedCurvePreset preset,  List<CurvePoint> points)?  $default,) {final _that = this;
switch (_that) {
case _SpeedCurve() when $default != null:
return $default(_that.preset,_that.points);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpeedCurve extends SpeedCurve {
  const _SpeedCurve({required this.preset, required  List<CurvePoint> points}): _points = points,super._();
  factory _SpeedCurve.fromJson(Map<String, dynamic> json) => _$SpeedCurveFromJson(json);

@override final  SpeedCurvePreset preset;
 final  List<CurvePoint> _points;
@override List<CurvePoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}


/// Create a copy of SpeedCurve
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedCurveCopyWith<_SpeedCurve> get copyWith => __$SpeedCurveCopyWithImpl<_SpeedCurve>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpeedCurveToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedCurve&&(identical(other.preset, preset) || other.preset == preset)&&const DeepCollectionEquality().equals(other.points, _points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,preset,const DeepCollectionEquality().hash(_points));
}

@override
String toString() {
    return 'SpeedCurve(preset: $preset, points: $points)';
}


}

/// @nodoc
abstract mixin class _$SpeedCurveCopyWith<$Res> implements $SpeedCurveCopyWith<$Res> {
  factory _$SpeedCurveCopyWith(_SpeedCurve value, $Res Function(_SpeedCurve) _then) = __$SpeedCurveCopyWithImpl;
@override @useResult
$Res call({
 SpeedCurvePreset preset, List<CurvePoint> points
});




}
/// @nodoc
class __$SpeedCurveCopyWithImpl<$Res>
    implements _$SpeedCurveCopyWith<$Res> {
  __$SpeedCurveCopyWithImpl(this._self, this._then);

  final _SpeedCurve _self;
  final $Res Function(_SpeedCurve) _then;

/// Create a copy of SpeedCurve
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? preset = null,Object? points = null,}) {
  return _then(_SpeedCurve(
preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as SpeedCurvePreset,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<CurvePoint>,
  ));
}


}

// dart format on
