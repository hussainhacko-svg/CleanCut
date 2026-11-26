import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_scale.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// One mark on the timeline ruler.
@immutable
final class RulerTick {
  /// Creates a tick at [timeUs]; [isMajor] ticks carry a label.
  const new(this.timeUs, {required this.isMajor});

  /// Position in microseconds.
  final int timeUs;

  /// Major ticks show a label; minor ones are dots.
  final bool isMajor;

  @override
  bool operator ==(Object other) =>
      other is RulerTick && other.timeUs == timeUs && other.isMajor == isMajor;

  @override
  int get hashCode => Object.hash(timeUs, isMajor);

  @override
  String toString() => 'RulerTick($timeUs${isMajor ? ', major' : ''})';
}

/// Candidate spacings between labels, in microseconds.
const List<int> _majorSteps = [
  100000, 200000, 500000, //
  1000000, 2000000, 5000000, 10000000, 15000000, 30000000, //
  60000000, 120000000, 300000000, 600000000, 1800000000, 3600000000,
];

/// Labels are at least this far apart (the kit's "0s" and "5s" sit 114 px
/// apart at the default zoom).
const double minMajorSpacingPx = 90;

/// Minor dots between two labels (the kit shows 4 dots between 0s and 5s).
const int minorDivisions = 5;

/// The label spacing used at [scale]: the smallest step whose labels are at
/// least [minMajorSpacingPx] apart.
int majorStepUs(TimelineScale scale) => _majorSteps.firstWhere(
  (step) => scale.toPx(step) >= minMajorSpacingPx,
  orElse: () => _majorSteps.last,
);

/// Ticks covering `[fromUs, toUs]` (clamped to ≥ 0), in time order.
List<RulerTick> rulerTicks(
  TimelineScale scale, {
  required int fromUs,
  required int toUs,
}) {
  final major = majorStepUs(scale);
  final minor = major ~/ minorDivisions;
  final start = fromUs < 0 ? 0 : (fromUs ~/ minor) * minor;
  return [
    for (var t = start; t <= toUs; t += minor)
      RulerTick(t, isMajor: t % major == 0),
  ];
}

/// Label of a major tick: `0s`, `5s`, `0.5s` below a minute, `1:05` above.
String rulerLabel(int timeUs) {
  if (timeUs < 60 * Micros.perSecond) {
    final tenths = (timeUs / 100000).round();
    return tenths % 10 == 0 ? '${tenths ~/ 10}s' : '${tenths / 10}s';
  }
  final total = timeUs ~/ Micros.perSecond;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = (total % 60).toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:$seconds'
      : '$minutes:$seconds';
}
