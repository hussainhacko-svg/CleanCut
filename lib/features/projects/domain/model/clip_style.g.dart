// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_style.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CropRect _$CropRectFromJson(Map<String, dynamic> json) => _CropRect(
  left: (json['left'] as num?)?.toDouble() ?? 0,
  top: (json['top'] as num?)?.toDouble() ?? 0,
  right: (json['right'] as num?)?.toDouble() ?? 1,
  bottom: (json['bottom'] as num?)?.toDouble() ?? 1,
  aspect: json['aspect'] == null
      ? null
      : CanvasAspect.fromJson(json['aspect'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CropRectToJson(_CropRect instance) => <String, dynamic>{
  'left': instance.left,
  'top': instance.top,
  'right': instance.right,
  'bottom': instance.bottom,
  'aspect': instance.aspect?.toJson(),
};

_ClipBorder _$ClipBorderFromJson(Map<String, dynamic> json) => _ClipBorder(
  width: (json['width'] as num?)?.toDouble() ?? 0,
  argb: (json['argb'] as num?)?.toInt() ?? 0xFFFFFFFF,
  radius: (json['radius'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$ClipBorderToJson(_ClipBorder instance) =>
    <String, dynamic>{
      'width': instance.width,
      'argb': instance.argb,
      'radius': instance.radius,
    };
