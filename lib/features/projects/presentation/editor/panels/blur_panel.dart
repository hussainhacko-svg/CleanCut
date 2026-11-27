import 'dart:async';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/features/projects/domain/model/clip_effects.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/panel_widgets.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/tool_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Whole-clip Gaussian blur panel (Phase 6B): quick strength presets, gradient
/// slider with snap-to-zero haptic, tap-to-type percentage, keyframe toggle,
/// and Reset.
class BlurPanel extends StatelessWidget {
  /// Creates the panel.
  const new({
    required this.amount,
    required this.onDrag,
    required this.onDragEnd,
    required this.onSet,
    required this.onClose,
    this.animated = false,
    this.keyframeActive = false,
    this.onToggleKeyframe,
    super.key,
  });

  /// Current blur strength in `0..1` at the playhead.
  final double amount;

  /// Whether blur has any keyframes on the clip.
  final bool animated;

  /// Whether a blur keyframe sits at the playhead.
  final bool keyframeActive;

  /// Toggles a blur keyframe at the playhead.
  final VoidCallback? onToggleKeyframe;

  /// Called live while dragging the strength slider (coalesced).
  final ValueChanged<double> onDrag;

  /// Called when the drag finishes (seals the undo step).
  final VoidCallback onDragEnd;

  /// Called on discrete edits: preset taps, typed values, or Reset.
  final ValueChanged<double> onSet;

  /// Closes the panel.
  final VoidCallback onClose;

  Future<void> _typeValue(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final typed = await showValueDialog(
      context,
      title: l10n.toolBlur,
      label: l10n.valueRangeLabel('0', '100'),
      invalidText: l10n.valueRangeInvalid('0', '100'),
      initialText: (amount * 100).round().toString(),
      parse: (text) {
        final v = double.tryParse(text.replaceAll('−', '-'));
        if (v == null || v < 0 || v > 100) return null;
        return v / 100;
      },
    );
    if (typed != null) onSet(BlurLimits.clamp(typed));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pct = (amount * 100).round();

    return ToolPanel(
      title: l10n.toolBlur,
      onClose: onClose,
      onReset: amount == 0 ? null : () => onSet(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
            child: Row(
              children: [
                for (final level in BlurLimits.presets)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 4,
                      ),
                      child: _BlurPresetPill(
                        label: l10n.percentValue((level * 100).round()),
                        selected: (amount - level).abs() < 0.01,
                        onTap: () {
                          unawaited(HapticFeedback.selectionClick());
                          onSet(level);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          GradientSliderRow(
            label: l10n.blurStrength,
            valueText: l10n.percentValue(pct),
            position: amount,
            snapPositions: const [0],
            onChanged: (p) => onDrag((p * 100).roundToDouble() / 100),
            onChangeEnd: onDragEnd,
            onTapValue: () => unawaited(_typeValue(context)),
            trailing: onToggleKeyframe == null
                ? null
                : KeyframeToggleButton(
                    active: keyframeActive,
                    animated: animated,
                    tooltip: keyframeActive
                        ? l10n.keyframeRemove(l10n.toolBlur)
                        : l10n.keyframeAdd(l10n.toolBlur),
                    onPressed: onToggleKeyframe!,
                  ),
          ),
        ],
      ),
    );
  }
}

class _BlurPresetPill extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 8,
                vertical: 8,
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
              child: PanelLabel(
                text: label,
                selected: selected,
                fontSize: 12,
                muted: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
