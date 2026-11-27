import 'dart:math' as math;

import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Width and height in canvas pixels (pure Dart, no Flutter dependency).
typedef CanvasSize2D = ({double width, double height});

/// Returns the clip's base displayed size inside a [canvasWidth] ×
/// [canvasHeight] canvas before scale, rotation and position apply.
///
/// Matches `ClipFrameGeometry.of` in `ClipLook.kt`.
CanvasSize2D fittedClipSize({
  required double canvasWidth,
  required double canvasHeight,
  required double sourceRatio,
  required CropRect crop,
  required FitMode fitMode,
}) {
  if (canvasWidth <= 0 || canvasHeight <= 0) {
    return (width: 0, height: 0);
  }
  final safeRatio = sourceRatio > 0 && sourceRatio.isFinite
      ? sourceRatio
      : canvasWidth / canvasHeight;
  final cropW = crop.width > 0 ? crop.width : 1.0;
  final cropH = crop.height > 0 ? crop.height : 1.0;
  final croppedRatio = safeRatio * (cropW / cropH);
  final canvasRatio = canvasWidth / canvasHeight;
  return switch (fitMode) {
    FitMode.fit =>
      croppedRatio >= canvasRatio
          ? (width: canvasWidth, height: canvasWidth / croppedRatio)
          : (width: canvasHeight * croppedRatio, height: canvasHeight),
    FitMode.fill =>
      croppedRatio >= canvasRatio
          ? (width: canvasHeight * croppedRatio, height: canvasHeight)
          : (width: canvasWidth, height: canvasWidth / croppedRatio),
    FitMode.stretch => (width: canvasWidth, height: canvasHeight),
  };
}

/// Active snap guides during an on-preview transform gesture.
@immutable
final class TransformSnap {
  /// Creates a snap state.
  const new({
    this.centerX = false,
    this.centerY = false,
    this.leftEdge = false,
    this.rightEdge = false,
    this.topEdge = false,
    this.bottomEdge = false,
    this.rotationDegrees,
  });

  /// No guides active.
  static const none = TransformSnap();

  /// Clip center is snapped to the canvas vertical center line.
  final bool centerX;

  /// Clip center is snapped to the canvas horizontal center line.
  final bool centerY;

  /// Clip left bounding edge is snapped to the canvas left edge.
  final bool leftEdge;

  /// Clip right bounding edge is snapped to the canvas right edge.
  final bool rightEdge;

  /// Clip top bounding edge is snapped to the canvas top edge.
  final bool topEdge;

  /// Clip bottom bounding edge is snapped to the canvas bottom edge.
  final bool bottomEdge;

  /// Snapped cardinal angle (`0`, `90`, `180`, or `270`), or null when free.
  final int? rotationDegrees;

  /// Whether at least one snap guide is active.
  bool get hasAny =>
      centerX ||
      centerY ||
      leftEdge ||
      rightEdge ||
      topEdge ||
      bottomEdge ||
      rotationDegrees != null;

  /// Whether any snap target newly engaged compared to [previous].
  bool hasNewSnapSince(TransformSnap previous) =>
      (centerX && !previous.centerX) ||
      (centerY && !previous.centerY) ||
      (leftEdge && !previous.leftEdge) ||
      (rightEdge && !previous.rightEdge) ||
      (topEdge && !previous.topEdge) ||
      (bottomEdge && !previous.bottomEdge) ||
      (rotationDegrees != null && rotationDegrees != previous.rotationDegrees);

  @override
  bool operator ==(Object other) =>
      other is TransformSnap &&
      other.centerX == centerX &&
      other.centerY == centerY &&
      other.leftEdge == leftEdge &&
      other.rightEdge == rightEdge &&
      other.topEdge == topEdge &&
      other.bottomEdge == bottomEdge &&
      other.rotationDegrees == rotationDegrees;

  @override
  int get hashCode => Object.hash(
    centerX,
    centerY,
    leftEdge,
    rightEdge,
    topEdge,
    bottomEdge,
    rotationDegrees,
  );
}

/// Output of [snapClipTransform].
typedef SnappedTransform = ({
  Vec2 position,
  double scale,
  double rotation,
  TransformSnap snap,
});

/// Default pixel snap radius for center and canvas edges.
const double defaultTransformPositionSnapPx = 8;

/// Default angular snap radius in degrees for 0° / 90° / 180° / 270°.
const double defaultTransformRotationSnapDegrees = 5;

/// Snaps a raw preview transform against the canvas center, canvas edges,
/// and 90° rotation intervals, clamping into [TransformLimits].
///
/// The returned rotation is wrapped into `[-180, 180]` (the range the
/// rotation rulers show), so a long twist never stores e.g. 400°.
SnappedTransform snapClipTransform({
  required Vec2 rawPosition,
  required double rawScale,
  required double rawRotation,
  required double canvasWidth,
  required double canvasHeight,
  required double sourceRatio,
  required CropRect crop,
  required FitMode fitMode,
  bool snapPosition = true,
  bool snapRotation = false,
  double positionSnapPx = defaultTransformPositionSnapPx,
  double rotationSnapDegrees = defaultTransformRotationSnapDegrees,
}) {
  final scale = TransformLimits.clampScale(rawScale);
  var rotation = rawRotation.isFinite ? rawRotation : 0.0;
  int? snappedRotation;

  if (snapRotation && rotationSnapDegrees >= 0) {
    final nearestQuarter = (rotation / 90).round() * 90.0;
    if ((rotation - nearestQuarter).abs() <= rotationSnapDegrees) {
      rotation = _cleanZero(nearestQuarter);
      snappedRotation = ((nearestQuarter.round() % 360) + 360) % 360;
    }
  }

  final clamped = TransformLimits.clampPosition(rawPosition);
  var x = _cleanZero(clamped.x);
  var y = _cleanZero(clamped.y);
  var centerX = false;
  var centerY = false;
  var leftEdge = false;
  var rightEdge = false;
  var topEdge = false;
  var bottomEdge = false;

  if (snapPosition &&
      canvasWidth > 0 &&
      canvasHeight > 0 &&
      positionSnapPx >= 0) {
    final base = fittedClipSize(
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      sourceRatio: sourceRatio,
      crop: crop,
      fitMode: fitMode,
    );
    final halfW = base.width * scale / 2;
    final halfH = base.height * scale / 2;
    final rad = rotation * math.pi / 180;
    final c = math.cos(rad).abs();
    final s = math.sin(rad).abs();
    final aabbHalfW = halfW * c + halfH * s;
    final aabbHalfH = halfW * s + halfH * c;
    final normHalfW = aabbHalfW / (canvasWidth / 2);
    final normHalfH = aabbHalfH / (canvasHeight / 2);

    final threshX = positionSnapPx / (canvasWidth / 2);
    final threshY = positionSnapPx / (canvasHeight / 2);

    final snappedX = _snapAxis(x, normHalfW, threshX);
    x = snappedX.value;
    centerX = snappedX.kind == _AxisSnap.center;
    leftEdge = snappedX.kind == _AxisSnap.startEdge;
    rightEdge = snappedX.kind == _AxisSnap.endEdge;

    final snappedY = _snapAxis(y, normHalfH, threshY);
    y = snappedY.value;
    centerY = snappedY.kind == _AxisSnap.center;
    topEdge = snappedY.kind == _AxisSnap.startEdge;
    bottomEdge = snappedY.kind == _AxisSnap.endEdge;
  }

  return (
    position: Vec2(x: x, y: y),
    scale: scale,
    rotation: wrapDegrees(rotation),
    snap: TransformSnap(
      centerX: centerX,
      centerY: centerY,
      leftEdge: leftEdge,
      rightEdge: rightEdge,
      topEdge: topEdge,
      bottomEdge: bottomEdge,
      rotationDegrees: snappedRotation,
    ),
  );
}

enum _AxisSnap { none, center, startEdge, endEdge }

({double value, _AxisSnap kind}) _snapAxis(
  double raw,
  double normHalfExtent,
  double threshold,
) {
  final candidates = <(_AxisSnap, double)>[
    // Center first so ties on full-canvas clips prefer the center guide.
    (_AxisSnap.center, 0),
    (_AxisSnap.startEdge, -1 + normHalfExtent),
    (_AxisSnap.endEdge, 1 - normHalfExtent),
  ];

  var bestKind = _AxisSnap.none;
  var bestTarget = raw;
  var bestDist = threshold + 1;

  for (final (kind, target) in candidates) {
    if (target.abs() > TransformLimits.maxOffset) continue;
    final dist = (raw - target).abs();
    if (dist <= threshold && dist < bestDist - 1e-9) {
      bestDist = dist;
      bestTarget = target;
      bestKind = kind;
    }
  }

  return (value: _cleanZero(bestTarget), kind: bestKind);
}

double _cleanZero(double value) => value == 0 ? 0.0 : value;
