// Phase 4 dock actions on the selected main clip: split, duplicate, delete
// and the Speed panel.
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/presentation/editor/editor_state.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/speed_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/timeline/timeline_view.dart';
import 'package:cleancut/features/projects/presentation/editor/tool_dock.dart';
import 'package:cleancut/features/projects/presentation/project_screen.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../domain/fixtures.dart';

const s = 1000000;

void main() {
  late TestEnv env;

  Future<void> pumpEditor(WidgetTester tester) async {
    env = TestEnv(
      projects: [
        project(mainSeconds: [2, 3]),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: env.overrides,
        child: localizedApp(const ProjectScreen(projectId: 'p1')),
      ),
    );
    await tester.pumpAndSettle();
    env.engine.emitState(durationUs: 5 * s);
    await tester.pump();
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(ProjectScreen)));

  Project present(WidgetTester tester) =>
      containerOf(tester)
          .read(projectSessionProvider('p1'))
          .requireValue
          .history
          .present;

  List<String> ids(WidgetTester tester) => [
    for (final c in present(tester).mainTrack.clips) c.id,
  ];

  Future<void> selectClip(WidgetTester tester, int index) async {
    await tester.tap(find.byType(MainClipView).at(index));
    await tester.pump();
  }

  Future<void> tapTool(WidgetTester tester, String label) async {
    await tester.tap(find.byTooltip(label));
    await tester.pump();
  }

  testWidgets('Split cuts the selected clip at the playhead; undo', (
    tester,
  ) async {
    await pumpEditor(tester);
    await selectClip(tester, 1);
    env.engine.emitPosition(3 * s);
    await tester.pump();
    await tapTool(tester, 'Split');
    expect(ids(tester), ['m0', 'm1', 'new0']);
    expect(present(tester).mainTrack.clips[1].sourceOutUs, s);
    expect(find.byType(MainClipView), findsNWidgets(3));

    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    expect(ids(tester), ['m0', 'm1']);
  });

  testWidgets('Split explains when the playhead is outside the clip', (
    tester,
  ) async {
    await pumpEditor(tester);
    await selectClip(tester, 1);
    // The playhead is at 0, inside the first clip.
    await tapTool(tester, 'Split');
    expect(
      find.text('Move the playhead over the selected clip to split it.'),
      findsOneWidget,
    );
    expect(ids(tester), ['m0', 'm1']);
  });

  testWidgets('Duplicate inserts a copy after the clip', (tester) async {
    await pumpEditor(tester);
    await selectClip(tester, 0);
    await tapTool(tester, 'Duplicate');
    expect(ids(tester), ['m0', 'new0', 'm1']);
    expect(present(tester).durationUs, 7 * s);
  });

  testWidgets('Delete removes the clip without asking, and is undoable', (
    tester,
  ) async {
    await pumpEditor(tester);
    await selectClip(tester, 0);
    await tapTool(tester, 'Delete');
    expect(find.byType(AlertDialog), findsNothing);
    expect(ids(tester), ['m1']);
    // The selection went with the clip, so the add dock is back.
    expect(find.byTooltip('Add media'), findsOneWidget);

    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    expect(ids(tester), ['m0', 'm1']);
  });

  testWidgets('Speed opens the panel over the dock and edits the clip', (
    tester,
  ) async {
    await pumpEditor(tester);
    await selectClip(tester, 0);
    await tapTool(tester, 'Speed');
    expect(find.byType(SpeedPanel), findsOneWidget);
    expect(find.byType(ToolDock), findsNothing);

    tester.widget<SpeedPanel>(find.byType(SpeedPanel)).onChanged(2);
    await tester.pump();
    final clip = present(tester).mainTrack.clips.first;
    expect(clip.speed, 2);
    expect(present(tester).durationUs, 4 * s);
    expect(tester.widget<SpeedPanel>(find.byType(SpeedPanel)).speed, 2);

    tester.widget<SpeedPanel>(find.byType(SpeedPanel)).onKeepPitchChanged!(
      false,
    );
    await tester.pump();
    expect(present(tester).mainTrack.clips.first.keepPitch, isFalse);

    // Each change is its own undo step.
    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    expect(present(tester).mainTrack.clips.first.keepPitch, isTrue);
    expect(present(tester).mainTrack.clips.first.speed, 2);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    expect(find.byType(SpeedPanel), findsNothing);
    expect(find.byType(ToolDock), findsOneWidget);
  });

  testWidgets('the panel closes when the selection changes', (tester) async {
    await pumpEditor(tester);
    await selectClip(tester, 0);
    await tapTool(tester, 'Speed');
    containerOf(tester)
        .read(timelineSelectionControllerProvider('p1').notifier)
        .clear();
    await tester.pump();
    expect(find.byType(SpeedPanel), findsNothing);
    expect(containerOf(tester).read(openToolPanelProvider('p1')), isNull);
  });

  testWidgets('system back closes the panel before leaving', (tester) async {
    await pumpEditor(tester);
    await selectClip(tester, 0);
    await tapTool(tester, 'Speed');
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(SpeedPanel), findsNothing);
    expect(find.byType(ProjectScreen), findsOneWidget);
  });

  testWidgets('tablet shows the panel in place of the properties', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpEditor(tester);
    await selectClip(tester, 0);
    await tapTool(tester, 'Speed');
    expect(find.byType(SpeedPanel), findsOneWidget);
    expect(find.byType(PropertiesPanel), findsNothing);
    expect(find.byType(ToolRail), findsOneWidget);
  });
}
