import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_scale.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_selection.dart';
import 'package:cleancut/features/projects/presentation/playback/playback_controller.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editor_state.g.dart';

/// Horizontal zoom of a project's timeline.
@riverpod
class TimelineZoom extends _$TimelineZoom {
  @override
  TimelineScale build(String projectId) => TimelineScale.initial;

  /// Sets the zoom (clamped by [TimelineScale]).
  // A method so it can be passed around as a callback.
  // ignore: use_setters_to_change_properties
  void set(TimelineScale scale) => state = scale;
}

/// What is selected on a project's timeline. Drops the selection when its
/// item disappears (delete, undo).
@riverpod
class TimelineSelectionController extends _$TimelineSelectionController {
  @override
  TimelineSelection build(String projectId) {
    ref.listen(
      projectSessionProvider(projectId).select((s) => s.value?.history.present),
      (_, project) {
        if (project != null) state = state.validIn(project);
      },
    );
    return TimelineSelection.none;
  }

  /// Selects [selection]; selecting the current item again deselects it.
  void toggle(TimelineSelection selection) =>
      state = state == selection ? TimelineSelection.none : selection;

  /// Clears the selection.
  void clear() => state = TimelineSelection.none;
}

/// Audio peaks of [uri] for an audio lane (null when it has no audio).
@riverpod
Future<WaveformData?> clipWaveform(Ref ref, String uri) =>
    ref.watch(mediaEngineProvider).waveform(uri);
