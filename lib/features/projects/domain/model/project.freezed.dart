// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Project {

 String get id; String get name; DateTime get createdAt; DateTime get updatedAt; int get schemaVersion; ProjectCanvas get canvas; MainTrack get mainTrack; List<LayerTrack> get overlayTracks; List<AudioTrack> get audioTracks;
/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectCopyWith<Project> get copyWith => _$ProjectCopyWithImpl<Project>(this as Project, _$identity);

  /// Serializes this Project to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Project;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Project&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.schemaVersion, _this.schemaVersion) || other.schemaVersion == _this.schemaVersion)&&(identical(other.canvas, _this.canvas) || other.canvas == _this.canvas)&&(identical(other.mainTrack, _this.mainTrack) || other.mainTrack == _this.mainTrack)&&const DeepCollectionEquality().equals(other.overlayTracks, _this.overlayTracks)&&const DeepCollectionEquality().equals(other.audioTracks, _this.audioTracks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Project;
  return Object.hash(runtimeType,_this.id,_this.name,_this.createdAt,_this.updatedAt,_this.schemaVersion,_this.canvas,_this.mainTrack,const DeepCollectionEquality().hash(_this.overlayTracks),const DeepCollectionEquality().hash(_this.audioTracks));
}

@override
String toString() {
  final _this = this as Project;
  return 'Project(id: ${_this.id}, name: ${_this.name}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, schemaVersion: ${_this.schemaVersion}, canvas: ${_this.canvas}, mainTrack: ${_this.mainTrack}, overlayTracks: ${_this.overlayTracks}, audioTracks: ${_this.audioTracks})';
}


}

/// @nodoc
abstract mixin class $ProjectCopyWith<$Res>  {
  factory $ProjectCopyWith(Project value, $Res Function(Project) _then) = _$ProjectCopyWithImpl;
@useResult
$Res call({
 String id, String name, DateTime createdAt, DateTime updatedAt, int schemaVersion, ProjectCanvas canvas, MainTrack mainTrack, List<LayerTrack> overlayTracks, List<AudioTrack> audioTracks
});


$ProjectCanvasCopyWith<$Res> get canvas;$MainTrackCopyWith<$Res> get mainTrack;

}
/// @nodoc
class _$ProjectCopyWithImpl<$Res>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._self, this._then);

  final Project _self;
  final $Res Function(Project) _then;

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,Object? canvas = null,Object? mainTrack = null,Object? overlayTracks = null,Object? audioTracks = null,}) {
  return _then(Project(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,canvas: null == canvas ? _self.canvas : canvas // ignore: cast_nullable_to_non_nullable
as ProjectCanvas,mainTrack: null == mainTrack ? _self.mainTrack : mainTrack // ignore: cast_nullable_to_non_nullable
as MainTrack,overlayTracks: null == overlayTracks ? _self.overlayTracks : overlayTracks // ignore: cast_nullable_to_non_nullable
as List<LayerTrack>,audioTracks: null == audioTracks ? _self.audioTracks : audioTracks // ignore: cast_nullable_to_non_nullable
as List<AudioTrack>,
  ));
}
/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectCanvasCopyWith<$Res> get canvas {
  
  return $ProjectCanvasCopyWith<$Res>(_self.canvas, (value) {
    return _then(_self.copyWith(canvas: value));
  });
}/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MainTrackCopyWith<$Res> get mainTrack {
  
  return $MainTrackCopyWith<$Res>(_self.mainTrack, (value) {
    return _then(_self.copyWith(mainTrack: value));
  });
}
}


/// Adds pattern-matching-related methods to [Project].
extension ProjectPatterns on Project {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Project value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Project() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Project value)  $default,){
final _that = this;
switch (_that) {
case _Project():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Project value)?  $default,){
final _that = this;
switch (_that) {
case _Project() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion,  ProjectCanvas canvas,  MainTrack mainTrack,  List<LayerTrack> overlayTracks,  List<AudioTrack> audioTracks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.schemaVersion,_that.canvas,_that.mainTrack,_that.overlayTracks,_that.audioTracks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion,  ProjectCanvas canvas,  MainTrack mainTrack,  List<LayerTrack> overlayTracks,  List<AudioTrack> audioTracks)  $default,) {final _that = this;
switch (_that) {
case _Project():
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.schemaVersion,_that.canvas,_that.mainTrack,_that.overlayTracks,_that.audioTracks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion,  ProjectCanvas canvas,  MainTrack mainTrack,  List<LayerTrack> overlayTracks,  List<AudioTrack> audioTracks)?  $default,) {final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.schemaVersion,_that.canvas,_that.mainTrack,_that.overlayTracks,_that.audioTracks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Project extends Project {
  const _Project({required this.id, required this.name, required this.createdAt, required this.updatedAt, this.schemaVersion = Project.currentSchemaVersion, this.canvas = const ProjectCanvas(), this.mainTrack = const MainTrack(),  List<LayerTrack> overlayTracks = const <LayerTrack>[],  List<AudioTrack> audioTracks = const <AudioTrack>[]}): _overlayTracks = overlayTracks,_audioTracks = audioTracks,super._();
  factory _Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);

@override final  String id;
@override final  String name;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  int schemaVersion;
@override@JsonKey() final  ProjectCanvas canvas;
@override@JsonKey() final  MainTrack mainTrack;
 final  List<LayerTrack> _overlayTracks;
@override@JsonKey() List<LayerTrack> get overlayTracks {
  if (_overlayTracks is EqualUnmodifiableListView) return _overlayTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_overlayTracks);
}

 final  List<AudioTrack> _audioTracks;
@override@JsonKey() List<AudioTrack> get audioTracks {
  if (_audioTracks is EqualUnmodifiableListView) return _audioTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audioTracks);
}


/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectCopyWith<_Project> get copyWith => __$ProjectCopyWithImpl<_Project>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Project&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.canvas, canvas) || other.canvas == canvas)&&(identical(other.mainTrack, mainTrack) || other.mainTrack == mainTrack)&&const DeepCollectionEquality().equals(other.overlayTracks, _overlayTracks)&&const DeepCollectionEquality().equals(other.audioTracks, _audioTracks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,createdAt,updatedAt,schemaVersion,canvas,mainTrack,const DeepCollectionEquality().hash(_overlayTracks),const DeepCollectionEquality().hash(_audioTracks));
}

@override
String toString() {
    return 'Project(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion, canvas: $canvas, mainTrack: $mainTrack, overlayTracks: $overlayTracks, audioTracks: $audioTracks)';
}


}

/// @nodoc
abstract mixin class _$ProjectCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$ProjectCopyWith(_Project value, $Res Function(_Project) _then) = __$ProjectCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, DateTime createdAt, DateTime updatedAt, int schemaVersion, ProjectCanvas canvas, MainTrack mainTrack, List<LayerTrack> overlayTracks, List<AudioTrack> audioTracks
});


@override $ProjectCanvasCopyWith<$Res> get canvas;@override $MainTrackCopyWith<$Res> get mainTrack;

}
/// @nodoc
class __$ProjectCopyWithImpl<$Res>
    implements _$ProjectCopyWith<$Res> {
  __$ProjectCopyWithImpl(this._self, this._then);

  final _Project _self;
  final $Res Function(_Project) _then;

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,Object? canvas = null,Object? mainTrack = null,Object? overlayTracks = null,Object? audioTracks = null,}) {
  return _then(_Project(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,canvas: null == canvas ? _self.canvas : canvas // ignore: cast_nullable_to_non_nullable
as ProjectCanvas,mainTrack: null == mainTrack ? _self.mainTrack : mainTrack // ignore: cast_nullable_to_non_nullable
as MainTrack,overlayTracks: null == overlayTracks ? _self._overlayTracks : overlayTracks // ignore: cast_nullable_to_non_nullable
as List<LayerTrack>,audioTracks: null == audioTracks ? _self._audioTracks : audioTracks // ignore: cast_nullable_to_non_nullable
as List<AudioTrack>,
  ));
}

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectCanvasCopyWith<$Res> get canvas {
  
  return $ProjectCanvasCopyWith<$Res>(_self.canvas, (value) {
    return _then(_self.copyWith(canvas: value));
  });
}/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MainTrackCopyWith<$Res> get mainTrack {
  
  return $MainTrackCopyWith<$Res>(_self.mainTrack, (value) {
    return _then(_self.copyWith(mainTrack: value));
  });
}
}

// dart format on
