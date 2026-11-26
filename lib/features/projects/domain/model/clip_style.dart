import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'clip_style.freezed.dart';
part 'clip_style.g.dart';

/// The part of a clip's source frame that is shown, in normalized
/// coordinates of the *displayed* frame (after the media's rotation):
/// `(0, 0)` is the top-left corner, `(1, 1)` the bottom-right one.
@freezed
abstract class CropRect with _$CropRect {
  /// Creates a crop rectangle. Use [validate] to check it.
  ///
  /// [aspect] is the preset the user locked the crop to, or `null` for a
  /// free crop. It only steers the crop handles; the rectangle is the
  /// truth.
  const factory({
    @Default(0) double left,
    @Default(0) double top,
    @Default(1) double right,
    @Default(1) double bottom,
    CanvasAspect? aspect,
  }) = _CropRect;

  const new _();

  /// Parses a crop from JSON.
  factory fromJson(Map<String, dynamic> json) => _$CropRectFromJson(json);

  /// The largest centered crop of [aspect] inside a source whose displayed
  /// width-to-height ratio is [sourceRatio].
  ///
  /// Throws an [ArgumentError] for a non-positive [sourceRatio].
  factory centered(CanvasAspect aspect, double sourceRatio) {
    if (!(sourceRatio > 0) || !sourceRatio.isFinite) {
      throw ArgumentError.value(sourceRatio, 'sourceRatio', 'must be > 0');
    }
    // Width as a fraction of the source width when the crop is full height.
    final w = aspect.ratio / sourceRatio;
    if (w <= 1) {
      return CropRect(left: (1 - w) / 2, right: (1 + w) / 2, aspect: aspect);
    }
    final h = 1 / w;
    return CropRect(top: (1 - h) / 2, bottom: (1 + h) / 2, aspect: aspect);
  }

  /// No crop: the whole frame.
  static const full = CropRect();

  /// Smallest allowed side, as a fraction of the source side.
  static const double minSide = 0.05;

  /// Width as a fraction of the source width.
  double get width => right - left;

  /// Height as a fraction of the source height.
  double get height => bottom - top;

  /// Whether the whole frame is shown.
  bool get isFull => left == 0 && top == 0 && right == 1 && bottom == 1;

  /// Broken invariants, empty when the crop is valid.
  List<String> validate() => [
    if (left < 0 || top < 0 || right > 1 || bottom > 1) 'outside the frame',
    if (width < minSide - 1e-9 || height < minSide - 1e-9) 'too small',
  ];
}

/// Limits of [ClipBorder] values.
abstract final class BorderLimits {
  /// Thickest border, as a fraction of the canvas short side.
  static const double maxWidth = 0.05;

  /// Roundest corners: half the clip's shorter side makes a pill/circle.
  static const double maxRadius = 0.5;
}

/// A clip's border and rounded corners.
///
/// - `width`: stroke thickness as a fraction of the canvas short side,
///   `[0, BorderLimits.maxWidth]`; 0 draws no stroke.
/// - `argb`: stroke color, 0xAARRGGBB.
/// - `radius`: corner radius as a fraction of the clip's shorter displayed
///   side, `[0, BorderLimits.maxRadius]`. Corners are rounded even
///   without a stroke.
@freezed
abstract class ClipBorder with _$ClipBorder {
  /// Creates a border; the defaults draw nothing.
  const factory({
    @Default(0) double width,
    @Default(0xFFFFFFFF) int argb,
    @Default(0) double radius,
  }) = _ClipBorder;

  const new _();

  /// Parses a border from JSON.
  factory fromJson(Map<String, dynamic> json) => _$ClipBorderFromJson(json);

  /// Whether the border changes nothing.
  bool get isNone => width == 0 && radius == 0;

  /// Broken invariants, empty when the border is valid.
  List<String> validate() => [
    if (!(width >= 0 && width <= BorderLimits.maxWidth)) 'width out of range',
    if (!(radius >= 0 && radius <= BorderLimits.maxRadius))
      'radius out of range',
  ];
}
