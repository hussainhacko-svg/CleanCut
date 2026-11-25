import 'package:cleancut/features/projects/domain/model/project.dart';

/// Creates unique ids for new model objects (clips, tracks).
typedef IdGenerator = String Function();

/// A single, undoable change to a [Project].
///
/// Commands are pure: [apply] returns a new project and never mutates the
/// input. Implementations live next to the feature that issues them.
abstract class EditCommand {
  /// Allows subclasses to be const.
  const new();

  /// Returns [project] with this edit applied.
  ///
  /// Throws an [InvalidEditException] when the edit cannot be applied.
  Project apply(Project project);

  /// Consecutive commands with the same non-null key merge into one undo
  /// step (e.g. every tick of a slider drag). `null` never merges.
  Object? get coalesceKey => null;
}

/// Thrown when an [EditCommand] cannot be applied to a project.
final class InvalidEditException implements Exception {
  /// Creates the exception with a developer-facing [message].
  const new(this.message);

  /// Why the edit was rejected.
  final String message;

  @override
  String toString() => 'InvalidEditException: $message';
}
