// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_canvas.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CanvasAspect {

 int get width; int get height;
/// Create a copy of CanvasAspect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanvasAspectCopyWith<CanvasAspect> get copyWith => _$CanvasAspectCopyWithImpl<CanvasAspect>(this as CanvasAspect, _$identity);

  /// Serializes this CanvasAspect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CanvasAspect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanvasAspect&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CanvasAspect;
  return Object.hash(runtimeType,_this.width,_this.height);
}

@override
String toString() {
  final _this = this as CanvasAspect;
  return 'CanvasAspect(width: ${_this.width}, height: ${_this.height})';
}


}

/// @nodoc
abstract mixin class $CanvasAspectCopyWith<$Res>  {
  factory $CanvasAspectCopyWith(CanvasAspect value, $Res Function(CanvasAspect) _then) = _$CanvasAspectCopyWithImpl;
@useResult
$Res call({
 int width, int height
});




}
/// @nodoc
class _$CanvasAspectCopyWithImpl<$Res>
    implements $CanvasAspectCopyWith<$Res> {
  _$CanvasAspectCopyWithImpl(this._self, this._then);

  final CanvasAspect _self;
  final $Res Function(CanvasAspect) _then;

/// Create a copy of CanvasAspect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? width = null,Object? height = null,}) {
  return _then(CanvasAspect(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CanvasAspect].
extension CanvasAspectPatterns on CanvasAspect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CanvasAspect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CanvasAspect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CanvasAspect value)  $default,){
final _that = this;
switch (_that) {
case _CanvasAspect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CanvasAspect value)?  $default,){
final _that = this;
switch (_that) {
case _CanvasAspect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int width,  int height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CanvasAspect() when $default != null:
return $default(_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _CanvasAspect():
return $default(_that.width,_that.height);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int width,  int height)?  $default,) {final _that = this;
switch (_that) {
case _CanvasAspect() when $default != null:
return $default(_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CanvasAspect extends CanvasAspect {
  const _CanvasAspect({required this.width, required this.height}): assert(width > 0 && height > 0, 'sides must be positive'),super._();
  factory _CanvasAspect.fromJson(Map<String, dynamic> json) => _$CanvasAspectFromJson(json);

@override final  int width;
@override final  int height;

/// Create a copy of CanvasAspect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CanvasAspectCopyWith<_CanvasAspect> get copyWith => __$CanvasAspectCopyWithImpl<_CanvasAspect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CanvasAspectToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CanvasAspect&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,width,height);
}

@override
String toString() {
    return 'CanvasAspect(width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$CanvasAspectCopyWith<$Res> implements $CanvasAspectCopyWith<$Res> {
  factory _$CanvasAspectCopyWith(_CanvasAspect value, $Res Function(_CanvasAspect) _then) = __$CanvasAspectCopyWithImpl;
@override @useResult
$Res call({
 int width, int height
});




}
/// @nodoc
class __$CanvasAspectCopyWithImpl<$Res>
    implements _$CanvasAspectCopyWith<$Res> {
  __$CanvasAspectCopyWithImpl(this._self, this._then);

  final _CanvasAspect _self;
  final $Res Function(_CanvasAspect) _then;

/// Create a copy of CanvasAspect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? width = null,Object? height = null,}) {
  return _then(_CanvasAspect(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProjectCanvas {

 CanvasAspect get aspect; int get shortSidePx; int get fps; CanvasBackground get background;
/// Create a copy of ProjectCanvas
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectCanvasCopyWith<ProjectCanvas> get copyWith => _$ProjectCanvasCopyWithImpl<ProjectCanvas>(this as ProjectCanvas, _$identity);

  /// Serializes this ProjectCanvas to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProjectCanvas;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectCanvas&&(identical(other.aspect, _this.aspect) || other.aspect == _this.aspect)&&(identical(other.shortSidePx, _this.shortSidePx) || other.shortSidePx == _this.shortSidePx)&&(identical(other.fps, _this.fps) || other.fps == _this.fps)&&(identical(other.background, _this.background) || other.background == _this.background));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProjectCanvas;
  return Object.hash(runtimeType,_this.aspect,_this.shortSidePx,_this.fps,_this.background);
}

@override
String toString() {
  final _this = this as ProjectCanvas;
  return 'ProjectCanvas(aspect: ${_this.aspect}, shortSidePx: ${_this.shortSidePx}, fps: ${_this.fps}, background: ${_this.background})';
}


}

/// @nodoc
abstract mixin class $ProjectCanvasCopyWith<$Res>  {
  factory $ProjectCanvasCopyWith(ProjectCanvas value, $Res Function(ProjectCanvas) _then) = _$ProjectCanvasCopyWithImpl;
@useResult
$Res call({
 CanvasAspect aspect, int shortSidePx, int fps, CanvasBackground background
});


$CanvasAspectCopyWith<$Res> get aspect;$CanvasBackgroundCopyWith<$Res> get background;

}
/// @nodoc
class _$ProjectCanvasCopyWithImpl<$Res>
    implements $ProjectCanvasCopyWith<$Res> {
  _$ProjectCanvasCopyWithImpl(this._self, this._then);

  final ProjectCanvas _self;
  final $Res Function(ProjectCanvas) _then;

/// Create a copy of ProjectCanvas
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aspect = null,Object? shortSidePx = null,Object? fps = null,Object? background = null,}) {
  return _then(ProjectCanvas(
aspect: null == aspect ? _self.aspect : aspect // ignore: cast_nullable_to_non_nullable
as CanvasAspect,shortSidePx: null == shortSidePx ? _self.shortSidePx : shortSidePx // ignore: cast_nullable_to_non_nullable
as int,fps: null == fps ? _self.fps : fps // ignore: cast_nullable_to_non_nullable
as int,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as CanvasBackground,
  ));
}
/// Create a copy of ProjectCanvas
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanvasAspectCopyWith<$Res> get aspect {
  
  return $CanvasAspectCopyWith<$Res>(_self.aspect, (value) {
    return _then(_self.copyWith(aspect: value));
  });
}/// Create a copy of ProjectCanvas
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanvasBackgroundCopyWith<$Res> get background {
  
  return $CanvasBackgroundCopyWith<$Res>(_self.background, (value) {
    return _then(_self.copyWith(background: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectCanvas].
extension ProjectCanvasPatterns on ProjectCanvas {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectCanvas value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectCanvas() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectCanvas value)  $default,){
final _that = this;
switch (_that) {
case _ProjectCanvas():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectCanvas value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectCanvas() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CanvasAspect aspect,  int shortSidePx,  int fps,  CanvasBackground background)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectCanvas() when $default != null:
return $default(_that.aspect,_that.shortSidePx,_that.fps,_that.background);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CanvasAspect aspect,  int shortSidePx,  int fps,  CanvasBackground background)  $default,) {final _that = this;
switch (_that) {
case _ProjectCanvas():
return $default(_that.aspect,_that.shortSidePx,_that.fps,_that.background);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CanvasAspect aspect,  int shortSidePx,  int fps,  CanvasBackground background)?  $default,) {final _that = this;
switch (_that) {
case _ProjectCanvas() when $default != null:
return $default(_that.aspect,_that.shortSidePx,_that.fps,_that.background);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectCanvas implements ProjectCanvas {
  const _ProjectCanvas({this.aspect = CanvasAspect.landscape16x9, this.shortSidePx = 1080, this.fps = 30, this.background = CanvasBackground.black});
  factory _ProjectCanvas.fromJson(Map<String, dynamic> json) => _$ProjectCanvasFromJson(json);

@override@JsonKey() final  CanvasAspect aspect;
@override@JsonKey() final  int shortSidePx;
@override@JsonKey() final  int fps;
@override@JsonKey() final  CanvasBackground background;

/// Create a copy of ProjectCanvas
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectCanvasCopyWith<_ProjectCanvas> get copyWith => __$ProjectCanvasCopyWithImpl<_ProjectCanvas>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectCanvasToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectCanvas&&(identical(other.aspect, aspect) || other.aspect == aspect)&&(identical(other.shortSidePx, shortSidePx) || other.shortSidePx == shortSidePx)&&(identical(other.fps, fps) || other.fps == fps)&&(identical(other.background, background) || other.background == background));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,aspect,shortSidePx,fps,background);
}

@override
String toString() {
    return 'ProjectCanvas(aspect: $aspect, shortSidePx: $shortSidePx, fps: $fps, background: $background)';
}


}

/// @nodoc
abstract mixin class _$ProjectCanvasCopyWith<$Res> implements $ProjectCanvasCopyWith<$Res> {
  factory _$ProjectCanvasCopyWith(_ProjectCanvas value, $Res Function(_ProjectCanvas) _then) = __$ProjectCanvasCopyWithImpl;
@override @useResult
$Res call({
 CanvasAspect aspect, int shortSidePx, int fps, CanvasBackground background
});


@override $CanvasAspectCopyWith<$Res> get aspect;@override $CanvasBackgroundCopyWith<$Res> get background;

}
/// @nodoc
class __$ProjectCanvasCopyWithImpl<$Res>
    implements _$ProjectCanvasCopyWith<$Res> {
  __$ProjectCanvasCopyWithImpl(this._self, this._then);

  final _ProjectCanvas _self;
  final $Res Function(_ProjectCanvas) _then;

/// Create a copy of ProjectCanvas
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aspect = null,Object? shortSidePx = null,Object? fps = null,Object? background = null,}) {
  return _then(_ProjectCanvas(
aspect: null == aspect ? _self.aspect : aspect // ignore: cast_nullable_to_non_nullable
as CanvasAspect,shortSidePx: null == shortSidePx ? _self.shortSidePx : shortSidePx // ignore: cast_nullable_to_non_nullable
as int,fps: null == fps ? _self.fps : fps // ignore: cast_nullable_to_non_nullable
as int,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as CanvasBackground,
  ));
}

/// Create a copy of ProjectCanvas
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanvasAspectCopyWith<$Res> get aspect {
  
  return $CanvasAspectCopyWith<$Res>(_self.aspect, (value) {
    return _then(_self.copyWith(aspect: value));
  });
}/// Create a copy of ProjectCanvas
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanvasBackgroundCopyWith<$Res> get background {
  
  return $CanvasBackgroundCopyWith<$Res>(_self.background, (value) {
    return _then(_self.copyWith(background: value));
  });
}
}

// dart format on
