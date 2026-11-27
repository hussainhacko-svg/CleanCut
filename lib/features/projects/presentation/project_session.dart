import 'dart:async';

import 'package:cleancut/features/projects/data/autosaver.dart';
import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/history/history.dart';
import 'package:cleancut/features/projects/presentation/project_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'project_session.g.dart';

/// State of an open project.
@immutable
final class SessionState {
  /// Creates the state.
  const new({required this.history, this.saveFailed = false});

  /// Undo/redo history; `history.present` is the project.
  final History history;

  /// Whether the last save attempt failed.
  final bool saveFailed;

  @override
  bool operator ==(Object other) =>
      other is SessionState &&
      identical(other.history, history) &&
      other.saveFailed == saveFailed;

  @override
  int get hashCode => Object.hash(identityHashCode(history), saveFailed);
}

/// An open project: applies [EditCommand]s, undo/redo and autosave.
@riverpod
class ProjectSession extends _$ProjectSession {
  Autosaver? _autosaver;

  @override
  Future<SessionState> build(String projectId) async {
    final repo = await ref.watch(projectRepositoryProvider.future);
    final project = await repo.load(projectId);
    final autosaver = Autosaver(
      save: (p) async {
        final saved = await repo.save(p, onlyIfExists: true);
        if (!ref.mounted) return;
        ref.read(projectListProvider.notifier).upsert(saved);
        _setSaveFailed(false);
      },
      onError: (error, stack) {
        if (ref.mounted) _setSaveFailed(true);
      },
    );
    _autosaver = autosaver;
    ref.onDispose(() => unawaited(autosaver.dispose()));
    return SessionState(history: History.initial(project));
  }

  void _setSaveFailed(bool failed) {
    final current = state.value;
    if (current == null || current.saveFailed == failed) return;
    state = AsyncData(
      SessionState(history: current.history, saveFailed: failed),
    );
  }

  void _update(History Function(History) change) {
    final current = state.value;
    if (current == null) return;
    final next = change(current.history);
    if (identical(next, current.history)) return;
    state = AsyncData(
      SessionState(history: next, saveFailed: current.saveFailed),
    );
    if (next.present != current.history.present) {
      _autosaver?.schedule(next.present);
    }
  }

  /// Applies [command]. Throws an [InvalidEditException] when rejected.
  void apply(EditCommand command) => _update((h) => h.apply(command));

  /// Ends a coalescing gesture (e.g. finger lifted after a drag).
  void seal() => _update((h) => h.seal());

  /// Undoes the last edit.
  void undo() => _update((h) => h.undo());

  /// Redoes the last undone edit.
  void redo() => _update((h) => h.redo());

  /// Saves pending changes now. Call before leaving the editor.
  Future<void> flush() async {
    try {
      await _autosaver?.flush();
    } on Exception {
      if (ref.mounted) _setSaveFailed(true);
    }
  }
}
