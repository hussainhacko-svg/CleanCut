import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'clip_transition.freezed.dart';
part 'clip_transition.g.dart';

/// Grouping of [TransitionType]s in the transition picker panel.
enum TransitionCategory {
  /// Dissolve, dips and iris transitions.
  basic,

  /// Directional push-slide transitions.
  slide,

  /// Directional wipe reveals.
  wipe,

  /// Zoom crossfades.
  zoom,
}

/// Visual transition played across the overlap between two adjacent
/// main-track clips (Phase 6C).
enum TransitionType {
  /// Smooth cross-dissolve from outgoing to incoming clip.
  dissolve(TransitionCategory.basic),

  /// Dip through black from outgoing to incoming clip.
  fadeBlack(TransitionCategory.basic),

  /// Dip through white from outgoing to incoming clip.
  fadeWhite(TransitionCategory.basic),

  /// Expanding circular iris reveal of the incoming clip.
  circle(TransitionCategory.basic),

  /// Incoming clip pushes outgoing clip out to the left.
  slideLeft(TransitionCategory.slide),

  /// Incoming clip pushes outgoing clip out to the right.
  slideRight(TransitionCategory.slide),

  /// Incoming clip pushes outgoing clip out upward.
  slideUp(TransitionCategory.slide),

  /// Incoming clip pushes outgoing clip out downward.
  slideDown(TransitionCategory.slide),

  /// Incoming clip wipes over outgoing clip from right to left.
  wipeLeft(TransitionCategory.wipe),

  /// Incoming clip wipes over outgoing clip from left to right.
  wipeRight(TransitionCategory.wipe),

  /// Incoming clip wipes over outgoing clip from bottom to top.
  wipeUp(TransitionCategory.wipe),

  /// Incoming clip wipes over outgoing clip from top to bottom.
  wipeDown(TransitionCategory.wipe),

  /// Outgoing clip zooms in while crossfading into zooming-in incoming clip.
  zoomIn(TransitionCategory.zoom),

  /// Outgoing clip zooms out while crossfading into zooming-out incoming clip.
  zoomOut(TransitionCategory.zoom);

  new(this.category);

  /// Picker category this transition belongs to.
  final TransitionCategory category;

  /// All transitions belonging to [category], in display order.
  static List<TransitionType> inCategory(TransitionCategory category) => [
    for (final t in values)
      if (t.category == category) t,
  ];
}

/// Allowed transition duration range and overlap cap math (microseconds).
abstract final class TransitionLimits {
  /// Shortest transition duration (0.1 s).
  static const int minDurationUs = 100000;

  /// Longest transition duration (3.0 s).
  static const int maxDurationUs = 3000000;

  /// Default transition duration when first applied (0.5 s).
  static const int defaultDurationUs = 500000;

  /// Maximum transition overlap allowed between clips of lengths
  /// [leftDurationUs] and [rightDurationUs] so transitions on opposite sides
  /// of a clip can never collide with each other.
  static int maxBetween(int leftDurationUs, int rightDurationUs) {
    final shorter = math.min(leftDurationUs, rightDurationUs);
    if (shorter <= 0) return 0;
    return math.min(maxDurationUs, shorter ~/ 2);
  }

  /// Actual overlap in microseconds played for a transition requesting
  /// [requestedUs] between clips of lengths [leftDurationUs] and
  /// [rightDurationUs].
  ///
  /// When the clips are too short for even [minDurationUs], this is `0` (a
  /// hard cut); the stored transition plays again once they grow.
  static int effectiveDurationUs(
    int requestedUs,
    int leftDurationUs,
    int rightDurationUs,
  ) {
    if (requestedUs <= 0) return 0;
    final overlap = math.min(
      requestedUs,
      maxBetween(leftDurationUs, rightDurationUs),
    );
    return overlap < minDurationUs ? 0 : overlap;
  }
}

/// Transition applied between a main-track clip and the clip immediately
/// following it.
@freezed
abstract class ClipTransition with _$ClipTransition {
  /// Creates a transition.
  const factory({
    required TransitionType type,
    @Default(TransitionLimits.defaultDurationUs) int durationUs,
  }) = _ClipTransition;

  const new _();

  /// Parses a transition from JSON.
  factory fromJson(Map<String, dynamic> json) => _$ClipTransitionFromJson(json);

  /// Broken invariants, empty when valid.
  List<String> validate() => [
    if (durationUs < TransitionLimits.minDurationUs ||
        durationUs > TransitionLimits.maxDurationUs)
      'durationUs out of range',
  ];
}
