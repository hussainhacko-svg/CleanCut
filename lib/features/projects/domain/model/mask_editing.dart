import 'dart:math' as math;

import 'package:cleancut/features/projects/domain/model/clip_effects.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/transform_editing.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// A 2D point in canvas or local pixel coordinates (pure Dart).
typedef Point2D = ({double x, double y});

/// Which on-preview handle of a mask is being dragged.
enum MaskHandle {
  /// Moves the mask center.
  move,

  /// Adjusts width (`size.x`), or uniform size for heart/star.
  width,

  /// Adjusts height (`size.y`), or band thickness for mirror.
  height,

  /// Adjusts edge softness (`feather`).
  feather,

  /// Rotates the mask around its center (used for linear).
  rotate,
}

/// Active magnetic snap guides while editing a mask on the preview.
@immutable
final class MaskSnap {
  /// Creates a snap state.
  const new({this.centerX = false, this.centerY = false, this.rotationDegrees});

  /// No guides active.
  static const none = MaskSnap();

  /// Mask center is snapped to the clip's vertical center axis.
  final bool centerX;

  /// Mask center is snapped to the clip's horizontal center axis.
  final bool centerY;

  /// Snapped cardinal angle (`0`, `90`, `180`, `270`), or null when free.
  final int? rotationDegrees;

  /// Whether any guide is active.
  bool get hasAny => centerX || centerY || rotationDegrees != null;

  /// Whether any guide newly engaged compared to [previous].
  bool hasNewSnapSince(MaskSnap previous) =>
      (centerX && !previous.centerX) ||
      (centerY && !previous.centerY) ||
      (rotationDegrees != null && rotationDegrees != previous.rotationDegrees);

  @override
  bool operator ==(Object other) =>
      other is MaskSnap &&
      other.centerX == centerX &&
      other.centerY == centerY &&
      other.rotationDegrees == rotationDegrees;

  @override
  int get hashCode => Object.hash(centerX, centerY, rotationDegrees);
}

/// Pixel-space frame of a clip on the preview canvas (matching
/// `ClipFrameGeometry` in `ClipLook.kt`).
final class MaskClipFrame {
  /// Creates the clip frame geometry.
  const new({
    required this.centerX,
    required this.centerY,
    required this.halfWidth,
    required this.halfHeight,
    required this.rotationDegrees,
  });

  /// Computes the clip's displayed frame on a `[canvasWidth] × [canvasHeight]`
  /// canvas.
  factory fromClip({
    required double canvasWidth,
    required double canvasHeight,
    required double sourceRatio,
    required CropRect crop,
    required FitMode fitMode,
    required ResolvedTransform transform,
  }) {
    final base = fittedClipSize(
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      sourceRatio: sourceRatio,
      crop: crop,
      fitMode: fitMode,
    );
    return MaskClipFrame(
      centerX: canvasWidth / 2 + transform.position.x * canvasWidth / 2,
      centerY: canvasHeight / 2 + transform.position.y * canvasHeight / 2,
      halfWidth: math.max(1, base.width * transform.scale / 2),
      halfHeight: math.max(1, base.height * transform.scale / 2),
      rotationDegrees: transform.rotation,
    );
  }

  /// Clip center X in canvas pixels.
  final double centerX;

  /// Clip center Y in canvas pixels.
  final double centerY;

  /// Half of the clip's displayed width in canvas pixels.
  final double halfWidth;

  /// Half of the clip's displayed height in canvas pixels.
  final double halfHeight;

  /// Clip clockwise rotation in degrees.
  final double rotationDegrees;

  /// Reference half-side used for mask radii and feather:
  /// `min(halfWidth, halfHeight)`.
  double get refSide => math.min(halfWidth, halfHeight);

  /// Converts a canvas pixel point into clip-local unrotated pixels
  /// (origin at clip center, `[-halfWidth, halfWidth]`).
  Point2D canvasToClipLocal(Point2D canvasPoint) {
    final dx = canvasPoint.x - centerX;
    final dy = canvasPoint.y - centerY;
    final rad = rotationDegrees * math.pi / 180;
    final c = math.cos(rad);
    final s = math.sin(rad);
    return (x: c * dx + s * dy, y: -s * dx + c * dy);
  }

  /// Converts a clip-local unrotated pixel point back to canvas pixels.
  Point2D clipLocalToCanvas(Point2D local) {
    final rad = rotationDegrees * math.pi / 180;
    final c = math.cos(rad);
    final s = math.sin(rad);
    return (
      x: centerX + c * local.x - s * local.y,
      y: centerY + s * local.x + c * local.y,
    );
  }

  /// Converts a mask-local pixel point (origin at mask center, rotated by
  /// `mask.rotation` inside the clip) to canvas pixels.
  Point2D maskLocalToCanvas(ResolvedMask mask, Point2D maskPoint) {
    final rad = mask.rotation * math.pi / 180;
    final c = math.cos(rad);
    final s = math.sin(rad);
    final cx = mask.center.x * halfWidth;
    final cy = mask.center.y * halfHeight;
    return clipLocalToCanvas((
      x: cx + c * maskPoint.x - s * maskPoint.y,
      y: cy + s * maskPoint.x + c * maskPoint.y,
    ));
  }

  /// Converts a canvas pixel point into mask-local unrotated pixels.
  Point2D canvasToMaskLocal(ResolvedMask mask, Point2D canvasPoint) {
    final local = canvasToClipLocal(canvasPoint);
    final dx = local.x - mask.center.x * halfWidth;
    final dy = local.y - mask.center.y * halfHeight;
    final rad = mask.rotation * math.pi / 180;
    final c = math.cos(rad);
    final s = math.sin(rad);
    return (x: c * dx + s * dy, y: -s * dx + c * dy);
  }

  /// Mask pixel half-extents `(rx, ry)`.
  Point2D maskRadiiPx(ResolvedMask mask) =>
      (x: mask.size.x * refSide, y: mask.size.y * refSide);

  /// Feather width in canvas pixels.
  double featherPx(ResolvedMask mask) => mask.feather * refSide;

  /// Positions of the interactive handles in canvas pixels for [shape].
  Map<MaskHandle, Point2D> handlePositions(MaskShape shape, ResolvedMask mask) {
    final r = maskRadiiPx(mask);
    final featherOffset = featherPx(mask) * 0.5 + 24;
    return switch (shape) {
      MaskShape.linear => {
        MaskHandle.rotate: maskLocalToCanvas(mask, (
          x: math.min(refSide * 0.65, 90),
          y: 0,
        )),
        MaskHandle.feather: maskLocalToCanvas(mask, (x: 0, y: featherOffset)),
      },
      MaskShape.mirror => {
        MaskHandle.height: maskLocalToCanvas(mask, (x: 0, y: -r.y)),
        MaskHandle.feather: maskLocalToCanvas(mask, (
          x: 0,
          y: r.y + featherOffset,
        )),
      },
      MaskShape.circle || MaskShape.rect => {
        MaskHandle.width: maskLocalToCanvas(mask, (x: r.x, y: 0)),
        MaskHandle.height: maskLocalToCanvas(mask, (x: 0, y: -r.y)),
        MaskHandle.feather: maskLocalToCanvas(mask, (
          x: 0,
          y: r.y + featherOffset,
        )),
      },
      MaskShape.heart || MaskShape.star => {
        MaskHandle.width: maskLocalToCanvas(mask, (x: r.x, y: 0)),
        MaskHandle.feather: maskLocalToCanvas(mask, (
          x: 0,
          y: r.y + featherOffset,
        )),
      },
    };
  }
}

/// Default pixel snap threshold for the mask center.
const double defaultMaskCenterSnapPx = 8;

/// Default angular snap threshold in degrees for cardinal mask rotations.
const double defaultMaskRotationSnapDegrees = 5;

/// Snaps a raw mask center against the clip's center axes `(0, 0)`.
({Vec2 center, bool snapX, bool snapY}) snapMaskCenter({
  required Vec2 rawCenter,
  required MaskClipFrame frame,
  double snapPx = defaultMaskCenterSnapPx,
}) {
  final clamped = MaskLimits.clampCenter(rawCenter);
  var x = clamped.x;
  var y = clamped.y;
  var snapX = false;
  var snapY = false;
  if (snapPx >= 0 && frame.halfWidth > 0 && frame.halfHeight > 0) {
    if ((x * frame.halfWidth).abs() <= snapPx) {
      x = 0;
      snapX = true;
    }
    if ((y * frame.halfHeight).abs() <= snapPx) {
      y = 0;
      snapY = true;
    }
  }
  return (center: Vec2(x: x, y: y), snapX: snapX, snapY: snapY);
}

/// Snaps a raw mask rotation against multiples of 90°.
({double rotation, int? snappedDegrees}) snapMaskRotation(
  double rawRotation, {
  double snapDegrees = defaultMaskRotationSnapDegrees,
}) {
  var rot = rawRotation.isFinite ? rawRotation : 0.0;
  int? snapped;
  if (snapDegrees >= 0) {
    final nearest = (rot / 90).round() * 90.0;
    if ((rot - nearest).abs() <= snapDegrees) {
      rot = nearest == 0 ? 0.0 : nearest;
      snapped = ((nearest.round() % 360) + 360) % 360;
    }
  }
  return (rotation: wrapDegrees(rot), snappedDegrees: snapped);
}

/// Computes the updated mask value after dragging [handle] to [canvasPoint].
({Vec2? size, double? feather, double? rotation, int? snappedDegrees})
dragMaskHandle({
  required MaskShape shape,
  required MaskHandle handle,
  required ResolvedMask startMask,
  required MaskClipFrame frame,
  required Point2D canvasPoint,
}) {
  final mp = frame.canvasToMaskLocal(startMask, canvasPoint);
  final ref = math.max<double>(1, frame.refSide);
  switch (handle) {
    case MaskHandle.move:
      return (size: null, feather: null, rotation: null, snappedDegrees: null);
    case MaskHandle.width:
      final nextX = (mp.x.abs() / ref).clamp(
        MaskLimits.minSize,
        MaskLimits.maxSize,
      );
      final uniform = shape == MaskShape.heart || shape == MaskShape.star;
      final nextSize = uniform
          ? Vec2(x: nextX, y: nextX)
          : Vec2(x: nextX, y: startMask.size.y);
      return (
        size: MaskLimits.clampSize(nextSize),
        feather: null,
        rotation: null,
        snappedDegrees: null,
      );
    case MaskHandle.height:
      final nextY = (mp.y.abs() / ref).clamp(
        MaskLimits.minSize,
        MaskLimits.maxSize,
      );
      return (
        size: MaskLimits.clampSize(Vec2(x: startMask.size.x, y: nextY)),
        feather: null,
        rotation: null,
        snappedDegrees: null,
      );
    case MaskHandle.feather:
      final edgeY = shape == MaskShape.linear ? 0 : startMask.size.y * ref;
      // Handle sits 24px outside the edge at feather == 0.
      final rawFeather = ((mp.y - edgeY - 24) * 2) / ref;
      return (
        size: null,
        feather: MaskLimits.clampFeather(rawFeather),
        rotation: null,
        snappedDegrees: null,
      );
    case MaskHandle.rotate:
      final local = frame.canvasToClipLocal(canvasPoint);
      final dx = local.x - startMask.center.x * frame.halfWidth;
      final dy = local.y - startMask.center.y * frame.halfHeight;
      if (dx * dx + dy * dy < 1e-4) {
        return (
          size: null,
          feather: null,
          rotation: startMask.rotation,
          snappedDegrees: null,
        );
      }
      final rawDeg = math.atan2(dy, dx) * 180 / math.pi;
      final snapped = snapMaskRotation(rawDeg);
      return (
        size: null,
        feather: null,
        rotation: snapped.rotation,
        snappedDegrees: snapped.snappedDegrees,
      );
  }
}
