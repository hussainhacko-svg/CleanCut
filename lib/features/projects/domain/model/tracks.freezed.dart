// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracks.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MainTrack {

 List<Clip> get clips;
/// Create a copy of MainTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MainTrackCopyWith<MainTrack> get copyWith => _$MainTrackCopyWithImpl<MainTrack>(this as MainTrack, _$identity);

  /// Serializes this MainTrack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MainTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MainTrack&&const DeepCollectionEquality().equals(other.clips, _this.clips));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MainTrack;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.clips));
}

@override
String toString() {
  final _this = this as MainTrack;
  return 'MainTrack(clips: ${_this.clips})';
}


}

/// @nodoc
abstract mixin class $MainTrackCopyWith<$Res>  {
  factory $MainTrackCopyWith(MainTrack value, $Res Function(MainTrack) _then) = _$MainTrackCopyWithImpl;
@useResult
$Res call({
 List<Clip> clips
});




}
/// @nodoc
class _$MainTrackCopyWithImpl<$Res>
    implements $MainTrackCopyWith<$Res> {
  _$MainTrackCopyWithImpl(this._self, this._then);

  final MainTrack _self;
  final $Res Function(MainTrack) _then;

/// Create a copy of MainTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clips = null,}) {
  return _then(MainTrack(
clips: null == clips ? _self.clips : clips // ignore: cast_nullable_to_non_nullable
as List<Clip>,
  ));
}

}


/// Adds pattern-matching-related methods to [MainTrack].
extension MainTrackPatterns on MainTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MainTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MainTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MainTrack value)  $default,){
final _that = this;
switch (_that) {
case _MainTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MainTrack value)?  $default,){
final _that = this;
switch (_that) {
case _MainTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Clip> clips)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MainTrack() when $default != null:
return $default(_that.clips);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Clip> clips)  $default,) {final _that = this;
switch (_that) {
case _MainTrack():
return $default(_that.clips);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Clip> clips)?  $default,) {final _that = this;
switch (_that) {
case _MainTrack() when $default != null:
return $default(_that.clips);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MainTrack extends MainTrack {
  const _MainTrack({ List<Clip> clips = const <Clip>[]}): _clips = clips,super._();
  factory _MainTrack.fromJson(Map<String, dynamic> json) => _$MainTrackFromJson(json);

 final  List<Clip> _clips;
@override@JsonKey() List<Clip> get clips {
  if (_clips is EqualUnmodifiableListView) return _clips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_clips);
}


/// Create a copy of MainTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MainTrackCopyWith<_MainTrack> get copyWith => __$MainTrackCopyWithImpl<_MainTrack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MainTrackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MainTrack&&const DeepCollectionEquality().equals(other.clips, _clips));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_clips));
}

@override
String toString() {
    return 'MainTrack(clips: $clips)';
}


}

/// @nodoc
abstract mixin class _$MainTrackCopyWith<$Res> implements $MainTrackCopyWith<$Res> {
  factory _$MainTrackCopyWith(_MainTrack value, $Res Function(_MainTrack) _then) = __$MainTrackCopyWithImpl;
@override @useResult
$Res call({
 List<Clip> clips
});




}
/// @nodoc
class __$MainTrackCopyWithImpl<$Res>
    implements _$MainTrackCopyWith<$Res> {
  __$MainTrackCopyWithImpl(this._self, this._then);

  final _MainTrack _self;
  final $Res Function(_MainTrack) _then;

/// Create a copy of MainTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clips = null,}) {
  return _then(_MainTrack(
clips: null == clips ? _self._clips : clips // ignore: cast_nullable_to_non_nullable
as List<Clip>,
  ));
}


}


/// @nodoc
mixin _$PlacedClip {

 int get startUs; Clip get clip;
/// Create a copy of PlacedClip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlacedClipCopyWith<PlacedClip> get copyWith => _$PlacedClipCopyWithImpl<PlacedClip>(this as PlacedClip, _$identity);

  /// Serializes this PlacedClip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlacedClip;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlacedClip&&(identical(other.startUs, _this.startUs) || other.startUs == _this.startUs)&&(identical(other.clip, _this.clip) || other.clip == _this.clip));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlacedClip;
  return Object.hash(runtimeType,_this.startUs,_this.clip);
}

@override
String toString() {
  final _this = this as PlacedClip;
  return 'PlacedClip(startUs: ${_this.startUs}, clip: ${_this.clip})';
}


}

/// @nodoc
abstract mixin class $PlacedClipCopyWith<$Res>  {
  factory $PlacedClipCopyWith(PlacedClip value, $Res Function(PlacedClip) _then) = _$PlacedClipCopyWithImpl;
@useResult
$Res call({
 int startUs, Clip clip
});


$ClipCopyWith<$Res> get clip;

}
/// @nodoc
class _$PlacedClipCopyWithImpl<$Res>
    implements $PlacedClipCopyWith<$Res> {
  _$PlacedClipCopyWithImpl(this._self, this._then);

  final PlacedClip _self;
  final $Res Function(PlacedClip) _then;

/// Create a copy of PlacedClip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startUs = null,Object? clip = null,}) {
  return _then(PlacedClip(
startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,clip: null == clip ? _self.clip : clip // ignore: cast_nullable_to_non_nullable
as Clip,
  ));
}
/// Create a copy of PlacedClip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClipCopyWith<$Res> get clip {
  
  return $ClipCopyWith<$Res>(_self.clip, (value) {
    return _then(_self.copyWith(clip: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlacedClip].
extension PlacedClipPatterns on PlacedClip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlacedClip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlacedClip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlacedClip value)  $default,){
final _that = this;
switch (_that) {
case _PlacedClip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlacedClip value)?  $default,){
final _that = this;
switch (_that) {
case _PlacedClip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int startUs,  Clip clip)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlacedClip() when $default != null:
return $default(_that.startUs,_that.clip);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int startUs,  Clip clip)  $default,) {final _that = this;
switch (_that) {
case _PlacedClip():
return $default(_that.startUs,_that.clip);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int startUs,  Clip clip)?  $default,) {final _that = this;
switch (_that) {
case _PlacedClip() when $default != null:
return $default(_that.startUs,_that.clip);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlacedClip extends PlacedClip {
  const _PlacedClip({required this.startUs, required this.clip}): super._();
  factory _PlacedClip.fromJson(Map<String, dynamic> json) => _$PlacedClipFromJson(json);

@override final  int startUs;
@override final  Clip clip;

/// Create a copy of PlacedClip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlacedClipCopyWith<_PlacedClip> get copyWith => __$PlacedClipCopyWithImpl<_PlacedClip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlacedClipToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlacedClip&&(identical(other.startUs, startUs) || other.startUs == startUs)&&(identical(other.clip, clip) || other.clip == clip));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startUs,clip);
}

@override
String toString() {
    return 'PlacedClip(startUs: $startUs, clip: $clip)';
}


}

/// @nodoc
abstract mixin class _$PlacedClipCopyWith<$Res> implements $PlacedClipCopyWith<$Res> {
  factory _$PlacedClipCopyWith(_PlacedClip value, $Res Function(_PlacedClip) _then) = __$PlacedClipCopyWithImpl;
@override @useResult
$Res call({
 int startUs, Clip clip
});


@override $ClipCopyWith<$Res> get clip;

}
/// @nodoc
class __$PlacedClipCopyWithImpl<$Res>
    implements _$PlacedClipCopyWith<$Res> {
  __$PlacedClipCopyWithImpl(this._self, this._then);

  final _PlacedClip _self;
  final $Res Function(_PlacedClip) _then;

/// Create a copy of PlacedClip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startUs = null,Object? clip = null,}) {
  return _then(_PlacedClip(
startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,clip: null == clip ? _self.clip : clip // ignore: cast_nullable_to_non_nullable
as Clip,
  ));
}

/// Create a copy of PlacedClip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClipCopyWith<$Res> get clip {
  
  return $ClipCopyWith<$Res>(_self.clip, (value) {
    return _then(_self.copyWith(clip: value));
  });
}
}


/// @nodoc
mixin _$LayerTrack {

 String get id; List<PlacedClip> get items;
/// Create a copy of LayerTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LayerTrackCopyWith<LayerTrack> get copyWith => _$LayerTrackCopyWithImpl<LayerTrack>(this as LayerTrack, _$identity);

  /// Serializes this LayerTrack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LayerTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LayerTrack&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LayerTrack;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as LayerTrack;
  return 'LayerTrack(id: ${_this.id}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $LayerTrackCopyWith<$Res>  {
  factory $LayerTrackCopyWith(LayerTrack value, $Res Function(LayerTrack) _then) = _$LayerTrackCopyWithImpl;
@useResult
$Res call({
 String id, List<PlacedClip> items
});




}
/// @nodoc
class _$LayerTrackCopyWithImpl<$Res>
    implements $LayerTrackCopyWith<$Res> {
  _$LayerTrackCopyWithImpl(this._self, this._then);

  final LayerTrack _self;
  final $Res Function(LayerTrack) _then;

/// Create a copy of LayerTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? items = null,}) {
  return _then(LayerTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PlacedClip>,
  ));
}

}


/// Adds pattern-matching-related methods to [LayerTrack].
extension LayerTrackPatterns on LayerTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LayerTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LayerTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LayerTrack value)  $default,){
final _that = this;
switch (_that) {
case _LayerTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LayerTrack value)?  $default,){
final _that = this;
switch (_that) {
case _LayerTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  List<PlacedClip> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LayerTrack() when $default != null:
return $default(_that.id,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  List<PlacedClip> items)  $default,) {final _that = this;
switch (_that) {
case _LayerTrack():
return $default(_that.id,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  List<PlacedClip> items)?  $default,) {final _that = this;
switch (_that) {
case _LayerTrack() when $default != null:
return $default(_that.id,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LayerTrack extends LayerTrack {
  const _LayerTrack({required this.id,  List<PlacedClip> items = const <PlacedClip>[]}): _items = items,super._();
  factory _LayerTrack.fromJson(Map<String, dynamic> json) => _$LayerTrackFromJson(json);

@override final  String id;
 final  List<PlacedClip> _items;
@override@JsonKey() List<PlacedClip> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of LayerTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LayerTrackCopyWith<_LayerTrack> get copyWith => __$LayerTrackCopyWithImpl<_LayerTrack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LayerTrackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LayerTrack&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'LayerTrack(id: $id, items: $items)';
}


}

/// @nodoc
abstract mixin class _$LayerTrackCopyWith<$Res> implements $LayerTrackCopyWith<$Res> {
  factory _$LayerTrackCopyWith(_LayerTrack value, $Res Function(_LayerTrack) _then) = __$LayerTrackCopyWithImpl;
@override @useResult
$Res call({
 String id, List<PlacedClip> items
});




}
/// @nodoc
class __$LayerTrackCopyWithImpl<$Res>
    implements _$LayerTrackCopyWith<$Res> {
  __$LayerTrackCopyWithImpl(this._self, this._then);

  final _LayerTrack _self;
  final $Res Function(_LayerTrack) _then;

/// Create a copy of LayerTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? items = null,}) {
  return _then(_LayerTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PlacedClip>,
  ));
}


}


/// @nodoc
mixin _$PlacedAudioClip {

 int get startUs; AudioClip get clip;
/// Create a copy of PlacedAudioClip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlacedAudioClipCopyWith<PlacedAudioClip> get copyWith => _$PlacedAudioClipCopyWithImpl<PlacedAudioClip>(this as PlacedAudioClip, _$identity);

  /// Serializes this PlacedAudioClip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlacedAudioClip;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlacedAudioClip&&(identical(other.startUs, _this.startUs) || other.startUs == _this.startUs)&&(identical(other.clip, _this.clip) || other.clip == _this.clip));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlacedAudioClip;
  return Object.hash(runtimeType,_this.startUs,_this.clip);
}

@override
String toString() {
  final _this = this as PlacedAudioClip;
  return 'PlacedAudioClip(startUs: ${_this.startUs}, clip: ${_this.clip})';
}


}

/// @nodoc
abstract mixin class $PlacedAudioClipCopyWith<$Res>  {
  factory $PlacedAudioClipCopyWith(PlacedAudioClip value, $Res Function(PlacedAudioClip) _then) = _$PlacedAudioClipCopyWithImpl;
@useResult
$Res call({
 int startUs, AudioClip clip
});


$AudioClipCopyWith<$Res> get clip;

}
/// @nodoc
class _$PlacedAudioClipCopyWithImpl<$Res>
    implements $PlacedAudioClipCopyWith<$Res> {
  _$PlacedAudioClipCopyWithImpl(this._self, this._then);

  final PlacedAudioClip _self;
  final $Res Function(PlacedAudioClip) _then;

/// Create a copy of PlacedAudioClip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startUs = null,Object? clip = null,}) {
  return _then(PlacedAudioClip(
startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,clip: null == clip ? _self.clip : clip // ignore: cast_nullable_to_non_nullable
as AudioClip,
  ));
}
/// Create a copy of PlacedAudioClip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioClipCopyWith<$Res> get clip {
  
  return $AudioClipCopyWith<$Res>(_self.clip, (value) {
    return _then(_self.copyWith(clip: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlacedAudioClip].
extension PlacedAudioClipPatterns on PlacedAudioClip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlacedAudioClip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlacedAudioClip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlacedAudioClip value)  $default,){
final _that = this;
switch (_that) {
case _PlacedAudioClip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlacedAudioClip value)?  $default,){
final _that = this;
switch (_that) {
case _PlacedAudioClip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int startUs,  AudioClip clip)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlacedAudioClip() when $default != null:
return $default(_that.startUs,_that.clip);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int startUs,  AudioClip clip)  $default,) {final _that = this;
switch (_that) {
case _PlacedAudioClip():
return $default(_that.startUs,_that.clip);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int startUs,  AudioClip clip)?  $default,) {final _that = this;
switch (_that) {
case _PlacedAudioClip() when $default != null:
return $default(_that.startUs,_that.clip);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlacedAudioClip extends PlacedAudioClip {
  const _PlacedAudioClip({required this.startUs, required this.clip}): super._();
  factory _PlacedAudioClip.fromJson(Map<String, dynamic> json) => _$PlacedAudioClipFromJson(json);

@override final  int startUs;
@override final  AudioClip clip;

/// Create a copy of PlacedAudioClip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlacedAudioClipCopyWith<_PlacedAudioClip> get copyWith => __$PlacedAudioClipCopyWithImpl<_PlacedAudioClip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlacedAudioClipToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlacedAudioClip&&(identical(other.startUs, startUs) || other.startUs == startUs)&&(identical(other.clip, clip) || other.clip == clip));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startUs,clip);
}

@override
String toString() {
    return 'PlacedAudioClip(startUs: $startUs, clip: $clip)';
}


}

/// @nodoc
abstract mixin class _$PlacedAudioClipCopyWith<$Res> implements $PlacedAudioClipCopyWith<$Res> {
  factory _$PlacedAudioClipCopyWith(_PlacedAudioClip value, $Res Function(_PlacedAudioClip) _then) = __$PlacedAudioClipCopyWithImpl;
@override @useResult
$Res call({
 int startUs, AudioClip clip
});


@override $AudioClipCopyWith<$Res> get clip;

}
/// @nodoc
class __$PlacedAudioClipCopyWithImpl<$Res>
    implements _$PlacedAudioClipCopyWith<$Res> {
  __$PlacedAudioClipCopyWithImpl(this._self, this._then);

  final _PlacedAudioClip _self;
  final $Res Function(_PlacedAudioClip) _then;

/// Create a copy of PlacedAudioClip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startUs = null,Object? clip = null,}) {
  return _then(_PlacedAudioClip(
startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,clip: null == clip ? _self.clip : clip // ignore: cast_nullable_to_non_nullable
as AudioClip,
  ));
}

/// Create a copy of PlacedAudioClip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioClipCopyWith<$Res> get clip {
  
  return $AudioClipCopyWith<$Res>(_self.clip, (value) {
    return _then(_self.copyWith(clip: value));
  });
}
}


/// @nodoc
mixin _$AudioTrack {

 String get id; List<PlacedAudioClip> get items;
/// Create a copy of AudioTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioTrackCopyWith<AudioTrack> get copyWith => _$AudioTrackCopyWithImpl<AudioTrack>(this as AudioTrack, _$identity);

  /// Serializes this AudioTrack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AudioTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioTrack&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AudioTrack;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as AudioTrack;
  return 'AudioTrack(id: ${_this.id}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $AudioTrackCopyWith<$Res>  {
  factory $AudioTrackCopyWith(AudioTrack value, $Res Function(AudioTrack) _then) = _$AudioTrackCopyWithImpl;
@useResult
$Res call({
 String id, List<PlacedAudioClip> items
});




}
/// @nodoc
class _$AudioTrackCopyWithImpl<$Res>
    implements $AudioTrackCopyWith<$Res> {
  _$AudioTrackCopyWithImpl(this._self, this._then);

  final AudioTrack _self;
  final $Res Function(AudioTrack) _then;

/// Create a copy of AudioTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? items = null,}) {
  return _then(AudioTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PlacedAudioClip>,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioTrack].
extension AudioTrackPatterns on AudioTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioTrack value)  $default,){
final _that = this;
switch (_that) {
case _AudioTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioTrack value)?  $default,){
final _that = this;
switch (_that) {
case _AudioTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  List<PlacedAudioClip> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioTrack() when $default != null:
return $default(_that.id,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  List<PlacedAudioClip> items)  $default,) {final _that = this;
switch (_that) {
case _AudioTrack():
return $default(_that.id,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  List<PlacedAudioClip> items)?  $default,) {final _that = this;
switch (_that) {
case _AudioTrack() when $default != null:
return $default(_that.id,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AudioTrack extends AudioTrack {
  const _AudioTrack({required this.id,  List<PlacedAudioClip> items = const <PlacedAudioClip>[]}): _items = items,super._();
  factory _AudioTrack.fromJson(Map<String, dynamic> json) => _$AudioTrackFromJson(json);

@override final  String id;
 final  List<PlacedAudioClip> _items;
@override@JsonKey() List<PlacedAudioClip> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of AudioTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioTrackCopyWith<_AudioTrack> get copyWith => __$AudioTrackCopyWithImpl<_AudioTrack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AudioTrackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioTrack&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'AudioTrack(id: $id, items: $items)';
}


}

/// @nodoc
abstract mixin class _$AudioTrackCopyWith<$Res> implements $AudioTrackCopyWith<$Res> {
  factory _$AudioTrackCopyWith(_AudioTrack value, $Res Function(_AudioTrack) _then) = __$AudioTrackCopyWithImpl;
@override @useResult
$Res call({
 String id, List<PlacedAudioClip> items
});




}
/// @nodoc
class __$AudioTrackCopyWithImpl<$Res>
    implements _$AudioTrackCopyWith<$Res> {
  __$AudioTrackCopyWithImpl(this._self, this._then);

  final _AudioTrack _self;
  final $Res Function(_AudioTrack) _then;

/// Create a copy of AudioTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? items = null,}) {
  return _then(_AudioTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PlacedAudioClip>,
  ));
}


}

// dart format on
