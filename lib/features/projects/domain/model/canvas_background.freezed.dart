// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'canvas_background.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
CanvasBackground _$CanvasBackgroundFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'color':
          return ColorBackground.fromJson(
            json
          );
                case 'gradient':
          return GradientBackground.fromJson(
            json
          );
                case 'blur':
          return BlurBackground.fromJson(
            json
          );
                case 'image':
          return ImageBackground.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'CanvasBackground',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$CanvasBackground {



  /// Serializes this CanvasBackground to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CanvasBackground);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CanvasBackground()';
}


}

/// @nodoc
class $CanvasBackgroundCopyWith<$Res>  {
$CanvasBackgroundCopyWith(CanvasBackground _, $Res Function(CanvasBackground) __);
}


/// Adds pattern-matching-related methods to [CanvasBackground].
extension CanvasBackgroundPatterns on CanvasBackground {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ColorBackground value)?  color,TResult Function( GradientBackground value)?  gradient,TResult Function( BlurBackground value)?  blur,TResult Function( ImageBackground value)?  image,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ColorBackground() when color != null:
return color(_that);case GradientBackground() when gradient != null:
return gradient(_that);case BlurBackground() when blur != null:
return blur(_that);case ImageBackground() when image != null:
return image(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ColorBackground value)  color,required TResult Function( GradientBackground value)  gradient,required TResult Function( BlurBackground value)  blur,required TResult Function( ImageBackground value)  image,}){
final _that = this;
switch (_that) {
case ColorBackground():
return color(_that);case GradientBackground():
return gradient(_that);case BlurBackground():
return blur(_that);case ImageBackground():
return image(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ColorBackground value)?  color,TResult? Function( GradientBackground value)?  gradient,TResult? Function( BlurBackground value)?  blur,TResult? Function( ImageBackground value)?  image,}){
final _that = this;
switch (_that) {
case ColorBackground() when color != null:
return color(_that);case GradientBackground() when gradient != null:
return gradient(_that);case BlurBackground() when blur != null:
return blur(_that);case ImageBackground() when image != null:
return image(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int argb)?  color,TResult Function( int startArgb,  int endArgb,  double angleDegrees)?  gradient,TResult Function( double amount)?  blur,TResult Function( String uri,  double blur)?  image,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ColorBackground() when color != null:
return color(_that.argb);case GradientBackground() when gradient != null:
return gradient(_that.startArgb,_that.endArgb,_that.angleDegrees);case BlurBackground() when blur != null:
return blur(_that.amount);case ImageBackground() when image != null:
return image(_that.uri,_that.blur);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int argb)  color,required TResult Function( int startArgb,  int endArgb,  double angleDegrees)  gradient,required TResult Function( double amount)  blur,required TResult Function( String uri,  double blur)  image,}) {final _that = this;
switch (_that) {
case ColorBackground():
return color(_that.argb);case GradientBackground():
return gradient(_that.startArgb,_that.endArgb,_that.angleDegrees);case BlurBackground():
return blur(_that.amount);case ImageBackground():
return image(_that.uri,_that.blur);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int argb)?  color,TResult? Function( int startArgb,  int endArgb,  double angleDegrees)?  gradient,TResult? Function( double amount)?  blur,TResult? Function( String uri,  double blur)?  image,}) {final _that = this;
switch (_that) {
case ColorBackground() when color != null:
return color(_that.argb);case GradientBackground() when gradient != null:
return gradient(_that.startArgb,_that.endArgb,_that.angleDegrees);case BlurBackground() when blur != null:
return blur(_that.amount);case ImageBackground() when image != null:
return image(_that.uri,_that.blur);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class ColorBackground extends CanvasBackground {
  const ColorBackground({required this.argb,  String? $type}): $type = $type ?? 'color',super._();
  factory ColorBackground.fromJson(Map<String, dynamic> json) => _$ColorBackgroundFromJson(json);

 final  int argb;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of CanvasBackground
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ColorBackgroundCopyWith<ColorBackground> get copyWith => _$ColorBackgroundCopyWithImpl<ColorBackground>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ColorBackgroundToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ColorBackground&&(identical(other.argb, argb) || other.argb == argb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,argb);
}

@override
String toString() {
    return 'CanvasBackground.color(argb: $argb)';
}


}

/// @nodoc
abstract mixin class $ColorBackgroundCopyWith<$Res> implements $CanvasBackgroundCopyWith<$Res> {
  factory $ColorBackgroundCopyWith(ColorBackground value, $Res Function(ColorBackground) _then) = _$ColorBackgroundCopyWithImpl;
@useResult
$Res call({
 int argb
});




}
/// @nodoc
class _$ColorBackgroundCopyWithImpl<$Res>
    implements $ColorBackgroundCopyWith<$Res> {
  _$ColorBackgroundCopyWithImpl(this._self, this._then);

  final ColorBackground _self;
  final $Res Function(ColorBackground) _then;

/// Create a copy of CanvasBackground
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? argb = null,}) {
  return _then(ColorBackground(
argb: null == argb ? _self.argb : argb // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GradientBackground extends CanvasBackground {
  const GradientBackground({required this.startArgb, required this.endArgb, this.angleDegrees = 180,  String? $type}): $type = $type ?? 'gradient',super._();
  factory GradientBackground.fromJson(Map<String, dynamic> json) => _$GradientBackgroundFromJson(json);

 final  int startArgb;
 final  int endArgb;
@JsonKey() final  double angleDegrees;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of CanvasBackground
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GradientBackgroundCopyWith<GradientBackground> get copyWith => _$GradientBackgroundCopyWithImpl<GradientBackground>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GradientBackgroundToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GradientBackground&&(identical(other.startArgb, startArgb) || other.startArgb == startArgb)&&(identical(other.endArgb, endArgb) || other.endArgb == endArgb)&&(identical(other.angleDegrees, angleDegrees) || other.angleDegrees == angleDegrees));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startArgb,endArgb,angleDegrees);
}

@override
String toString() {
    return 'CanvasBackground.gradient(startArgb: $startArgb, endArgb: $endArgb, angleDegrees: $angleDegrees)';
}


}

/// @nodoc
abstract mixin class $GradientBackgroundCopyWith<$Res> implements $CanvasBackgroundCopyWith<$Res> {
  factory $GradientBackgroundCopyWith(GradientBackground value, $Res Function(GradientBackground) _then) = _$GradientBackgroundCopyWithImpl;
@useResult
$Res call({
 int startArgb, int endArgb, double angleDegrees
});




}
/// @nodoc
class _$GradientBackgroundCopyWithImpl<$Res>
    implements $GradientBackgroundCopyWith<$Res> {
  _$GradientBackgroundCopyWithImpl(this._self, this._then);

  final GradientBackground _self;
  final $Res Function(GradientBackground) _then;

/// Create a copy of CanvasBackground
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startArgb = null,Object? endArgb = null,Object? angleDegrees = null,}) {
  return _then(GradientBackground(
startArgb: null == startArgb ? _self.startArgb : startArgb // ignore: cast_nullable_to_non_nullable
as int,endArgb: null == endArgb ? _self.endArgb : endArgb // ignore: cast_nullable_to_non_nullable
as int,angleDegrees: null == angleDegrees ? _self.angleDegrees : angleDegrees // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BlurBackground extends CanvasBackground {
  const BlurBackground({this.amount = 0.5,  String? $type}): $type = $type ?? 'blur',super._();
  factory BlurBackground.fromJson(Map<String, dynamic> json) => _$BlurBackgroundFromJson(json);

@JsonKey() final  double amount;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of CanvasBackground
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlurBackgroundCopyWith<BlurBackground> get copyWith => _$BlurBackgroundCopyWithImpl<BlurBackground>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlurBackgroundToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BlurBackground&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,amount);
}

@override
String toString() {
    return 'CanvasBackground.blur(amount: $amount)';
}


}

/// @nodoc
abstract mixin class $BlurBackgroundCopyWith<$Res> implements $CanvasBackgroundCopyWith<$Res> {
  factory $BlurBackgroundCopyWith(BlurBackground value, $Res Function(BlurBackground) _then) = _$BlurBackgroundCopyWithImpl;
@useResult
$Res call({
 double amount
});




}
/// @nodoc
class _$BlurBackgroundCopyWithImpl<$Res>
    implements $BlurBackgroundCopyWith<$Res> {
  _$BlurBackgroundCopyWithImpl(this._self, this._then);

  final BlurBackground _self;
  final $Res Function(BlurBackground) _then;

/// Create a copy of CanvasBackground
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? amount = null,}) {
  return _then(BlurBackground(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ImageBackground extends CanvasBackground {
  const ImageBackground({required this.uri, this.blur = 0,  String? $type}): $type = $type ?? 'image',super._();
  factory ImageBackground.fromJson(Map<String, dynamic> json) => _$ImageBackgroundFromJson(json);

 final  String uri;
@JsonKey() final  double blur;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of CanvasBackground
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageBackgroundCopyWith<ImageBackground> get copyWith => _$ImageBackgroundCopyWithImpl<ImageBackground>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImageBackgroundToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageBackground&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.blur, blur) || other.blur == blur));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,uri,blur);
}

@override
String toString() {
    return 'CanvasBackground.image(uri: $uri, blur: $blur)';
}


}

/// @nodoc
abstract mixin class $ImageBackgroundCopyWith<$Res> implements $CanvasBackgroundCopyWith<$Res> {
  factory $ImageBackgroundCopyWith(ImageBackground value, $Res Function(ImageBackground) _then) = _$ImageBackgroundCopyWithImpl;
@useResult
$Res call({
 String uri, double blur
});




}
/// @nodoc
class _$ImageBackgroundCopyWithImpl<$Res>
    implements $ImageBackgroundCopyWith<$Res> {
  _$ImageBackgroundCopyWithImpl(this._self, this._then);

  final ImageBackground _self;
  final $Res Function(ImageBackground) _then;

/// Create a copy of CanvasBackground
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? uri = null,Object? blur = null,}) {
  return _then(ImageBackground(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,blur: null == blur ? _self.blur : blur // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
