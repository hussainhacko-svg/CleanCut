import 'dart:convert';
import 'dart:io';

import 'package:cleancut/features/projects/data/autosaver.dart';
import 'package:cleancut/features/projects/data/file_project_repository.dart';
import 'package:cleancut/features/projects/data/project_codec.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fixtures.dart';

void main() {
  group('ProjectCodec', () {
    const codec = ProjectCodec();

    test('round-trips a project', () {
      final p = project(mainSeconds: [1, 2]);
      expect(codec.decode(codec.encode(p)), p);
    });

    test('rejects files from a newer app', () {
      final json = project().toJson()..['schemaVersion'] = 99;
      expect(
        () => codec.decode(jsonEncode(json)),
        throwsA(
          isA<UnsupportedSchemaException>().having((e) => e.found, 'found', 99),
        ),
      );
    });

    test('rejects malformed files', () {
      expect(() => codec.decode('[]'), throwsFormatException);
      expect(() => codec.decode('{"name": "x"}'), throwsFormatException);
      expect(() => codec.decode('not json'), throwsFormatException);
      expect(
        () => codec.decode('{"schemaVersion": 1, "name": "x"}'),
        throwsFormatException,
      );
    });

    test('runs migrations in order up to the current version', () {
      // Simulates a future schema 6 whose project name moved twice.
      final migrating = ProjectCodec(
        currentVersion: 6,
        migrations: {
          1: (json) => {...json, 'title': json['label']},
          2: (json) => {...json, 'name': json['title']},
          3: (json) => json,
          4: (json) => json,
          5: (json) => json,
        },
      );
      final v1 = project().toJson()
        ..remove('name')
        ..['label'] = 'Old'
        ..['schemaVersion'] = 1;
      final migrated = migrating.migrate(v1);
      expect(migrated['schemaVersion'], 6);
      expect(migrated['name'], 'Old');
    });

    test('fails loudly when a migration is missing', () {
      const gap = ProjectCodec(
        currentVersion: Project.currentSchemaVersion + 1,
      );
      expect(() => gap.migrate(project().toJson()), throwsStateError);
    });

    test('current schema has a migration for every older version', () {
      for (var v = 1; v < Project.currentSchemaVersion; v++) {
        expect(projectMigrations, contains(v));
      }
    });
  });

  group('FileProjectRepository', () {
    late Directory root;
    late FileProjectRepository repo;
    var now = testTime;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('cleancut_test');
      repo = FileProjectRepository(root, clock: () => now);
    });

    tearDown(() => root.delete(recursive: true));

    test('save stamps updatedAt and load reads it back', () async {
      now = testTime.add(const Duration(hours: 1));
      final stored = await repo.save(project(mainSeconds: [2]));
      expect(stored.updatedAt, now);
      expect(await repo.load('p1'), stored);
      expect(File('${root.path}/p1/project.json.tmp').existsSync(), isFalse);
    });

    test('loadAll sorts newest first and skips corrupt files', () async {
      now = testTime;
      await repo.save(project(id: 'old'));
      now = testTime.add(const Duration(days: 1));
      await repo.save(project(id: 'new'));
      await Directory('${root.path}/broken').create();
      await File('${root.path}/broken/project.json').writeAsString('{');
      await Directory('${root.path}/empty').create();

      final all = await repo.loadAll();
      expect(all.map((p) => p.id), ['new', 'old']);
    });

    test('loadAll on a missing root is empty', () async {
      await root.delete(recursive: true);
      expect(await repo.loadAll(), isEmpty);
      await root.create();
    });

    test('load of an unknown id throws', () {
      expect(repo.load('nope'), throwsA(isA<ProjectNotFoundException>()));
    });

    test('delete removes the project and tolerates unknown ids', () async {
      await repo.save(project());
      await repo.delete('p1');
      await repo.delete('p1');
      expect(await repo.loadAll(), isEmpty);
    });

    test('rejects ids that would escape the root', () {
      expect(repo.load('../x'), throwsArgumentError);
      expect(repo.delete('..'), throwsArgumentError);
    });
  });

  group('Autosaver', () {
    test('saves only the latest project after the delay', () async {
      final saved = <String>[];
      final autosaver =
          Autosaver(
              save: (p) async => saved.add(p.name),
              onError: (e, s) => fail('$e'),
              delay: const Duration(milliseconds: 10),
            )
            ..schedule(project().copyWith(name: 'a'))
            ..schedule(project().copyWith(name: 'b'));
      expect(autosaver.hasPending, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(saved, ['b']);
      expect(autosaver.hasPending, isFalse);
    });

    test('flush saves immediately and dispose saves the rest', () async {
      final saved = <String>[];
      final autosaver = Autosaver(
        save: (p) async => saved.add(p.name),
        onError: (e, s) => fail('$e'),
        delay: const Duration(hours: 1),
      )..schedule(project().copyWith(name: 'a'));
      await autosaver.flush();
      autosaver.schedule(project().copyWith(name: 'b'));
      await autosaver.dispose();
      expect(saved, ['a', 'b']);
    });

    test('timer save errors go to onError, flush errors to caller', () async {
      final errors = <Object>[];
      final autosaver = Autosaver(
        save: (p) async => throw StateError('disk full'),
        onError: (e, s) => errors.add(e),
        delay: const Duration(milliseconds: 1),
      )..schedule(project());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(errors, [isStateError]);

      autosaver.schedule(project());
      await expectLater(autosaver.flush(), throwsStateError);
      await autosaver.flush();
    });
  });
}
