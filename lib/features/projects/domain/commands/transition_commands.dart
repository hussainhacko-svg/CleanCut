/// Editing transitions between adjacent main-track clips (Phase 6C).
library;

import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/model/clip_transition.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';

/// Sets (or clears with `null`) the transition immediately after main-track
/// clip [afterClipId].
///
/// The clip must exist on the main track and have a following clip. Duration
/// slider drags pass `coalesce: true` and call `session.seal()` on release;
/// preset taps, typed values and reset pass `coalesce: false`.
final class SetTransitionCommand extends EditCommand {
  /// Creates the command.
  const new(this.afterClipId, this.transition, {this.coalesce = false});

  /// Id of the clip before the boundary.
  final String afterClipId;

  /// New transition, or null to remove it (hard cut).
  final ClipTransition? transition;

  /// Whether consecutive edits on the same boundary merge into one undo step.
  final bool coalesce;

  @override
  Object? get coalesceKey =>
      coalesce ? (SetTransitionCommand, afterClipId) : null;

  @override
  Project apply(Project project) {
    final clips = project.mainTrack.clips;
    final index = clips.indexWhere((c) => c.id == afterClipId);
    if (index < 0 || index >= clips.length - 1) {
      throw InvalidEditException('No transition boundary after $afterClipId');
    }
    if (transition case final t?) {
      final problems = t.validate();
      if (problems.isNotEmpty) {
        throw InvalidEditException('Invalid transition: $problems');
      }
    }
    final current = project.mainTrack.transitions[afterClipId];
    if (current == transition) return project;
    final updated = Map<String, ClipTransition>.of(
      project.mainTrack.transitions,
    );
    if (transition == null) {
      updated.remove(afterClipId);
    } else {
      updated[afterClipId] = transition!;
    }
    return project.copyWith(
      mainTrack: project.mainTrack.copyWith(transitions: updated),
    );
  }
}

/// Applies [transition] (or clears all with `null`) to every boundary on the
/// main track in one undo step.
final class ApplyTransitionToAllCommand extends EditCommand {
  /// Creates the command.
  const new(this.transition);

  /// Transition to apply to every boundary, or null to clear all.
  final ClipTransition? transition;

  @override
  Project apply(Project project) {
    final clips = project.mainTrack.clips;
    if (clips.length < 2) return project;
    if (transition case final t?) {
      final problems = t.validate();
      if (problems.isNotEmpty) {
        throw InvalidEditException('Invalid transition: $problems');
      }
    }
    final updated = <String, ClipTransition>{};
    if (transition case final t?) {
      for (var i = 0; i < clips.length - 1; i++) {
        updated[clips[i].id] = t;
      }
    }
    final current = project.mainTrack.transitions;
    if (current.length == updated.length &&
        updated.entries.every((e) => current[e.key] == e.value)) {
      return project;
    }
    return project.copyWith(
      mainTrack: project.mainTrack.copyWith(transitions: updated),
    );
  }
}
