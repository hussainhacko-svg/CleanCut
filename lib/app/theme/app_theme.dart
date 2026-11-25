import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Themes for CleanCut, following the VCLIP design kit (see DESIGN.md §5).
///
/// Widgets must take colors from `Theme.of(context).colorScheme` and text
/// styles from `textTheme`; the palette below holds the only literal colors.
abstract final class AppTheme {
  // VCLIP palette.
  static const Color _black = Color(0xFF030303);
  static const Color _panel = Color(0xFF1F1F1F);
  static const Color _card = Color(0xFF212121);
  static const Color _chip = Color(0xFF3A3A3A);
  static const Color _hairline = Color(0xFF2D2D2D);
  static const Color _muted = Color(0xFF606060);
  static const Color _secondaryText = Color(0xFF9E9E9E);
  static const Color _pink = Color(0xFFCE50E0);
  static const Color _orange = Color(0xFFFFB951);

  /// Default theme.
  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: _pink,
      onPrimary: Colors.white,
      secondary: _orange,
      onSecondary: _black,
      error: Color(0xFFFF6B6B),
      onError: _black,
      surface: _black,
      onSurface: Colors.white,
      onSurfaceVariant: _secondaryText,
      surfaceContainerLowest: _black,
      surfaceContainerLow: Color(0xFF141414),
      surfaceContainer: _panel,
      surfaceContainerHigh: _card,
      surfaceContainerHighest: _chip,
      outline: _muted,
      outlineVariant: _hairline,
      inverseSurface: Colors.white,
      onInverseSurface: _black,
      surfaceTint: Colors.transparent,
    ),
  );

  /// Optional light theme: the same accents on white surfaces.
  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: _pink,
      primary: _pink,
      onPrimary: Colors.white,
      secondary: _orange,
      surface: Colors.white,
      surfaceTint: Colors.transparent,
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      colorScheme: scheme,
      fontFamily: AppTokens.fontFamily,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
    const cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppTokens.cardRadius)),
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(Icons.chevron_left),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        modalBackgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.sheetRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppTokens.sheetRadius),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: cardShape,
      ),
    );
  }
}
