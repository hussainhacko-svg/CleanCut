import 'dart:async';
import 'dart:math' as math;

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/crop_editing.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// On-preview crop frame (VCLIP "Crop"): darkened scrim outside the crop box,
/// 3×3 rule-of-thirds grid, and white L-shaped corner handles.
///
/// Sits over the uncropped, fitted preview of the selected clip. Dragging any
/// corner or edge resizes the crop (respecting `crop.aspect` when locked);
/// dragging inside pans the crop rectangle.
class CropOverlay extends StatefulWidget {
  /// Creates the overlay.
  const new({
    required this.crop,
    required this.sourceRatio,
    required this.rotationDegrees,
    required this.flipX,
    required this.flipY,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  /// Current crop rectangle in source coordinates.
  final CropRect crop;

  /// Uncropped displayed `width / height` of the clip.
  final double sourceRatio;

  /// Clockwise rotation at the playhead, in degrees.
  final double rotationDegrees;

  /// Whether the clip is mirrored horizontally.
  final bool flipX;

  /// Whether the clip is flipped vertically.
  final bool flipY;

  /// Called live as the user drags a handle or pans the crop box.
  final ValueChanged<CropRect> onChanged;

  /// Called when the drag ends or cancels (to seal the undo step).
  final VoidCallback onChangeEnd;

  /// Key of the fitted frame box (for widget tests).
  @visibleForTesting
  static const frameKey = Key('cropOverlayFrame');

  /// Half the 48dp touch target around corners and edges (AGENTS.md §8).
  static const double hitRadius = 24;

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  CropHandle? _handle;
  CropRect? _startCrop;
  Offset? _startLocal;
  CropRect? _dragCrop;

  /// Rotation captured when a drag starts. Finger positions map into the
  /// frame with it for the whole drag, so a keyframed rotation changing
  /// during playback can't move the crop while the finger is still.
  double? _dragRotation;

  CropRect get _crop => _dragCrop ?? widget.crop;

  @override
  void didUpdateWidget(CropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_handle == null && _dragCrop != null) {
      _dragCrop = null;
    } else if (_handle != null &&
        widget.crop != oldWidget.crop &&
        widget.crop != _dragCrop) {
      // External edit (undo, reset, preset) cancels the active drag. It
      // still ends it (sealing its undo step), after this build.
      _handle = null;
      _startCrop = null;
      _startLocal = null;
      _dragCrop = null;
      _dragRotation = null;
      final onEnd = widget.onChangeEnd;
      WidgetsBinding.instance.addPostFrameCallback((_) => onEnd());
    }
  }

  @override
  void dispose() {
    // Removed mid-drag (panel closed, selection changed): still seal the
    // drag's undo step, after this frame.
    if (_handle != null) {
      // The finger's later events still reach this state; they must not
      // end the drag a second time.
      _handle = null;
      final onEnd = widget.onChangeEnd;
      WidgetsBinding.instance.addPostFrameCallback((_) => onEnd());
    }
    super.dispose();
  }

  Rect _cropRectPx(Size frameSize, CropRect crop) {
    final v = crop.toVisual(flipX: widget.flipX, flipY: widget.flipY);
    return Rect.fromLTRB(
      v.left * frameSize.width,
      v.top * frameSize.height,
      v.right * frameSize.width,
      v.bottom * frameSize.height,
    );
  }

  CropHandle? _hitTest(Offset point, Rect rect) {
    const r = CropOverlay.hitRadius;
    final corners = <(CropHandle, Offset)>[
      (CropHandle.topLeft, rect.topLeft),
      (CropHandle.topRight, rect.topRight),
      (CropHandle.bottomLeft, rect.bottomLeft),
      (CropHandle.bottomRight, rect.bottomRight),
    ];
    CropHandle? bestCorner;
    var bestDist = r;
    for (final (handle, corner) in corners) {
      final d = (point - corner).distance;
      if (d <= bestDist) {
        bestDist = d;
        bestCorner = handle;
      }
    }
    if (bestCorner != null) return bestCorner;

    final inY = point.dy >= rect.top - r && point.dy <= rect.bottom + r;
    final inX = point.dx >= rect.left - r && point.dx <= rect.right + r;
    final edges = <(CropHandle, double)>[
      if (inY) (CropHandle.left, (point.dx - rect.left).abs()),
      if (inY) (CropHandle.right, (point.dx - rect.right).abs()),
      if (inX) (CropHandle.top, (point.dy - rect.top).abs()),
      if (inX) (CropHandle.bottom, (point.dy - rect.bottom).abs()),
    ];
    CropHandle? bestEdge;
    var bestEdgeDist = r;
    for (final (handle, d) in edges) {
      if (d <= bestEdgeDist) {
        bestEdgeDist = d;
        bestEdge = handle;
      }
    }
    if (bestEdge != null) return bestEdge;

    if (rect.contains(point)) return CropHandle.move;
    return null;
  }

  /// Converts a point in canvas coordinates into the unrotated fitted-frame
  /// coordinate space `(0..fitW, 0..fitH)`.
  Offset _toFrameLocal(
    Offset canvasPoint,
    Size canvasSize,
    Size frameSize,
    double rotationDegrees,
  ) {
    final dx = canvasPoint.dx - canvasSize.width / 2;
    final dy = canvasPoint.dy - canvasSize.height / 2;
    final rad = rotationDegrees * math.pi / 180;
    final cos = math.cos(rad);
    final sin = math.sin(rad);
    final lx = cos * dx + sin * dy;
    final ly = -sin * dx + cos * dy;
    return Offset(lx + frameSize.width / 2, ly + frameSize.height / 2);
  }

  void _onPanStart(DragStartDetails details, Size canvasSize, Size frameSize) {
    final rotation = widget.rotationDegrees;
    final local = _toFrameLocal(
      details.localPosition,
      canvasSize,
      frameSize,
      rotation,
    );
    final hit = _hitTest(local, _cropRectPx(frameSize, _crop));
    if (hit == null) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _handle = hit;
      _dragRotation = rotation;
      _startCrop = _crop;
      _startLocal = local;
      _dragCrop = _crop;
    });
  }

  void _onPanUpdate(
    DragUpdateDetails details,
    Size canvasSize,
    Size frameSize,
  ) {
    final handle = _handle;
    final startCrop = _startCrop;
    final startLocal = _startLocal;
    final rotation = _dragRotation;
    if (handle == null ||
        startCrop == null ||
        startLocal == null ||
        rotation == null) {
      return;
    }
    if (frameSize.width <= 0 || frameSize.height <= 0) return;

    final local = _toFrameLocal(
      details.localPosition,
      canvasSize,
      frameSize,
      rotation,
    );
    final dx = (local.dx - startLocal.dx) / frameSize.width;
    final dy = (local.dy - startLocal.dy) / frameSize.height;
    final next = startCrop.dragged(
      handle,
      dx: dx,
      dy: dy,
      sourceRatio: widget.sourceRatio,
      flipX: widget.flipX,
      flipY: widget.flipY,
    );
    if (next == _dragCrop) return;
    setState(() => _dragCrop = next);
    widget.onChanged(next);
  }

  void _onPanEnd() {
    if (_handle == null) return;
    setState(() {
      _handle = null;
      _startCrop = null;
      _startLocal = null;
      _dragCrop = null;
      _dragRotation = null;
    });
    widget.onChangeEnd();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final safeRatio = widget.sourceRatio > 0 && widget.sourceRatio.isFinite
        ? widget.sourceRatio
        : 1.0;
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canvasW = constraints.maxWidth;
          final canvasH = constraints.maxHeight;
          if (canvasW <= 0 || canvasH <= 0) return const SizedBox.shrink();
          final canvasSize = Size(canvasW, canvasH);
          final canvasRatio = canvasW / canvasH;
          final fitW = safeRatio >= canvasRatio ? canvasW : canvasH * safeRatio;
          final fitH = safeRatio >= canvasRatio ? canvasW / safeRatio : canvasH;
          final frameSize = Size(fitW, fitH);
          final cropRect = _cropRectPx(frameSize, _crop);

          // GestureDetector covers the full canvas box so corner/edge targets
          // stay reachable even when the crop sits on the right/bottom edges.
          return Semantics(
            label: l10n.cropOverlayLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Hit-test the handle where the finger went down, not where
              // the drag was recognized (up to the touch slop away).
              dragStartBehavior: DragStartBehavior.down,
              onPanStart: (d) => _onPanStart(d, canvasSize, frameSize),
              onPanUpdate: (d) => _onPanUpdate(d, canvasSize, frameSize),
              onPanEnd: (_) => _onPanEnd(),
              onPanCancel: _onPanEnd,
              child: Center(
                child: Transform.rotate(
                  angle: widget.rotationDegrees * math.pi / 180,
                  child: SizedBox(
                    key: CropOverlay.frameKey,
                    width: fitW,
                    height: fitH,
                    child: CustomPaint(
                      size: frameSize,
                      painter: _CropOverlayPainter(
                        cropRect: cropRect,
                        scrimColor: scheme.scrim,
                        lineColor: scheme.onSurface,
                        dragging: _handle != null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  new({
    required this.cropRect,
    required this.scrimColor,
    required this.lineColor,
    required this.dragging,
  });

  final Rect cropRect;
  final Color scrimColor;
  final Color lineColor;
  final bool dragging;

  @override
  void paint(Canvas canvas, Size size) {
    // Darkened mask outside the crop rectangle.
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(cropRect);
    canvas.drawPath(mask, Paint()..color = scrimColor.withValues(alpha: 0.58));

    // Crisp outer border of the crop rectangle.
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = lineColor.withValues(alpha: 0.9);
    canvas.drawRect(cropRect, borderPaint);

    // 3×3 rule-of-thirds grid (kit "Crop").
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = lineColor.withValues(alpha: dragging ? 0.65 : 0.4);
    final thirdW = cropRect.width / 3;
    final thirdH = cropRect.height / 3;
    for (var i = 1; i <= 2; i++) {
      final x = cropRect.left + thirdW * i;
      final y = cropRect.top + thirdH * i;
      canvas
        ..drawLine(
          Offset(x, cropRect.top),
          Offset(x, cropRect.bottom),
          gridPaint,
        )
        ..drawLine(
          Offset(cropRect.left, y),
          Offset(cropRect.right, y),
          gridPaint,
        );
    }

    // Thick white L-shaped corner brackets (kit "Crop").
    final arm = math.min<double>(
      20,
      math.min(cropRect.width, cropRect.height) / 3,
    );
    const thickness = 3.5;
    const inset = thickness / 2;
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square
      ..color = lineColor;

    final l = cropRect.left + inset;
    final t = cropRect.top + inset;
    final r = cropRect.right - inset;
    final b = cropRect.bottom - inset;
    canvas
      // Top-left
      ..drawPath(
        Path()
          ..moveTo(l, t + arm)
          ..lineTo(l, t)
          ..lineTo(l + arm, t),
        bracket,
      )
      // Top-right
      ..drawPath(
        Path()
          ..moveTo(r - arm, t)
          ..lineTo(r, t)
          ..lineTo(r, t + arm),
        bracket,
      )
      // Bottom-left
      ..drawPath(
        Path()
          ..moveTo(l, b - arm)
          ..lineTo(l, b)
          ..lineTo(l + arm, b),
        bracket,
      )
      // Bottom-right
      ..drawPath(
        Path()
          ..moveTo(r - arm, b)
          ..lineTo(r, b)
          ..lineTo(r, b - arm),
        bracket,
      );
  }

  @override
  bool shouldRepaint(_CropOverlayPainter old) =>
      old.cropRect != cropRect ||
      old.scrimColor != scrimColor ||
      old.lineColor != lineColor ||
      old.dragging != dragging;
}
