import 'package:cleancut/features/projects/domain/model/project.dart';

/// Distance in logical pixels within which the playhead snaps to a target.
const double snapDistancePx = 8;

/// Times the playhead and clip edges snap to: the start, every main-track
/// clip boundary and the edges of every overlay and audio item. Sorted and
/// unique.
List<int> snapTargets(Project project) {
  final targets = <int>{0};
  var start = 0;
  for (final clip in project.mainTrack.clips) {
    start += clip.durationUs;
    targets.add(start);
  }
  for (final track in project.overlayTracks) {
    for (final item in track.items) {
      targets
        ..add(item.range.startUs)
        ..add(item.range.endUs);
    }
  }
  for (final track in project.audioTracks) {
    for (final item in track.items) {
      targets
        ..add(item.range.startUs)
        ..add(item.range.endUs);
    }
  }
  return targets.toList()..sort();
}

/// The target in sorted [targets] nearest to [timeUs] if it is within
/// [toleranceUs], else null. Ties go to the earlier target.
int? snapTo(int timeUs, List<int> targets, {required int toleranceUs}) {
  if (targets.isEmpty || toleranceUs < 0) return null;
  // Binary search for the first target >= timeUs.
  var lo = 0;
  var hi = targets.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (targets[mid] < timeUs) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  int? best;
  var bestDistance = toleranceUs + 1;
  for (final i in [lo - 1, lo]) {
    if (i < 0 || i >= targets.length) continue;
    final distance = (targets[i] - timeUs).abs();
    if (distance < bestDistance) {
      best = targets[i];
      bestDistance = distance;
    }
  }
  return best;
}
