import 'package:cleancut/features/projects/domain/commands/project_commands.dart';
import 'package:cleancut/features/projects/domain/history/history.dart';
import 'package:cleancut/features/projects/presentation/project_providers.dart';
import 'package:cleancut/features/projects/presentation/project_screen.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../domain/fixtures.dart';

void main() {
  group('ProjectSession', () {
    late TestEnv env;
    late ProviderContainer container;

    setUp(() {
      env = TestEnv(
        projects: [
          project(mainSeconds: [1]),
        ],
      );
      container = ProviderContainer.test(overrides: env.overrides);
    });

    Future<ProjectSession> open() async {
      container.listen(projectSessionProvider('p1'), (_, _) {});
      await container.read(projectSessionProvider('p1').future);
      final session = container.read(projectSessionProvider('p1').notifier);
      return session;
    }

    History history() =>
        container.read(projectSessionProvider('p1')).requireValue.history;

    test('apply, undo and redo update the present project', () async {
      final session = await open();
      session.apply(const RenameProjectCommand('A'));
      expect(history().present.name, 'A');
      session.undo();
      expect(history().present.name, 'Test project');
      session.redo();
      expect(history().present.name, 'A');
    });

    test('flush saves and refreshes the project list', () async {
      await container.read(projectListProvider.future);
      final session = await open();
      env.repo.now = testTime.add(const Duration(minutes: 5));
      session.apply(const RenameProjectCommand('Saved'));
      await session.flush();

      expect(env.repo.projects['p1']!.name, 'Saved');
      final list = container.read(projectListProvider).requireValue;
      expect(list.single.name, 'Saved');
      expect(list.single.updatedAt, env.repo.now);
    });

    test('undo/redo with no change does not save', () async {
      final session = await open();
      session.undo();
      await session.flush();
      expect(env.repo.saveCount, 0);
    });
  });

  testWidgets('editor undo button reverts an edit and reloads the preview', (
    tester,
  ) async {
    final env = TestEnv(
      projects: [
        project(mainSeconds: [2]),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: env.overrides,
        child: localizedApp(const ProjectScreen(projectId: 'p1')),
      ),
    );
    await tester.pumpAndSettle();
    // The preview loaded the project.
    expect(env.engine.specs, hasLength(1));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProjectScreen)),
    );
    String name() => container
        .read(projectSessionProvider('p1'))
        .value!
        .history
        .present
        .name;
    container
        .read(projectSessionProvider('p1').notifier)
        .apply(const RenameProjectCommand('Renamed'));
    await tester.pump();
    expect(name(), 'Renamed');
    // Every edit reloads the preview.
    expect(env.engine.specs, hasLength(2));

    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    expect(name(), 'Test project');
    expect(env.engine.specs, hasLength(3));

    // Let the debounced autosave run so no timer is left pending.
    await tester.pump(const Duration(seconds: 1));
    expect(env.repo.projects['p1']!.name, 'Test project');
  });

  testWidgets('unknown project shows a message', (tester) async {
    final env = TestEnv();
    await tester.pumpWidget(
      ProviderScope(
        overrides: env.overrides,
        child: localizedApp(const ProjectScreen(projectId: 'gone')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('This project no longer exists.'), findsOneWidget);
  });
}
