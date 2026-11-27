import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/domain/model/tracks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';
part 'project.g.dart';

/// A video editing project: canvas settings plus tracks of clips.
///
/// Immutable. Change it only through `EditCommand`s so undo/redo works.
@freezed
abstract class Project with _$Project {
  /// Creates a project.
  const factory({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(Project.currentSchemaVersion) int schemaVersion,
    @Default(ProjectCanvas()) ProjectCanvas canvas,
    @Default(MainTrack()) MainTrack mainTrack,
    @Default(<LayerTrack>[]) List<LayerTrack> overlayTracks,
    @Default(<AudioTrack>[]) List<AudioTrack> audioTracks,
  }) = _Project;

  const new _();

  /// Parses a project from JSON of the current schema version.
  ///
  /// Older files must be migrated first (see the data layer).
  factory fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);

  /// Schema version written by this build. Bump it with a migration.
  ///
  /// 2: clips may have a `speedCurve` (Phase 4 Flow curves).
  /// 3: `canvas.background` replaces `canvas.backgroundArgb`; clips may
  /// have `crop` and `border` (Phase 5).
  /// 4: clips may have `filter` and `adjustments` (Phase 6A).
  /// 5: clips may have `blur` and `mask` (Phase 6B).
  static const int currentSchemaVersion = 5;

  /// Length of the whole edit: the end of the latest track.
  int get durationUs {
    var end = mainTrack.durationUs;
    for (final t in overlayTracks) {
      if (t.endUs > end) end = t.endUs;
    }
    for (final t in audioTracks) {
      if (t.endUs > end) end = t.endUs;
    }
    return end;
  }

  /// Number of clips on all tracks.
  int get clipCount =>
      mainTrack.clips.length +
      overlayTracks.fold<int>(0, (n, t) => n + t.items.length) +
      audioTracks.fold<int>(0, (n, t) => n + t.items.length);

  /// Broken invariants, as human-readable paths; empty when valid.
  List<String> validate() {
    final problems = <String>[];
    if (name.trim().isEmpty) problems.add('name: empty');
    if (canvas.fps <= 0) problems.add('canvas.fps: must be > 0');
    problems.addAll(canvas.background.validate().map((p) => 'canvas: $p'));
    if (canvas.shortSidePx <= 0) {
      problems.add('canvas.shortSidePx: must be > 0');
    }

    final clipIds = <String>{};
    void checkId(String path, String id) {
      if (!clipIds.add(id)) problems.add('$path: duplicate clip id $id');
    }

    for (final (i, clip) in mainTrack.clips.indexed) {
      final path = 'mainTrack.clips[$i]';
      checkId(path, clip.id);
      problems.addAll(clip.validate().map((p) => '$path: $p'));
    }

    final trackIds = <String>{};
    for (final (t, track) in overlayTracks.indexed) {
      final path = 'overlayTracks[$t]';
      if (!trackIds.add(track.id)) problems.add('$path: duplicate track id');
      for (final (i, item) in track.items.indexed) {
        checkId('$path.items[$i]', item.clip.id);
        if (item.startUs < 0) problems.add('$path.items[$i]: startUs < 0');
        problems.addAll(item.clip.validate().map((p) => '$path.items[$i]: $p'));
      }
      // Only valid items have a time range (an invalid speed or length
      // would throw); their own problems are reported above.
      final valid = [
        for (final (i, item) in track.items.indexed)
          if (item.clip.validate().isEmpty) (i, item.range),
      ];
      for (final (a, b) in findOverlaps([for (final (_, r) in valid) r])) {
        problems.add('$path: items ${valid[a].$1} and ${valid[b].$1} overlap');
      }
    }

    for (final (t, track) in audioTracks.indexed) {
      final path = 'audioTracks[$t]';
      if (!trackIds.add(track.id)) problems.add('$path: duplicate track id');
      for (final (i, item) in track.items.indexed) {
        checkId('$path.items[$i]', item.clip.id);
        if (item.startUs < 0) problems.add('$path.items[$i]: startUs < 0');
        problems.addAll(item.clip.validate().map((p) => '$path.items[$i]: $p'));
      }
      // Only valid items have a time range (an invalid speed or length
      // would throw); their own problems are reported above.
      final valid = [
        for (final (i, item) in track.items.indexed)
          if (item.clip.validate().isEmpty) (i, item.range),
      ];
      for (final (a, b) in findOverlaps([for (final (_, r) in valid) r])) {
        problems.add('$path: items ${valid[a].$1} and ${valid[b].$1} overlap');
      }
    }
    return problems;
  }
}
