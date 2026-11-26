// Regression tests for the post-Phase-2 audit findings in storage.
import 'dart:convert';
import 'dart:io';

import 'package:cleancut/features/projects/data/file_project_repository.dart';
import 'package:cleancut/features/projects/data/project_codec.dart';
import 'package:cleancut/features/settings/data/file_settings_repository.dart';
import 'package:cleancut/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fixtures.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('cc_audit'));
  tearDown(() => dir.delete(recursive: true));

  test('decode rejects projects that break model invariants', () {
    const codec = ProjectCodec();
    final json = jsonDecode(
      codec.encode(project(mainSeconds: [1])),
    ) as Map<String, dynamic>;
    _firstClip(json)['speed'] = 0;
    expect(() => codec.decode(jsonEncode(json)), throwsFormatException);
  });

  test('loadAll skips a project that breaks invariants', () async {
    final repo = FileProjectRepository(dir, clock: () => testTime);
    await repo.save(project(id: 'good', mainSeconds: [1]));
    final bad = await repo.save(project(id: 'bad', mainSeconds: [1]));
    final file = File('${dir.path}/bad/project.json');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    _firstClip(json)['sourceOutUs'] = -5;
    file.writeAsStringSync(jsonEncode(json));
    expect(bad.id, 'bad');
    expect((await repo.loadAll()).map((p) => p.id), ['good']);
  });

  test('save can keep updatedAt (undo of a delete)', () async {
    final repo = FileProjectRepository(
      dir,
      clock: () => testTime.add(const Duration(days: 5)),
    );
    final p = project();
    final stored = await repo.save(p, keepUpdatedAt: true);
    expect(stored.updatedAt, p.updatedAt);
    expect((await repo.load(p.id)).updatedAt, p.updatedAt);
  });

  test('concurrent project saves do not collide', () async {
    final repo = FileProjectRepository(dir, clock: () => testTime);
    final p = project();
    await Future.wait([
      for (var i = 0; i < 20; i++) repo.save(p.copyWith(name: 'n$i')),
    ]);
    expect((await repo.load(p.id)).name, 'n19');
    expect(
      Directory('${dir.path}/${p.id}').listSync().map((e) => e.path),
      everyElement(endsWith('project.json')),
    );
  });

  test('concurrent settings saves keep the last value', () async {
    final repo = FileSettingsRepository(File('${dir.path}/settings.json'));
    await Future.wait([
      for (var i = 0; i < 20; i++)
        repo.save(
          AppSettings(
            theme: ThemePreference.values[i % ThemePreference.values.length],
          ),
        ),
    ]);
    expect(
      (await repo.load()).theme,
      ThemePreference.values[19 % ThemePreference.values.length],
    );
  });

  test('delete waits for an in-flight save on the same project', () async {
    final repo = FileProjectRepository(dir, clock: () => testTime);
    final p = project();
    await Future.wait([
      for (var i = 0; i < 10; i++) repo.save(p.copyWith(name: 'n$i')),
      repo.delete(p.id),
    ]);
    expect(await repo.loadAll(), isEmpty);
    expect(Directory('${dir.path}/${p.id}').existsSync(), isFalse);
  });
}

Map<String, dynamic> _firstClip(Map<String, dynamic> projectJson) {
  final track = projectJson['mainTrack'] as Map<String, dynamic>;
  return (track['clips'] as List<dynamic>).first as Map<String, dynamic>;
}
