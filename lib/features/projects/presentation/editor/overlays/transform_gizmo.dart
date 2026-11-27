import 'dart:async';
import 'dart:math' as math;

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/transform_editing.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Callback emitting whichever transform properties changed during a preview
/// gesture.
typedef TransformGestureCallback = void Function({
  Vec2? position,
  double? scale,
  double? rotation,
});

/// On-preview direct manipulation gizmo for a selected clip: 1-finger drag to
/// move, 2-finger pinch/twist to scale and rotate, with magnetic snap guides
/// (canvas center X/Y, canvas edges, and 0°/90°/180°/270°) and haptic ticks.
class TransformGizmo extends StatefulWidget {
  /// Creates the gizmo.
  const new({
    required this.position,
    required this.scale,
    required this.rotation,
    required this.sourceRatio,
    required this.crop,
    required this.fitMode,
    required this.onChanged,
    required this.onChangeEnd,
    this.onChangeStart,
    this.showFrame = false,
    super.key,
  });

  /// Current normalized center offset (`Vec2.zero` is canvas center).
  final Vec2 position;

  /// Current uniform scale factor (`1` is fitted size).
  final double scale;

  /// Current clockwise rotation in degrees.
  final double rotation;

  /// Uncropped displayed `width / height` of the clip.
  final double sourceRatio;

  /// Current clip crop rectangle.
  final CropRect crop;

  /// Current clip fit mode.
  final FitMode fitMode;

  /// Whether to keep the clip outline visible when idle (e.g. while the
  /// Transform panel is open). While gesturing, the outline always shows.
  final bool showFrame;

  /// Called live as the user moves, scales, or rotates the clip.
  final TransformGestureCallback onChanged;

  /// Called when a gesture starts, before any [onChanged].
  final VoidCallback? onChangeStart;

  /// Called once when a gesture ends, including when an outside change
  /// (undo, reset, a panel slider) cancels it mid-gesture. Always pairs with
  /// [onChangeStart].
  final VoidCallback onChangeEnd;

  /// Key of the gesture surface (for widget tests).
  @visibleForTesting
  static const canvasKey = Key('transformGizmoCanvas');

  /// Key of the snapped-angle badge shown when rotation snaps to a 90° angle.
  @visibleForTesting
  static const rotationBadgeKey = Key('transformGizmoRotationBadge');

  /// Minimum two-finger twist in degrees before rotation engages, preventing
  /// accidental tilt during a pure pinch-zoom.
  static const double rotationEngageDegrees = 3;

  @override
  State<TransformGizmo> createState() => _TransformGizmoState();
}

class _TransformGizmoState extends State<TransformGizmo> {
  bool _active = false;

  /// Pointers currently down on the gizmo. Flutter ends and restarts a scale
  /// gesture whenever a finger is added or lifted; one touch (first finger
  /// down to last finger up) is still one gesture and one undo step.
  final Set<int> _pointers = {};
  int _lastPointerCount = 0;

  Vec2 _rawPosition = Vec2.zero;
  double _rawScale = 1;
  double _rawRotation = 0;

  Vec2 _emittedPosition = Vec2.zero;
  double _emittedScale = 1;
  double _emittedRotation = 0;

  double _anchorScale = 1;
  double _anchorRotation = 0;
  double _anchorGestureScale = 1;
  double _lastGestureRotation = 0;
  double _gestureRotationDeg = 0;
  bool _rotationEngaged = false;
  bool _positionMoved = false;

  /// Which values this gesture has reported through [TransformGizmo.onChanged].
  bool _positionEmitted = false;
  bool _scaleEmitted = false;
  bool _rotationEmitted = false;

  TransformSnap _snap = TransformSnap.none;
  TransformSnap _lastHapticSnap = TransformSnap.none;

  Vec2 get _displayPosition => _active ? _emittedPosition : widget.position;
  double get _displayScale => _active ? _emittedScale : widget.scale;
  double get _displayRotation => _active ? _emittedRotation : widget.rotation;

  @override
  void didUpdateWidget(TransformGizmo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_active) return;
    final posChangedExternally =
        widget.position != oldWidget.position &&
        widget.position != _emittedPosition;
    final scaleChangedExternally =
        widget.scale != oldWidget.scale && widget.scale != _emittedScale;
    // The model may store the emitted angle a whole turn away (it keeps
    // constants within [-180, 180] and keyframes near their neighbours).
    final rotChangedExternally =
        widget.rotation != oldWidget.rotation &&
        !sameAngle(widget.rotation, _emittedRotation);
    if ((posChangedExternally && _positionEmitted) ||
        (scaleChangedExternally && _scaleEmitted) ||
        (rotChangedExternally && _rotationEmitted)) {
      // External edit (undo, reset, panel slider) of a value this gesture
      // set cancels it. It still ends it (sealing its undo step), after this
      // build.
      _resetGesture();
      final onEnd = widget.onChangeEnd;
      WidgetsBinding.instance.addPostFrameCallback((_) => onEnd());
      return;
    }
    // A value this gesture hasn't set yet changed, e.g. because the gesture
    // locked its time a frame after the values were read while playing:
    // carry on from the new value, keeping the finger's movement so far.
    if (posChangedExternally) {
      _rawPosition = Vec2(
        x: _rawPosition.x + widget.position.x - _emittedPosition.x,
        y: _rawPosition.y + widget.position.y - _emittedPosition.y,
      );
      _emittedPosition = widget.position;
    }
    if (scaleChangedExternally && _emittedScale > 0) {
      final factor = widget.scale / _emittedScale;
      _rawScale *= factor;
      _anchorScale *= factor;
      _emittedScale = widget.scale;
    }
    if (rotChangedExternally) {
      final delta = widget.rotation - _emittedRotation;
      _rawRotation += delta;
      _anchorRotation += delta;
      _emittedRotation = widget.rotation;
    }
  }

  @override
  void dispose() {
    // Removed mid-gesture (another panel opened, the selection changed):
    // still end the gesture so its undo step is sealed, after this frame.
    if (_active) {
      // The finger's later events still reach this state; they must not
      // end the gesture a second time.
      _active = false;
      final onEnd = widget.onChangeEnd;
      WidgetsBinding.instance.addPostFrameCallback((_) => onEnd());
    }
    super.dispose();
  }

  void _resetGesture() {
    _active = false;
    _lastPointerCount = 0;
    _rotationEngaged = false;
    _positionMoved = false;
    _positionEmitted = false;
    _scaleEmitted = false;
    _rotationEmitted = false;
    _snap = TransformSnap.none;
    _lastHapticSnap = TransformSnap.none;
  }

  void _onScaleStart(ScaleStartDetails details, Size canvasSize) {
    if (_active) {
      // A finger was added or lifted mid-touch: carry on from where the
      // clip is now, re-anchoring the pinch and twist.
      _lastPointerCount = details.pointerCount;
      _anchorScale = _rawScale;
      _anchorRotation = _rawRotation;
      _anchorGestureScale = 1;
      _lastGestureRotation = 0;
      _gestureRotationDeg = 0;
      if (details.pointerCount < 2) _rotationEngaged = false;
      return;
    }
    final initial = snapClipTransform(
      rawPosition: widget.position,
      rawScale: widget.scale,
      rawRotation: widget.rotation,
      canvasWidth: canvasSize.width,
      canvasHeight: canvasSize.height,
      sourceRatio: widget.sourceRatio,
      crop: widget.crop,
      fitMode: widget.fitMode,
      snapRotation: true,
    );
    setState(() {
      _active = true;
      _lastPointerCount = details.pointerCount;
      _rawPosition = widget.position;
      _rawScale = widget.scale;
      _rawRotation = widget.rotation;
      _emittedPosition = widget.position;
      _emittedScale = widget.scale;
      _emittedRotation = widget.rotation;
      _anchorScale = widget.scale;
      _anchorRotation = widget.rotation;
      _anchorGestureScale = 1;
      _lastGestureRotation = 0;
      _gestureRotationDeg = 0;
      _rotationEngaged = false;
      _positionMoved = false;
      _positionEmitted = false;
      _scaleEmitted = false;
      _rotationEmitted = false;
      _snap = TransformSnap.none;
      _lastHapticSnap = initial.snap;
    });
    widget.onChangeStart?.call();
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size canvasSize) {
    if (!_active || canvasSize.width <= 0 || canvasSize.height <= 0) return;

    // Re-anchor scale and rotation whenever fingers are added or lifted so the
    // clip never jumps mid-gesture.
    if (details.pointerCount != _lastPointerCount) {
      _anchorScale = _rawScale;
      _anchorRotation = _rawRotation;
      _anchorGestureScale = details.scale > 0 ? details.scale : 1;
      _lastGestureRotation = details.rotation;
      _gestureRotationDeg = 0;
      if (details.pointerCount < 2) _rotationEngaged = false;
      _lastPointerCount = details.pointerCount;
    }

    if (details.focalPointDelta != Offset.zero) {
      _positionMoved = true;
      final dx = 2 * details.focalPointDelta.dx / canvasSize.width;
      final dy = 2 * details.focalPointDelta.dy / canvasSize.height;
      _rawPosition = TransformLimits.clampPosition(
        Vec2(x: _rawPosition.x + dx, y: _rawPosition.y + dy),
      );
    }

    final multiTouch = details.pointerCount >= 2;
    if (multiTouch) {
      if (details.scale > 0 && _anchorGestureScale > 0) {
        _rawScale = TransformLimits.clampScale(
          _anchorScale * (details.scale / _anchorGestureScale),
        );
      }
      // Flutter's ScaleGestureRecognizer computes rotation via raw atan2
      // subtraction, which can jump by ±2π across the horizontal axis.
      // Accumulate wrapped per-frame deltas so rotation stays continuous.
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
          _gestureRotationDeg.abs() >= TransformGizmo.rotationEngageDegrees) {
        _rotationEngaged = true;
      }
      if (_rotationEngaged) {
        _rawRotation = _anchorRotation + _gestureRotationDeg;
      }
    }

    final snapped = snapClipTransform(
      rawPosition: _rawPosition,
      rawScale: _rawScale,
      rawRotation: _rawRotation,
      canvasWidth: canvasSize.width,
      canvasHeight: canvasSize.height,
      sourceRatio: widget.sourceRatio,
      crop: widget.crop,
      fitMode: widget.fitMode,
      snapPosition: _positionMoved,
      snapRotation: _rotationEngaged,
    );

    final nextHaptic = TransformSnap(
      centerX: _positionMoved ? snapped.snap.centerX : _lastHapticSnap.centerX,
      centerY: _positionMoved ? snapped.snap.centerY : _lastHapticSnap.centerY,
      leftEdge: _positionMoved
          ? snapped.snap.leftEdge
          : _lastHapticSnap.leftEdge,
      rightEdge: _positionMoved
          ? snapped.snap.rightEdge
          : _lastHapticSnap.rightEdge,
      topEdge: _positionMoved ? snapped.snap.topEdge : _lastHapticSnap.topEdge,
      bottomEdge: _positionMoved
          ? snapped.snap.bottomEdge
          : _lastHapticSnap.bottomEdge,
      rotationDegrees: _rotationEngaged
          ? snapped.snap.rotationDegrees
          : _lastHapticSnap.rotationDegrees,
    );
    if (nextHaptic.hasNewSnapSince(_lastHapticSnap)) {
      unawaited(HapticFeedback.selectionClick());
    }
    _lastHapticSnap = nextHaptic;

    final emitPos = _positionMoved && snapped.position != _emittedPosition
        ? snapped.position
        : null;
    final emitScale = multiTouch && snapped.scale != _emittedScale
        ? snapped.scale
        : null;
    final emitRot = _rotationEngaged && snapped.rotation != _emittedRotation
        ? snapped.rotation
        : null;

    setState(() {
      _snap = snapped.snap;
      if (emitPos != null) {
        _emittedPosition = emitPos;
        _positionEmitted = true;
      }
      if (emitScale != null) {
        _emittedScale = emitScale;
        _scaleEmitted = true;
      }
      if (emitRot != null) {
        _emittedRotation = emitRot;
        _rotationEmitted = true;
      }
    });

    if (emitPos != null || emitScale != null || emitRot != null) {
      widget.onChanged(position: emitPos, scale: emitScale, rotation: emitRot);
    }
  }

  void _onScaleEnd() {
    // Fingers still down: Flutter restarts the gesture (see [_pointers]).
    if (_pointers.isNotEmpty) return;
    _finishGesture();
  }

  void _finishGesture() {
    if (!_active) return;
    setState(_resetGesture);
    widget.onChangeEnd();
  }

  void _onPointerUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.isEmpty) _finishGesture();
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
          final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
          if (canvasSize.width <= 0 || canvasSize.height <= 0) {
            return const SizedBox.shrink();
          }
          final base = fittedClipSize(
            canvasWidth: canvasSize.width,
            canvasHeight: canvasSize.height,
            sourceRatio: widget.sourceRatio,
            crop: widget.crop,
            fitMode: widget.fitMode,
          );
          final paintFrame = _active || widget.showFrame;
          return Semantics(
            label: l10n.transformGizmoLabel,
            child: Listener(
              // Tracks which fingers are down. Pointer events reach the
              // GestureDetector's recognizers first (deepest target first),
              // so _onScaleEnd still sees a lifted finger in _pointers and
              // _onPointerUp finishes the gesture instead.
              onPointerDown: (e) => _pointers.add(e.pointer),
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerUp,
              child: GestureDetector(
                key: TransformGizmo.canvasKey,
                behavior: HitTestBehavior.opaque,
                onScaleStart: (d) => _onScaleStart(d, canvasSize),
                onScaleUpdate: (d) => _onScaleUpdate(d, canvasSize),
                onScaleEnd: (_) => _onScaleEnd(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (paintFrame || _snap.hasAny)
                      CustomPaint(
                        size: canvasSize,
                        painter: _TransformGizmoPainter(
                          baseSize: Size(base.width, base.height),
                          position: _displayPosition,
                          scale: _displayScale,
                          rotationDegrees: _displayRotation,
                          showFrame: paintFrame,
                          snap: _active ? _snap : TransformSnap.none,
                          frameColor: scheme.onSurface,
                          shadowColor: scheme.scrim,
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
                              key: TransformGizmo.rotationBadgeKey,
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

class _TransformGizmoPainter extends CustomPainter {
  new({
    required this.baseSize,
    required this.position,
    required this.scale,
    required this.rotationDegrees,
    required this.showFrame,
    required this.snap,
    required this.frameColor,
    required this.shadowColor,
    required this.guideGradient,
  });

  final Size baseSize;
  final Vec2 position;
  final double scale;
  final double rotationDegrees;
  final bool showFrame;
  final TransformSnap snap;
  final Color frameColor;
  final Color shadowColor;
  final AccentGradient guideGradient;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2 + position.x * size.width / 2;
    final cy = size.height / 2 + position.y * size.height / 2;
    final halfW = baseSize.width * scale / 2;
    final halfH = baseSize.height * scale / 2;

    if (showFrame && halfW > 0 && halfH > 0) {
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: halfW * 2,
        height: halfH * 2,
      );
      canvas
        ..save()
        ..translate(cx, cy)
        ..rotate(rotationDegrees * math.pi / 180)
        // Subtle dark halo keeps the white outline legible on bright frames.
        ..drawRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..color = shadowColor.withValues(alpha: 0.45),
        )
        ..drawRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = frameColor.withValues(alpha: 0.9),
        )
        ..restore();
    }

    if (!snap.hasAny) return;

    final guideRect = Offset.zero & size;
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = LinearGradient(
        colors: [guideGradient.start, guideGradient.end],
      ).createShader(guideRect);
    final guideShadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = shadowColor.withValues(alpha: 0.4);

    void drawGuide(Offset a, Offset b) {
      canvas
        ..drawLine(a, b, guideShadow)
        ..drawLine(a, b, guidePaint);
    }

    const edgeInset = 1.0;
    if (snap.centerX) {
      drawGuide(Offset(size.width / 2, 0), Offset(size.width / 2, size.height));
    }
    if (snap.centerY) {
      drawGuide(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
      );
    }
    if (snap.leftEdge) {
      drawGuide(const Offset(edgeInset, 0), Offset(edgeInset, size.height));
    }
    if (snap.rightEdge) {
      drawGuide(
        Offset(size.width - edgeInset, 0),
        Offset(size.width - edgeInset, size.height),
      );
    }
    if (snap.topEdge) {
      drawGuide(const Offset(0, edgeInset), Offset(size.width, edgeInset));
    }
    if (snap.bottomEdge) {
      drawGuide(
        Offset(0, size.height - edgeInset),
        Offset(size.width, size.height - edgeInset),
      );
    }
    if (snap.rotationDegrees != null) {
      // Crosshair aligned to the snapped 90° orientation through the center.
      final rad = rotationDegrees * math.pi / 180;
      final arm = math.max(size.width, size.height);
      final dx = math.cos(rad) * arm;
      final dy = math.sin(rad) * arm;
      drawGuide(Offset(cx - dx, cy - dy), Offset(cx + dx, cy + dy));
      drawGuide(Offset(cx + dy, cy - dx), Offset(cx - dy, cy + dx));
    }
  }

  @override
  bool shouldRepaint(_TransformGizmoPainter old) =>
      old.baseSize != baseSize ||
      old.position != position ||
      old.scale != scale ||
      old.rotationDegrees != rotationDegrees ||
      old.showFrame != showFrame ||
      old.snap != snap ||
      old.frameColor != frameColor ||
      old.shadowColor != shadowColor ||
      old.guideGradient != guideGradient;
}
