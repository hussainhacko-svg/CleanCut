// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_transform.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClipTransform _$ClipTransformFromJson(Map<String, dynamic> json) =>
    _ClipTransform(
      position: json['position'] == null
          ? const Animatable<Vec2>.constant(Vec2.zero)
          : const AnimatableVec2Converter().fromJson(
              json['position'] as Map<String, dynamic>,
            ),
      scale: json['scale'] == null
          ? const Animatable<double>.constant(1)
          : const AnimatableDoubleConverter().fromJson(
              json['scale'] as Map<String, dynamic>,
            ),
      rotation: json['rotation'] == null
          ? const Animatable<double>.constant(0)
          : const AnimatableDoubleConverter().fromJson(
              json['rotation'] as Map<String, dynamic>,
            ),
      opacity: json['opacity'] == null
          ? const Animatable<double>.constant(1)
          : const AnimatableDoubleConverter().fromJson(
              json['opacity'] as Map<String, dynamic>,
            ),
      flipX: json['flipX'] as bool? ?? false,
      flipY: json['flipY'] as bool? ?? false,
    );

Map<String, dynamic> _$ClipTransformToJson(_ClipTransform instance) =>
    <String, dynamic>{
      'position': const AnimatableVec2Converter().toJson(instance.position),
      'scale': const AnimatableDoubleConverter().toJson(instance.scale),
      'rotation': const AnimatableDoubleConverter().toJson(instance.rotation),
      'opacity': const AnimatableDoubleConverter().toJson(instance.opacity),
      'flipX': instance.flipX,
      'flipY': instance.flipY,
    };
