import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/presentation/home_screen.dart';
import 'package:cleancut/features/projects/presentation/project_card.dart';
import 'package:cleancut/features/projects/presentation/project_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../domain/fixtures.dart';

Future<void> openMenu(WidgetTester tester, String projectName) async {
  await tester.tap(find.byTooltip('Options for $projectName'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the empty state without projects', (tester) async {
    await TestEnv().pumpApp(tester);
    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.text('New project'), findsOneWidget);
  });

  testWidgets('lists projects newest first with clip summary', (tester) async {
    final env = TestEnv(
      projects: [
        project(id: 'a', mainSeconds: [65]).copyWith(name: 'Older'),
        project(id: 'b').copyWith(
          name: 'Newer',
          updatedAt: testTime.add(const Duration(days: 1)),
        ),
      ],
    );
    await env.pumpApp(tester);

    final names = tester
        .widgetList<ProjectCard>(find.byType(ProjectCard))
        .map((c) => c.project.name);
    expect(names, ['Newer', 'Older']);
    expect(find.text('01:05'), findsOneWidget);
  });

  testWidgets('new project: pick media, choose aspect, open editor', (
    tester,
  ) async {
    final env = TestEnv();
    env.picker.next = [video(seconds: 3), image()];
    await env.pumpApp(tester);

    await tester.tap(find.text('New project'));
    await tester.pumpAndSettle();
    expect(find.text('Canvas size'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);

    await tester.tap(find.text('9:16'));
    await tester.pumpAndSettle();

    final created = env.repo.projects.values.single;
    expect(created.id, 'new0');
    expect(created.canvas.aspect, CanvasAspect.portrait9x16);
    expect(created.mainTrack.clips.map((c) => c.id), ['new1', 'new2']);
    expect(created.name, 'Project Nov 26, 2026');
    expect(find.byType(ProjectScreen), findsOneWidget);
    expect(env.engine.specs.single.clips, hasLength(2));
  });

  testWidgets('cancelling the picker creates nothing', (tester) async {
    final env = TestEnv();
    await env.pumpApp(tester);

    await tester.tap(find.text('New project'));
    await tester.pumpAndSettle();

    expect(env.picker.calls, 1);
    expect(find.text('Canvas size'), findsNothing);
    expect(env.repo.projects, isEmpty);
  });

  testWidgets('dismissing the aspect sheet creates nothing', (tester) async {
    final env = TestEnv();
    env.picker.next = [video()];
    await env.pumpApp(tester);

    await tester.tap(find.text('New project'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(env.repo.projects, isEmpty);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('rename updates the card', (tester) async {
    final env = TestEnv(projects: [project()]);
    await env.pumpApp(tester);

    await openMenu(tester, 'Test project');
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Holiday  ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Holiday'), findsOneWidget);
    expect(env.repo.projects['p1']!.name, 'Holiday');
  });

  testWidgets('duplicate adds a copy', (tester) async {
    final env = TestEnv(
      projects: [
        project(mainSeconds: [1]),
      ],
    );
    await env.pumpApp(tester);

    await openMenu(tester, 'Test project');
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(find.text('Test project copy'), findsOneWidget);
    expect(env.repo.projects['new0']!.mainTrack.clips, hasLength(1));
  });

  testWidgets('delete can be undone from the snackbar', (tester) async {
    final env = TestEnv(projects: [project()]);
    await env.pumpApp(tester);

    await openMenu(tester, 'Test project');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectCard), findsNothing);
    expect(env.repo.projects, isEmpty);
    expect(find.text('Deleted "Test project"'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectCard), findsOneWidget);
    expect(env.repo.projects, contains('p1'));
  });

  testWidgets('undoing a delete keeps the project in its old place', (
    tester,
  ) async {
    final env = TestEnv(
      projects: [
        project(id: 'old').copyWith(name: 'Older'),
        project(id: 'new').copyWith(
          name: 'Newer',
          updatedAt: testTime.add(const Duration(days: 1)),
        ),
      ],
    );
    await env.pumpApp(tester);
    // Time passes before the user deletes and undoes.
    env.repo.now = testTime.add(const Duration(days: 9));

    await openMenu(tester, 'Older');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    final names = tester
        .widgetList<ProjectCard>(find.byType(ProjectCard))
        .map((c) => c.project.name);
    expect(names, ['Newer', 'Older']);
    expect(env.repo.projects['old']!.updatedAt, testTime);
  });

  testWidgets('delete snackbar dismisses itself', (tester) async {
    final env = TestEnv(projects: [project()]);
    await env.pumpApp(tester);

    await openMenu(tester, 'Test project');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Deleted "Test project"'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Deleted "Test project"'), findsNothing);
    expect(env.repo.projects, isEmpty);
  });

  test('originalAspectOf uses the first media with a size', () {
    expect(originalAspectOf([audio(), video()]), CanvasAspect.landscape16x9);
    expect(originalAspectOf([image()]), CanvasAspect.portrait4x5);
    expect(originalAspectOf([audio()]), isNull);
  });
}
