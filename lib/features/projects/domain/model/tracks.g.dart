// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracks.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MainTrack _$MainTrackFromJson(Map<String, dynamic> json) => _MainTrack(
  clips:
      (json['clips'] as List<dynamic>?)
          ?.map((e) => Clip.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Clip>[],
  transitions:
      (json['transitions'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, ClipTransition.fromJson(e as Map<String, dynamic>)),
      ) ??
      const <String, ClipTransition>{},
);

Map<String, dynamic> _$MainTrackToJson(
  _MainTrack instance,
) => <String, dynamic>{
  'clips': instance.clips.map((e) => e.toJson()).toList(),
  'transitions': instance.transitions.map((k, e) => MapEntry(k, e.toJson())),
};

_PlacedClip _$PlacedClipFromJson(Map<String, dynamic> json) => _PlacedClip(
  startUs: (json['startUs'] as num).toInt(),
  clip: Clip.fromJson(json['clip'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PlacedClipToJson(_PlacedClip instance) =>
    <String, dynamic>{
      'startUs': instance.startUs,
      'clip': instance.clip.toJson(),
    };

_LayerTrack _$LayerTrackFromJson(Map<String, dynamic> json) => _LayerTrack(
  id: json['id'] as String,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => PlacedClip.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PlacedClip>[],
);

Map<String, dynamic> _$LayerTrackToJson(_LayerTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

_PlacedAudioClip _$PlacedAudioClipFromJson(Map<String, dynamic> json) =>
    _PlacedAudioClip(
      startUs: (json['startUs'] as num).toInt(),
      clip: AudioClip.fromJson(json['clip'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PlacedAudioClipToJson(_PlacedAudioClip instance) =>
    <String, dynamic>{
      'startUs': instance.startUs,
      'clip': instance.clip.toJson(),
    };

_AudioTrack _$AudioTrackFromJson(Map<String, dynamic> json) => _AudioTrack(
  id: json['id'] as String,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => PlacedAudioClip.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PlacedAudioClip>[],
);

Map<String, dynamic> _$AudioTrackToJson(_AudioTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
