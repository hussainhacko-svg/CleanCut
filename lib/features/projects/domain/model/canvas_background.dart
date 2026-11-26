import 'package:freezed_annotation/freezed_annotation.dart';

part 'canvas_background.freezed.dart';
part 'canvas_background.g.dart';

/// What fills the canvas behind the clips (visible where a clip is
/// letterboxed, scaled down, moved or transparent).
@Freezed(unionKey: 'type')
sealed class CanvasBackground with _$CanvasBackground {
  /// A solid color, 0xAARRGGBB.
  const factory color({required int argb}) = ColorBackground;

  /// A linear gradient from [startArgb] to [endArgb]. [angleDegrees] is
  /// the direction it runs in, clockwise from "towards the top" (0 runs
  /// bottom to top, 90 left to right).
  const factory gradient({
    required int startArgb,
    required int endArgb,
    @Default(180) double angleDegrees,
  }) = GradientBackground;

  /// The current clip itself, scaled to fill the canvas and blurred.
  /// [amount] in `[0, 1]` is how strong the blur is.
  const factory blur({@Default(0.5) double amount}) = BlurBackground;

  /// A picture from the device (content URI with a persisted read
  /// permission) scaled to fill the canvas, blurred by [blur] in `[0, 1]`.
  const factory image({required String uri, @Default(0) double blur}) =
      ImageBackground;

  const new _();

  /// Parses a background from JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$CanvasBackgroundFromJson(json);

  /// The default: black.
  static const black = CanvasBackground.color(argb: 0xFF000000);

  /// Blur amounts offered in the Background panel.
  static const blurLevels = [0.25, 0.5, 0.75, 1.0];

  /// Broken invariants, empty when the background is valid.
  List<String> validate() => switch (this) {
    ColorBackground() || GradientBackground() => const [],
    BlurBackground(:final amount) => [
      if (!(amount >= 0 && amount <= 1)) 'blur amount out of range',
    ],
    ImageBackground(:final uri, :final blur) => [
      if (uri.isEmpty) 'empty image uri',
      if (!(blur >= 0 && blur <= 1)) 'blur amount out of range',
    ],
  };
}
