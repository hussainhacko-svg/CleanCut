import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_color.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/adjust_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/filters_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/timeline/timeline_view.dart';
import 'package:cleancut/features/projects/presentation/project_screen.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../domain/fixtures.dart';

void main() {
  group('FiltersPanel', () {
    testWidgets(
      'switches categories, picks a filter, adjusts intensity and resets',
      (tester) async {
        ClipFilter? current;
        final dragged = <double>[];
        var ended = 0;
        var closed = 0;

        Future<void> pump(WidgetTester tester) => tester.pumpWidget(
          localizedApp(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => FiltersPanel(
                  filter: current,
                  onSelect: (next) => setState(() => current = next),
                  onIntensityDrag: (v) {
                    dragged.add(v);
                    setState(() => current = current?.copyWith(intensity: v));
                  },
                  onIntensityDragEnd: () => ended++,
                  onIntensitySet: (v) =>
                      setState(() => current = current?.copyWith(intensity: v)),
                  onClose: () => closed++,
                ),
              ),
            ),
          ),
        );

        await pump(tester);
        expect(find.text('Film'), findsOneWidget);
        expect(find.text('Vibrant'), findsOneWidget);
        expect(find.text('B&W'), findsOneWidget);
        expect(find.text('None'), findsOneWidget);
        expect(find.text('Gold'), findsOneWidget);
        expect(find.text('Intensity'), findsNothing);

        // Switch to B&W category and pick Noir.
        await tester.tap(find.text('B&W'));
        await tester.pump();
        expect(find.text('Noir'), findsOneWidget);
        await tester.tap(find.text('Noir'));
        await tester.pump();
        expect(current, const ClipFilter(id: 'bw_noir'));
        expect(find.text('Intensity'), findsOneWidget);

        // Type exact intensity 60%.
        await tester.tap(find.text('100%'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '60');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(current?.intensity, closeTo(0.6, 1e-9));

        // Drag intensity slider.
        await tester.drag(find.byType(Slider), const Offset(-40, 0));
        await tester.pump();
        expect(dragged, isNotEmpty);
        expect(ended, 1);

        // Reset clears the filter back to None.
        await tester.tap(find.text('Reset'));
        await tester.pump();
        expect(current, isNull);
        expect(find.text('Intensity'), findsNothing);

        await tester.tap(find.byTooltip('Close'));
        expect(closed, 1);
      },
    );
  });

  group('AdjustPanel', () {
    testWidgets(
      'selects adjustment chips, types values, resets field and resets all',
      (tester) async {
        var current = ClipAdjustments.none;
        var ended = 0;

        await tester.pumpWidget(
          localizedApp(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => AdjustPanel(
                  adjustments: current,
                  onDrag: (next) => setState(() => current = next),
                  onDragEnd: () => ended++,
                  onSet: (next) => setState(() => current = next),
                  onClose: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Exposure'), findsNWidgets(2));
        expect(find.text('Contrast'), findsOneWidget);

        // Type +40 for Exposure.
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '40');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(current.exposure, closeTo(0.4, 1e-9));
        expect(find.text('+40'), findsOneWidget);

        // Switch to Contrast and drag slider.
        await tester.tap(find.text('Contrast'));
        await tester.pump();
        await tester.drag(find.byType(Slider), const Offset(50, 0));
        await tester.pump();
        expect(current.contrast, greaterThan(0));
        expect(ended, 1);

        // Single-field reset restores only Contrast, keeping Exposure.
        await tester.tap(find.byTooltip('Reset Contrast'));
        await tester.pump();
        expect(current.contrast, 0);
        expect(current.exposure, closeTo(0.4, 1e-9));

        // Panel Reset restores all fields to zero.
        await tester.tap(find.text('Reset'));
        await tester.pump();
        expect(current, ClipAdjustments.none);
      },
    );
  });

  group('Editor integration', () {
    testWidgets(
      'Filters and Adjust dock tools edit the clip and undo cleanly',
      (tester) async {
        final env = TestEnv(
          projects: [
            project(mainSeconds: [3]),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: env.overrides,
            child: localizedApp(const ProjectScreen(projectId: 'p1')),
          ),
        );
        await tester.pumpAndSettle();

        // Select clip -> open Filters.
        await tester.tap(find.byType(MainClipView).first);
        await tester.pump();
        await tester.tap(find.byTooltip('Filters'));
        await tester.pumpAndSettle();
        expect(find.byType(FiltersPanel), findsOneWidget);
        expect(env.engine.filterPreviewCalls, isNotEmpty);

        await tester.tap(find.text('Gold'));
        await tester.pump();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(ProjectScreen)),
        );
        Clip currentClip() => container
            .read(projectSessionProvider('p1'))
            .requireValue
            .history
            .present
            .mainTrack
            .clips
            .first;

        expect(currentClip().filter, const ClipFilter(id: 'film_gold'));
        expect(env.engine.specs.last.clips.first.style.filterId, 'film_gold');

        // Close Filters -> open Adjust -> apply brightness.
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Adjust'));
        await tester.pumpAndSettle();
        expect(find.byType(AdjustPanel), findsOneWidget);

        tester
            .widget<AdjustPanel>(find.byType(AdjustPanel))
            .onSet(const ClipAdjustments(brightness: 0.35));
        await tester.pump();
        expect(currentClip().adjustments.brightness, 0.35);
        expect(
          env.engine.specs.last.clips.first.style.adjustments.brightness,
          0.35,
        );

        // Undo reverts Adjust, then Filters.
        await tester.tap(find.byTooltip('Undo'));
        await tester.pump();
        expect(currentClip().adjustments, ClipAdjustments.none);
        await tester.tap(find.byTooltip('Undo'));
        await tester.pump();
        expect(currentClip().filter, isNull);
      },
    );
  });
}
