// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clip_transition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClipTransition {

 TransitionType get type; int get durationUs;
/// Create a copy of ClipTransition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClipTransitionCopyWith<ClipTransition> get copyWith => _$ClipTransitionCopyWithImpl<ClipTransition>(this as ClipTransition, _$identity);

  /// Serializes this ClipTransition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ClipTransition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClipTransition&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.durationUs, _this.durationUs) || other.durationUs == _this.durationUs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ClipTransition;
  return Object.hash(runtimeType,_this.type,_this.durationUs);
}

@override
String toString() {
  final _this = this as ClipTransition;
  return 'ClipTransition(type: ${_this.type}, durationUs: ${_this.durationUs})';
}


}

/// @nodoc
abstract mixin class $ClipTransitionCopyWith<$Res>  {
  factory $ClipTransitionCopyWith(ClipTransition value, $Res Function(ClipTransition) _then) = _$ClipTransitionCopyWithImpl;
@useResult
$Res call({
 TransitionType type, int durationUs
});




}
/// @nodoc
class _$ClipTransitionCopyWithImpl<$Res>
    implements $ClipTransitionCopyWith<$Res> {
  _$ClipTransitionCopyWithImpl(this._self, this._then);

  final ClipTransition _self;
  final $Res Function(ClipTransition) _then;

/// Create a copy of ClipTransition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? durationUs = null,}) {
  return _then(ClipTransition(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransitionType,durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ClipTransition].
extension ClipTransitionPatterns on ClipTransition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClipTransition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClipTransition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClipTransition value)  $default,){
final _that = this;
switch (_that) {
case _ClipTransition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClipTransition value)?  $default,){
final _that = this;
switch (_that) {
case _ClipTransition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TransitionType type,  int durationUs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClipTransition() when $default != null:
return $default(_that.type,_that.durationUs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TransitionType type,  int durationUs)  $default,) {final _that = this;
switch (_that) {
case _ClipTransition():
return $default(_that.type,_that.durationUs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TransitionType type,  int durationUs)?  $default,) {final _that = this;
switch (_that) {
case _ClipTransition() when $default != null:
return $default(_that.type,_that.durationUs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClipTransition extends ClipTransition {
  const _ClipTransition({required this.type, this.durationUs = TransitionLimits.defaultDurationUs}): super._();
  factory _ClipTransition.fromJson(Map<String, dynamic> json) => _$ClipTransitionFromJson(json);

@override final  TransitionType type;
@override@JsonKey() final  int durationUs;

/// Create a copy of ClipTransition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClipTransitionCopyWith<_ClipTransition> get copyWith => __$ClipTransitionCopyWithImpl<_ClipTransition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClipTransitionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClipTransition&&(identical(other.type, type) || other.type == type)&&(identical(other.durationUs, durationUs) || other.durationUs == durationUs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,durationUs);
}

@override
String toString() {
    return 'ClipTransition(type: $type, durationUs: $durationUs)';
}


}

/// @nodoc
abstract mixin class _$ClipTransitionCopyWith<$Res> implements $ClipTransitionCopyWith<$Res> {
  factory _$ClipTransitionCopyWith(_ClipTransition value, $Res Function(_ClipTransition) _then) = __$ClipTransitionCopyWithImpl;
@override @useResult
$Res call({
 TransitionType type, int durationUs
});




}
/// @nodoc
class __$ClipTransitionCopyWithImpl<$Res>
    implements _$ClipTransitionCopyWith<$Res> {
  __$ClipTransitionCopyWithImpl(this._self, this._then);

  final _ClipTransition _self;
  final $Res Function(_ClipTransition) _then;

/// Create a copy of ClipTransition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? durationUs = null,}) {
  return _then(_ClipTransition(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransitionType,durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
