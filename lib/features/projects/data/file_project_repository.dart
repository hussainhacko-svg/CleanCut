import 'dart:io';

import 'package:cleancut/features/projects/data/project_codec.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/project_repository.dart';

/// Stores each project as `<root>/<id>/project.json`.
///
/// Writes go to a temporary file first and are renamed into place, so a
/// crash mid-save never leaves a truncated project.
final class FileProjectRepository implements ProjectRepository {
  /// Creates a repository under [root]; [clock] stamps `updatedAt`.
  new(
    this.root, {
    this._codec = const ProjectCodec(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Directory holding one sub-directory per project.
  final Directory root;

  final ProjectCodec _codec;
  final DateTime Function() _clock;

  static const _fileName = 'project.json';

  Directory _dirOf(String id) {
    if (id.isEmpty || id.contains(RegExp(r'[\\/]')) || id.startsWith('.')) {
      throw ArgumentError.value(id, 'id', 'is not a safe directory name');
    }
    return Directory('${root.path}${Platform.pathSeparator}$id');
  }

  File _fileOf(String id) =>
      File('${_dirOf(id).path}${Platform.pathSeparator}$_fileName');

  @override
  Future<List<Project>> loadAll() async {
    if (!root.existsSync()) return [];
    final projects = <Project>[];
    await for (final entry in root.list()) {
      if (entry is! Directory) continue;
      final file = File('${entry.path}${Platform.pathSeparator}$_fileName');
      if (!file.existsSync()) continue;
      try {
        projects.add(_codec.decode(await file.readAsString()));
      } on Exception {
        // A corrupt or newer project must not hide the others.
        continue;
      }
    }
    return projects..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<Project> load(String id) async {
    final file = _fileOf(id);
    if (!file.existsSync()) throw ProjectNotFoundException(id);
    return _codec.decode(await file.readAsString());
  }

  @override
  Future<Project> save(Project project) async {
    final stored = project.copyWith(updatedAt: _clock().toUtc());
    final dir = _dirOf(project.id);
    await dir.create(recursive: true);
    final target = _fileOf(project.id);
    final temp = File('${target.path}.tmp');
    await temp.writeAsString(_codec.encode(stored), flush: true);
    await temp.rename(target.path);
    return stored;
  }

  @override
  Future<void> delete(String id) async {
    final dir = _dirOf(id);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}
