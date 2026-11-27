// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Clip {

 String get id; MediaRef get media; int get sourceInUs; int get sourceOutUs; double get speed; SpeedCurve? get speedCurve; bool get keepPitch; ClipTransform get transform; FitMode get fitMode; CropRect get crop; ClipBorder get border; double get volume; bool get muted;
/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClipCopyWith<Clip> get copyWith => _$ClipCopyWithImpl<Clip>(this as Clip, _$identity);

  /// Serializes this Clip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Clip;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Clip&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.media, _this.media) || other.media == _this.media)&&(identical(other.sourceInUs, _this.sourceInUs) || other.sourceInUs == _this.sourceInUs)&&(identical(other.sourceOutUs, _this.sourceOutUs) || other.sourceOutUs == _this.sourceOutUs)&&(identical(other.speed, _this.speed) || other.speed == _this.speed)&&(identical(other.speedCurve, _this.speedCurve) || other.speedCurve == _this.speedCurve)&&(identical(other.keepPitch, _this.keepPitch) || other.keepPitch == _this.keepPitch)&&(identical(other.transform, _this.transform) || other.transform == _this.transform)&&(identical(other.fitMode, _this.fitMode) || other.fitMode == _this.fitMode)&&(identical(other.crop, _this.crop) || other.crop == _this.crop)&&(identical(other.border, _this.border) || other.border == _this.border)&&(identical(other.volume, _this.volume) || other.volume == _this.volume)&&(identical(other.muted, _this.muted) || other.muted == _this.muted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Clip;
  return Object.hash(runtimeType,_this.id,_this.media,_this.sourceInUs,_this.sourceOutUs,_this.speed,_this.speedCurve,_this.keepPitch,_this.transform,_this.fitMode,_this.crop,_this.border,_this.volume,_this.muted);
}

@override
String toString() {
  final _this = this as Clip;
  return 'Clip(id: ${_this.id}, media: ${_this.media}, sourceInUs: ${_this.sourceInUs}, sourceOutUs: ${_this.sourceOutUs}, speed: ${_this.speed}, speedCurve: ${_this.speedCurve}, keepPitch: ${_this.keepPitch}, transform: ${_this.transform}, fitMode: ${_this.fitMode}, crop: ${_this.crop}, border: ${_this.border}, volume: ${_this.volume}, muted: ${_this.muted})';
}


}

/// @nodoc
abstract mixin class $ClipCopyWith<$Res>  {
  factory $ClipCopyWith(Clip value, $Res Function(Clip) _then) = _$ClipCopyWithImpl;
@useResult
$Res call({
 String id, MediaRef media, int sourceInUs, int sourceOutUs, double speed, SpeedCurve? speedCurve, bool keepPitch, ClipTransform transform, FitMode fitMode, CropRect crop, ClipBorder border, double volume, bool muted
});


$MediaRefCopyWith<$Res> get media;$SpeedCurveCopyWith<$Res>? get speedCurve;$ClipTransformCopyWith<$Res> get transform;$CropRectCopyWith<$Res> get crop;$ClipBorderCopyWith<$Res> get border;

}
/// @nodoc
class _$ClipCopyWithImpl<$Res>
    implements $ClipCopyWith<$Res> {
  _$ClipCopyWithImpl(this._self, this._then);

  final Clip _self;
  final $Res Function(Clip) _then;

/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? media = null,Object? sourceInUs = null,Object? sourceOutUs = null,Object? speed = null,Object? speedCurve = freezed,Object? keepPitch = null,Object? transform = null,Object? fitMode = null,Object? crop = null,Object? border = null,Object? volume = null,Object? muted = null,}) {
  return _then(Clip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as MediaRef,sourceInUs: null == sourceInUs ? _self.sourceInUs : sourceInUs // ignore: cast_nullable_to_non_nullable
as int,sourceOutUs: null == sourceOutUs ? _self.sourceOutUs : sourceOutUs // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,speedCurve: freezed == speedCurve ? _self.speedCurve : speedCurve // ignore: cast_nullable_to_non_nullable
as SpeedCurve?,keepPitch: null == keepPitch ? _self.keepPitch : keepPitch // ignore: cast_nullable_to_non_nullable
as bool,transform: null == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as ClipTransform,fitMode: null == fitMode ? _self.fitMode : fitMode // ignore: cast_nullable_to_non_nullable
as FitMode,crop: null == crop ? _self.crop : crop // ignore: cast_nullable_to_non_nullable
as CropRect,border: null == border ? _self.border : border // ignore: cast_nullable_to_non_nullable
as ClipBorder,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaRefCopyWith<$Res> get media {
  
  return $MediaRefCopyWith<$Res>(_self.media, (value) {
    return _then(_self.copyWith(media: value));
  });
}/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedCurveCopyWith<$Res>? get speedCurve {
    if (_self.speedCurve == null) {
    return null;
  }

  return $SpeedCurveCopyWith<$Res>(_self.speedCurve!, (value) {
    return _then(_self.copyWith(speedCurve: value));
  });
}/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClipTransformCopyWith<$Res> get transform {
  
  return $ClipTransformCopyWith<$Res>(_self.transform, (value) {
    return _then(_self.copyWith(transform: value));
  });
}/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CropRectCopyWith<$Res> get crop {
  
  return $CropRectCopyWith<$Res>(_self.crop, (value) {
    return _then(_self.copyWith(crop: value));
  });
}/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClipBorderCopyWith<$Res> get border {
  
  return $ClipBorderCopyWith<$Res>(_self.border, (value) {
    return _then(_self.copyWith(border: value));
  });
}
}


/// Adds pattern-matching-related methods to [Clip].
extension ClipPatterns on Clip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Clip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Clip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Clip value)  $default,){
final _that = this;
switch (_that) {
case _Clip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Clip value)?  $default,){
final _that = this;
switch (_that) {
case _Clip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  MediaRef media,  int sourceInUs,  int sourceOutUs,  double speed,  SpeedCurve? speedCurve,  bool keepPitch,  ClipTransform transform,  FitMode fitMode,  CropRect crop,  ClipBorder border,  double volume,  bool muted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Clip() when $default != null:
return $default(_that.id,_that.media,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.speedCurve,_that.keepPitch,_that.transform,_that.fitMode,_that.crop,_that.border,_that.volume,_that.muted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  MediaRef media,  int sourceInUs,  int sourceOutUs,  double speed,  SpeedCurve? speedCurve,  bool keepPitch,  ClipTransform transform,  FitMode fitMode,  CropRect crop,  ClipBorder border,  double volume,  bool muted)  $default,) {final _that = this;
switch (_that) {
case _Clip():
return $default(_that.id,_that.media,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.speedCurve,_that.keepPitch,_that.transform,_that.fitMode,_that.crop,_that.border,_that.volume,_that.muted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  MediaRef media,  int sourceInUs,  int sourceOutUs,  double speed,  SpeedCurve? speedCurve,  bool keepPitch,  ClipTransform transform,  FitMode fitMode,  CropRect crop,  ClipBorder border,  double volume,  bool muted)?  $default,) {final _that = this;
switch (_that) {
case _Clip() when $default != null:
return $default(_that.id,_that.media,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.speedCurve,_that.keepPitch,_that.transform,_that.fitMode,_that.crop,_that.border,_that.volume,_that.muted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Clip extends Clip {
  const _Clip({required this.id, required this.media, required this.sourceInUs, required this.sourceOutUs, this.speed = 1.0, this.speedCurve, this.keepPitch = true, this.transform = const ClipTransform(), this.fitMode = FitMode.fit, this.crop = CropRect.full, this.border = const ClipBorder(), this.volume = 1.0, this.muted = false}): super._();
  factory _Clip.fromJson(Map<String, dynamic> json) => _$ClipFromJson(json);

@override final  String id;
@override final  MediaRef media;
@override final  int sourceInUs;
@override final  int sourceOutUs;
@override@JsonKey() final  double speed;
@override final  SpeedCurve? speedCurve;
@override@JsonKey() final  bool keepPitch;
@override@JsonKey() final  ClipTransform transform;
@override@JsonKey() final  FitMode fitMode;
@override@JsonKey() final  CropRect crop;
@override@JsonKey() final  ClipBorder border;
@override@JsonKey() final  double volume;
@override@JsonKey() final  bool muted;

/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClipCopyWith<_Clip> get copyWith => __$ClipCopyWithImpl<_Clip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClipToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Clip&&(identical(other.id, id) || other.id == id)&&(identical(other.media, media) || other.media == media)&&(identical(other.sourceInUs, sourceInUs) || other.sourceInUs == sourceInUs)&&(identical(other.sourceOutUs, sourceOutUs) || other.sourceOutUs == sourceOutUs)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.speedCurve, speedCurve) || other.speedCurve == speedCurve)&&(identical(other.keepPitch, keepPitch) || other.keepPitch == keepPitch)&&(identical(other.transform, transform) || other.transform == transform)&&(identical(other.fitMode, fitMode) || other.fitMode == fitMode)&&(identical(other.crop, crop) || other.crop == crop)&&(identical(other.border, border) || other.border == border)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.muted, muted) || other.muted == muted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,media,sourceInUs,sourceOutUs,speed,speedCurve,keepPitch,transform,fitMode,crop,border,volume,muted);
}

@override
String toString() {
    return 'Clip(id: $id, media: $media, sourceInUs: $sourceInUs, sourceOutUs: $sourceOutUs, speed: $speed, speedCurve: $speedCurve, keepPitch: $keepPitch, transform: $transform, fitMode: $fitMode, crop: $crop, border: $border, volume: $volume, muted: $muted)';
}


}

/// @nodoc
abstract mixin class _$ClipCopyWith<$Res> implements $ClipCopyWith<$Res> {
  factory _$ClipCopyWith(_Clip value, $Res Function(_Clip) _then) = __$ClipCopyWithImpl;
@override @useResult
$Res call({
 String id, MediaRef media, int sourceInUs, int sourceOutUs, double speed, SpeedCurve? speedCurve, bool keepPitch, ClipTransform transform, FitMode fitMode, CropRect crop, ClipBorder border, double volume, bool muted
});


@override $MediaRefCopyWith<$Res> get media;@override $SpeedCurveCopyWith<$Res>? get speedCurve;@override $ClipTransformCopyWith<$Res> get transform;@override $CropRectCopyWith<$Res> get crop;@override $ClipBorderCopyWith<$Res> get border;

}
/// @nodoc
class __$ClipCopyWithImpl<$Res>
    implements _$ClipCopyWith<$Res> {
  __$ClipCopyWithImpl(this._self, this._then);

  final _Clip _self;
  final $Res Function(_Clip) _then;

/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? media = null,Object? sourceInUs = null,Object? sourceOutUs = null,Object? speed = null,Object? speedCurve = freezed,Object? keepPitch = null,Object? transform = null,Object? fitMode = null,Object? crop = null,Object? border = null,Object? volume = null,Object? muted = null,}) {
  return _then(_Clip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as MediaRef,sourceInUs: null == sourceInUs ? _self.sourceInUs : sourceInUs // ignore: cast_nullable_to_non_nullable
as int,sourceOutUs: null == sourceOutUs ? _self.sourceOutUs : sourceOutUs // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,speedCurve: freezed == speedCurve ? _self.speedCurve : speedCurve // ignore: cast_nullable_to_non_nullable
as SpeedCurve?,keepPitch: null == keepPitch ? _self.keepPitch : keepPitch // ignore: cast_nullable_to_non_nullable
as bool,transform: null == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as ClipTransform,fitMode: null == fitMode ? _self.fitMode : fitMode // ignore: cast_nullable_to_non_nullable
as FitMode,crop: null == crop ? _self.crop : crop // ignore: cast_nullable_to_non_nullable
as CropRect,border: null == border ? _self.border : border // ignore: cast_nullable_to_non_nullable
as ClipBorder,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaRefCopyWith<$Res> get media {
  
  return $MediaRefCopyWith<$Res>(_self.media, (value) {
    return _then(_self.copyWith(media: value));
  });
}/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedCurveCopyWith<$Res>? get speedCurve {
    if (_self.speedCurve == null) {
    return null;
  }

  return $SpeedCurveCopyWith<$Res>(_self.speedCurve!, (value) {
    return _then(_self.copyWith(speedCurve: value));
  });
}/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClipTransformCopyWith<$Res> get transform {
  
  return $ClipTransformCopyWith<$Res>(_self.transform, (value) {
    return _then(_self.copyWith(transform: value));
  });
}/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CropRectCopyWith<$Res> get crop {
  
  return $CropRectCopyWith<$Res>(_self.crop, (value) {
    return _then(_self.copyWith(crop: value));
  });
}/// Create a copy of Clip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClipBorderCopyWith<$Res> get border {
  
  return $ClipBorderCopyWith<$Res>(_self.border, (value) {
    return _then(_self.copyWith(border: value));
  });
}
}


/// @nodoc
mixin _$AudioClip {

 String get id; MediaRef get media; int get sourceInUs; int get sourceOutUs; double get speed; double get volume; int get fadeInUs; int get fadeOutUs;
/// Create a copy of AudioClip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioClipCopyWith<AudioClip> get copyWith => _$AudioClipCopyWithImpl<AudioClip>(this as AudioClip, _$identity);

  /// Serializes this AudioClip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AudioClip;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioClip&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.media, _this.media) || other.media == _this.media)&&(identical(other.sourceInUs, _this.sourceInUs) || other.sourceInUs == _this.sourceInUs)&&(identical(other.sourceOutUs, _this.sourceOutUs) || other.sourceOutUs == _this.sourceOutUs)&&(identical(other.speed, _this.speed) || other.speed == _this.speed)&&(identical(other.volume, _this.volume) || other.volume == _this.volume)&&(identical(other.fadeInUs, _this.fadeInUs) || other.fadeInUs == _this.fadeInUs)&&(identical(other.fadeOutUs, _this.fadeOutUs) || other.fadeOutUs == _this.fadeOutUs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AudioClip;
  return Object.hash(runtimeType,_this.id,_this.media,_this.sourceInUs,_this.sourceOutUs,_this.speed,_this.volume,_this.fadeInUs,_this.fadeOutUs);
}

@override
String toString() {
  final _this = this as AudioClip;
  return 'AudioClip(id: ${_this.id}, media: ${_this.media}, sourceInUs: ${_this.sourceInUs}, sourceOutUs: ${_this.sourceOutUs}, speed: ${_this.speed}, volume: ${_this.volume}, fadeInUs: ${_this.fadeInUs}, fadeOutUs: ${_this.fadeOutUs})';
}


}

/// @nodoc
abstract mixin class $AudioClipCopyWith<$Res>  {
  factory $AudioClipCopyWith(AudioClip value, $Res Function(AudioClip) _then) = _$AudioClipCopyWithImpl;
@useResult
$Res call({
 String id, MediaRef media, int sourceInUs, int sourceOutUs, double speed, double volume, int fadeInUs, int fadeOutUs
});


$MediaRefCopyWith<$Res> get media;

}
/// @nodoc
class _$AudioClipCopyWithImpl<$Res>
    implements $AudioClipCopyWith<$Res> {
  _$AudioClipCopyWithImpl(this._self, this._then);

  final AudioClip _self;
  final $Res Function(AudioClip) _then;

/// Create a copy of AudioClip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? media = null,Object? sourceInUs = null,Object? sourceOutUs = null,Object? speed = null,Object? volume = null,Object? fadeInUs = null,Object? fadeOutUs = null,}) {
  return _then(AudioClip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as MediaRef,sourceInUs: null == sourceInUs ? _self.sourceInUs : sourceInUs // ignore: cast_nullable_to_non_nullable
as int,sourceOutUs: null == sourceOutUs ? _self.sourceOutUs : sourceOutUs // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,fadeInUs: null == fadeInUs ? _self.fadeInUs : fadeInUs // ignore: cast_nullable_to_non_nullable
as int,fadeOutUs: null == fadeOutUs ? _self.fadeOutUs : fadeOutUs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of AudioClip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaRefCopyWith<$Res> get media {
  
  return $MediaRefCopyWith<$Res>(_self.media, (value) {
    return _then(_self.copyWith(media: value));
  });
}
}


/// Adds pattern-matching-related methods to [AudioClip].
extension AudioClipPatterns on AudioClip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioClip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioClip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioClip value)  $default,){
final _that = this;
switch (_that) {
case _AudioClip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioClip value)?  $default,){
final _that = this;
switch (_that) {
case _AudioClip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  MediaRef media,  int sourceInUs,  int sourceOutUs,  double speed,  double volume,  int fadeInUs,  int fadeOutUs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioClip() when $default != null:
return $default(_that.id,_that.media,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.volume,_that.fadeInUs,_that.fadeOutUs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  MediaRef media,  int sourceInUs,  int sourceOutUs,  double speed,  double volume,  int fadeInUs,  int fadeOutUs)  $default,) {final _that = this;
switch (_that) {
case _AudioClip():
return $default(_that.id,_that.media,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.volume,_that.fadeInUs,_that.fadeOutUs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  MediaRef media,  int sourceInUs,  int sourceOutUs,  double speed,  double volume,  int fadeInUs,  int fadeOutUs)?  $default,) {final _that = this;
switch (_that) {
case _AudioClip() when $default != null:
return $default(_that.id,_that.media,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.volume,_that.fadeInUs,_that.fadeOutUs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AudioClip extends AudioClip {
  const _AudioClip({required this.id, required this.media, required this.sourceInUs, required this.sourceOutUs, this.speed = 1.0, this.volume = 1.0, this.fadeInUs = 0, this.fadeOutUs = 0}): super._();
  factory _AudioClip.fromJson(Map<String, dynamic> json) => _$AudioClipFromJson(json);

@override final  String id;
@override final  MediaRef media;
@override final  int sourceInUs;
@override final  int sourceOutUs;
@override@JsonKey() final  double speed;
@override@JsonKey() final  double volume;
@override@JsonKey() final  int fadeInUs;
@override@JsonKey() final  int fadeOutUs;

/// Create a copy of AudioClip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioClipCopyWith<_AudioClip> get copyWith => __$AudioClipCopyWithImpl<_AudioClip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AudioClipToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioClip&&(identical(other.id, id) || other.id == id)&&(identical(other.media, media) || other.media == media)&&(identical(other.sourceInUs, sourceInUs) || other.sourceInUs == sourceInUs)&&(identical(other.sourceOutUs, sourceOutUs) || other.sourceOutUs == sourceOutUs)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.fadeInUs, fadeInUs) || other.fadeInUs == fadeInUs)&&(identical(other.fadeOutUs, fadeOutUs) || other.fadeOutUs == fadeOutUs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,media,sourceInUs,sourceOutUs,speed,volume,fadeInUs,fadeOutUs);
}

@override
String toString() {
    return 'AudioClip(id: $id, media: $media, sourceInUs: $sourceInUs, sourceOutUs: $sourceOutUs, speed: $speed, volume: $volume, fadeInUs: $fadeInUs, fadeOutUs: $fadeOutUs)';
}


}

/// @nodoc
abstract mixin class _$AudioClipCopyWith<$Res> implements $AudioClipCopyWith<$Res> {
  factory _$AudioClipCopyWith(_AudioClip value, $Res Function(_AudioClip) _then) = __$AudioClipCopyWithImpl;
@override @useResult
$Res call({
 String id, MediaRef media, int sourceInUs, int sourceOutUs, double speed, double volume, int fadeInUs, int fadeOutUs
});


@override $MediaRefCopyWith<$Res> get media;

}
/// @nodoc
class __$AudioClipCopyWithImpl<$Res>
    implements _$AudioClipCopyWith<$Res> {
  __$AudioClipCopyWithImpl(this._self, this._then);

  final _AudioClip _self;
  final $Res Function(_AudioClip) _then;

/// Create a copy of AudioClip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? media = null,Object? sourceInUs = null,Object? sourceOutUs = null,Object? speed = null,Object? volume = null,Object? fadeInUs = null,Object? fadeOutUs = null,}) {
  return _then(_AudioClip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as MediaRef,sourceInUs: null == sourceInUs ? _self.sourceInUs : sourceInUs // ignore: cast_nullable_to_non_nullable
as int,sourceOutUs: null == sourceOutUs ? _self.sourceOutUs : sourceOutUs // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,fadeInUs: null == fadeInUs ? _self.fadeInUs : fadeInUs // ignore: cast_nullable_to_non_nullable
as int,fadeOutUs: null == fadeOutUs ? _self.fadeOutUs : fadeOutUs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of AudioClip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaRefCopyWith<$Res> get media {
  
  return $MediaRefCopyWith<$Res>(_self.media, (value) {
    return _then(_self.copyWith(media: value));
  });
}
}

// dart format on
