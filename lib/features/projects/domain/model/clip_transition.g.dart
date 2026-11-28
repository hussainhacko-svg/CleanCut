// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_transition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClipTransition _$ClipTransitionFromJson(Map<String, dynamic> json) =>
    _ClipTransition(
      type: $enumDecode(_$TransitionTypeEnumMap, json['type']),
      durationUs:
          (json['durationUs'] as num?)?.toInt() ??
          TransitionLimits.defaultDurationUs,
    );

Map<String, dynamic> _$ClipTransitionToJson(_ClipTransition instance) =>
    <String, dynamic>{
      'type': _$TransitionTypeEnumMap[instance.type]!,
      'durationUs': instance.durationUs,
    };

const _$TransitionTypeEnumMap = {
  TransitionType.dissolve: 'dissolve',
  TransitionType.fadeBlack: 'fadeBlack',
  TransitionType.fadeWhite: 'fadeWhite',
  TransitionType.circle: 'circle',
  TransitionType.slideLeft: 'slideLeft',
  TransitionType.slideRight: 'slideRight',
  TransitionType.slideUp: 'slideUp',
  TransitionType.slideDown: 'slideDown',
  TransitionType.wipeLeft: 'wipeLeft',
  TransitionType.wipeRight: 'wipeRight',
  TransitionType.wipeUp: 'wipeUp',
  TransitionType.wipeDown: 'wipeDown',
  TransitionType.zoomIn: 'zoomIn',
  TransitionType.zoomOut: 'zoomOut',
};
