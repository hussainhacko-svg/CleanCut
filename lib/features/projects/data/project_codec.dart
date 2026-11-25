import 'dart:convert';

import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/project_repository.dart';

/// Upgrades raw project JSON by exactly one schema version.
typedef JsonMigration = Map<String, dynamic> Function(Map<String, dynamic>);

/// Encodes and decodes project files, migrating older schemas.
final class ProjectCodec {
  /// Creates a codec. [migrations] maps version `n` to the migration that
  /// produces version `n + 1`; [currentVersion] is the version written.
  const new({
    this.migrations = projectMigrations,
    this.currentVersion = Project.currentSchemaVersion,
  });

  /// Migrations by source version.
  final Map<int, JsonMigration> migrations;

  /// Version this codec reads into and writes.
  final int currentVersion;

  /// Serializes [project] as indented JSON.
  String encode(Project project) =>
      const JsonEncoder.withIndent('  ')
          .convert(project.copyWith(schemaVersion: currentVersion).toJson());

  /// Parses a project file.
  ///
  /// Throws a [FormatException] for malformed files and an
  /// [UnsupportedSchemaException] for files newer than [currentVersion].
  Project decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Project file is not a JSON object');
    }
    final migrated = migrate(decoded);
    try {
      return Project.fromJson(migrated);
    } on Object catch (e) {
      // json_serializable reports missing or mistyped fields as TypeError.
      throw FormatException('Invalid project file: $e');
    }
  }

  /// Applies migrations until [json] reaches [currentVersion].
  Map<String, dynamic> migrate(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version is! int || version < 1) {
      throw FormatException('Invalid schemaVersion: $version');
    }
    if (version > currentVersion) throw UnsupportedSchemaException(version);

    var current = json;
    for (var v = version; v < currentVersion; v++) {
      final migration = migrations[v];
      if (migration == null) {
        throw StateError('No migration from schema $v');
      }
      current = {...migration(current), 'schemaVersion': v + 1};
    }
    return current;
  }
}

/// Project schema migrations, keyed by the version they upgrade from.
///
/// When bumping `Project.currentSchemaVersion` to `n + 1`, add entry `n`
/// here and a migration test.
const Map<int, JsonMigration> projectMigrations = {};
