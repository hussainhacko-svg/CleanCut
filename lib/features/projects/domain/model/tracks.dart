import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracks.freezed.dart';
part 'tracks.g.dart';

/// The main (magnetic) video track: clips play back to back, so a clip's
/// start is the sum of the durations before it.
@freezed
abstract class MainTrack with _$MainTrack {
  /// Creates the main track.
  const factory({@Default(<Clip>[]) List<Clip> clips}) = _MainTrack;

  const new _();

  /// Parses the main track from JSON.
  factory fromJson(Map<String, dynamic> json) => _$MainTrackFromJson(json);

  /// Total length.
  int get durationUs => clips.fold(0, (sum, c) => sum + c.durationUs);

  /// Timeline start of the clip at [index].
  int startOf(int index) {
    RangeError.checkValidIndex(index, clips);
    var start = 0;
    for (var i = 0; i < index; i++) {
      start += clips[i].durationUs;
    }
    return start;
  }

  /// Index of the clip playing at [timeUs], or `null` outside the track.
  ///
  /// At a boundary the later clip wins.
  int? indexAt(int timeUs) {
    if (timeUs < 0) return null;
    var start = 0;
    for (var i = 0; i < clips.length; i++) {
      final end = start + clips[i].durationUs;
      if (timeUs < end) return i;
      start = end;
    }
    return null;
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
