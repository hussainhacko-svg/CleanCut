import 'dart:async';
import 'dart:math' as math;

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:cleancut/features/projects/domain/model/clip_effects.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/mask_editing.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/mask_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Callback emitting whichever mask properties changed during an on-preview
/// gesture.
typedef MaskGestureCallback = void Function({
  Vec2? center,
  Vec2? size,
  double? rotation,
  double? feather,
});

/// On-preview interactive mask handles (Phase 6B):
/// - Drag anywhere to move the mask center (snaps to clip center axes).
/// - Drag width/height/rotate handles to resize or orient the mask.
/// - Drag the outward feather handle to soften or sharpen the edge.
/// - Two-finger pinch/twist to scale and rotate continuously with 90° snaps.
class MaskOverlay extends StatefulWidget {
  /// Creates the mask overlay.
  const new({
    required this.shape,
    required this.mask,
    required this.invert,
    required this.clipTransform,
    required this.sourceRatio,
    required this.crop,
    required this.fitMode,
    required this.onChanged,
    required this.onChangeEnd,
    this.onChangeStart,
    super.key,
  });

  /// Active mask shape.
  final MaskShape shape;

  /// Current resolved mask parameters at the playhead.
  final ResolvedMask mask;

  /// Whether the mask is inverted.
  final bool invert;

  /// Clip transform at the playhead (used to align mask space to pixels).
  final ResolvedTransform clipTransform;

  /// Uncropped displayed `width / height` of the clip.
  final double sourceRatio;

  /// Current clip crop rectangle.
  final CropRect crop;

  /// Current clip fit mode.
  final FitMode fitMode;

  /// Called when a gesture starts, before any [onChanged].
  final VoidCallback? onChangeStart;

  /// Called live as the user manipulates the mask.
  final MaskGestureCallback onChanged;

  /// Called once when the gesture ends or cancels (to seal the undo step).
  final VoidCallback onChangeEnd;

  /// Key of the gesture surface (for widget tests).
  @visibleForTesting
  static const canvasKey = Key('maskOverlayCanvas');

  /// Key of the snapped-angle pill shown during rotation snap.
  @visibleForTesting
  static const rotationBadgeKey = Key('maskOverlayRotationBadge');

  /// Half the 48dp touch target around each handle.
  static const double hitRadius = 24;

  /// Minimum two-finger twist in degrees before rotation engages.
  static const double rotationEngageDegrees = 3;

  @override
  State<MaskOverlay> createState() => _MaskOverlayState();
}

class _MaskOverlayState extends State<MaskOverlay> {
  bool _active = false;
  final Set<int> _pointers = {};
  Offset? _firstDownLocal;
  int _lastPointerCount = 0;

  MaskHandle _handle = MaskHandle.move;
  ResolvedMask _startMask = (
    center: Vec2.zero,
    size: MaskLimits.defaultSize,
    rotation: 0,
    feather: 0,
  );
  ResolvedMask _emitted = (
    center: Vec2.zero,
    size: MaskLimits.defaultSize,
    rotation: 0,
    feather: 0,
  );

  Vec2 _rawCenter = Vec2.zero;
  Vec2 _anchorSize = MaskLimits.defaultSize;
  double _rawRotation = 0;
  double _anchorRotation = 0;
  double _anchorGestureScale = 1;
  double _lastGestureRotation = 0;
  double _gestureRotationDeg = 0;
  bool _rotationEngaged = false;

  bool _centerEmitted = false;
  bool _sizeEmitted = false;
  bool _rotationEmitted = false;
  bool _featherEmitted = false;

  MaskSnap _snap = MaskSnap.none;
  MaskSnap _lastHapticSnap = MaskSnap.none;

  ResolvedMask get _displayMask => _active ? _emitted : widget.mask;

  @override
  void didUpdateWidget(MaskOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_active) return;
    if (widget.shape != oldWidget.shape) {
      _cancelExternal();
      return;
    }
    final m = widget.mask;
    final old = oldWidget.mask;
    final centerExt = m.center != old.center && m.center != _emitted.center;
    final sizeExt = m.size != old.size && m.size != _emitted.size;
    final rotExt =
        m.rotation != old.rotation && !sameAngle(m.rotation, _emitted.rotation);
    final featherExt =
        m.feather != old.feather && m.feather != _emitted.feather;
    if ((centerExt && _centerEmitted) ||
        (sizeExt && _sizeEmitted) ||
        (rotExt && _rotationEmitted) ||
        (featherExt && _featherEmitted)) {
      _cancelExternal();
    }
  }

  void _cancelExternal() {
    _resetGesture();
    final onEnd = widget.onChangeEnd;
    WidgetsBinding.instance.addPostFrameCallback((_) => onEnd());
  }

  @override
  void dispose() {
    if (_active) {
      _active = false;
      final onEnd = widget.onChangeEnd;
      WidgetsBinding.instance.addPostFrameCallback((_) => onEnd());
    }
    super.dispose();
  }

  void _resetGesture() {
    _active = false;
    _lastPointerCount = 0;
    _handle = MaskHandle.move;
    _rotationEngaged = false;
    _centerEmitted = false;
    _sizeEmitted = false;
    _rotationEmitted = false;
    _featherEmitted = false;
    _snap = MaskSnap.none;
    _lastHapticSnap = MaskSnap.none;
  }

  MaskHandle _hitTestHandles(Offset point, Map<MaskHandle, Point2D> handles) {
    MaskHandle? best;
    var bestDist = MaskOverlay.hitRadius;
    for (final entry in handles.entries) {
      final d = (point - Offset(entry.value.x, entry.value.y)).distance;
      if (d <= bestDist) {
        bestDist = d;
        best = entry.key;
      }
    }
    return best ?? MaskHandle.move;
  }

  void _onScaleStart(ScaleStartDetails details, MaskClipFrame frame) {
    if (_active) {
      _lastPointerCount = details.pointerCount;
      _anchorSize = _emitted.size;
      _anchorRotation = _rawRotation;
      _anchorGestureScale = 1;
      _lastGestureRotation = 0;
      _gestureRotationDeg = 0;
      if (details.pointerCount >= 2) {
        _handle = MaskHandle.move;
      } else {
        _rotationEngaged = false;
      }
      return;
    }

    final touch = _firstDownLocal ?? details.localFocalPoint;
    final handles = frame.handlePositions(widget.shape, widget.mask);
    final hit = details.pointerCount >= 2
        ? MaskHandle.move
        : _hitTestHandles(touch, handles);
    if (hit != MaskHandle.move) {
      unawaited(HapticFeedback.selectionClick());
    }
    final initialCenterSnap = snapMaskCenter(
      rawCenter: widget.mask.center,
      frame: frame,
    );
    final initialRotSnap = snapMaskRotation(widget.mask.rotation);
    setState(() {
      _active = true;
      _lastPointerCount = details.pointerCount;
      _handle = hit;
      _startMask = widget.mask;
      _emitted = widget.mask;
      _rawCenter = widget.mask.center;
      _anchorSize = widget.mask.size;
      _rawRotation = widget.mask.rotation;
      _anchorRotation = widget.mask.rotation;
      _anchorGestureScale = 1;
      _lastGestureRotation = 0;
      _gestureRotationDeg = 0;
      _rotationEngaged = false;
      _centerEmitted = false;
      _sizeEmitted = false;
      _rotationEmitted = false;
      _featherEmitted = false;
      _snap = MaskSnap.none;
      _lastHapticSnap = MaskSnap(
        centerX: initialCenterSnap.snapX,
        centerY: initialCenterSnap.snapY,
        rotationDegrees: initialRotSnap.snappedDegrees,
      );
    });
    widget.onChangeStart?.call();
  }

  void _onScaleUpdate(ScaleUpdateDetails details, MaskClipFrame frame) {
    if (!_active) return;

    if (details.pointerCount != _lastPointerCount) {
      _anchorSize = _emitted.size;
      _anchorRotation = _rawRotation;
      _anchorGestureScale = details.scale > 0 ? details.scale : 1;
      _lastGestureRotation = details.rotation;
      _gestureRotationDeg = 0;
      if (details.pointerCount >= 2) {
        _handle = MaskHandle.move;
      } else {
        _rotationEngaged = false;
      }
      _lastPointerCount = details.pointerCount;
    }

    // Single-finger dedicated handle drag (width, height, feather, rotate).
    if (details.pointerCount < 2 && _handle != MaskHandle.move) {
      final pt = details.localFocalPoint;
      final res = dragMaskHandle(
        shape: widget.shape,
        handle: _handle,
        startMask: _startMask,
        frame: frame,
        canvasPoint: (x: pt.dx, y: pt.dy),
      );
      final nextSnap = MaskSnap(rotationDegrees: res.snappedDegrees);
      if (nextSnap.hasNewSnapSince(_lastHapticSnap)) {
        unawaited(HapticFeedback.selectionClick());
      }
      _lastHapticSnap = nextSnap;

      final emitSize = res.size != null && res.size != _emitted.size
          ? res.size
          : null;
      final emitFeather = res.feather != null && res.feather != _emitted.feather
          ? res.feather
          : null;
      final emitRot =
          res.rotation != null && !sameAngle(res.rotation!, _emitted.rotation)
          ? res.rotation
          : null;
      setState(() {
        _snap = nextSnap;
        if (emitSize != null) {
          _emitted = (
            center: _emitted.center,
            size: emitSize,
            rotation: _emitted.rotation,
            feather: _emitted.feather,
          );
          _sizeEmitted = true;
        }
        if (emitFeather != null) {
          _emitted = (
            center: _emitted.center,
            size: _emitted.size,
            rotation: _emitted.rotation,
            feather: emitFeather,
          );
          _featherEmitted = true;
        }
        if (emitRot != null) {
          _rawRotation = emitRot;
          _emitted = (
            center: _emitted.center,
            size: _emitted.size,
            rotation: emitRot,
            feather: _emitted.feather,
          );
          _rotationEmitted = true;
        }
      });
      if (emitSize != null || emitFeather != null || emitRot != null) {
        widget.onChanged(
          size: emitSize,
          feather: emitFeather,
          rotation: emitRot,
        );
      }
      return;
    }

    // Move + optional 2-finger pinch/twist.
    var moved = false;
    if (details.focalPointDelta != Offset.zero) {
      moved = true;
      final rad = frame.rotationDegrees * math.pi / 180;
      final c = math.cos(rad);
      final s = math.sin(rad);
      final d = details.focalPointDelta;
      final localDx = c * d.dx + s * d.dy;
      final localDy = -s * d.dx + c * d.dy;
      _rawCenter = MaskLimits.clampCenter(
        Vec2(
          x: _rawCenter.x + localDx / frame.halfWidth,
          y: _rawCenter.y + localDy / frame.halfHeight,
        ),
      );
    }

    Vec2? nextSize;
    final multiTouch = details.pointerCount >= 2;
    if (multiTouch) {
      if (widget.shape != MaskShape.linear &&
          details.scale > 0 &&
          _anchorGestureScale > 0) {
        final factor = details.scale / _anchorGestureScale;
        nextSize = MaskLimits.clampSize(
          widget.shape == MaskShape.mirror
              ? Vec2(x: _anchorSize.x, y: _anchorSize.y * factor)
              : Vec2(x: _anchorSize.x * factor, y: _anchorSize.y * factor),
        );
      }
      var stepRad = details.rotation - _lastGestureRotation;
      while (stepRad > math.pi) {
        stepRad -= 2 * math.pi;
      }
      while (stepRad < -math.pi) {
        stepRad += 2 * math.pi;
      }
      _lastGestureRotation = details.rotation;
      _gestureRotationDeg += stepRad * 180 / math.pi;
      if (!_rotationEngaged &&
          _gestureRotationDeg.abs() >= MaskOverlay.rotationEngageDegrees) {
        _rotationEngaged = true;
      }
      if (_rotationEngaged) {
        _rawRotation = _anchorRotation + _gestureRotationDeg;
      }
    }

    final centerRes = moved
        ? snapMaskCenter(rawCenter: _rawCenter, frame: frame)
        : (center: _emitted.center, snapX: false, snapY: false);
    final rotRes = _rotationEngaged
        ? snapMaskRotation(_rawRotation)
        : (rotation: _emitted.rotation, snappedDegrees: null);

    final nextSnap = MaskSnap(
      centerX: centerRes.snapX,
      centerY: centerRes.snapY,
      rotationDegrees: rotRes.snappedDegrees,
    );
    final nextHaptic = MaskSnap(
      centerX: moved ? nextSnap.centerX : _lastHapticSnap.centerX,
      centerY: moved ? nextSnap.centerY : _lastHapticSnap.centerY,
      rotationDegrees: _rotationEngaged
          ? nextSnap.rotationDegrees
          : _lastHapticSnap.rotationDegrees,
    );
    if (nextHaptic.hasNewSnapSince(_lastHapticSnap)) {
      unawaited(HapticFeedback.selectionClick());
    }
    _lastHapticSnap = nextHaptic;

    final emitCenter = moved && centerRes.center != _emitted.center
        ? centerRes.center
        : null;
    final emitSize = nextSize != null && nextSize != _emitted.size
        ? nextSize
        : null;
    final emitRot = _rotationEngaged && rotRes.rotation != _emitted.rotation
        ? rotRes.rotation
        : null;

    setState(() {
      _snap = nextSnap;
      if (emitCenter != null) {
        _emitted = (
          center: emitCenter,
          size: _emitted.size,
          rotation: _emitted.rotation,
          feather: _emitted.feather,
        );
        _centerEmitted = true;
      }
      if (emitSize != null) {
        _emitted = (
          center: _emitted.center,
          size: emitSize,
          rotation: _emitted.rotation,
          feather: _emitted.feather,
        );
        _sizeEmitted = true;
      }
      if (emitRot != null) {
        _emitted = (
          center: _emitted.center,
          size: _emitted.size,
          rotation: emitRot,
          feather: _emitted.feather,
        );
        _rotationEmitted = true;
      }
    });

    if (emitCenter != null || emitSize != null || emitRot != null) {
      widget.onChanged(center: emitCenter, size: emitSize, rotation: emitRot);
    }
  }

  void _onScaleEnd() {
    if (_pointers.isNotEmpty) return;
    _finishGesture();
  }

  void _finishGesture() {
    if (!_active) return;
    setState(_resetGesture);
    widget.onChangeEnd();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointers.isEmpty) _firstDownLocal = event.localPosition;
    _pointers.add(event.pointer);
  }

  void _onPointerUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.isEmpty) {
      _firstDownLocal = null;
      _finishGesture();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gradient = AccentGradient.of(context);
    final snappedDeg = _active ? _snap.rotationDegrees : null;

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          if (w <= 0 || h <= 0) return const SizedBox.shrink();
          final frame = MaskClipFrame.fromClip(
            canvasWidth: w,
            canvasHeight: h,
            sourceRatio: widget.sourceRatio,
            crop: widget.crop,
            fitMode: widget.fitMode,
            transform: widget.clipTransform,
          );
          final mask = _displayMask;
          final handles = frame.handlePositions(widget.shape, mask);

          return Semantics(
            label: l10n.maskOverlayLabel,
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerUp,
              child: GestureDetector(
                key: MaskOverlay.canvasKey,
                behavior: HitTestBehavior.opaque,
                onScaleStart: (d) => _onScaleStart(d, frame),
                onScaleUpdate: (d) => _onScaleUpdate(d, frame),
                onScaleEnd: (_) => _onScaleEnd(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      size: Size(w, h),
                      painter: _MaskOverlayPainter(
                        shape: widget.shape,
                        mask: mask,
                        frame: frame,
                        handles: handles,
                        activeHandle: _active ? _handle : null,
                        snap: _active ? _snap : MaskSnap.none,
                        lineColor: scheme.onSurface,
                        accentColor: scheme.primary,
                        shadowColor: scheme.scrim,
                        surfaceColor: scheme.surfaceContainer,
                        guideGradient: gradient,
                      ),
                    ),
                    if (snappedDeg != null)
                      Align(
                        alignment: AlignmentDirectional.topCenter,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(top: 8),
                          child: IgnorePointer(
                            child: Container(
                              key: MaskOverlay.rotationBadgeKey,
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainer.withValues(
                                  alpha: 0.85,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: scheme.primary.withValues(alpha: 0.8),
                                ),
                              ),
                              child: Text(
                                l10n.rotationValue(snappedDeg),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontVariations: const [
                                    FontVariation.weight(600),
                                  ],
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MaskOverlayPainter extends CustomPainter {
  new({
    required this.shape,
    required this.mask,
    required this.frame,
    required this.handles,
    required this.activeHandle,
    required this.snap,
    required this.lineColor,
    required this.accentColor,
    required this.shadowColor,
    required this.surfaceColor,
    required this.guideGradient,
  });

  final MaskShape shape;
  final ResolvedMask mask;
  final MaskClipFrame frame;
  final Map<MaskHandle, Point2D> handles;
  final MaskHandle? activeHandle;
  final MaskSnap snap;
  final Color lineColor;
  final Color accentColor;
  final Color shadowColor;
  final Color surfaceColor;
  final AccentGradient guideGradient;

  @override
  void paint(Canvas canvas, Size size) {
    // Magnetic center snap guides in clip space.
    if (snap.centerX || snap.centerY) {
      final guidePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = LinearGradient(
          colors: [guideGradient.start, guideGradient.end],
        ).createShader(Offset.zero & size);
      final guideShadow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = shadowColor.withValues(alpha: 0.4);
      if (snap.centerX) {
        final a = frame.clipLocalToCanvas((x: 0, y: -frame.halfHeight));
        final b = frame.clipLocalToCanvas((x: 0, y: frame.halfHeight));
        canvas
          ..drawLine(Offset(a.x, a.y), Offset(b.x, b.y), guideShadow)
          ..drawLine(Offset(a.x, a.y), Offset(b.x, b.y), guidePaint);
      }
      if (snap.centerY) {
        final a = frame.clipLocalToCanvas((x: -frame.halfWidth, y: 0));
        final b = frame.clipLocalToCanvas((x: frame.halfWidth, y: 0));
        canvas
          ..drawLine(Offset(a.x, a.y), Offset(b.x, b.y), guideShadow)
          ..drawLine(Offset(a.x, a.y), Offset(b.x, b.y), guidePaint);
      }
    }

    // Transform canvas into mask-local space (origin at mask center).
    final centerCanvas = frame.maskLocalToCanvas(mask, (x: 0, y: 0));
    final totalRad = (frame.rotationDegrees + mask.rotation) * math.pi / 180;
    final radii = frame.maskRadiiPx(mask);
    final lineSpan = math.max(size.width, size.height);

    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = shadowColor.withValues(alpha: 0.45);
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = accentColor;

    canvas
      ..save()
      ..translate(centerCanvas.x, centerCanvas.y)
      ..rotate(totalRad);

    void drawShapeOutline(Paint p) {
      switch (shape) {
        case MaskShape.linear:
          canvas.drawLine(Offset(-lineSpan, 0), Offset(lineSpan, 0), p);
        case MaskShape.mirror:
          canvas
            ..drawLine(
              Offset(-lineSpan, -radii.y),
              Offset(lineSpan, -radii.y),
              p,
            )
            ..drawLine(
              Offset(-lineSpan, radii.y),
              Offset(lineSpan, radii.y),
              p,
            );
        case MaskShape.circle:
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: radii.x * 2,
              height: radii.y * 2,
            ),
            p,
          );
        case MaskShape.rect:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: radii.x * 2,
              height: radii.y * 2,
            ),
            p,
          );
        case MaskShape.heart:
          canvas.drawPath(buildHeartPath(Offset.zero, radii.x, radii.y), p);
        case MaskShape.star:
          canvas.drawPath(buildStarPath(Offset.zero, radii.x, radii.y), p);
      }
    }

    drawShapeOutline(haloPaint);
    drawShapeOutline(outlinePaint);

    // Subtle secondary ring indicating feather falloff distance.
    final featherHalf = frame.featherPx(mask) * 0.5;
    if (featherHalf > 1) {
      final fPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = lineColor.withValues(alpha: 0.5);
      switch (shape) {
        case MaskShape.linear:
          canvas.drawLine(
            Offset(-lineSpan, featherHalf),
            Offset(lineSpan, featherHalf),
            fPaint,
          );
        case MaskShape.mirror:
          canvas
            ..drawLine(
              Offset(-lineSpan, -(radii.y + featherHalf)),
              Offset(lineSpan, -(radii.y + featherHalf)),
              fPaint,
            )
            ..drawLine(
              Offset(-lineSpan, radii.y + featherHalf),
              Offset(lineSpan, radii.y + featherHalf),
              fPaint,
            );
        case MaskShape.circle:
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: (radii.x + featherHalf) * 2,
              height: (radii.y + featherHalf) * 2,
            ),
            fPaint,
          );
        case MaskShape.rect:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: (radii.x + featherHalf) * 2,
              height: (radii.y + featherHalf) * 2,
            ),
            fPaint,
          );
        case MaskShape.heart:
          canvas.drawPath(
            buildHeartPath(
              Offset.zero,
              radii.x + featherHalf,
              radii.y + featherHalf,
            ),
            fPaint,
          );
        case MaskShape.star:
          canvas.drawPath(
            buildStarPath(
              Offset.zero,
              radii.x + featherHalf,
              radii.y + featherHalf,
            ),
            fPaint,
          );
      }
    }

    // Center dot for direct orientation reference.
    canvas
      ..drawCircle(
        Offset.zero,
        4,
        Paint()..color = shadowColor.withValues(alpha: 0.5),
      )
      ..drawCircle(Offset.zero, 2.8, Paint()..color = lineColor)
      ..restore();

    // Draw interactive handle knobs in canvas space.
    for (final entry in handles.entries) {
      final pt = Offset(entry.value.x, entry.value.y);
      final isActive = activeHandle == entry.key;
      final isFeather = entry.key == MaskHandle.feather;
      final r = isActive ? 9.0 : 7.5;
      canvas
        ..drawCircle(
          pt,
          r + 1.5,
          Paint()..color = shadowColor.withValues(alpha: 0.45),
        )
        ..drawCircle(
          pt,
          r,
          Paint()..color = isActive ? accentColor : surfaceColor,
        )
        ..drawCircle(
          pt,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = isActive ? lineColor : accentColor,
        );
      if (isFeather) {
        // Small outward chevron inside the feather handle.
        final chevron = Path()
          ..moveTo(pt.dx - 3, pt.dy - 1.2)
          ..lineTo(pt.dx, pt.dy + 2.2)
          ..lineTo(pt.dx + 3, pt.dy - 1.2);
        canvas.drawPath(
          chevron,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = lineColor,
        );
      } else {
        canvas.drawCircle(pt, 2.5, Paint()..color = lineColor);
      }
    }
  }

  @override
  bool shouldRepaint(_MaskOverlayPainter old) =>
      old.shape != shape ||
      old.mask != mask ||
      old.frame.centerX != frame.centerX ||
      old.frame.centerY != frame.centerY ||
      old.frame.halfWidth != frame.halfWidth ||
      old.frame.halfHeight != frame.halfHeight ||
      old.frame.rotationDegrees != frame.rotationDegrees ||
      old.activeHandle != activeHandle ||
      old.snap != snap ||
      old.lineColor != lineColor ||
      old.accentColor != accentColor;
}
