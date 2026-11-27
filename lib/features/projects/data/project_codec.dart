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
  /// Throws a [FormatException] for malformed files or projects that fail
  /// `Project.validate`, and an
  /// [UnsupportedSchemaException] for files newer than [currentVersion].
  Project decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Project file is not a JSON object');
    }
    final migrated = migrate(decoded);
    final Project project;
    try {
      project = Project.fromJson(migrated);
    } on Object catch (e) {
      // json_serializable reports missing or mistyped fields as TypeError.
      throw FormatException('Invalid project file: $e');
    }
    // Well-formed JSON can still break invariants (speed 0, negative
    // lengths) that would crash playback later; refuse it here.
    final problems = project.validate();
    if (problems.isNotEmpty) {
      throw FormatException('Invalid project: ${problems.join('; ')}');
    }
    return project;
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
const Map<int, JsonMigration> projectMigrations = {
  // 1 -> 2: clips gained an optional `speedCurve`; a missing one means a
  // constant speed, so v1 files need no change.
  1: _addSpeedCurves,
  // 2 -> 3: the canvas color became a `background` union; clips gained
  // `crop` and `border`, whose defaults (no crop, no border) need no data.
  2: _canvasBackground,
};

Map<String, dynamic> _addSpeedCurves(Map<String, dynamic> json) => json;

Map<String, dynamic> _canvasBackground(Map<String, dynamic> json) {
  final canvas = json['canvas'];
  if (canvas is! Map<String, dynamic>) return json;
  final argb = canvas['backgroundArgb'];
  return {
    ...json,
    'canvas': {
      for (final e in canvas.entries)
        if (e.key != 'backgroundArgb') e.key: e.value,
      if (argb is int) 'background': {'type': 'color', 'argb': argb},
    },
  };
}
