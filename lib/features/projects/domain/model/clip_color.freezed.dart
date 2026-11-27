// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clip_color.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClipFilter {

 String get id; double get intensity;
/// Create a copy of ClipFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClipFilterCopyWith<ClipFilter> get copyWith => _$ClipFilterCopyWithImpl<ClipFilter>(this as ClipFilter, _$identity);

  /// Serializes this ClipFilter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ClipFilter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClipFilter&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.intensity, _this.intensity) || other.intensity == _this.intensity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ClipFilter;
  return Object.hash(runtimeType,_this.id,_this.intensity);
}

@override
String toString() {
  final _this = this as ClipFilter;
  return 'ClipFilter(id: ${_this.id}, intensity: ${_this.intensity})';
}


}

/// @nodoc
abstract mixin class $ClipFilterCopyWith<$Res>  {
  factory $ClipFilterCopyWith(ClipFilter value, $Res Function(ClipFilter) _then) = _$ClipFilterCopyWithImpl;
@useResult
$Res call({
 String id, double intensity
});




}
/// @nodoc
class _$ClipFilterCopyWithImpl<$Res>
    implements $ClipFilterCopyWith<$Res> {
  _$ClipFilterCopyWithImpl(this._self, this._then);

  final ClipFilter _self;
  final $Res Function(ClipFilter) _then;

/// Create a copy of ClipFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? intensity = null,}) {
  return _then(ClipFilter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ClipFilter].
extension ClipFilterPatterns on ClipFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClipFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClipFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClipFilter value)  $default,){
final _that = this;
switch (_that) {
case _ClipFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClipFilter value)?  $default,){
final _that = this;
switch (_that) {
case _ClipFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  double intensity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClipFilter() when $default != null:
return $default(_that.id,_that.intensity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  double intensity)  $default,) {final _that = this;
switch (_that) {
case _ClipFilter():
return $default(_that.id,_that.intensity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  double intensity)?  $default,) {final _that = this;
switch (_that) {
case _ClipFilter() when $default != null:
return $default(_that.id,_that.intensity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClipFilter extends ClipFilter {
  const _ClipFilter({required this.id, this.intensity = 1.0}): super._();
  factory _ClipFilter.fromJson(Map<String, dynamic> json) => _$ClipFilterFromJson(json);

@override final  String id;
@override@JsonKey() final  double intensity;

/// Create a copy of ClipFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClipFilterCopyWith<_ClipFilter> get copyWith => __$ClipFilterCopyWithImpl<_ClipFilter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClipFilterToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClipFilter&&(identical(other.id, id) || other.id == id)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,intensity);
}

@override
String toString() {
    return 'ClipFilter(id: $id, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class _$ClipFilterCopyWith<$Res> implements $ClipFilterCopyWith<$Res> {
  factory _$ClipFilterCopyWith(_ClipFilter value, $Res Function(_ClipFilter) _then) = __$ClipFilterCopyWithImpl;
@override @useResult
$Res call({
 String id, double intensity
});




}
/// @nodoc
class __$ClipFilterCopyWithImpl<$Res>
    implements _$ClipFilterCopyWith<$Res> {
  __$ClipFilterCopyWithImpl(this._self, this._then);

  final _ClipFilter _self;
  final $Res Function(_ClipFilter) _then;

/// Create a copy of ClipFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? intensity = null,}) {
  return _then(_ClipFilter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ClipAdjustments {

 double get exposure; double get brightness; double get contrast; double get saturation; double get warmth; double get tint; double get highlights; double get shadows; double get sharpen; double get vignette;
/// Create a copy of ClipAdjustments
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClipAdjustmentsCopyWith<ClipAdjustments> get copyWith => _$ClipAdjustmentsCopyWithImpl<ClipAdjustments>(this as ClipAdjustments, _$identity);

  /// Serializes this ClipAdjustments to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ClipAdjustments;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClipAdjustments&&(identical(other.exposure, _this.exposure) || other.exposure == _this.exposure)&&(identical(other.brightness, _this.brightness) || other.brightness == _this.brightness)&&(identical(other.contrast, _this.contrast) || other.contrast == _this.contrast)&&(identical(other.saturation, _this.saturation) || other.saturation == _this.saturation)&&(identical(other.warmth, _this.warmth) || other.warmth == _this.warmth)&&(identical(other.tint, _this.tint) || other.tint == _this.tint)&&(identical(other.highlights, _this.highlights) || other.highlights == _this.highlights)&&(identical(other.shadows, _this.shadows) || other.shadows == _this.shadows)&&(identical(other.sharpen, _this.sharpen) || other.sharpen == _this.sharpen)&&(identical(other.vignette, _this.vignette) || other.vignette == _this.vignette));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ClipAdjustments;
  return Object.hash(runtimeType,_this.exposure,_this.brightness,_this.contrast,_this.saturation,_this.warmth,_this.tint,_this.highlights,_this.shadows,_this.sharpen,_this.vignette);
}

@override
String toString() {
  final _this = this as ClipAdjustments;
  return 'ClipAdjustments(exposure: ${_this.exposure}, brightness: ${_this.brightness}, contrast: ${_this.contrast}, saturation: ${_this.saturation}, warmth: ${_this.warmth}, tint: ${_this.tint}, highlights: ${_this.highlights}, shadows: ${_this.shadows}, sharpen: ${_this.sharpen}, vignette: ${_this.vignette})';
}


}

/// @nodoc
abstract mixin class $ClipAdjustmentsCopyWith<$Res>  {
  factory $ClipAdjustmentsCopyWith(ClipAdjustments value, $Res Function(ClipAdjustments) _then) = _$ClipAdjustmentsCopyWithImpl;
@useResult
$Res call({
 double exposure, double brightness, double contrast, double saturation, double warmth, double tint, double highlights, double shadows, double sharpen, double vignette
});




}
/// @nodoc
class _$ClipAdjustmentsCopyWithImpl<$Res>
    implements $ClipAdjustmentsCopyWith<$Res> {
  _$ClipAdjustmentsCopyWithImpl(this._self, this._then);

  final ClipAdjustments _self;
  final $Res Function(ClipAdjustments) _then;

/// Create a copy of ClipAdjustments
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exposure = null,Object? brightness = null,Object? contrast = null,Object? saturation = null,Object? warmth = null,Object? tint = null,Object? highlights = null,Object? shadows = null,Object? sharpen = null,Object? vignette = null,}) {
  return _then(ClipAdjustments(
exposure: null == exposure ? _self.exposure : exposure // ignore: cast_nullable_to_non_nullable
as double,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as double,contrast: null == contrast ? _self.contrast : contrast // ignore: cast_nullable_to_non_nullable
as double,saturation: null == saturation ? _self.saturation : saturation // ignore: cast_nullable_to_non_nullable
as double,warmth: null == warmth ? _self.warmth : warmth // ignore: cast_nullable_to_non_nullable
as double,tint: null == tint ? _self.tint : tint // ignore: cast_nullable_to_non_nullable
as double,highlights: null == highlights ? _self.highlights : highlights // ignore: cast_nullable_to_non_nullable
as double,shadows: null == shadows ? _self.shadows : shadows // ignore: cast_nullable_to_non_nullable
as double,sharpen: null == sharpen ? _self.sharpen : sharpen // ignore: cast_nullable_to_non_nullable
as double,vignette: null == vignette ? _self.vignette : vignette // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ClipAdjustments].
extension ClipAdjustmentsPatterns on ClipAdjustments {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClipAdjustments value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClipAdjustments() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClipAdjustments value)  $default,){
final _that = this;
switch (_that) {
case _ClipAdjustments():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClipAdjustments value)?  $default,){
final _that = this;
switch (_that) {
case _ClipAdjustments() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double exposure,  double brightness,  double contrast,  double saturation,  double warmth,  double tint,  double highlights,  double shadows,  double sharpen,  double vignette)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClipAdjustments() when $default != null:
return $default(_that.exposure,_that.brightness,_that.contrast,_that.saturation,_that.warmth,_that.tint,_that.highlights,_that.shadows,_that.sharpen,_that.vignette);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double exposure,  double brightness,  double contrast,  double saturation,  double warmth,  double tint,  double highlights,  double shadows,  double sharpen,  double vignette)  $default,) {final _that = this;
switch (_that) {
case _ClipAdjustments():
return $default(_that.exposure,_that.brightness,_that.contrast,_that.saturation,_that.warmth,_that.tint,_that.highlights,_that.shadows,_that.sharpen,_that.vignette);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double exposure,  double brightness,  double contrast,  double saturation,  double warmth,  double tint,  double highlights,  double shadows,  double sharpen,  double vignette)?  $default,) {final _that = this;
switch (_that) {
case _ClipAdjustments() when $default != null:
return $default(_that.exposure,_that.brightness,_that.contrast,_that.saturation,_that.warmth,_that.tint,_that.highlights,_that.shadows,_that.sharpen,_that.vignette);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClipAdjustments extends ClipAdjustments {
  const _ClipAdjustments({this.exposure = 0.0, this.brightness = 0.0, this.contrast = 0.0, this.saturation = 0.0, this.warmth = 0.0, this.tint = 0.0, this.highlights = 0.0, this.shadows = 0.0, this.sharpen = 0.0, this.vignette = 0.0}): super._();
  factory _ClipAdjustments.fromJson(Map<String, dynamic> json) => _$ClipAdjustmentsFromJson(json);

@override@JsonKey() final  double exposure;
@override@JsonKey() final  double brightness;
@override@JsonKey() final  double contrast;
@override@JsonKey() final  double saturation;
@override@JsonKey() final  double warmth;
@override@JsonKey() final  double tint;
@override@JsonKey() final  double highlights;
@override@JsonKey() final  double shadows;
@override@JsonKey() final  double sharpen;
@override@JsonKey() final  double vignette;

/// Create a copy of ClipAdjustments
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClipAdjustmentsCopyWith<_ClipAdjustments> get copyWith => __$ClipAdjustmentsCopyWithImpl<_ClipAdjustments>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClipAdjustmentsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClipAdjustments&&(identical(other.exposure, exposure) || other.exposure == exposure)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.contrast, contrast) || other.contrast == contrast)&&(identical(other.saturation, saturation) || other.saturation == saturation)&&(identical(other.warmth, warmth) || other.warmth == warmth)&&(identical(other.tint, tint) || other.tint == tint)&&(identical(other.highlights, highlights) || other.highlights == highlights)&&(identical(other.shadows, shadows) || other.shadows == shadows)&&(identical(other.sharpen, sharpen) || other.sharpen == sharpen)&&(identical(other.vignette, vignette) || other.vignette == vignette));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,exposure,brightness,contrast,saturation,warmth,tint,highlights,shadows,sharpen,vignette);
}

@override
String toString() {
    return 'ClipAdjustments(exposure: $exposure, brightness: $brightness, contrast: $contrast, saturation: $saturation, warmth: $warmth, tint: $tint, highlights: $highlights, shadows: $shadows, sharpen: $sharpen, vignette: $vignette)';
}


}

/// @nodoc
abstract mixin class _$ClipAdjustmentsCopyWith<$Res> implements $ClipAdjustmentsCopyWith<$Res> {
  factory _$ClipAdjustmentsCopyWith(_ClipAdjustments value, $Res Function(_ClipAdjustments) _then) = __$ClipAdjustmentsCopyWithImpl;
@override @useResult
$Res call({
 double exposure, double brightness, double contrast, double saturation, double warmth, double tint, double highlights, double shadows, double sharpen, double vignette
});




}
/// @nodoc
class __$ClipAdjustmentsCopyWithImpl<$Res>
    implements _$ClipAdjustmentsCopyWith<$Res> {
  __$ClipAdjustmentsCopyWithImpl(this._self, this._then);

  final _ClipAdjustments _self;
  final $Res Function(_ClipAdjustments) _then;

/// Create a copy of ClipAdjustments
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exposure = null,Object? brightness = null,Object? contrast = null,Object? saturation = null,Object? warmth = null,Object? tint = null,Object? highlights = null,Object? shadows = null,Object? sharpen = null,Object? vignette = null,}) {
  return _then(_ClipAdjustments(
exposure: null == exposure ? _self.exposure : exposure // ignore: cast_nullable_to_non_nullable
as double,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as double,contrast: null == contrast ? _self.contrast : contrast // ignore: cast_nullable_to_non_nullable
as double,saturation: null == saturation ? _self.saturation : saturation // ignore: cast_nullable_to_non_nullable
as double,warmth: null == warmth ? _self.warmth : warmth // ignore: cast_nullable_to_non_nullable
as double,tint: null == tint ? _self.tint : tint // ignore: cast_nullable_to_non_nullable
as double,highlights: null == highlights ? _self.highlights : highlights // ignore: cast_nullable_to_non_nullable
as double,shadows: null == shadows ? _self.shadows : shadows // ignore: cast_nullable_to_non_nullable
as double,sharpen: null == sharpen ? _self.sharpen : sharpen // ignore: cast_nullable_to_non_nullable
as double,vignette: null == vignette ? _self.vignette : vignette // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
