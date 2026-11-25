// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Project _$ProjectFromJson(Map<String, dynamic> json) => _Project(
  id: json['id'] as String,
  name: json['name'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  schemaVersion:
      (json['schemaVersion'] as num?)?.toInt() ?? Project.currentSchemaVersion,
  canvas: json['canvas'] == null
      ? const ProjectCanvas()
      : ProjectCanvas.fromJson(json['canvas'] as Map<String, dynamic>),
  mainTrack: json['mainTrack'] == null
      ? const MainTrack()
      : MainTrack.fromJson(json['mainTrack'] as Map<String, dynamic>),
  overlayTracks:
      (json['overlayTracks'] as List<dynamic>?)
          ?.map((e) => LayerTrack.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LayerTrack>[],
  audioTracks:
      (json['audioTracks'] as List<dynamic>?)
          ?.map((e) => AudioTrack.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AudioTrack>[],
);

Map<String, dynamic> _$ProjectToJson(_Project instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'schemaVersion': instance.schemaVersion,
  'canvas': instance.canvas.toJson(),
  'mainTrack': instance.mainTrack.toJson(),
  'overlayTracks': instance.overlayTracks.map((e) => e.toJson()).toList(),
  'audioTracks': instance.audioTracks.map((e) => e.toJson()).toList(),
};
