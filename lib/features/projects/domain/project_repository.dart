import 'package:cleancut/features/projects/domain/model/project.dart';

/// Stores projects.
abstract interface class ProjectRepository {
  /// All readable projects, most recently updated first.
  ///
  /// Unreadable or corrupt projects are skipped.
  Future<List<Project>> loadAll();

  /// The project with [id].
  ///
  /// Throws a [ProjectNotFoundException] when it does not exist.
  Future<Project> load(String id);

  /// Creates or overwrites [project]. Returns the stored project, whose
  /// `updatedAt` is set to the save time.
  Future<Project> save(Project project);

  /// Deletes the project with [id]; does nothing when it does not exist.
  Future<void> delete(String id);
}

/// Thrown when a project id is unknown.
final class ProjectNotFoundException implements Exception {
  /// Creates the exception.
  const new(this.id);

  /// The missing id.
  final String id;

  @override
  String toString() => 'ProjectNotFoundException: $id';
}

/// Thrown when a project file was written by a newer app version.
final class UnsupportedSchemaException implements Exception {
  /// Creates the exception.
  const new(this.found);

  /// Schema version found in the file.
  final int found;

  @override
  String toString() =>
      'UnsupportedSchemaException: file has schema $found, this app '
      'supports up to ${Project.currentSchemaVersion}';
}
