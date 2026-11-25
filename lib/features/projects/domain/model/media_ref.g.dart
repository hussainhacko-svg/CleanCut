// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaRef _$MediaRefFromJson(Map<String, dynamic> json) => _MediaRef(
  uri: json['uri'] as String,
  kind: $enumDecode(_$MediaKindEnumMap, json['kind']),
  durationUs: (json['durationUs'] as num?)?.toInt(),
  width: (json['width'] as num?)?.toInt() ?? 0,
  height: (json['height'] as num?)?.toInt() ?? 0,
  rotationDegrees: (json['rotationDegrees'] as num?)?.toInt() ?? 0,
  displayName: json['displayName'] as String?,
);

Map<String, dynamic> _$MediaRefToJson(_MediaRef instance) => <String, dynamic>{
  'uri': instance.uri,
  'kind': _$MediaKindEnumMap[instance.kind]!,
  'durationUs': instance.durationUs,
  'width': instance.width,
  'height': instance.height,
  'rotationDegrees': instance.rotationDegrees,
  'displayName': instance.displayName,
};

const _$MediaKindEnumMap = {
  MediaKind.video: 'video',
  MediaKind.image: 'image',
  MediaKind.audio: 'audio',
};
