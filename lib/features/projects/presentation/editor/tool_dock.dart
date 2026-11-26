import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/core/utils/timecode.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_selection.dart';
import 'package:flutter/material.dart';

/// Every tool the dock can show (VCLIP "Timeline" and "Video" frames).
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

  /// Filters.
  filters(AppIcons.toolFilters),

  /// Crop.
  crop(AppIcons.toolCrop),

  /// Adjustments.
  adjust(AppIcons.toolAdjust),

  /// Speed.
  speed(AppIcons.toolSpeed),

  /// Animation.
  animation(AppIcons.toolAnimation),

  /// Volume.
  volume(AppIcons.toolVolume),

  /// Delete.
  delete(AppIcons.toolDelete);

  new(this.icon);

  /// The kit glyph.
  final AppIcons icon;

  /// The first item of each dock is a white circle without a label.
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
    filters => l10n.toolFilters,
    crop => l10n.toolCrop,
    adjust => l10n.toolAdjust,
    speed => l10n.toolSpeed,
    animation => l10n.toolAnimation,
    volume => l10n.toolVolume,
    delete => l10n.toolDelete,
  };
}

/// The dock's tools for [selection]: "add" tools with nothing selected,
/// clip tools otherwise (DESIGN.md §3, kit order).
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
    DockTool.filters,
    DockTool.crop,
    DockTool.adjust,
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

/// Phone dock: a horizontally scrolling row of icon + 8px label items,
/// 52dp apart, the first one a white circle (kit "Timeline" frame).
class ToolDock extends StatelessWidget {
  /// Creates the dock.
  const new({required this.tools, required this.onTool, super.key});

  /// Tools in order.
  final List<DockTool> tools;

  /// Called with the tapped tool.
  final ValueChanged<DockTool> onTool;

  /// Height of the dock row.
  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
        children: [
          for (final tool in tools)
            _DockItem(tool: tool, onTap: () => onTool(tool)),
        ],
      ),
    );
  }
}

/// Tablet rail: the same tools in a vertical column (DESIGN.md §2).
class ToolRail extends StatelessWidget {
  /// Creates the rail.
  const new({required this.tools, required this.onTool, super.key});

  /// Tools in order.
  final List<DockTool> tools;

  /// Called with the tapped tool.
  final ValueChanged<DockTool> onTool;

  /// Width of the rail.
  static const double width = 72;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ListView(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 12),
        children: [
          for (final tool in tools)
            Center(
              child: _DockItem(
                tool: tool,
                onTap: () => onTool(tool),
                height: 60,
              ),
            ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const new({required this.tool, required this.onTap, this.height = 64});

  final DockTool tool;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = tool.label(l10n);
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: SizedBox(
            width: 52,
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(
                  tool.icon,
                  color: tool.isLeading ? null : scheme.onSurface,
                ),
                if (!tool.isLeading) ...[
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tablet properties panel (VCLIP panel style). Phase 3 shows what is
/// selected; tool controls arrive with their phases.
class PropertiesPanel extends StatelessWidget {
  /// Creates the panel for [selection] in [project].
  const new({required this.project, required this.selection, super.key});

  /// The project.
  final Project project;

  /// Current selection.
  final TimelineSelection selection;

  /// Width of the panel.
  static const double width = 320;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (title, detail) = _describe(l10n);
    return Container(
      width: width,
      margin: const EdgeInsetsDirectional.fromSTEB(0, 12, 12, 12),
      padding: const EdgeInsetsDirectional.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTokens.sheetRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }

  (String, String) _describe(AppLocalizations l10n) {
    switch (selection) {
      case NoSelection():
        return (l10n.panelTitle, l10n.panelNothingSelected);
      case MainClipSelection(:final clipId):
        for (final clip in project.mainTrack.clips) {
          if (clip.id == clipId) {
            return (
              clip.media.displayName ?? l10n.panelClip,
              formatDurationUs(clip.durationUs),
            );
          }
        }
        return (l10n.panelTitle, l10n.panelNothingSelected);
      case OverlaySelection(:final trackId, :final clipId):
        for (final track in project.overlayTracks) {
          if (track.id != trackId) continue;
          for (final item in track.items) {
            if (item.clip.id == clipId) {
              return (
                item.clip.media.displayName ?? l10n.laneOverlay,
                formatDurationUs(item.clip.durationUs),
              );
            }
          }
        }
        return (l10n.panelTitle, l10n.panelNothingSelected);
      case AudioSelection(:final trackId, :final clipId):
        for (final track in project.audioTracks) {
          if (track.id != trackId) continue;
          for (final item in track.items) {
            if (item.clip.id == clipId) {
              return (
                item.clip.media.displayName ?? l10n.laneAudio,
                formatDurationUs(item.clip.durationUs),
              );
            }
          }
        }
        return (l10n.panelTitle, l10n.panelNothingSelected);
    }
  }
}
