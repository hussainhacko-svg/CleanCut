import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/core/theme/timeline_colors.dart';
import 'package:flutter/material.dart';

/// Themes for CleanCut, following the Clipcraft design system
/// (see DESIGN.md §5).
///
/// Widgets must take colors from `Theme.of(context).colorScheme` / extensions
/// and text styles from `textTheme`; the palette below holds the only literal
/// UI colors.
abstract final class AppTheme {
  // Clipcraft dark palette.
  static const Color _darkPrimary = Color(0xFF7C8CFF);
  static const Color _secondary = Color(0xFFA35CFF);
  static const Color _tertiary = Color(0xFFFF4FD8);
  static const Color _darkBg = Color(0xFF16171B);
  static const Color _darkEditorBg = Color(0xFF0F1014);
  static const Color _darkSurface = Color(0xFF1D1E24);
  static const Color _darkSurfaceVariant = Color(0xFF262730);
  static const Color _darkOutline = Color(0xFF6B6F85);
  static const Color _darkOutlineVariant = Color(0xFF2E2F39);
  static const Color _darkOnSurface = Color(0xFFE6E6EA);
  static const Color _darkOnSurfaceVariant = Color(0xFF8B8FA3);

  // Shared Clipcraft category & semantic colors.
  static const Color _error = Color(0xFFFF5D73);
  static const Color _catVideo = Color(0xFF36C5F0);
  static const Color _catAudio = Color(0xFF1DD1A1);
  static const Color _catText = Color(0xFFFF9F43);
  static const Color _catEffect = Color(0xFFA35CFF);
  static const Color _catOverlay = Color(0xFFFF5D73);
  static const Color _catMusic = Color(0xFF5B8CFF);

  /// The app theme (CleanCut is dark only).
  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: _darkPrimary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF292E4F),
      onPrimaryContainer: Color(0xFFDDE1FF),
      secondary: _secondary,
      onSecondary: Colors.white,
      tertiary: _tertiary,
      onTertiary: Colors.white,
      error: _error,
      onError: Colors.white,
      surface: _darkBg,
      onSurface: _darkOnSurface,
      onSurfaceVariant: _darkOnSurfaceVariant,
      surfaceContainerLowest: _darkEditorBg,
      surfaceContainerLow: _darkBg,
      surfaceContainer: _darkSurface,
      surfaceContainerHigh: _darkSurfaceVariant,
      surfaceContainerHighest: _darkOutlineVariant,
      outline: _darkOutline,
      outlineVariant: _darkOutlineVariant,
      inverseSurface: _darkOnSurface,
      onInverseSurface: _darkBg,
      scrim: Colors.black,
      shadow: Colors.black,
      surfaceTint: Colors.transparent,
    ),
    gradientStart: _darkPrimary,
  );

  static TextStyle _text(
    double size,
    double height,
    FontWeight weight,
    Color color, {
    double spacing = 0,
  }) => TextStyle(
    fontFamily: AppTokens.fontFamily,
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    letterSpacing: spacing,
    color: color,
  );

  static TextTheme _textTheme(Color onSurface) => TextTheme(
    displayLarge: _text(48, 56, FontWeight.w800, onSurface, spacing: -0.5),
    displayMedium: _text(40, 48, FontWeight.w800, onSurface, spacing: -0.25),
    displaySmall: _text(32, 40, FontWeight.w700, onSurface),
    headlineLarge: _text(28, 36, FontWeight.w700, onSurface),
    headlineMedium: _text(24, 32, FontWeight.w700, onSurface),
    headlineSmall: _text(20, 28, FontWeight.w700, onSurface),
    titleLarge: _text(20, 28, FontWeight.w700, onSurface),
    titleMedium: _text(16, 24, FontWeight.w600, onSurface, spacing: 0.1),
    titleSmall: _text(14, 20, FontWeight.w600, onSurface, spacing: 0.1),
    bodyLarge: _text(16, 24, FontWeight.w400, onSurface, spacing: 0.1),
    bodyMedium: _text(14, 20, FontWeight.w400, onSurface, spacing: 0.1),
    bodySmall: _text(12, 16, FontWeight.w400, onSurface, spacing: 0.2),
    labelLarge: _text(14, 20, FontWeight.w600, onSurface, spacing: 0.1),
    labelMedium: _text(12, 16, FontWeight.w600, onSurface, spacing: 0.3),
    labelSmall: _text(10, 14, FontWeight.w500, onSurface, spacing: 0.4),
  );

  static ThemeData _build(ColorScheme scheme, {required Color gradientStart}) {
    final textTheme = _textTheme(scheme.onSurface);
    final primaryTextTheme = _textTheme(scheme.onPrimary);
    final base = ThemeData(
      colorScheme: scheme,
      fontFamily: AppTokens.fontFamily,
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
    const cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppTokens.cardRadius)),
    );
    return base.copyWith(
      extensions: [
        AccentGradient(start: gradientStart, end: _secondary),
        const TimelineColors(
          video: _catVideo,
          effect: _catEffect,
          text: _catText,
          overlay: _catOverlay,
          audio: _catAudio,
          music: _catMusic,
          selectionTint: _catVideo,
        ),
      ],
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      // Every icon button is a full 48dp target (AGENTS.md §9).
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size.square(48)),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(Icons.chevron_left),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
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
        color: scheme.surfaceContainerHigh,
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
