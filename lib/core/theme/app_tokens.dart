import 'package:flutter/material.dart';

/// Shape and type tokens of the Clipcraft design system, shared by the app
/// theme and feature widgets. Colors live in the theme's `ColorScheme` and
/// theme extensions.
abstract final class AppTokens {
  /// Primary UI font of the whole app (Manrope variable, SIL OFL).
  static const String fontFamily = 'Manrope';

  /// Fixed-width font for timecodes and numeric readouts (JetBrains Mono,
  /// SIL OFL), so digits do not jump while scrubbing.
  static const String monoFontFamily = 'JetBrainsMono';

  /// Corner radius of cards, preview thumbnails and buttons.
  static const double cardRadius = 12;

  /// Corner radius of floating panels (tablet inspector / tool card).
  static const double inspectorRadius = 14;

  /// Top corner radius of bottom sheets and the phone editor timeline sheet.
  static const double sheetRadius = 22;

  /// Horizontal page gutter on phones.
  static const double gutter = 16;

  /// Size of round icon chips (such as card overflow buttons).
  static const double chipSize = 32;

  /// Monospace timecode style (JetBrains Mono 12sp Medium, tabular figures).
  static TextStyle timecodeStyle(BuildContext context, {Color? color}) {
    final base = Theme.of(context).textTheme.bodySmall;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: monoFontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      fontVariations: const [FontVariation.weight(500)],
      letterSpacing: 0,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
