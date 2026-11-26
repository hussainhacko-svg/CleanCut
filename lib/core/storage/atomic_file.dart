import 'dart:async';
import 'dart:io';

/// Writes text files atomically, one write at a time per path.
///
/// Each write goes to its own temp file next to the target and is then
/// renamed over it, so a reader never sees a half-written file. Writes to
/// the same path are queued, so concurrent saves can't collide on a temp
/// file and always land in call order.
abstract final class AtomicFile {
  static final Map<String, Future<void>> _queues = {};
  static int _counter = 0;

  /// Replaces [target]'s contents with [contents].
  static Future<void> writeString(File target, String contents) {
    final key = target.absolute.path;
    final next = _after(_queues[key], () => _write(target, contents));
    _queues[key] = next;
    unawaited(_forget(key, next));
    return next;
  }

  static Future<void> _after(
    Future<void>? previous,
    Future<void> Function() action,
  ) async {
    try {
      await previous;
    } on Object {
      // An earlier write's error belongs to its own caller.
    }
    await action();
  }

  static Future<void> _forget(String key, Future<void> write) async {
    try {
      await write;
    } on Object {
      // Reported to the caller of writeString.
    } finally {
      // remove() returns the finished write itself; nothing to await.
      if (identical(_queues[key], write)) unawaited(_queues.remove(key));
    }
  }

  static Future<void> _write(File target, String contents) async {
    // Created inside the queue so callers needn't await anything before
    // writeString (that would let writes queue out of call order).
    await target.parent.create(recursive: true);
    final temp = File('${target.path}.${pid}_${_counter++}.tmp');
    try {
      await temp.writeAsString(contents, flush: true);
      await temp.rename(target.path);
    } on Object {
      if (temp.existsSync()) await temp.delete();
      rethrow;
    }
  }
}
