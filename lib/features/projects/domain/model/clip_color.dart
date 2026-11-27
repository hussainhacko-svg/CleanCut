import 'package:freezed_annotation/freezed_annotation.dart';

part 'clip_color.freezed.dart';
part 'clip_color.g.dart';

/// Filter preset category shown as tabs in the Filters panel.
enum FilterCategory {
  /// Classic film emulations and cinema split-tones.
  film,

  /// Clean, vivid and atmospheric color grades.
  vibrant,

  /// Monochrome and archival B&W looks.
  bw,
}

/// Metadata for a bundled 3D `.cube` LUT preset.
///
/// The [id] matches the bundled asset `luts/<id>.cube` loaded by the native
/// engine.
final class FilterPreset {
  /// Creates a preset entry.
  const new({required this.id, required this.category});

  /// Stable preset identifier stored in project files and sent to the engine.
  final String id;

  /// Panel tab this preset belongs to.
  final FilterCategory category;

  /// All 12 curated presets bundled with the app, in display order.
  static const List<FilterPreset> all = [
    // Film
    FilterPreset(id: 'film_gold', category: FilterCategory.film),
    FilterPreset(id: 'film_velvia', category: FilterCategory.film),
    FilterPreset(id: 'film_vintage', category: FilterCategory.film),
    FilterPreset(id: 'film_cinema', category: FilterCategory.film),
    // Vibrant
    FilterPreset(id: 'viv_vivid', category: FilterCategory.vibrant),
    FilterPreset(id: 'viv_sunset', category: FilterCategory.vibrant),
    FilterPreset(id: 'viv_nordic', category: FilterCategory.vibrant),
    FilterPreset(id: 'viv_pastel', category: FilterCategory.vibrant),
    // B&W
    FilterPreset(id: 'bw_noir', category: FilterCategory.bw),
    FilterPreset(id: 'bw_silver', category: FilterCategory.bw),
    FilterPreset(id: 'bw_sepia', category: FilterCategory.bw),
    FilterPreset(id: 'bw_matte', category: FilterCategory.bw),
  ];

  /// Presets belonging to [category].
  static List<FilterPreset> inCategory(FilterCategory category) => [
    for (final p in all)
      if (p.category == category) p,
  ];

  /// Looks up a preset by [id], or returns null if unknown.
  static FilterPreset? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// A LUT filter applied to a clip at a given [intensity] (`0..1`).
@freezed
abstract class ClipFilter with _$ClipFilter {
  /// Creates a filter reference. Use [validate] to check its invariants.
  const factory({required String id, @Default(1.0) double intensity}) =
      _ClipFilter;

  const new _();

  /// Parses a filter from JSON.
  factory fromJson(Map<String, dynamic> json) => _$ClipFilterFromJson(json);

  /// Broken invariants, empty when valid.
  List<String> validate() => [
    if (id.trim().isEmpty) 'empty filter id',
    if (!intensity.isFinite || intensity < 0 || intensity > 1)
      'intensity out of range',
  ];
}

/// One slider in [ClipAdjustments].
enum AdjustmentField {
  /// Exposure (`-1..1`).
  exposure(-1, 1),

  /// Brightness (`-1..1`).
  brightness(-1, 1),

  /// Contrast (`-1..1`).
  contrast(-1, 1),

  /// Saturation (`-1..1`).
  saturation(-1, 1),

  /// Warmth / color temperature (`-1..1`, negative = cool, positive = warm).
  warmth(-1, 1),

  /// Tint (`-1..1`, negative = green, positive = magenta).
  tint(-1, 1),

  /// Highlights (`-1..1`).
  highlights(-1, 1),

  /// Shadows (`-1..1`).
  shadows(-1, 1),

  /// Sharpen (`0..1`).
  sharpen(0, 1),

  /// Vignette (`0..1`).
  vignette(0, 1);

  new(this.min, this.max);

  /// Lowest allowed value.
  final double min;

  /// Highest allowed value.
  final double max;

  /// Clamps [value] into `[min, max]`, turning non-finite numbers into `0`.
  double clamp(double value) => value.isFinite ? value.clamp(min, max) : 0;

  /// Reads this field's value from [adjustments].
  double valueOf(ClipAdjustments adjustments) => switch (this) {
    exposure => adjustments.exposure,
    brightness => adjustments.brightness,
    contrast => adjustments.contrast,
    saturation => adjustments.saturation,
    warmth => adjustments.warmth,
    tint => adjustments.tint,
    highlights => adjustments.highlights,
    shadows => adjustments.shadows,
    sharpen => adjustments.sharpen,
    vignette => adjustments.vignette,
  };

  /// Returns [adjustments] with this field set to [value] (clamped).
  ClipAdjustments withValue(ClipAdjustments adjustments, double value) {
    final v = clamp(value);
    final normalized = v == 0 ? 0.0 : v;
    return switch (this) {
      exposure => adjustments.copyWith(exposure: normalized),
      brightness => adjustments.copyWith(brightness: normalized),
      contrast => adjustments.copyWith(contrast: normalized),
      saturation => adjustments.copyWith(saturation: normalized),
      warmth => adjustments.copyWith(warmth: normalized),
      tint => adjustments.copyWith(tint: normalized),
      highlights => adjustments.copyWith(highlights: normalized),
      shadows => adjustments.copyWith(shadows: normalized),
      sharpen => adjustments.copyWith(sharpen: normalized),
      vignette => adjustments.copyWith(vignette: normalized),
    };
  }
}

/// Per-clip color and tone adjustments. All fields default to `0` (no change).
@freezed
abstract class ClipAdjustments with _$ClipAdjustments {
  /// Creates adjustments. Use [validate] to check invariants.
  const factory({
    @Default(0.0) double exposure,
    @Default(0.0) double brightness,
    @Default(0.0) double contrast,
    @Default(0.0) double saturation,
    @Default(0.0) double warmth,
    @Default(0.0) double tint,
    @Default(0.0) double highlights,
    @Default(0.0) double shadows,
    @Default(0.0) double sharpen,
    @Default(0.0) double vignette,
  }) = _ClipAdjustments;

  const new _();

  /// Parses adjustments from JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$ClipAdjustmentsFromJson(json);

  /// Neutral adjustments (no change).
  static const none = ClipAdjustments();

  /// Whether every adjustment is at its default `0`.
  bool get isNone =>
      exposure == 0 &&
      brightness == 0 &&
      contrast == 0 &&
      saturation == 0 &&
      warmth == 0 &&
      tint == 0 &&
      highlights == 0 &&
      shadows == 0 &&
      sharpen == 0 &&
      vignette == 0;

  /// Broken invariants, empty when valid.
  List<String> validate() => [
    for (final field in AdjustmentField.values)
      if (!field.valueOf(this).isFinite ||
          field.valueOf(this) < field.min ||
          field.valueOf(this) > field.max)
        '${field.name} out of range',
  ];
}
