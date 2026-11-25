import 'package:flutter/material.dart';

/// Material 3 themes for CleanCut.
///
/// Widgets must take colors from `Theme.of(context).colorScheme`; the
/// seed and surface overrides below are the only literal colors.
abstract final class AppTheme {
  /// Accent used for selection, playhead and primary actions.
  static const Color seed = Color(0xFF00BFA5);

  // Near-black so video colors read true in the editor (DESIGN.md §5).
  static const Color _darkSurface = Color(0xFF0F1112);

  /// Default theme.
  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(surface: _darkSurface),
  );

  /// Optional light theme.
  static ThemeData light() => _build(ColorScheme.fromSeed(seedColor: seed));

  static ThemeData _build(ColorScheme scheme) => ThemeData(
    colorScheme: scheme,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
