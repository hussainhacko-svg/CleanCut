import 'dart:async';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/domain/model/clip_color.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/panel_widgets.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/tool_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Per-clip color and tone adjustments panel: a horizontal selector row of 10
/// Clipcraft icon chips (`Exposure`, `Brightness`, `Contrast`, `Saturation`,
/// `Warmth`, `Tint`, `Highlights`, `Shadows`, `Sharpen`, `Vignette`) paired
/// with a focused gradient slider, tap-to-type exact input, per-field reset,
/// and panel-wide Reset.
class AdjustPanel extends StatefulWidget {
  /// Creates the panel.
  const new({
    required this.adjustments,
    required this.onDrag,
    required this.onDragEnd,
    required this.onSet,
    required this.onClose,
    super.key,
  });

  /// Current clip adjustments.
  final ClipAdjustments adjustments;

  /// Called live while dragging a slider (coalesced into one undo step).
  final ValueChanged<ClipAdjustments> onDrag;

  /// Called when a drag ends (seals the undo step).
  final VoidCallback onDragEnd;

  /// Called on discrete edits: typed values, single-field reset, or Reset All.
  final ValueChanged<ClipAdjustments> onSet;

  /// Closes the panel.
  final VoidCallback onClose;

  @override
  State<AdjustPanel> createState() => _AdjustPanelState();
}

class _AdjustPanelState extends State<AdjustPanel> {
  // Ephemeral UI selection: which adjustment slider is focused.
  AdjustmentField _selected = AdjustmentField.exposure;

  double _positionOf(AdjustmentField field, double value) =>
      (value - field.min) / (field.max - field.min);

  double _valueAt(AdjustmentField field, double position) {
    final raw = field.min + position.clamp(0.0, 1.0) * (field.max - field.min);
    // Round to whole percentage steps so slider & typed readouts stay clean.
    final rounded = (raw * 100).round() / 100;
    return rounded == 0 ? 0.0 : rounded;
  }

  Future<void> _typeValue(AdjustmentField field, String label) async {
    final l10n = AppLocalizations.of(context);
    final minInt = (field.min * 100).round();
    final maxInt = (field.max * 100).round();
    final curInt = (field.valueOf(widget.adjustments) * 100).round();
    final typed = await showValueDialog(
      context,
      title: label,
      label: l10n.valueRangeLabel('$minInt', '$maxInt'),
      invalidText: l10n.valueRangeInvalid('$minInt', '$maxInt'),
      initialText: '$curInt',
      parse: (text) {
        final v = double.tryParse(text.replaceAll('−', '-'));
        if (v == null || v < minInt || v > maxInt) return null;
        return v / 100;
      },
    );
    if (typed != null && mounted) {
      widget.onSet(field.withValue(widget.adjustments, typed));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final adj = widget.adjustments;
    final field = _selected;
    final value = field.valueOf(adj);
    final label = _fieldLabel(l10n, field);
    final intPct = (value * 100).round();
    final valueText = intPct > 0 && field.min < 0 ? '+$intPct' : '$intPct';
    final zeroSnap = _positionOf(field, 0);

    return ToolPanel(
      title: l10n.toolAdjust,
      onClose: widget.onClose,
      onReset: adj.isNone ? null : () => widget.onSet(ClipAdjustments.none),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 66,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
              children: [
                for (final f in AdjustmentField.values) ...[
                  _AdjustChip(
                    icon: _fieldIcon(f),
                    label: _fieldLabel(l10n, f),
                    selected: f == field,
                    modified: f.valueOf(adj) != 0,
                    onTap: () {
                      unawaited(HapticFeedback.selectionClick());
                      setState(() => _selected = f);
                    },
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          GradientSliderRow(
            label: label,
            valueText: valueText,
            position: _positionOf(field, value),
            snapPositions: [zeroSnap],
            onChanged: (pos) =>
                widget.onDrag(field.withValue(adj, _valueAt(field, pos))),
            onChangeEnd: widget.onDragEnd,
            onTapValue: () => unawaited(_typeValue(field, label)),
            trailing: IconButton(
              tooltip: l10n.adjustResetField(label),
              onPressed: value == 0
                  ? null
                  : () {
                      unawaited(HapticFeedback.selectionClick());
                      widget.onSet(field.withValue(adj, 0));
                    },
              icon: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: value == 0
                    ? scheme.outline.withValues(alpha: 0.4)
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static AppIcons _fieldIcon(AdjustmentField field) => switch (field) {
    AdjustmentField.exposure => AppIcons.adjustExposure,
    AdjustmentField.brightness => AppIcons.adjustBrightness,
    AdjustmentField.contrast => AppIcons.adjustContrast,
    AdjustmentField.saturation => AppIcons.adjustSaturation,
    AdjustmentField.warmth => AppIcons.adjustWarmth,
    AdjustmentField.tint => AppIcons.adjustTint,
    AdjustmentField.highlights => AppIcons.adjustHighlights,
    AdjustmentField.shadows => AppIcons.adjustShadows,
    AdjustmentField.sharpen => AppIcons.adjustSharpen,
    AdjustmentField.vignette => AppIcons.adjustVignette,
  };

  static String _fieldLabel(AppLocalizations l10n, AdjustmentField field) =>
      switch (field) {
        AdjustmentField.exposure => l10n.adjustExposure,
        AdjustmentField.brightness => l10n.adjustBrightness,
        AdjustmentField.contrast => l10n.adjustContrast,
        AdjustmentField.saturation => l10n.adjustSaturation,
        AdjustmentField.warmth => l10n.adjustWarmth,
        AdjustmentField.tint => l10n.adjustTint,
        AdjustmentField.highlights => l10n.adjustHighlights,
        AdjustmentField.shadows => l10n.adjustShadows,
        AdjustmentField.sharpen => l10n.adjustSharpen,
        AdjustmentField.vignette => l10n.adjustVignette,
      };
}

class _AdjustChip extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.selected,
    required this.modified,
    required this.onTap,
  });

  final AppIcons icon;
  final String label;
  final bool selected;
  final bool modified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gradient = AccentGradient.of(context).linear;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        child: Container(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected
                ? scheme.surfaceContainerHigh
                : scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AppIcon(icon, size: 20),
                  if (modified)
                    PositionedDirectional(
                      top: -2,
                      end: -5,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: gradient,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontVariations: [FontVariation.weight(selected ? 700 : 500)],
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
