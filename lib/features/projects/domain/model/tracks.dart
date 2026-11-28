import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_transition.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracks.freezed.dart';
part 'tracks.g.dart';

/// The main (magnetic) video track: clips play back to back, overlapping by
/// any [transitions] placed on their boundaries.
@freezed
abstract class MainTrack with _$MainTrack {
  /// Creates the main track.
  const factory({
    @Default(<Clip>[]) List<Clip> clips,
    @Default(<String, ClipTransition>{})
    Map<String, ClipTransition> transitions,
  }) = _MainTrack;

  const new _();

  /// Parses the main track from JSON.
  factory fromJson(Map<String, dynamic> json) => _$MainTrackFromJson(json);

  /// Transition between `clips[index]` and `clips[index + 1]`, or null.
  ClipTransition? transitionAfter(int index) {
    if (index < 0 || index >= clips.length - 1) return null;
    return transitions[clips[index].id];
  }

  /// Effective overlap in microseconds between `clips[index]` and
  /// `clips[index + 1]`. Always `0` when there is no transition, and capped at
  /// half the shorter neighbor so adjacent transitions never collide.
  int overlapAfter(int index) {
    final t = transitionAfter(index);
    if (t == null) return 0;
    return TransitionLimits.effectiveDurationUs(
      t.durationUs,
      clips[index].durationUs,
      clips[index + 1].durationUs,
    );
  }

  /// Effective overlap in microseconds before `clips[index]`.
  int overlapBefore(int index) => index <= 0 ? 0 : overlapAfter(index - 1);

  /// Total length: sum of clip lengths minus active transition overlaps.
  int get durationUs {
    if (clips.isEmpty) return 0;
    return startOf(clips.length - 1) + clips.last.durationUs;
  }

  /// Timeline start of the clip at [index].
  int startOf(int index) {
    RangeError.checkValidIndex(index, clips);
    var start = 0;
    for (var i = 0; i < index; i++) {
      start += clips[i].durationUs - overlapAfter(i);
    }
    return start;
  }

  /// Timeline end (exclusive) of the clip at [index].
  int endOf(int index) => startOf(index) + clips[index].durationUs;

  /// Midpoint of the boundary between `clips[index]` and `clips[index + 1]`
  /// (equals `endOf(index)` when there is no overlap).
  int boundaryCenterOf(int index) {
    RangeError.checkValidIndex(index, clips);
    if (index >= clips.length - 1) return endOf(index);
    return startOf(index + 1) + overlapAfter(index) ~/ 2;
  }

  /// Non-overlapping timeline span `(startUs, endUs)` assigned to
  /// `clips[index]` on the single-row timeline strip, splitting each
  /// transition overlap evenly at [boundaryCenterOf].
  (int, int) visualSlotOf(int index) {
    RangeError.checkValidIndex(index, clips);
    final slotStart = index == 0 ? 0 : boundaryCenterOf(index - 1);
    final slotEnd = index == clips.length - 1
        ? durationUs
        : boundaryCenterOf(index);
    return (slotStart, slotEnd);
  }

  /// Index of the clip playing at [timeUs], or `null` outside the track.
  ///
  /// At a boundary (or transition midpoint) the later clip wins.
  int? indexAt(int timeUs) {
    if (timeUs < 0 || clips.isEmpty) return null;
    for (var i = 0; i < clips.length; i++) {
      final (_, slotEnd) = visualSlotOf(i);
      if (timeUs < slotEnd) return i;
    }
    return null;
  }

  /// Broken invariants on [transitions], empty when valid.
  List<String> validateTransitions() {
    final problems = <String>[];
    final validBoundaryIds = <String>{
      for (var i = 0; i < clips.length - 1; i++) clips[i].id,
    };
    for (final entry in transitions.entries) {
      if (!validBoundaryIds.contains(entry.key)) {
        problems.add('transitions[${entry.key}]: not a valid clip boundary');
      }
      for (final p in entry.value.validate()) {
        problems.add('transitions[${entry.key}]: $p');
      }
    }
    return problems;
  }
}

/// A visual clip placed at a fixed time on a layer track.
@freezed
abstract class PlacedClip with _$PlacedClip {
  /// Creates a placed clip.
  const factory({required int startUs, required Clip clip}) = _PlacedClip;

  const new _();

  /// Parses a placed clip from JSON.
  factory fromJson(Map<String, dynamic> json) => _$PlacedClipFromJson(json);

  /// Time span on the timeline.
  TimeRange get range => TimeRange(startUs, startUs + clip.durationUs);
}

/// An overlay (picture-in-picture) track with freely placed clips.
@freezed
abstract class LayerTrack with _$LayerTrack {
  /// Creates a layer track.
  const factory({
    required String id,
    @Default(<PlacedClip>[]) List<PlacedClip> items,
  }) = _LayerTrack;

  const new _();

  /// Parses a layer track from JSON.
  factory fromJson(Map<String, dynamic> json) => _$LayerTrackFromJson(json);

  /// End of the last item.
  int get endUs =>
      items.fold(0, (end, i) => i.range.endUs > end ? i.range.endUs : end);
}

/// An audio clip placed at a fixed time on an audio track.
@freezed
abstract class PlacedAudioClip with _$PlacedAudioClip {
  /// Creates a placed audio clip.
  const factory({required int startUs, required AudioClip clip}) =
      _PlacedAudioClip;

  const new _();

  /// Parses a placed audio clip from JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$PlacedAudioClipFromJson(json);

  /// Time span on the timeline.
  TimeRange get range => TimeRange(startUs, startUs + clip.durationUs);
}

/// An audio track with freely placed clips.
@freezed
abstract class AudioTrack with _$AudioTrack {
  /// Creates an audio track.
  const factory({
    required String id,
    @Default(<PlacedAudioClip>[]) List<PlacedAudioClip> items,
  }) = _AudioTrack;

  const new _();

  /// Parses an audio track from JSON.
  factory fromJson(Map<String, dynamic> json) => _$AudioTrackFromJson(json);

  /// End of the last item.
  int get endUs =>
      items.fold(0, (end, i) => i.range.endUs > end ? i.range.endUs : end);
}

/// Returns pairs of indexes in [ranges] that overlap in time.
List<(int, int)> findOverlaps(List<TimeRange> ranges) {
  final order = List.generate(ranges.length, (i) => i)
    ..sort((a, b) => ranges[a].startUs.compareTo(ranges[b].startUs));
  final result = <(int, int)>[];
  for (var i = 0; i < order.length; i++) {
    for (var j = i + 1; j < order.length; j++) {
      if (ranges[order[j]].startUs >= ranges[order[i]].endUs) break;
      if (ranges[order[i]].overlaps(ranges[order[j]])) {
        result.add((order[i], order[j]));
      }
    }
  }
  return result;
}
