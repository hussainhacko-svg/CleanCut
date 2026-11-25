import 'dart:async';

import 'package:cleancut/features/projects/domain/model/project.dart';

/// Debounces project saves: only the latest project is written, [delay]
/// after the last change.
final class Autosaver {
  /// Creates an autosaver that writes with `save`. Errors from saves
  /// started by the timer go to [onError].
  new({
    required this._save,
    required this.onError,
    this.delay = const Duration(milliseconds: 800),
  });

  /// Receives errors of timer-triggered saves.
  final void Function(Object error, StackTrace stackTrace) onError;

  /// Quiet time before a scheduled save runs.
  final Duration delay;

  final Future<void> Function(Project project) _save;
  Timer? _timer;
  Project? _pending;
  Future<void> _inFlight = Future.value();

  /// Whether a save is scheduled but not yet started.
  bool get hasPending => _pending != null;

  /// Schedules [project] to be saved, replacing any pending project.
  void schedule(Project project) {
    _pending = project;
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(flush().catchError(onError)));
  }

  /// Saves the pending project now, after any save already running.
  /// Errors from the save are passed to the returned future.
  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    final project = _pending;
    _pending = null;
    // An earlier failure was already reported to its own caller.
    if (project == null) return _inFlight.catchError((Object _) {});
    return _inFlight = _inFlight
        .catchError((Object _) {})
        .then((_) => _save(project));
  }

  /// Stops the timer and saves anything pending.
  Future<void> dispose() => flush();
}
