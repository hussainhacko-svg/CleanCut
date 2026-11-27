// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_color.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClipFilter _$ClipFilterFromJson(Map<String, dynamic> json) => _ClipFilter(
  id: json['id'] as String,
  intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
);

Map<String, dynamic> _$ClipFilterToJson(_ClipFilter instance) =>
    <String, dynamic>{'id': instance.id, 'intensity': instance.intensity};

_ClipAdjustments _$ClipAdjustmentsFromJson(Map<String, dynamic> json) =>
    _ClipAdjustments(
      exposure: (json['exposure'] as num?)?.toDouble() ?? 0.0,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 0.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 0.0,
      warmth: (json['warmth'] as num?)?.toDouble() ?? 0.0,
      tint: (json['tint'] as num?)?.toDouble() ?? 0.0,
      highlights: (json['highlights'] as num?)?.toDouble() ?? 0.0,
      shadows: (json['shadows'] as num?)?.toDouble() ?? 0.0,
      sharpen: (json['sharpen'] as num?)?.toDouble() ?? 0.0,
      vignette: (json['vignette'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$ClipAdjustmentsToJson(_ClipAdjustments instance) =>
    <String, dynamic>{
      'exposure': instance.exposure,
      'brightness': instance.brightness,
      'contrast': instance.contrast,
      'saturation': instance.saturation,
      'warmth': instance.warmth,
      'tint': instance.tint,
      'highlights': instance.highlights,
      'shadows': instance.shadows,
      'sharpen': instance.sharpen,
      'vignette': instance.vignette,
    };
