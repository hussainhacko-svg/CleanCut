// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Clip _$ClipFromJson(Map<String, dynamic> json) => _Clip(
  id: json['id'] as String,
  media: MediaRef.fromJson(json['media'] as Map<String, dynamic>),
  sourceInUs: (json['sourceInUs'] as num).toInt(),
  sourceOutUs: (json['sourceOutUs'] as num).toInt(),
  speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
  speedCurve: json['speedCurve'] == null
      ? null
      : SpeedCurve.fromJson(json['speedCurve'] as Map<String, dynamic>),
  keepPitch: json['keepPitch'] as bool? ?? true,
  transform: json['transform'] == null
      ? const ClipTransform()
      : ClipTransform.fromJson(json['transform'] as Map<String, dynamic>),
  fitMode:
      $enumDecodeNullable(_$FitModeEnumMap, json['fitMode']) ?? FitMode.fit,
  crop: json['crop'] == null
      ? CropRect.full
      : CropRect.fromJson(json['crop'] as Map<String, dynamic>),
  border: json['border'] == null
      ? const ClipBorder()
      : ClipBorder.fromJson(json['border'] as Map<String, dynamic>),
  filter: json['filter'] == null
      ? null
      : ClipFilter.fromJson(json['filter'] as Map<String, dynamic>),
  adjustments: json['adjustments'] == null
      ? ClipAdjustments.none
      : ClipAdjustments.fromJson(json['adjustments'] as Map<String, dynamic>),
  blur: json['blur'] == null
      ? const Animatable<double>.constant(0)
      : const AnimatableDoubleConverter().fromJson(
          json['blur'] as Map<String, dynamic>,
        ),
  mask: json['mask'] == null
      ? null
      : ClipMask.fromJson(json['mask'] as Map<String, dynamic>),
  volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
  muted: json['muted'] as bool? ?? false,
);

Map<String, dynamic> _$ClipToJson(_Clip instance) => <String, dynamic>{
  'id': instance.id,
  'media': instance.media.toJson(),
  'sourceInUs': instance.sourceInUs,
  'sourceOutUs': instance.sourceOutUs,
  'speed': instance.speed,
  'speedCurve': instance.speedCurve?.toJson(),
  'keepPitch': instance.keepPitch,
  'transform': instance.transform.toJson(),
  'fitMode': _$FitModeEnumMap[instance.fitMode]!,
  'crop': instance.crop.toJson(),
  'border': instance.border.toJson(),
  'filter': instance.filter?.toJson(),
  'adjustments': instance.adjustments.toJson(),
  'blur': const AnimatableDoubleConverter().toJson(instance.blur),
  'mask': instance.mask?.toJson(),
  'volume': instance.volume,
  'muted': instance.muted,
};

const _$FitModeEnumMap = {
  FitMode.fit: 'fit',
  FitMode.fill: 'fill',
  FitMode.stretch: 'stretch',
};

_AudioClip _$AudioClipFromJson(Map<String, dynamic> json) => _AudioClip(
  id: json['id'] as String,
  media: MediaRef.fromJson(json['media'] as Map<String, dynamic>),
  sourceInUs: (json['sourceInUs'] as num).toInt(),
  sourceOutUs: (json['sourceOutUs'] as num).toInt(),
  speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
  volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
  fadeInUs: (json['fadeInUs'] as num?)?.toInt() ?? 0,
  fadeOutUs: (json['fadeOutUs'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AudioClipToJson(_AudioClip instance) =>
    <String, dynamic>{
      'id': instance.id,
      'media': instance.media.toJson(),
      'sourceInUs': instance.sourceInUs,
      'sourceOutUs': instance.sourceOutUs,
      'speed': instance.speed,
      'volume': instance.volume,
      'fadeInUs': instance.fadeInUs,
      'fadeOutUs': instance.fadeOutUs,
    };
