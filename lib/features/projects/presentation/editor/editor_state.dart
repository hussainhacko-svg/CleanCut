import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/domain/model/clip_color.dart';
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

/// Tool panels that open over the dock (phone) or in the properties panel
/// (tablet).
enum ToolPanelKind {
  /// Constant speed + keep pitch (kit "Speed").
  speed,

  /// Crop presets, rotation, mirror and flip (kit "Crop").
  crop,

  /// Fill mode, position/scale/rotation, opacity and border.
  transform,

  /// Canvas aspect ratio and background.
  ratio,

  /// Bundled LUT filter presets and intensity.
  filters,

  /// Color and tone adjustments.
  adjust,

  /// Whole-clip Gaussian blur.
  blur,

  /// Shape mask with feather, invert, and on-preview handles.
  mask,
}

/// The tool panel open in a project's editor, if any. Closes whenever the
/// selection changes, since every panel edits the selected clip.
@riverpod
class OpenToolPanel extends _$OpenToolPanel {
  @override
  ToolPanelKind? build(String projectId) {
    ref.listen(timelineSelectionControllerProvider(projectId), (prev, next) {
      if (prev != next) state = null;
    });
    return null;
  }

  /// Opens [panel].
  // A method to match close(); a setter would read oddly here.
  // ignore: use_setters_to_change_properties
  void open(ToolPanelKind panel) => state = panel;

  /// Closes the open panel.
  void close() => state = null;
}

/// Whether a project's preview is open full screen. The editor's own
/// preview tweaks (e.g. the uncropped clip under the crop handles) pause
/// while it is, so full screen always shows the real result.
@riverpod
class PreviewFullscreen extends _$PreviewFullscreen {
  @override
  bool build(String projectId) => false;

  /// Marks the full screen preview as open or closed.
  // A method to match OpenToolPanel; a setter would read oddly here.
  // ignore: use_setters_to_change_properties
  void set({required bool open}) => state = open;
}

/// Audio peaks of [uri] for an audio lane (null when it has no audio).
@riverpod
Future<WaveformData?> clipWaveform(Ref ref, String uri) =>
    ref.watch(mediaEngineProvider).waveform(uri);

/// Cached LUT-graded preview JPEG paths for every bundled [FilterPreset] on a
/// frame of [uri] at [timeUs].
@riverpod
Future<Map<String, String?>> clipFilterPreviews(
  Ref ref,
  String uri,
  int timeUs,
  int heightPx,
) => ref
    .watch(mediaEngineProvider)
    .filterPreviews(
      uri,
      timeUs,
      heightPx: heightPx,
      filterIds: [for (final p in FilterPreset.all) p.id],
    );
