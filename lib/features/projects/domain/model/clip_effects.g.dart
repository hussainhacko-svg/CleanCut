// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_effects.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClipMask _$ClipMaskFromJson(Map<String, dynamic> json) => _ClipMask(
  shape: $enumDecode(_$MaskShapeEnumMap, json['shape']),
  center: json['center'] == null
      ? const Animatable<Vec2>.constant(Vec2.zero)
      : const AnimatableVec2Converter().fromJson(
          json['center'] as Map<String, dynamic>,
        ),
  size: json['size'] == null
      ? const Animatable<Vec2>.constant(MaskLimits.defaultSize)
      : const AnimatableVec2Converter().fromJson(
          json['size'] as Map<String, dynamic>,
        ),
  rotation: json['rotation'] == null
      ? const Animatable<double>.constant(0)
      : const AnimatableDoubleConverter().fromJson(
          json['rotation'] as Map<String, dynamic>,
        ),
  feather: json['feather'] == null
      ? const Animatable<double>.constant(0)
      : const AnimatableDoubleConverter().fromJson(
          json['feather'] as Map<String, dynamic>,
        ),
  invert: json['invert'] as bool? ?? false,
);

Map<String, dynamic> _$ClipMaskToJson(_ClipMask instance) => <String, dynamic>{
  'shape': _$MaskShapeEnumMap[instance.shape]!,
  'center': const AnimatableVec2Converter().toJson(instance.center),
  'size': const AnimatableVec2Converter().toJson(instance.size),
  'rotation': const AnimatableDoubleConverter().toJson(instance.rotation),
  'feather': const AnimatableDoubleConverter().toJson(instance.feather),
  'invert': instance.invert,
};

const _$MaskShapeEnumMap = {
  MaskShape.linear: 'linear',
  MaskShape.mirror: 'mirror',
  MaskShape.circle: 'circle',
  MaskShape.rect: 'rect',
  MaskShape.heart: 'heart',
  MaskShape.star: 'star',
};
