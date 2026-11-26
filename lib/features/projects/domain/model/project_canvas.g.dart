// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_canvas.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CanvasAspect _$CanvasAspectFromJson(Map<String, dynamic> json) =>
    _CanvasAspect(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$CanvasAspectToJson(_CanvasAspect instance) =>
    <String, dynamic>{'width': instance.width, 'height': instance.height};

_ProjectCanvas _$ProjectCanvasFromJson(Map<String, dynamic> json) =>
    _ProjectCanvas(
      aspect: json['aspect'] == null
          ? CanvasAspect.landscape16x9
          : CanvasAspect.fromJson(json['aspect'] as Map<String, dynamic>),
      shortSidePx: (json['shortSidePx'] as num?)?.toInt() ?? 1080,
      fps: (json['fps'] as num?)?.toInt() ?? 30,
      background: json['background'] == null
          ? CanvasBackground.black
          : CanvasBackground.fromJson(
              json['background'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ProjectCanvasToJson(_ProjectCanvas instance) =>
    <String, dynamic>{
      'aspect': instance.aspect.toJson(),
      'shortSidePx': instance.shortSidePx,
      'fps': instance.fps,
      'background': instance.background.toJson(),
    };
