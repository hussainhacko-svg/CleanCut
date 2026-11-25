/// Shape and type tokens of the VCLIP design kit, shared by the app theme
/// and feature widgets. Colors live in the theme's `ColorScheme`.
abstract final class AppTokens {
  /// Body font of the whole app.
  static const String fontFamily = 'PlusJakartaSans';

  /// Display font used for the wordmark.
  static const String wordmarkFontFamily = 'BebasNeue';

  /// Corner radius of cards, tiles and preset thumbnails.
  static const double cardRadius = 10;

  /// Top corner radius of bottom sheets and tool panels.
  static const double sheetRadius = 20;

  /// Horizontal page gutter on phones.
  static const double gutter = 18;

  /// Size of round icon chips (the "+" and "•••" buttons).
  static const double chipSize = 32;
}
