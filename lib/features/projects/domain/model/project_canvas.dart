import 'package:cleancut/features/projects/domain/model/canvas_background.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_canvas.freezed.dart';
part 'project_canvas.g.dart';

/// Width-to-height ratio of the canvas, kept as a reduced fraction.
@freezed
abstract class CanvasAspect with _$CanvasAspect {
  /// Creates an aspect ratio. Both sides must be positive.
  @Assert('width > 0 && height > 0', 'sides must be positive')
  const factory({required int width, required int height}) = _CanvasAspect;

  const new _();

  /// Reduces `width:height` (e.g. 1920:1080 becomes 16:9).
  ///
  /// Throws an [ArgumentError] when a side is not positive.
  factory reduced(int width, int height) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Aspect sides must be positive: $width:$height');
    }
    final divisor = width.gcd(height);
    return CanvasAspect(width: width ~/ divisor, height: height ~/ divisor);
  }

  /// Parses an aspect ratio from JSON.
  factory fromJson(Map<String, dynamic> json) => _$CanvasAspectFromJson(json);

  /// Landscape 16:9.
  static const landscape16x9 = CanvasAspect(width: 16, height: 9);

  /// Portrait 9:16 (stories, shorts).
  static const portrait9x16 = CanvasAspect(width: 9, height: 16);

  /// Square 1:1.
  static const square = CanvasAspect(width: 1, height: 1);

  /// Portrait 4:5.
  static const portrait4x5 = CanvasAspect(width: 4, height: 5);

  /// Portrait 3:4.
  static const portrait3x4 = CanvasAspect(width: 3, height: 4);

  /// Landscape 4:3.
  static const landscape4x3 = CanvasAspect(width: 4, height: 3);

  /// Presets offered when creating a project, in display order.
  static const List<CanvasAspect> presets = [
    portrait9x16,
    landscape16x9,
    square,
    portrait4x5,
    portrait3x4,
    landscape4x3,
  ];

  /// Width divided by height.
  double get ratio => width / height;

  /// Pixel size whose shorter side is [shortSidePx], each side rounded to
  /// an even number (required by video encoders).
  ({int width, int height}) pixelSize(int shortSidePx) {
    int even(double v) => (v / 2).round() * 2;
    return width >= height
        ? (width: even(shortSidePx * ratio), height: even(shortSidePx * 1.0))
        : (width: even(shortSidePx * 1.0), height: even(shortSidePx / ratio));
  }
}

/// Output frame settings of a project.
@freezed
abstract class ProjectCanvas with _$ProjectCanvas {
  /// Creates canvas settings.
  ///
  /// [background] fills the canvas behind the clips.
  const factory({
    @Default(CanvasAspect.landscape16x9) CanvasAspect aspect,
    @Default(1080) int shortSidePx,
    @Default(30) int fps,
    @Default(CanvasBackground.black) CanvasBackground background,
  }) = _ProjectCanvas;

  /// Parses canvas settings from JSON.
  factory fromJson(Map<String, dynamic> json) => _$ProjectCanvasFromJson(json);
}
