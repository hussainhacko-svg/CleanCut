import 'dart:async';
import 'dart:math' as math;

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/panel_widgets.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/tool_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Maps the Crop panel's rotation ruler (positions 0–1) to angles from
/// −180° to 180°, snapping to multiples of 45°.
abstract final class RotationScale {
  /// Lowest angle on the ruler.
  static const double min = -180;

  /// Highest angle on the ruler.
  static const double max = 180;

  /// Angles the ruler snaps to (with a haptic tick).
  static const double snapStep = 45;

  /// How close to a snap angle a drag must come to snap, in degrees.
  static const double snapDegrees = 3;

  /// [degrees] wrapped into [−180°, 180°], the range the ruler shows.
  /// Values already within `[min, max]` stay as they are (so `−180°` stays
  /// at the left end of the ruler instead of jumping to `+180°`).
  static double wrap(double degrees) {
    if (!degrees.isFinite) return 0;
    if (degrees >= min && degrees <= max) {
      return degrees == 0 ? 0 : degrees;
    }
    final w = degrees % 360;
    final wrapped = w > 180 ? w - 360 : w;
    return wrapped == 0 ? 0 : wrapped;
  }

  /// Ruler position (0–1) of [degrees].
  static double positionOf(double degrees) =>
      (wrap(degrees) - min) / (max - min);

  /// Angle at ruler [position], whole degrees, snapped near multiples of
  /// [snapStep].
  static double degreesAt(double position) {
    if (!position.isFinite) return 0;
    final raw = min + position.clamp(0.0, 1.0) * (max - min);
    final snapped = (raw / snapStep).roundToDouble() * snapStep;
    final result = (raw - snapped).abs() <= snapDegrees
        ? snapped
        : raw.roundToDouble();
    return result == 0 ? 0 : result;
  }

  /// Whether [degrees] is a snap angle.
  static bool isSnap(double degrees) => degrees % snapStep == 0;
}

/// The kit's "Crop" panel: mirror and flip at the left, rotate 90° at the
/// right, a rotation ruler, and the aspect presets (Free plus fixed ratios).
///
/// The ruler works like the Speed panel's: drag (live, reported on every
/// move and once more on release), tap to jump, tap the bubble to type an
/// exact angle. Reset restores the whole frame, mirror, flip and rotation.
class CropPanel extends StatefulWidget {
  /// Creates the panel.
  const new({
    required this.aspect,
    required this.rotation,
    required this.mirrored,
    required this.flipped,
    required this.onAspect,
    required this.onRotationDrag,
    required this.onRotationDragEnd,
    required this.onRotationSet,
    required this.onMirror,
    required this.onFlip,
    required this.onRotateQuarter,
    required this.onClose,
    this.onReset,
    super.key,
  });

  /// The locked crop aspect, or null for a free crop.
  final CanvasAspect? aspect;

  /// Rotation at the playhead, in clockwise degrees.
  final double rotation;

  /// Whether the clip is mirrored left-right.
  final bool mirrored;

  /// Whether the clip is flipped upside down.
  final bool flipped;

  /// Called with a tapped preset (null = Free).
  final ValueChanged<CanvasAspect?> onAspect;

  /// Called on every move of a ruler drag.
  final ValueChanged<double> onRotationDrag;

  /// Called when a ruler drag ends.
  final VoidCallback onRotationDragEnd;

  /// Called with a tapped or typed angle.
  final ValueChanged<double> onRotationSet;

  /// Toggles mirror.
  final VoidCallback onMirror;

  /// Toggles flip.
  final VoidCallback onFlip;

  /// Turns the clip a quarter turn clockwise.
  final VoidCallback onRotateQuarter;

  /// Restores the defaults; null shows Reset disabled.
  final VoidCallback? onReset;

  /// Closes the panel.
  final VoidCallback onClose;

  /// Aspect presets in display order; null is Free (owner's list).
  static const List<CanvasAspect?> presets = [
    null,
    CanvasAspect.square,
    CanvasAspect.portrait9x16,
    CanvasAspect.landscape16x9,
    CanvasAspect.portrait3x4,
    CanvasAspect.landscape4x3,
    CanvasAspect(width: 2, height: 1),
    CanvasAspect.portrait4x5,
  ];

  /// Key of the bubble + ruler area (for tests and integration drivers).
  static const rulerKey = Key('cropPanelRuler');

  /// Distance of the ruler from the panel's left and right edges.
  static const double rulerInset = 34;

  @override
  State<CropPanel> createState() => _CropPanelState();
}

class _CropPanelState extends State<CropPanel> {
  /// Angle shown while a finger is down (local, ephemeral gesture state).
  double? _dragDegrees;

  /// Whether a drag has reported a value and still owes
  /// [CropPanel.onRotationDragEnd]. Kept apart from [_dragDegrees], which an
  /// outside change clears while the finger stays down.
  bool _dragging = false;

  static const double _inset = CropPanel.rulerInset;

  double get _degrees => _dragDegrees ?? RotationScale.wrap(widget.rotation);

  @override
  void didUpdateWidget(CropPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragDegrees != null &&
        widget.rotation != oldWidget.rotation &&
        RotationScale.wrap(widget.rotation) != _dragDegrees) {
      _dragDegrees = null;
    }
  }

  @override
  void dispose() {
    // Removed mid-drag: still end the drag (sealing its undo step), after
    // this frame.
    if (_dragging) {
      _dragging = false;
      final onEnd = widget.onRotationDragEnd;
      WidgetsBinding.instance.addPostFrameCallback((_) => onEnd());
    }
    super.dispose();
  }

  double _degreesAtDx(double dx, double width) {
    final track = width - 2 * _inset;
    if (track <= 0) return 0;
    return RotationScale.degreesAt((dx - _inset) / track);
  }

  void _drag(double degrees) {
    if (degrees == _degrees) return;
    if (RotationScale.isSnap(degrees)) {
      unawaited(HapticFeedback.selectionClick());
    }
    setState(() => _dragDegrees = degrees);
    _dragging = true;
    widget.onRotationDrag(degrees);
  }

  void _endDrag() {
    if (!_dragging) return;
    _dragging = false;
    setState(() => _dragDegrees = null);
    widget.onRotationDragEnd();
  }

  void _set(double degrees) {
    if (degrees == widget.rotation) return;
    widget.onRotationSet(degrees);
  }

  Future<void> _type() async {
    final l10n = AppLocalizations.of(context);
    final wrapped = RotationScale.wrap(widget.rotation);
    final typed = await showValueDialog(
      context,
      title: l10n.cropRotation,
      label: l10n.rotationTypeLabel,
      invalidText: l10n.rotationTypeInvalid,
      initialText: wrapped == wrapped.roundToDouble()
          ? wrapped.toStringAsFixed(0)
          : wrapped.toString(),
      parse: (text) {
        final parsed = double.tryParse(text.replaceAll('−', '-'));
        if (parsed == null ||
            !(parsed >= RotationScale.min && parsed <= RotationScale.max)) {
          return null;
        }
        return parsed == 0 ? 0 : parsed;
      },
    );
    if (typed != null && mounted) _set(typed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ToolPanel(
      title: l10n.toolCrop,
      onClose: widget.onClose,
      onReset: widget.onReset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 22),
            child: Row(
              children: [
                _ToggleIcon(
                  icon: AppIcons.cropMirror,
                  tooltip: l10n.cropMirror,
                  selected: widget.mirrored,
                  onPressed: widget.onMirror,
                ),
                _ToggleIcon(
                  icon: AppIcons.cropFlip,
                  tooltip: l10n.cropFlip,
                  selected: widget.flipped,
                  onPressed: widget.onFlip,
                ),
                const Spacer(),
                _ToggleIcon(
                  icon: AppIcons.cropRotate,
                  tooltip: l10n.cropRotate90,
                  onPressed: widget.onRotateQuarter,
                ),
              ],
            ),
          ),
          _ruler(context),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final preset in CropPanel.presets)
                  _PresetTile(
                    aspect: preset,
                    selected: preset == widget.aspect,
                    onTap: () => widget.onAspect(preset),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Value bubble riding over a tick ruler (kit "Crop").
  Widget _ruler(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final degrees = _degrees;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final track = math.max<double>(0, width - 2 * _inset);
        final bubbleX = _inset + RotationScale.positionOf(degrees) * track;
        final text = l10n.rotationValue(degrees.round());
        return Semantics(
          slider: true,
          label: l10n.cropRotation,
          value: text,
          hint: l10n.rotationTypeHint,
          onTap: () => unawaited(_type()),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) =>
                _drag(_degreesAtDx(d.localPosition.dx, width)),
            onHorizontalDragUpdate: (d) =>
                _drag(_degreesAtDx(d.localPosition.dx, width)),
            onHorizontalDragEnd: (_) => _endDrag(),
            onHorizontalDragCancel: _endDrag,
            onTapUp: (d) {
              // The bubble types an exact value; the rest jumps.
              if ((d.localPosition.dx - bubbleX).abs() <= 24 &&
                  d.localPosition.dy <= 48) {
                unawaited(_type());
              } else {
                _set(_degreesAtDx(d.localPosition.dx, width));
              }
            },
            child: SizedBox(
              key: CropPanel.rulerKey,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 50,
                    child: CustomPaint(
                      painter: _RotationRulerPainter(
                        inset: _inset,
                        color: scheme.onSurface,
                        markerX: bubbleX,
                      ),
                    ),
                  ),
                  Positioned(
                    left: bubbleX - _inset,
                    top: 10,
                    width: _inset * 2,
                    child: Center(child: ValueBubble(text: text)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A 48dp icon button; [selected] ones sit on a faint disc.
class _ToggleIcon extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected,
  });

  final AppIcons icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// Null for a plain action; true/false for a toggle.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = selected ?? false;
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: on
            ? scheme.onSurface.withValues(alpha: 0.16)
            : Colors.transparent,
      ),
      icon: AppIcon(
        icon,
        color: on ? scheme.onSurface : scheme.onSurfaceVariant,
      ),
    );
  }
}

/// An aspect preset: its shape above its label (kit "Crop").
class _PresetTile extends StatelessWidget {
  const new({
    required this.aspect,
    required this.selected,
    required this.onTap,
  });

  /// Null is Free.
  final CanvasAspect? aspect;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final aspect = this.aspect;
    final label = aspect == null
        ? l10n.cropFree
        : l10n.cropAspect(aspect.width, aspect.height);
    final color = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 52, minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: 30,
                  child: Center(
                    child: aspect == null
                        ? AppIcon(AppIcons.cropFree, color: color)
                        : CustomPaint(
                            size: const Size.square(28),
                            painter: _AspectGlyphPainter(
                              ratio: aspect.ratio,
                              color: color,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A rounded rectangle of [ratio] inside the glyph box.
class _AspectGlyphPainter extends CustomPainter {
  new({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 1.8;
    final box = size.shortestSide - stroke;
    final w = ratio >= 1 ? box : box * ratio;
    final h = ratio >= 1 ? box / ratio : box;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: w,
      height: h,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_AspectGlyphPainter old) =>
      old.ratio != ratio || old.color != color;
}

/// Ticks every 15°, taller ones at the 45° snap angles, and a marker under
/// the value bubble (kit "Crop").
class _RotationRulerPainter extends CustomPainter {
  new({required this.inset, required this.color, required this.markerX});

  final double inset;
  final Color color;
  final double markerX;

  static const int _steps = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1.5;
    final track = size.width - 2 * inset;
    for (var i = 0; i <= _steps; i++) {
      final major = i % 3 == 0;
      final x = inset + track * i / _steps;
      final h = major ? 8.0 : 4.0;
      paint.color = color.withValues(alpha: major ? 1 : 0.6);
      canvas.drawLine(Offset(x, -h / 2), Offset(x, h / 2), paint);
    }
    canvas.drawLine(
      Offset(markerX, -8),
      Offset(markerX, 8),
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RotationRulerPainter old) =>
      old.inset != inset || old.color != color || old.markerX != markerX;
}
