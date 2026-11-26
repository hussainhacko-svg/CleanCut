import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icons from the VCLIP kit (`assets/icons`).
enum AppIcons {
  /// Back to the home screen.
  home('home'),

  /// Export the video.
  export('export'),

  /// Start playback.
  play('play'),

  /// Pause playback (drawn to match [play]).
  pause('pause'),

  /// Undo the last edit.
  undo('undo'),

  /// Redo the last undone edit.
  redo('redo'),

  /// Enter full screen.
  fullscreen('fullscreen'),

  /// Leave full screen.
  exitFullscreen('exit_fullscreen'),

  /// Close a panel or overlay.
  close('close'),

  /// Dock: add media (white circle).
  dockAdd('dock_add', multicolor: true),

  /// Dock: leave the clip tools (white circle with a chevron).
  dockBack('dock_back', multicolor: true),

  /// Dock: music.
  dockMusic('dock_music'),

  /// Dock: record a voiceover.
  dockVoice('dock_voice'),

  /// Dock: text.
  dockText('dock_text'),

  /// Dock: effects.
  dockEffect('dock_effect'),

  /// Dock: overlay.
  dockOverlay('dock_overlay'),

  /// Dock: canvas ratio.
  dockRatio('dock_ratio'),

  /// Clip tool: split at the playhead.
  toolSplit('tool_split'),

  /// Clip tool: duplicate (not in the kit; drawn in its style).
  toolDuplicate('tool_duplicate'),

  /// Clip tool: filters.
  toolFilters('tool_filters'),

  /// Clip tool: crop.
  toolCrop('tool_crop'),

  /// Clip tool: transform (not in the kit; drawn in its style).
  toolTransform('tool_transform'),

  /// Clip tool: adjustments.
  toolAdjust('tool_adjust'),

  /// Clip tool: speed.
  toolSpeed('tool_speed'),

  /// Clip tool: animation.
  toolAnimation('tool_animation'),

  /// Clip tool: volume.
  toolVolume('tool_volume'),

  /// Clip tool: delete.
  toolDelete('tool_delete'),

  /// Crop panel: mirror left-right.
  cropMirror('crop_mirror'),

  /// Crop panel: flip upside down.
  cropFlip('crop_flip'),

  /// Crop panel: rotate a quarter turn.
  cropRotate('crop_rotate'),

  /// Crop panel: free (unlocked) crop preset.
  cropFree('crop_free'),

  /// Timeline: transition marker between clips (white circle).
  transition('transition', multicolor: true),

  /// Timeline: mute the original audio.
  mute('mute'),

  /// Lane pill glyph: overlay.
  laneOverlay('lane_overlay'),

  /// Lane pill glyph: effect.
  laneEffect('lane_effect'),

  /// Lane pill glyph: audio.
  laneAudio('lane_audio');

  new(this._file, {this.multicolor = false});

  final String _file;

  /// Drawn in its own colors (e.g. a white disc with a dark glyph); never
  /// tinted.
  final bool multicolor;

  /// Asset path of the SVG.
  String get asset => 'assets/icons/$_file.svg';
}

/// Draws an [AppIcons] glyph at [size], tinted with [color] (defaults to the
/// ambient icon color).
class AppIcon extends StatelessWidget {
  /// Creates an icon.
  const new(this.icon, {this.size = 24, this.color, super.key});

  /// The glyph.
  final AppIcons icon;

  /// Box size; the glyph keeps its aspect ratio inside it.
  final double size;

  /// Tint; null uses `IconTheme.of(context).color`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = icon.multicolor ? null : color ?? IconTheme.of(context).color;
    return SizedBox.square(
      dimension: size,
      child: SvgPicture.asset(
        icon.asset,
        colorFilter: tint == null
            ? null
            : ColorFilter.mode(tint, BlendMode.srcIn),
      ),
    );
  }
}
