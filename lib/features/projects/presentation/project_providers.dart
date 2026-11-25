import 'dart:io';

import 'package:cleancut/core/storage/app_directories.dart';
import 'package:cleancut/features/projects/data/file_project_repository.dart';
import 'package:cleancut/features/projects/domain/commands/project_commands.dart';
import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/domain/project_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'project_providers.g.dart';

/// Where projects are stored.
@Riverpod(keepAlive: true)
Future<ProjectRepository> projectRepository(Ref ref) async {
  final docs = await ref.watch(appDocumentsDirectoryProvider.future);
  return FileProjectRepository(
    Directory(joinPath(docs, ['projects'])),
    clock: ref.watch(clockProvider),
  );
}

/// Source of new unique ids.
@Riverpod(keepAlive: true)
IdGenerator idGenerator(Ref ref) => const Uuid().v4;

/// Current time; override in tests for deterministic timestamps.
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;

/// All projects, most recently edited first.
@Riverpod(keepAlive: true)
class ProjectList extends _$ProjectList {
  @override
  Future<List<Project>> build() async {
    final repo = await ref.watch(projectRepositoryProvider.future);
    return await repo.loadAll();
  }

  Future<ProjectRepository> get _repo =>
      ref.read(projectRepositoryProvider.future);

  /// Creates and stores a project holding [media] on its main track.
  Future<Project> create({
    required String name,
    required CanvasAspect aspect,
    required List<MediaRef> media,
  }) async {
    final newId = ref.read(idGeneratorProvider);
    final empty = newProject(
      id: newId(),
      name: name,
      now: ref.read(clockProvider)().toUtc(),
      aspect: aspect,
    );
    final project = AppendMediaCommand(media, newId: newId).apply(empty);
    final saved = await (await _repo).save(project);
    upsert(saved);
    return saved;
  }

  /// Renames the project [id].
  Future<void> rename(String id, String name) async {
    final repo = await _repo;
    final project = await repo.load(id);
    upsert(await repo.save(RenameProjectCommand(name).apply(project)));
  }

  /// Copies the project [id] under a new id and [name].
  Future<Project> duplicate(String id, String name) async {
    final repo = await _repo;
    final source = await repo.load(id);
    final now = ref.read(clockProvider)().toUtc();
    final copy = RenameProjectCommand(name).apply(
      source.copyWith(id: ref.read(idGeneratorProvider)(), createdAt: now),
    );
    final saved = await repo.save(copy);
    upsert(saved);
    return saved;
  }

  /// Deletes the project [id] and returns it so the deletion can be undone
  /// with [restore].
  Future<Project> delete(String id) async {
    final repo = await _repo;
    final project = await repo.load(id);
    await repo.delete(id);
    final current = state.value;
    if (current != null) {
      state = AsyncData([
        for (final p in current)
          if (p.id != id) p,
      ]);
    }
    return project;
  }

  /// Stores a project previously returned by [delete].
  Future<void> restore(Project project) async {
    upsert(await (await _repo).save(project));
  }

  /// Inserts or replaces [project] in the list, keeping the sort order.
  void upsert(Project project) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      [
        project,
        for (final p in current)
          if (p.id != project.id) p,
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }
}
