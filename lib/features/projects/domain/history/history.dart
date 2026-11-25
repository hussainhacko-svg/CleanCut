import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Immutable undo/redo history of a [Project].
///
/// Stores whole project snapshots; the model is immutable, so unchanged
/// parts are shared between snapshots.
@immutable
final class History {
  const new _({
    required this.present,
    required this._past,
    required this._future,
    required this.limit,
    this._openCoalesceKey,
  });

  /// Starts a history at [project] keeping at most [limit] undo steps.
  factory initial(Project project, {int limit = 100}) {
    if (limit < 1) throw ArgumentError.value(limit, 'limit', 'must be >= 1');
    return History._(
      present: project,
      past: const [],
      future: const [],
      limit: limit,
    );
  }

  /// The current project.
  final Project present;

  /// Maximum number of undo steps kept.
  final int limit;

  final List<Project> _past;
  final List<Project> _future;
  final Object? _openCoalesceKey;

  /// Whether [undo] changes anything.
  bool get canUndo => _past.isNotEmpty;

  /// Whether [redo] changes anything.
  bool get canRedo => _future.isNotEmpty;

  /// Number of available undo steps.
  int get undoDepth => _past.length;

  /// Number of available redo steps.
  int get redoDepth => _future.length;

  /// Applies [command] and records an undo step.
  ///
  /// If [command] has the same non-null [EditCommand.coalesceKey] as the
  /// previous command and [seal] was not called in between, it replaces
  /// the present without a new undo step. A command that changes nothing
  /// returns this history unchanged. Clears the redo stack.
  ///
  /// Throws an [InvalidEditException] from the command.
  History apply(EditCommand command) {
    final next = command.apply(present);
    if (next == present) return this;

    final key = command.coalesceKey;
    if (key != null && key == _openCoalesceKey) {
      return History._(
        present: next,
        past: _past,
        future: const [],
        limit: limit,
        openCoalesceKey: key,
      );
    }

    final past = [..._past, present];
    return History._(
      present: next,
      past: List.unmodifiable(
        past.length > limit ? past.sublist(past.length - limit) : past,
      ),
      future: const [],
      limit: limit,
      openCoalesceKey: key,
    );
  }

  /// Ends the current coalescing run (call when a drag gesture ends), so
  /// the next command starts a new undo step.
  History seal() => _openCoalesceKey == null
      ? this
      : History._(present: present, past: _past, future: _future, limit: limit);

  /// Steps back one edit; returns this history when [canUndo] is false.
  History undo() {
    if (!canUndo) return this;
    return History._(
      present: _past.last,
      past: List.unmodifiable(_past.sublist(0, _past.length - 1)),
      future: List.unmodifiable([present, ..._future]),
      limit: limit,
    );
  }

  /// Re-applies one undone edit; returns this history when [canRedo] is
  /// false.
  History redo() {
    if (!canRedo) return this;
    return History._(
      present: _future.first,
      past: List.unmodifiable([..._past, present]),
      future: List.unmodifiable(_future.sublist(1)),
      limit: limit,
    );
  }
}
