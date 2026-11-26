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
  close('close');

  new(this._file);

  final String _file;

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
    final tint = color ?? IconTheme.of(context).color;
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
