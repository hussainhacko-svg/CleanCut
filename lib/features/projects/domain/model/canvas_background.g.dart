// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_background.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ColorBackground _$ColorBackgroundFromJson(Map<String, dynamic> json) =>
    ColorBackground(
      argb: (json['argb'] as num).toInt(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ColorBackgroundToJson(ColorBackground instance) =>
    <String, dynamic>{'argb': instance.argb, 'type': instance.$type};

GradientBackground _$GradientBackgroundFromJson(Map<String, dynamic> json) =>
    GradientBackground(
      startArgb: (json['startArgb'] as num).toInt(),
      endArgb: (json['endArgb'] as num).toInt(),
      angleDegrees: (json['angleDegrees'] as num?)?.toDouble() ?? 180,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$GradientBackgroundToJson(GradientBackground instance) =>
    <String, dynamic>{
      'startArgb': instance.startArgb,
      'endArgb': instance.endArgb,
      'angleDegrees': instance.angleDegrees,
      'type': instance.$type,
    };

BlurBackground _$BlurBackgroundFromJson(Map<String, dynamic> json) =>
    BlurBackground(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.5,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$BlurBackgroundToJson(BlurBackground instance) =>
    <String, dynamic>{'amount': instance.amount, 'type': instance.$type};

ImageBackground _$ImageBackgroundFromJson(Map<String, dynamic> json) =>
    ImageBackground(
      uri: json['uri'] as String,
      blur: (json['blur'] as num?)?.toDouble() ?? 0,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ImageBackgroundToJson(ImageBackground instance) =>
    <String, dynamic>{
      'uri': instance.uri,
      'blur': instance.blur,
      'type': instance.$type,
    };
