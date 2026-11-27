import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/core/utils/timecode.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_selection.dart';
import 'package:flutter/material.dart';

/// Every tool the editor tray can show.
enum DockTool {
  /// Add media to the end of the main track.
  add(AppIcons.dockAdd),

  /// Add music.
  music(AppIcons.dockMusic),

  /// Record a voiceover.
  voice(AppIcons.dockVoice),

  /// Add text.
  text(AppIcons.dockText),

  /// Add an effect.
  effect(AppIcons.dockEffect),

  /// Add an overlay.
  overlay(AppIcons.dockOverlay),

  /// Canvas ratio.
  ratio(AppIcons.dockRatio),

  /// Leave the clip tools (deselect).
  back(AppIcons.dockBack),

  /// Split at the playhead.
  split(AppIcons.toolSplit),

  /// Duplicate (right after Split).
  duplicate(AppIcons.toolDuplicate),

  /// Filters.
  filters(AppIcons.toolFilters),

  /// Crop.
  crop(AppIcons.toolCrop),

  /// Transform (right after Crop).
  transform(AppIcons.toolTransform),

  /// Adjustments.
  adjust(AppIcons.toolAdjust),

  /// Whole-clip blur.
  blur(AppIcons.toolBlur),

  /// Shape mask.
  mask(AppIcons.toolMask),

  /// Speed.
  speed(AppIcons.toolSpeed),

  /// Animation.
  animation(AppIcons.toolAnimation),

  /// Volume.
  volume(AppIcons.toolVolume),

  /// Delete.
  delete(AppIcons.toolDelete);

  new(this.icon);

  /// The Clipcraft duotone glyph.
  final AppIcons icon;

  /// Leading action button of each tray state (Add media / Back).
  bool get isLeading => this == add || this == back;

  /// Visible label (also the accessible name).
  String label(AppLocalizations l10n) => switch (this) {
    add => l10n.toolAdd,
    music => l10n.toolMusic,
    voice => l10n.toolVoice,
    text => l10n.toolText,
    effect => l10n.toolEffect,
    overlay => l10n.toolOverlay,
    ratio => l10n.toolRatio,
    back => l10n.commonBack,
    split => l10n.toolSplit,
    duplicate => l10n.toolDuplicate,
    filters => l10n.toolFilters,
    crop => l10n.toolCrop,
    transform => l10n.toolTransform,
    adjust => l10n.toolAdjust,
    blur => l10n.toolBlur,
    mask => l10n.toolMask,
    speed => l10n.toolSpeed,
    animation => l10n.toolAnimation,
    volume => l10n.toolVolume,
    delete => l10n.toolDelete,
  };
}

/// The tray's tools for [selection]: "add" tools with nothing selected,
/// clip tools otherwise (DESIGN.md §3).
List<DockTool> dockToolsFor(TimelineSelection selection) => switch (selection) {
  NoSelection() => const [
    DockTool.add,
    DockTool.music,
    DockTool.voice,
    DockTool.text,
    DockTool.effect,
    DockTool.overlay,
    DockTool.ratio,
  ],
  MainClipSelection() || OverlaySelection() => const [
    DockTool.back,
    DockTool.split,
    DockTool.duplicate,
    DockTool.filters,
    DockTool.crop,
    DockTool.transform,
    DockTool.adjust,
    DockTool.blur,
    DockTool.mask,
    DockTool.speed,
    DockTool.animation,
    DockTool.volume,
    DockTool.delete,
  ],
  AudioSelection() => const [
    DockTool.back,
    DockTool.split,
    DockTool.volume,
    DockTool.speed,
    DockTool.delete,
  ],
};

/// Clipcraft ToolTray: a horizontally scrolling row of category-colored
/// duotone icon + 10sp label items (used at the bottom of both the phone
/// editor sheet and the tablet Neon Focus layout).
class ToolDock extends StatelessWidget {
  /// Creates the tray.
  const new({required this.tools, required this.onTool, super.key});

  /// Tools in order.
  final List<DockTool> tools;

  /// Called with the tapped tool.
  final ValueChanged<DockTool> onTool;

  /// Height of the tray row.
  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        children: [
          for (final tool in tools)
            _TrayItem(tool: tool, onTap: () => onTool(tool)),
        ],
      ),
    );
  }
}

class _TrayItem extends StatelessWidget {
  const new({required this.tool, required this.onTap});

  final DockTool tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = tool.label(l10n);
    final isAdd = tool == DockTool.add;

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.cardRadius),
          child: SizedBox(
            width: 56,
            height: 56,
            child: tool.isLeading
                ? Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isAdd
                            ? scheme.primary
                            : scheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: isAdd
                            ? null
                            : Border.all(color: scheme.outlineVariant),
                      ),
                      child: AppIcon(
                        tool.icon,
                        size: 20,
                        color: isAdd ? scheme.onPrimary : scheme.onSurface,
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(tool.icon, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
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

/// Tablet Neon Focus floating Inspector card: shows what is currently
/// selected when no tool panel is open.
class PropertiesPanel extends StatelessWidget {
  /// Creates the inspector for [selection] in [project].
  const new({required this.project, required this.selection, super.key});

  /// The project.
  final Project project;

  /// Current selection.
  final TimelineSelection selection;

  /// Width of the floating inspector card.
  static const double width = 300;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (title, detail, isDuration) = _describe(l10n);
    return Container(
      width: width,
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTokens.inspectorRadius),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation.weight(700)],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: isDuration
                ? AppTokens.timecodeStyle(context)
                : theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
          ),
        ],
      ),
    );
  }

  (String, String, bool) _describe(AppLocalizations l10n) {
    switch (selection) {
      case NoSelection():
        return (l10n.panelTitle, l10n.panelNothingSelected, false);
      case MainClipSelection(:final clipId):
        for (final clip in project.mainTrack.clips) {
          if (clip.id == clipId) {
            return (
              clip.media.displayName ?? l10n.panelClip,
              formatDurationUs(clip.durationUs),
              true,
            );
          }
        }
        return (l10n.panelTitle, l10n.panelNothingSelected, false);
      case OverlaySelection(:final trackId, :final clipId):
        for (final track in project.overlayTracks) {
          if (track.id != trackId) continue;
          for (final item in track.items) {
            if (item.clip.id == clipId) {
              return (
                item.clip.media.displayName ?? l10n.laneOverlay,
                formatDurationUs(item.clip.durationUs),
                true,
              );
            }
          }
        }
        return (l10n.panelTitle, l10n.panelNothingSelected, false);
      case AudioSelection(:final trackId, :final clipId):
        for (final track in project.audioTracks) {
          if (track.id != trackId) continue;
          for (final item in track.items) {
            if (item.clip.id == clipId) {
              return (
                item.clip.media.displayName ?? l10n.laneAudio,
                formatDurationUs(item.clip.durationUs),
                true,
              );
            }
          }
        }
        return (l10n.panelTitle, l10n.panelNothingSelected, false);
    }
  }
}
