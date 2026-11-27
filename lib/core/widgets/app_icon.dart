import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Category-colored duotone icons from the Clipcraft icon pack (`assets/icons`).
enum AppIcons {
  /// The app's launcher icon (Clipcraft timeline bars), shown as the home
  /// screen logo.
  appLogo('app_logo'),

  /// Film reel glyph.
  film('film'),

  /// Settings gear.
  settings('settings'),

  /// Plus / add action.
  plus('plus'),

  /// Back chevron.
  chevronLeft('chevron_left'),

  /// Forward chevron.
  chevronRight('chevron_right'),

  /// Overflow menu dots.
  moreH('more_h'),

  /// Open folder (empty state).
  folderOpen('folder_open'),

  /// About / info.
  info('info'),

  /// Keyframe / gestures diamond.
  keyframe('keyframe'),

  /// Snap magnet.
  magnet('magnet'),

  /// Back to the home screen from the editor.
  home('chevron_left'),

  /// Export the video.
  export('export'),

  /// Start playback.
  play('play'),

  /// Pause playback.
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

  /// Dock: add media.
  dockAdd('plus'),

  /// Dock: leave the clip tools (deselect).
  dockBack('chevron_left'),

  /// Dock: music.
  dockMusic('music'),

  /// Dock: record a voiceover.
  dockVoice('mic'),

  /// Dock: text.
  dockText('text'),

  /// Dock: effects.
  dockEffect('effects'),

  /// Dock: overlay.
  dockOverlay('layers'),

  /// Dock: canvas ratio.
  dockRatio('aspect_ratio'),

  /// Clip tool: split at the playhead.
  toolSplit('cut'),

  /// Clip tool: duplicate.
  toolDuplicate('copy'),

  /// Clip tool: filters.
  toolFilters('color'),

  /// Clip tool: crop.
  toolCrop('crop'),

  /// Clip tool: transform.
  toolTransform('transform'),

  /// Clip tool: adjustments.
  toolAdjust('sliders'),

  /// Clip tool: whole-clip blur.
  toolBlur('blur'),

  /// Clip tool: shape mask.
  toolMask('mask'),

  /// Clip tool: speed.
  toolSpeed('speed'),

  /// Clip tool: animation.
  toolAnimation('sparkles'),

  /// Clip tool: volume.
  toolVolume('volume'),

  /// Clip tool: delete.
  toolDelete('trash'),

  /// Crop panel: mirror left-right.
  cropMirror('flip_h'),

  /// Crop panel: flip upside down.
  cropFlip('flip_v'),

  /// Crop panel: rotate a quarter turn.
  cropRotate('rotate'),

  /// Crop panel: free (unlocked) crop preset.
  cropFree('fit'),

  /// Timeline: transition marker between clips.
  transition('transition'),

  /// Timeline: mute the original audio.
  mute('volume_off'),

  /// Lane pill glyph: overlay.
  laneOverlay('layers'),

  /// Lane pill glyph: effect.
  laneEffect('effects'),

  /// Lane pill glyph: audio.
  laneAudio('music'),

  /// Adjust: exposure.
  adjustExposure('exposure'),

  /// Adjust: brightness.
  adjustBrightness('brightness'),

  /// Adjust: contrast.
  adjustContrast('contrast'),

  /// Adjust: saturation.
  adjustSaturation('saturation'),

  /// Adjust: warmth (color temperature).
  adjustWarmth('warmth'),

  /// Adjust: tint.
  adjustTint('tint'),

  /// Adjust: highlights.
  adjustHighlights('highlights'),

  /// Adjust: shadows.
  adjustShadows('shadows'),

  /// Adjust: sharpen.
  adjustSharpen('wand'),

  /// Adjust: vignette.
  adjustVignette('vignette');

  new(this._file);

  final String _file;

  /// Asset path of the SVG.
  String get asset => 'assets/icons/$_file.svg';

  /// The pack's uncategorized glyphs, drawn in a fixed grey (`#9aa0b4`) that
  /// fades on light surfaces. They take the ambient icon color instead.
  static const Set<String> _neutralFiles = {
    'chevron_left',
    'chevron_right',
    'close',
    'info',
    'more_h',
    'plus',
    'settings',
    'sliders',
  };

  /// Whether this glyph follows the theme instead of a category color.
  bool get neutral => _neutralFiles.contains(_file);
}

/// Draws an [AppIcons] glyph at [size].
///
/// Leave [color] null to keep a category icon's built-in Clipcraft duotone
/// color; [AppIcons.neutral] glyphs then take the ambient icon color (so they
/// follow the theme and dim when disabled). Pass [color] to tint any icon
/// (e.g., white on filled buttons).
class AppIcon extends StatelessWidget {
  /// Creates an icon.
  const new(this.icon, {this.size = 24, this.color, super.key});

  /// The glyph.
  final AppIcons icon;

  /// Box size; the glyph keeps its aspect ratio inside it.
  final double size;

  /// Optional tint; null keeps category colors and themes neutral glyphs.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? (icon.neutral ? IconTheme.of(context).color : null);
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
