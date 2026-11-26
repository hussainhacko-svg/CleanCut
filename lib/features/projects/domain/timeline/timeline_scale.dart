import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Horizontal zoom of the timeline: how many logical pixels one second
/// takes. Pure value object; the UI keeps the current one in a provider.
@immutable
final class TimelineScale {
  /// Creates a scale, clamped to [minPxPerSecond]..[maxPxPerSecond].
  new(double pxPerSecond)
    : pxPerSecond = pxPerSecond.isNaN
          ? defaultPxPerSecond
          : pxPerSecond.clamp(minPxPerSecond, maxPxPerSecond);

  /// The VCLIP "Timeline" frame: 5 s span 114 px.
  static const double defaultPxPerSecond = 114 / 5;

  /// Most zoomed out: about 10 minutes across a phone screen.
  static const double minPxPerSecond = 0.6;

  /// Most zoomed in: about a quarter second across a phone screen.
  static const double maxPxPerSecond = 1500;

  /// The kit's default zoom.
  static final TimelineScale initial = TimelineScale(defaultPxPerSecond);

  /// Logical pixels per second.
  final double pxPerSecond;

  /// Width in pixels of [micros].
  double toPx(int micros) => micros * pxPerSecond / Micros.perSecond;

  /// Time in microseconds covered by [px] pixels (rounded).
  int toUs(double px) => (px * Micros.perSecond / pxPerSecond).round();

  /// This scale multiplied by [factor] (pinch), clamped.
  TimelineScale zoomed(double factor) => TimelineScale(pxPerSecond * factor);

  @override
  bool operator ==(Object other) =>
      other is TimelineScale && other.pxPerSecond == pxPerSecond;

  @override
  int get hashCode => pxPerSecond.hashCode;

  @override
  String toString() => 'TimelineScale($pxPerSecond px/s)';
}
