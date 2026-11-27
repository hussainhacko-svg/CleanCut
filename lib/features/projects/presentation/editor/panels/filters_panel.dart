import 'dart:async';
import 'dart:io';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/core/theme/timeline_colors.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/domain/model/clip_color.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/panel_widgets.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/tool_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Filter presets panel: category tabs (`Film | Vibrant | B&W`), horizontal
/// strip of LUT preview thumbnails (`None` + category presets), and an
/// intensity slider (`0%..100%`) when a filter is active.
class FiltersPanel extends StatefulWidget {
  /// Creates the panel.
  const new({
    required this.filter,
    required this.onSelect,
    required this.onIntensityDrag,
    required this.onIntensityDragEnd,
    required this.onIntensitySet,
    required this.onClose,
    this.baseThumbnailPath,
    this.previewPaths = const {},
    super.key,
  });

  /// Currently applied clip filter, or null for None.
  final ClipFilter? filter;

  /// Optional ungraded frame thumbnail path for the None tile.
  final String? baseThumbnailPath;

  /// Native-engine cached preview JPEG paths keyed by `FilterPreset.id`.
  final Map<String, String?> previewPaths;

  /// Called when a preset (or null for None / Reset) is tapped.
  final ValueChanged<ClipFilter?> onSelect;

  /// Called live while dragging the intensity slider (`0..1`).
  final ValueChanged<double> onIntensityDrag;

  /// Called when an intensity slider drag finishes.
  final VoidCallback onIntensityDragEnd;

  /// Called when an exact intensity is typed (`0..1`).
  final ValueChanged<double> onIntensitySet;

  /// Closes the panel.
  final VoidCallback onClose;

  @override
  State<FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  // Ephemeral UI tab state: opens on the active filter's category when set.
  late int _categoryIndex = _initialCategoryIndex(widget.filter);

  static int _initialCategoryIndex(ClipFilter? filter) {
    if (filter == null) return 0;
    final preset = FilterPreset.byId(filter.id);
    return preset == null ? 0 : FilterCategory.values.indexOf(preset.category);
  }

  Future<void> _typeIntensity() async {
    final active = widget.filter;
    if (active == null) return;
    final l10n = AppLocalizations.of(context);
    final currentPct = (active.intensity * 100).round();
    final typed = await showValueDialog(
      context,
      title: l10n.filterIntensity,
      label: l10n.valueRangeLabel('0', '100'),
      invalidText: l10n.valueRangeInvalid('0', '100'),
      initialText: '$currentPct',
      parse: (text) {
        final v = double.tryParse(text);
        if (v == null || v < 0 || v > 100) return null;
        return v / 100;
      },
    );
    if (typed != null && mounted) widget.onIntensitySet(typed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = widget.filter;
    final category = FilterCategory.values[_categoryIndex];
    final presets = FilterPreset.inCategory(category);

    return ToolPanel(
      title: l10n.toolFilters,
      onClose: widget.onClose,
      onReset: active == null ? null : () => widget.onSelect(null),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelTabs(
            labels: [
              l10n.filterCategoryFilm,
              l10n.filterCategoryVibrant,
              l10n.filterCategoryBw,
            ],
            selected: _categoryIndex,
            onSelect: (i) => setState(() => _categoryIndex = i),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
              children: [
                _FilterTile(
                  label: l10n.filterNone,
                  selected: active == null,
                  imagePath: widget.baseThumbnailPath,
                  isNone: true,
                  accentIndex: 0,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    widget.onSelect(null);
                  },
                ),
                for (final (i, preset) in presets.indexed) ...[
                  const SizedBox(width: 10),
                  _FilterTile(
                    label: _presetLabel(l10n, preset.id),
                    selected: active?.id == preset.id,
                    imagePath: widget.previewPaths[preset.id],
                    isNone: false,
                    accentIndex: _categoryIndex * 4 + i,
                    onTap: () {
                      unawaited(HapticFeedback.selectionClick());
                      final intensity = active?.id == preset.id
                          ? active!.intensity
                          : (active?.intensity ?? 1.0);
                      widget.onSelect(
                        ClipFilter(id: preset.id, intensity: intensity),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          if (active != null) ...[
            const SizedBox(height: 6),
            GradientSliderRow(
              label: l10n.filterIntensity,
              valueText: l10n.percentValue((active.intensity * 100).round()),
              position: active.intensity,
              snapPositions: const [1],
              onChanged: widget.onIntensityDrag,
              onChangeEnd: widget.onIntensityDragEnd,
              onTapValue: () => unawaited(_typeIntensity()),
            ),
          ],
        ],
      ),
    );
  }

  static String _presetLabel(AppLocalizations l10n, String id) => switch (id) {
    'film_gold' => l10n.filterGold,
    'film_velvia' => l10n.filterVelvia,
    'film_vintage' => l10n.filterVintage,
    'film_cinema' => l10n.filterCinema,
    'viv_vivid' => l10n.filterVivid,
    'viv_sunset' => l10n.filterSunset,
    'viv_nordic' => l10n.filterNordic,
    'viv_pastel' => l10n.filterPastel,
    'bw_noir' => l10n.filterNoir,
    'bw_silver' => l10n.filterSilver,
    'bw_sepia' => l10n.filterSepia,
    'bw_matte' => l10n.filterMatte,
    _ => id,
  };
}

class _FilterTile extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.imagePath,
    required this.isNone,
    required this.accentIndex,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final String? imagePath;
  final bool isNone;
  final int accentIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gradient = AccentGradient.of(context).linear;
    final accents = TimelineColors.of(context).cardAccents;
    final accent = accents[accentIndex % accents.length];
    final path = imagePath;
    const tileRadius = BorderRadius.all(Radius.circular(10));

    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: isNone
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.55),
                  scheme.surfaceContainerHigh,
                ],
              ),
        color: isNone ? scheme.surfaceContainerHigh : null,
      ),
      child: Center(
        child: isNone
            ? Icon(Icons.block, size: 20, color: scheme.onSurfaceVariant)
            : AppIcon(
                AppIcons.toolFilters,
                size: 20,
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        child: SizedBox(
          width: 66,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: selected ? gradient : null,
                  border: selected
                      ? null
                      : Border.all(color: scheme.outlineVariant),
                ),
                child: ClipRRect(
                  borderRadius: tileRadius,
                  child: path == null
                      ? fallback
                      : Image.file(
                          File(path),
                          fit: BoxFit.cover,
                          cacheHeight: 128,
                          errorBuilder: (_, _, _) => fallback,
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontVariations: [FontVariation.weight(selected ? 700 : 400)],
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
