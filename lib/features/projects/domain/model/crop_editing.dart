import 'dart:math' as math;

import 'package:cleancut/features/projects/domain/model/clip_style.dart';

/// Which part of a [CropRect] is being dragged on the preview.
enum CropHandle {
  /// Top-left corner.
  topLeft,

  /// Top-right corner.
  topRight,

  /// Bottom-left corner.
  bottomLeft,

  /// Bottom-right corner.
  bottomRight,

  /// Left edge.
  left,

  /// Right edge.
  right,

  /// Top edge.
  top,

  /// Bottom edge.
  bottom,

  /// Inside the crop rectangle (moves it without resizing).
  move,
}

/// Visual-space (flipped, pre-rotation) crop rectangle in `[0, 1] × [0, 1]`,
/// used by the on-preview overlay.
typedef VisualCropBox = ({
  double left,
  double top,
  double right,
  double bottom,
});

/// Pure-Dart crop-handle math: dragging corners, edges or the interior while
/// respecting [CropRect.minSide], `[0, 1]` bounds, optional locked aspect, and
/// flip axes.
extension CropRectEditing on CropRect {
  /// Maps this source-space crop into visual box coordinates (after [flipX]
  /// and [flipY]).
  VisualCropBox toVisual({bool flipX = false, bool flipY = false}) => (
    left: flipX ? 1 - right : left,
    top: flipY ? 1 - bottom : top,
    right: flipX ? 1 - left : right,
    bottom: flipY ? 1 - top : bottom,
  );

  /// Converts a visual box back into a [CropRect] with the same [aspect].
  CropRect fromVisual(
    VisualCropBox box, {
    bool flipX = false,
    bool flipY = false,
  }) => CropRect(
    left: flipX ? 1 - box.right : box.left,
    top: flipY ? 1 - box.bottom : box.top,
    right: flipX ? 1 - box.left : box.right,
    bottom: flipY ? 1 - box.top : box.bottom,
    aspect: aspect,
  );

  /// Returns the updated crop after dragging [handle] by normalized visual
  /// delta `(dx, dy)` (in fractions of the uncropped displayed frame).
  ///
  /// [sourceRatio] is the uncropped frame's displayed `width / height`, used
  /// when [aspect] is locked. Always returns a valid [CropRect].
  CropRect dragged(
    CropHandle handle, {
    required double dx,
    required double dy,
    required double sourceRatio,
    bool flipX = false,
    bool flipY = false,
  }) {
    if (!dx.isFinite ||
        !dy.isFinite ||
        !(sourceRatio > 0) ||
        !sourceRatio.isFinite) {
      return this;
    }
    final v = toVisual(flipX: flipX, flipY: flipY);
    final next = handle == CropHandle.move
        ? _pan(v, dx, dy)
        : switch (aspect) {
            null => _resizeFree(v, handle, dx, dy),
            final locked => _resizeLocked(
              v,
              handle,
              dx,
              dy,
              locked.ratio / sourceRatio,
            ),
          };
    return fromVisual(next, flipX: flipX, flipY: flipY);
  }
}

VisualCropBox _pan(VisualCropBox v, double dx, double dy) {
  final shiftX = dx.clamp(-v.left, 1 - v.right);
  final shiftY = dy.clamp(-v.top, 1 - v.bottom);
  return (
    left: v.left + shiftX,
    top: v.top + shiftY,
    right: v.right + shiftX,
    bottom: v.bottom + shiftY,
  );
}

VisualCropBox _resizeFree(
  VisualCropBox v,
  CropHandle handle,
  double dx,
  double dy,
) {
  const min = CropRect.minSide;
  var left = v.left;
  var top = v.top;
  var right = v.right;
  var bottom = v.bottom;

  if (handle == CropHandle.left ||
      handle == CropHandle.topLeft ||
      handle == CropHandle.bottomLeft) {
    left = (left + dx).clamp(0, right - min);
  }
  if (handle == CropHandle.right ||
      handle == CropHandle.topRight ||
      handle == CropHandle.bottomRight) {
    right = (right + dx).clamp(left + min, 1);
  }
  if (handle == CropHandle.top ||
      handle == CropHandle.topLeft ||
      handle == CropHandle.topRight) {
    top = (top + dy).clamp(0, bottom - min);
  }
  if (handle == CropHandle.bottom ||
      handle == CropHandle.bottomLeft ||
      handle == CropHandle.bottomRight) {
    bottom = (bottom + dy).clamp(top + min, 1);
  }
  return (left: left, top: top, right: right, bottom: bottom);
}

/// Resizes while maintaining `width / height == k` in normalized coordinates.
VisualCropBox _resizeLocked(
  VisualCropBox v,
  CropHandle handle,
  double dx,
  double dy,
  double k,
) {
  const minSide = CropRect.minSide;
  // Smallest width that keeps both width and height >= minSide.
  final minW = math.min<double>(1, math.max(minSide, minSide * k));
  final minH = math.min<double>(1, math.max(minSide, minSide / k));
  final curW = v.right - v.left;
  final curH = v.bottom - v.top;

  switch (handle) {
    case CropHandle.bottomRight:
      final maxW = math.min(1 - v.left, math.max(minSide, (1 - v.top) * k));
      final w = _projectedWidth(curW + dx, curH + dy, k, minW, maxW);
      final h = (w / k).clamp(minSide, 1 - v.top);
      return (left: v.left, top: v.top, right: v.left + w, bottom: v.top + h);

    case CropHandle.topLeft:
      final maxW = math.min(v.right, math.max(minSide, v.bottom * k));
      final w = _projectedWidth(curW - dx, curH - dy, k, minW, maxW);
      final h = (w / k).clamp(minSide, v.bottom);
      return (
        left: v.right - w,
        top: v.bottom - h,
        right: v.right,
        bottom: v.bottom,
      );

    case CropHandle.topRight:
      final maxW = math.min(1 - v.left, math.max(minSide, v.bottom * k));
      final w = _projectedWidth(curW + dx, curH - dy, k, minW, maxW);
      final h = (w / k).clamp(minSide, v.bottom);
      return (
        left: v.left,
        top: v.bottom - h,
        right: v.left + w,
        bottom: v.bottom,
      );

    case CropHandle.bottomLeft:
      final maxW = math.min(v.right, math.max(minSide, (1 - v.top) * k));
      final w = _projectedWidth(curW - dx, curH + dy, k, minW, maxW);
      final h = (w / k).clamp(minSide, 1 - v.top);
      return (left: v.right - w, top: v.top, right: v.right, bottom: v.top + h);

    case CropHandle.right:
      final maxW = math.min(1 - v.left, math.max(minSide, k));
      final w = (curW + dx).clamp(math.min(minW, maxW), maxW);
      final h = (w / k).clamp(minSide, 1).toDouble();
      final (top, bottom) = _centeredSpan((v.top + v.bottom) / 2, h);
      return (left: v.left, top: top, right: v.left + w, bottom: bottom);

    case CropHandle.left:
      final maxW = math.min(v.right, math.max(minSide, k));
      final w = (curW - dx).clamp(math.min(minW, maxW), maxW);
      final h = (w / k).clamp(minSide, 1).toDouble();
      final (top, bottom) = _centeredSpan((v.top + v.bottom) / 2, h);
      return (left: v.right - w, top: top, right: v.right, bottom: bottom);

    case CropHandle.bottom:
      final maxH = math.min(1 - v.top, math.max(minSide, 1 / k));
      final h = (curH + dy).clamp(math.min(minH, maxH), maxH);
      final w = (h * k).clamp(minSide, 1).toDouble();
      final (left, right) = _centeredSpan((v.left + v.right) / 2, w);
      return (left: left, top: v.top, right: right, bottom: v.top + h);

    case CropHandle.top:
      final maxH = math.min(v.bottom, math.max(minSide, 1 / k));
      final h = (curH - dy).clamp(math.min(minH, maxH), maxH);
      final w = (h * k).clamp(minSide, 1).toDouble();
      final (left, right) = _centeredSpan((v.left + v.right) / 2, w);
      return (left: left, top: v.bottom - h, right: right, bottom: v.bottom);

    case CropHandle.move:
      return _pan(v, dx, dy);
  }
}

/// Projects target `(targetW, targetH)` onto the locked aspect line `w = k * h`
/// and clamps into `[min(minW, maxW), maxW]`.
double _projectedWidth(
  double targetW,
  double targetH,
  double k,
  double minW,
  double maxW,
) {
  final h = (targetW * k + targetH) / (k * k + 1);
  return (h * k).clamp(math.min(minW, maxW), maxW);
}

/// Centers a span of length [length] at [center], shifting it inside `[0, 1]`.
(double, double) _centeredSpan(double center, double length) {
  var start = center - length / 2;
  var end = start + length;
  if (start < 0) {
    start = 0;
    end = length;
  } else if (end > 1) {
    end = 1;
    start = 1 - length;
  }
  return (start.clamp(0, 1), end.clamp(0, 1));
}
