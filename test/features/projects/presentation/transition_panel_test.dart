import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/domain/commands/transition_commands.dart';
import 'package:cleancut/features/projects/domain/model/clip_transition.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_selection.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/transition_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/timeline/timeline_view.dart';
import 'package:cleancut/features/projects/presentation/editor/tool_dock.dart';
import 'package:cleancut/features/projects/presentation/project_screen.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../domain/fixtures.dart';

void main() {
  group('TimelineMetrics.transitionTapReach', () {
    test('gives full 48dp target on normal clips and protects short clips', () {
      expect(TimelineMetrics.transitionTapReach(100), 24);
      expect(TimelineMetrics.transitionTapReach(48), 24);
      expect(TimelineMetrics.transitionTapReach(30), closeTo(9, 1e-6));
      expect(TimelineMetrics.transitionTapReach(20), closeTo(6, 1e-6));
      expect(TimelineMetrics.transitionTapReach(8), 0);
    });
  });

  group('TransitionPanel', () {
    testWidgets(
      'switches categories, picks transition, edits duration, applies to all '
      'and resets',
      (tester) async {
        ClipTransition? current;
        var dragged = 0;
        var ended = 0;
        var appliedAll = 0;
        var closed = 0;

        await tester.pumpWidget(
          localizedApp(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => TransitionPanel(
                  transition: current,
                  maxDurationUs: 2000000,
                  canApplyAll: true,
                  onSelect: (t) => setState(() => current = t),
                  onDurationDrag: (us) {
                    dragged++;
                    setState(() => current = current?.copyWith(durationUs: us));
                  },
                  onDurationDragEnd: () => ended++,
                  onDurationSet: (us) => setState(
                    () => current = current?.copyWith(durationUs: us),
                  ),
                  onApplyAll: () => appliedAll++,
                  onClose: () => closed++,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Transition'), findsOneWidget);
        expect(find.text('Basic'), findsOneWidget);
        expect(find.text('Slide'), findsOneWidget);
        expect(find.text('Wipe'), findsOneWidget);
        expect(find.text('Zoom'), findsOneWidget);
        expect(find.text('Duration'), findsNothing);

        // Pick Dissolve from Basic.
        await tester.tap(find.text('Dissolve'));
        await tester.pump();
        expect(current, const ClipTransition(type: TransitionType.dissolve));
        expect(find.text('Duration'), findsOneWidget);
        expect(find.text('0.5s'), findsOneWidget);

        // Switch to Slide tab and pick Slide left (keeps 0.5 s duration).
        await tester.tap(find.text('Slide'));
        await tester.pump();
        await tester.tap(find.text('Slide left'));
        await tester.pump();
        expect(current?.type, TransitionType.slideLeft);
        expect(current?.durationUs, 500000);

        // Tap value pill and type 1.2 s.
        await tester.tap(find.text('0.5s'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '1.2');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(current?.durationUs, 1200000);
        expect(find.text('1.2s'), findsOneWidget);

        // Drag slider.
        await tester.drag(find.byType(Slider), const Offset(30, 0));
        await tester.pump();
        expect(dragged, greaterThan(0));
        expect(ended, 1);

        // Apply to all.
        await tester.tap(find.text('Apply to all'));
        expect(appliedAll, 1);

        // Reset clears back to None.
        await tester.tap(find.text('Reset'));
        await tester.pump();
        expect(current, isNull);
        expect(find.text('Duration'), findsNothing);

        await tester.tap(find.byTooltip('Close'));
        expect(closed, 1);
      },
    );

    testWidgets('shows message when adjacent clips are too short', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: TransitionPanel(
              transition: null,
              maxDurationUs: 50000,
              onSelect: (_) {},
              onDurationDrag: (_) {},
              onDurationDragEnd: () {},
              onDurationSet: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );
      expect(
        find.text('Clips are too short for a transition.'),
        findsOneWidget,
      );
    });
  });

  group('PropertiesPanel transition summary', () {
    Future<void> pumpSummary(WidgetTester tester, List<num> seconds) async {
      final p = const SetTransitionCommand(
        'm0',
        ClipTransition(type: TransitionType.dissolve),
      ).apply(project(mainSeconds: seconds));
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: PropertiesPanel(
              project: p,
              selection: const TransitionSelection('m0'),
            ),
          ),
        ),
      );
    }

    testWidgets('shows the played duration', (tester) async {
      await pumpSummary(tester, [4, 4]);
      expect(find.text('0.5s'), findsOneWidget);
    });

    testWidgets('says too short instead of 0.0s on very short clips', (
      tester,
    ) async {
      await pumpSummary(tester, [4, 0.15]);
      expect(
        find.text('Clips are too short for a transition.'),
        findsOneWidget,
      );
      expect(find.text('0.0s'), findsNothing);
    });
  });

  group('Editor integration (Phase 6C)', () {
    testWidgets(
      'tapping transition marker opens panel, updates composition, applies to '
      'all and undoes',
      (tester) async {
        final env = TestEnv(
          projects: [
            project(mainSeconds: [4, 4, 4]),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: env.overrides,
            child: localizedApp(const ProjectScreen(projectId: 'p1')),
          ),
        );
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(ProjectScreen)),
        );
        Map<String, ClipTransition> currentTransitions() => container
            .read(projectSessionProvider('p1'))
            .requireValue
            .history
            .present
            .mainTrack
            .transitions;

        // Tap transition marker between clips 1 and 2.
        await tester.tap(
          find.byKey(const ValueKey(('transitionMarker', 'm0'))),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TransitionPanel), findsOneWidget);

        // Pick Dissolve -> duration shrinks by 0.5 s & engine gets spec.
        await tester.tap(find.text('Dissolve'));
        await tester.pump();
        expect(currentTransitions()['m0']?.type, TransitionType.dissolve);
        expect(
          env.engine.specs.last.clips.first.transitionOut?.type,
          SpecTransitionType.dissolve,
        );
        expect(
          env.engine.specs.last.clips.first.transitionOut?.durationUs,
          500000,
        );

        // Apply to all sets both boundaries.
        await tester.ensureVisible(find.text('Apply to all'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply to all'));
        await tester.pump();
        expect(currentTransitions().keys, containsAll(['m0', 'm1']));

        // Undo reverts Apply to all, then reverts Dissolve.
        await tester.tap(find.byTooltip('Undo'));
        await tester.pump();
        expect(currentTransitions().keys, ['m0']);

        await tester.tap(find.byTooltip('Undo'));
        await tester.pump();
        expect(currentTransitions(), isEmpty);

        // Close panel clears selection.
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(TransitionPanel), findsNothing);
      },
    );
  });
}
