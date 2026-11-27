// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clip_style.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CropRect {

 double get left; double get top; double get right; double get bottom; CanvasAspect? get aspect;
/// Create a copy of CropRect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CropRectCopyWith<CropRect> get copyWith => _$CropRectCopyWithImpl<CropRect>(this as CropRect, _$identity);

  /// Serializes this CropRect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CropRect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CropRect&&(identical(other.left, _this.left) || other.left == _this.left)&&(identical(other.top, _this.top) || other.top == _this.top)&&(identical(other.right, _this.right) || other.right == _this.right)&&(identical(other.bottom, _this.bottom) || other.bottom == _this.bottom)&&(identical(other.aspect, _this.aspect) || other.aspect == _this.aspect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CropRect;
  return Object.hash(runtimeType,_this.left,_this.top,_this.right,_this.bottom,_this.aspect);
}

@override
String toString() {
  final _this = this as CropRect;
  return 'CropRect(left: ${_this.left}, top: ${_this.top}, right: ${_this.right}, bottom: ${_this.bottom}, aspect: ${_this.aspect})';
}


}

/// @nodoc
abstract mixin class $CropRectCopyWith<$Res>  {
  factory $CropRectCopyWith(CropRect value, $Res Function(CropRect) _then) = _$CropRectCopyWithImpl;
@useResult
$Res call({
 double left, double top, double right, double bottom, CanvasAspect? aspect
});


$CanvasAspectCopyWith<$Res>? get aspect;

}
/// @nodoc
class _$CropRectCopyWithImpl<$Res>
    implements $CropRectCopyWith<$Res> {
  _$CropRectCopyWithImpl(this._self, this._then);

  final CropRect _self;
  final $Res Function(CropRect) _then;

/// Create a copy of CropRect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? left = null,Object? top = null,Object? right = null,Object? bottom = null,Object? aspect = freezed,}) {
  return _then(CropRect(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as double,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as double,aspect: freezed == aspect ? _self.aspect : aspect // ignore: cast_nullable_to_non_nullable
as CanvasAspect?,
  ));
}
/// Create a copy of CropRect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanvasAspectCopyWith<$Res>? get aspect {
    if (_self.aspect == null) {
    return null;
  }

  return $CanvasAspectCopyWith<$Res>(_self.aspect!, (value) {
    return _then(_self.copyWith(aspect: value));
  });
}
}


/// Adds pattern-matching-related methods to [CropRect].
extension CropRectPatterns on CropRect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CropRect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CropRect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CropRect value)  $default,){
final _that = this;
switch (_that) {
case _CropRect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CropRect value)?  $default,){
final _that = this;
switch (_that) {
case _CropRect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double left,  double top,  double right,  double bottom,  CanvasAspect? aspect)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CropRect() when $default != null:
return $default(_that.left,_that.top,_that.right,_that.bottom,_that.aspect);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double left,  double top,  double right,  double bottom,  CanvasAspect? aspect)  $default,) {final _that = this;
switch (_that) {
case _CropRect():
return $default(_that.left,_that.top,_that.right,_that.bottom,_that.aspect);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double left,  double top,  double right,  double bottom,  CanvasAspect? aspect)?  $default,) {final _that = this;
switch (_that) {
case _CropRect() when $default != null:
return $default(_that.left,_that.top,_that.right,_that.bottom,_that.aspect);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CropRect extends CropRect {
  const _CropRect({this.left = 0, this.top = 0, this.right = 1, this.bottom = 1, this.aspect}): super._();
  factory _CropRect.fromJson(Map<String, dynamic> json) => _$CropRectFromJson(json);

@override@JsonKey() final  double left;
@override@JsonKey() final  double top;
@override@JsonKey() final  double right;
@override@JsonKey() final  double bottom;
@override final  CanvasAspect? aspect;

/// Create a copy of CropRect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CropRectCopyWith<_CropRect> get copyWith => __$CropRectCopyWithImpl<_CropRect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CropRectToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CropRect&&(identical(other.left, left) || other.left == left)&&(identical(other.top, top) || other.top == top)&&(identical(other.right, right) || other.right == right)&&(identical(other.bottom, bottom) || other.bottom == bottom)&&(identical(other.aspect, aspect) || other.aspect == aspect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,left,top,right,bottom,aspect);
}

@override
String toString() {
    return 'CropRect(left: $left, top: $top, right: $right, bottom: $bottom, aspect: $aspect)';
}


}

/// @nodoc
abstract mixin class _$CropRectCopyWith<$Res> implements $CropRectCopyWith<$Res> {
  factory _$CropRectCopyWith(_CropRect value, $Res Function(_CropRect) _then) = __$CropRectCopyWithImpl;
@override @useResult
$Res call({
 double left, double top, double right, double bottom, CanvasAspect? aspect
});


@override $CanvasAspectCopyWith<$Res>? get aspect;

}
/// @nodoc
class __$CropRectCopyWithImpl<$Res>
    implements _$CropRectCopyWith<$Res> {
  __$CropRectCopyWithImpl(this._self, this._then);

  final _CropRect _self;
  final $Res Function(_CropRect) _then;

/// Create a copy of CropRect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? left = null,Object? top = null,Object? right = null,Object? bottom = null,Object? aspect = freezed,}) {
  return _then(_CropRect(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as double,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as double,aspect: freezed == aspect ? _self.aspect : aspect // ignore: cast_nullable_to_non_nullable
as CanvasAspect?,
  ));
}

/// Create a copy of CropRect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanvasAspectCopyWith<$Res>? get aspect {
    if (_self.aspect == null) {
    return null;
  }

  return $CanvasAspectCopyWith<$Res>(_self.aspect!, (value) {
    return _then(_self.copyWith(aspect: value));
  });
}
}


/// @nodoc
mixin _$ClipBorder {

 double get width; int get argb; double get radius;
/// Create a copy of ClipBorder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClipBorderCopyWith<ClipBorder> get copyWith => _$ClipBorderCopyWithImpl<ClipBorder>(this as ClipBorder, _$identity);

  /// Serializes this ClipBorder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ClipBorder;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClipBorder&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.argb, _this.argb) || other.argb == _this.argb)&&(identical(other.radius, _this.radius) || other.radius == _this.radius));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ClipBorder;
  return Object.hash(runtimeType,_this.width,_this.argb,_this.radius);
}

@override
String toString() {
  final _this = this as ClipBorder;
  return 'ClipBorder(width: ${_this.width}, argb: ${_this.argb}, radius: ${_this.radius})';
}


}

/// @nodoc
abstract mixin class $ClipBorderCopyWith<$Res>  {
  factory $ClipBorderCopyWith(ClipBorder value, $Res Function(ClipBorder) _then) = _$ClipBorderCopyWithImpl;
@useResult
$Res call({
 double width, int argb, double radius
});




}
/// @nodoc
class _$ClipBorderCopyWithImpl<$Res>
    implements $ClipBorderCopyWith<$Res> {
  _$ClipBorderCopyWithImpl(this._self, this._then);

  final ClipBorder _self;
  final $Res Function(ClipBorder) _then;

/// Create a copy of ClipBorder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? width = null,Object? argb = null,Object? radius = null,}) {
  return _then(ClipBorder(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,argb: null == argb ? _self.argb : argb // ignore: cast_nullable_to_non_nullable
as int,radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ClipBorder].
extension ClipBorderPatterns on ClipBorder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClipBorder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClipBorder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClipBorder value)  $default,){
final _that = this;
switch (_that) {
case _ClipBorder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClipBorder value)?  $default,){
final _that = this;
switch (_that) {
case _ClipBorder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double width,  int argb,  double radius)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClipBorder() when $default != null:
return $default(_that.width,_that.argb,_that.radius);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double width,  int argb,  double radius)  $default,) {final _that = this;
switch (_that) {
case _ClipBorder():
return $default(_that.width,_that.argb,_that.radius);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double width,  int argb,  double radius)?  $default,) {final _that = this;
switch (_that) {
case _ClipBorder() when $default != null:
return $default(_that.width,_that.argb,_that.radius);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClipBorder extends ClipBorder {
  const _ClipBorder({this.width = 0, this.argb = 0xFFFFFFFF, this.radius = 0}): super._();
  factory _ClipBorder.fromJson(Map<String, dynamic> json) => _$ClipBorderFromJson(json);

@override@JsonKey() final  double width;
@override@JsonKey() final  int argb;
@override@JsonKey() final  double radius;

/// Create a copy of ClipBorder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClipBorderCopyWith<_ClipBorder> get copyWith => __$ClipBorderCopyWithImpl<_ClipBorder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClipBorderToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClipBorder&&(identical(other.width, width) || other.width == width)&&(identical(other.argb, argb) || other.argb == argb)&&(identical(other.radius, radius) || other.radius == radius));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,width,argb,radius);
}

@override
String toString() {
    return 'ClipBorder(width: $width, argb: $argb, radius: $radius)';
}


}

/// @nodoc
abstract mixin class _$ClipBorderCopyWith<$Res> implements $ClipBorderCopyWith<$Res> {
  factory _$ClipBorderCopyWith(_ClipBorder value, $Res Function(_ClipBorder) _then) = __$ClipBorderCopyWithImpl;
@override @useResult
$Res call({
 double width, int argb, double radius
});




}
/// @nodoc
class __$ClipBorderCopyWithImpl<$Res>
    implements _$ClipBorderCopyWith<$Res> {
  __$ClipBorderCopyWithImpl(this._self, this._then);

  final _ClipBorder _self;
  final $Res Function(_ClipBorder) _then;

/// Create a copy of ClipBorder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? width = null,Object? argb = null,Object? radius = null,}) {
  return _then(_ClipBorder(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,argb: null == argb ? _self.argb : argb // ignore: cast_nullable_to_non_nullable
as int,radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
