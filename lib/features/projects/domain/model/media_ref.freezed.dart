// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_ref.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaRef {

 String get uri; MediaKind get kind; int? get durationUs; int get width; int get height; int get rotationDegrees; String? get displayName;
/// Create a copy of MediaRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaRefCopyWith<MediaRef> get copyWith => _$MediaRefCopyWithImpl<MediaRef>(this as MediaRef, _$identity);

  /// Serializes this MediaRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MediaRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaRef&&(identical(other.uri, _this.uri) || other.uri == _this.uri)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.durationUs, _this.durationUs) || other.durationUs == _this.durationUs)&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height)&&(identical(other.rotationDegrees, _this.rotationDegrees) || other.rotationDegrees == _this.rotationDegrees)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MediaRef;
  return Object.hash(runtimeType,_this.uri,_this.kind,_this.durationUs,_this.width,_this.height,_this.rotationDegrees,_this.displayName);
}

@override
String toString() {
  final _this = this as MediaRef;
  return 'MediaRef(uri: ${_this.uri}, kind: ${_this.kind}, durationUs: ${_this.durationUs}, width: ${_this.width}, height: ${_this.height}, rotationDegrees: ${_this.rotationDegrees}, displayName: ${_this.displayName})';
}


}

/// @nodoc
abstract mixin class $MediaRefCopyWith<$Res>  {
  factory $MediaRefCopyWith(MediaRef value, $Res Function(MediaRef) _then) = _$MediaRefCopyWithImpl;
@useResult
$Res call({
 String uri, MediaKind kind, int? durationUs, int width, int height, int rotationDegrees, String? displayName
});




}
/// @nodoc
class _$MediaRefCopyWithImpl<$Res>
    implements $MediaRefCopyWith<$Res> {
  _$MediaRefCopyWithImpl(this._self, this._then);

  final MediaRef _self;
  final $Res Function(MediaRef) _then;

/// Create a copy of MediaRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uri = null,Object? kind = null,Object? durationUs = freezed,Object? width = null,Object? height = null,Object? rotationDegrees = null,Object? displayName = freezed,}) {
  return _then(MediaRef(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,durationUs: freezed == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int?,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,rotationDegrees: null == rotationDegrees ? _self.rotationDegrees : rotationDegrees // ignore: cast_nullable_to_non_nullable
as int,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaRef].
extension MediaRefPatterns on MediaRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaRef value)  $default,){
final _that = this;
switch (_that) {
case _MediaRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaRef value)?  $default,){
final _that = this;
switch (_that) {
case _MediaRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uri,  MediaKind kind,  int? durationUs,  int width,  int height,  int rotationDegrees,  String? displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaRef() when $default != null:
return $default(_that.uri,_that.kind,_that.durationUs,_that.width,_that.height,_that.rotationDegrees,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uri,  MediaKind kind,  int? durationUs,  int width,  int height,  int rotationDegrees,  String? displayName)  $default,) {final _that = this;
switch (_that) {
case _MediaRef():
return $default(_that.uri,_that.kind,_that.durationUs,_that.width,_that.height,_that.rotationDegrees,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uri,  MediaKind kind,  int? durationUs,  int width,  int height,  int rotationDegrees,  String? displayName)?  $default,) {final _that = this;
switch (_that) {
case _MediaRef() when $default != null:
return $default(_that.uri,_that.kind,_that.durationUs,_that.width,_that.height,_that.rotationDegrees,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaRef extends MediaRef {
  const _MediaRef({required this.uri, required this.kind, this.durationUs, this.width = 0, this.height = 0, this.rotationDegrees = 0, this.displayName}): super._();
  factory _MediaRef.fromJson(Map<String, dynamic> json) => _$MediaRefFromJson(json);

@override final  String uri;
@override final  MediaKind kind;
@override final  int? durationUs;
@override@JsonKey() final  int width;
@override@JsonKey() final  int height;
@override@JsonKey() final  int rotationDegrees;
@override final  String? displayName;

/// Create a copy of MediaRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaRefCopyWith<_MediaRef> get copyWith => __$MediaRefCopyWithImpl<_MediaRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaRefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaRef&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.durationUs, durationUs) || other.durationUs == durationUs)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.rotationDegrees, rotationDegrees) || other.rotationDegrees == rotationDegrees)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,uri,kind,durationUs,width,height,rotationDegrees,displayName);
}

@override
String toString() {
    return 'MediaRef(uri: $uri, kind: $kind, durationUs: $durationUs, width: $width, height: $height, rotationDegrees: $rotationDegrees, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$MediaRefCopyWith<$Res> implements $MediaRefCopyWith<$Res> {
  factory _$MediaRefCopyWith(_MediaRef value, $Res Function(_MediaRef) _then) = __$MediaRefCopyWithImpl;
@override @useResult
$Res call({
 String uri, MediaKind kind, int? durationUs, int width, int height, int rotationDegrees, String? displayName
});




}
/// @nodoc
class __$MediaRefCopyWithImpl<$Res>
    implements _$MediaRefCopyWith<$Res> {
  __$MediaRefCopyWithImpl(this._self, this._then);

  final _MediaRef _self;
  final $Res Function(_MediaRef) _then;

/// Create a copy of MediaRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uri = null,Object? kind = null,Object? durationUs = freezed,Object? width = null,Object? height = null,Object? rotationDegrees = null,Object? displayName = freezed,}) {
  return _then(_MediaRef(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,durationUs: freezed == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int?,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,rotationDegrees: null == rotationDegrees ? _self.rotationDegrees : rotationDegrees // ignore: cast_nullable_to_non_nullable
as int,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
