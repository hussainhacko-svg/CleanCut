// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speed_curve.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CurvePoint _$CurvePointFromJson(Map<String, dynamic> json) => _CurvePoint(
  x: (json['x'] as num).toDouble(),
  speed: (json['speed'] as num).toDouble(),
);

Map<String, dynamic> _$CurvePointToJson(_CurvePoint instance) =>
    <String, dynamic>{'x': instance.x, 'speed': instance.speed};

_SpeedCurve _$SpeedCurveFromJson(Map<String, dynamic> json) => _SpeedCurve(
  preset: $enumDecode(_$SpeedCurvePresetEnumMap, json['preset']),
  points: (json['points'] as List<dynamic>)
      .map((e) => CurvePoint.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SpeedCurveToJson(_SpeedCurve instance) =>
    <String, dynamic>{
      'preset': _$SpeedCurvePresetEnumMap[instance.preset]!,
      'points': instance.points.map((e) => e.toJson()).toList(),
    };

const _$SpeedCurvePresetEnumMap = {
  SpeedCurvePreset.custom: 'custom',
  SpeedCurvePreset.montage: 'montage',
  SpeedCurvePreset.hero: 'hero',
  SpeedCurvePreset.bullet: 'bullet',
  SpeedCurvePreset.flashIn: 'flashIn',
  SpeedCurvePreset.flashOut: 'flashOut',
};
