// Phase 7A: adding, selecting, trimming, moving, and editing overlay clips.
import 'package:cleancut/features/projects/domain/commands/overlay_commands.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/time.dart';
import 'package:cleancut/features/projects/presentation/editor/overlays/transform_gizmo.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/transform_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/timeline/timeline_view.dart';
import 'package:cleancut/features/projects/presentation/project_screen.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../domain/fixtures.dart';

const int s = Micros.perSecond;

void main() {
  late TestEnv env;

  Future<void> pumpEditor(WidgetTester tester, {Project? initial}) async {
    env = TestEnv(
      projects: [
        initial ?? project(mainSeconds: [6]),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: env.overrides,
        child: localizedApp(const ProjectScreen(projectId: 'p1')),
      ),
    );
    await tester.pumpAndSettle();
    env.engine.emitState(
      durationUs: (initial ?? project(mainSeconds: [6])).durationUs,
    );
    await tester.pump();
  }

  Project present(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(ProjectScreen)))
          .read(projectSessionProvider('p1'))
          .requireValue
          .history
          .present;

  testWidgets(
    'Overlay dock tool adds muted 50% PiP, selects it, and sends to engine',
    (tester) async {
      await pumpEditor(tester);
      env.engine.emitPosition(1 * s);
      await tester.pump();

      env.picker.next = [video(seconds: 3, uri: 'content://overlay/v1')];
      await tester.tap(find.byTooltip('Overlay'));
      await tester.pumpAndSettle();

      final p = present(tester);
      expect(p.overlayTracks, hasLength(1));
      final item = p.overlayTracks.single.items.single;
      expect(item.startUs, 1 * s);
      expect(item.clip.muted, isTrue);
      expect(item.clip.transform.at(0).scale, defaultOverlayScale);

      // Auto-selected: clip dock & TransformGizmo are shown immediately.
      expect(find.byTooltip('Transform'), findsOneWidget);
      expect(find.byType(TransformGizmo), findsOneWidget);
      expect(find.byType(LanePill), findsOneWidget);

      // Engine received overlayTracks with muted flag.
      final lastSpec = env.engine.specs.last;
      expect(lastSpec.overlayTracks, hasLength(1));
      expect(lastSpec.overlayTracks.single.clips.single.startUs, 1 * s);
      expect(lastSpec.overlayTracks.single.clips.single.clip.muted, isTrue);

      // Undo removes the overlay cleanly.
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(present(tester).overlayTracks, isEmpty);
    },
  );

  testWidgets(
    'Overlay clip supports Transform panel, Split, Duplicate, and Delete',
    (tester) async {
      var p = project(mainSeconds: [8]);
      p = AddOverlayCommand(
        [image(uri: 'content://overlay/photo')],
        atUs: 1 * s,
        newId: () => 'ov0',
        newTrackId: () => 'ot0',
      ).apply(p);
      await pumpEditor(tester, initial: p);

      // Select overlay pill.
      await tester.tap(find.byType(LanePill));
      await tester.pump();

      // Open Transform panel on overlay.
      await tester.tap(find.byTooltip('Transform'));
      await tester.pumpAndSettle();
      expect(find.byType(TransformPanel), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      // Split overlay at 2.5s (1.5s into [1s..4s]).
      env.engine.emitPosition(2500000);
      await tester.pump();
      await tester.tap(find.byTooltip('Split'));
      await tester.pump();
      expect(present(tester).overlayTracks.single.items, hasLength(2));

      // Duplicate first half.
      await tester.tap(find.byTooltip('Duplicate'));
      await tester.pump();
      final totalOverlays = present(tester).overlayTracks
          .fold<int>(0, (sum, t) => sum + t.items.length);
      expect(totalOverlays, 3);

      // Delete removes the selected overlay cleanly.
      await tester.tap(find.byTooltip('Delete'));
      await tester.pump();
      final afterDelete = present(tester).overlayTracks
          .fold<int>(0, (sum, t) => sum + t.items.length);
      expect(afterDelete, 2);
    },
  );

  testWidgets('Overlay trim handle and long-press drag update overlay timing', (
    tester,
  ) async {
    var p = project(mainSeconds: [10]);
    p = AddOverlayCommand(
      [image(uri: 'content://overlay/photo')],
      atUs: 2 * s,
      newId: () => 'ov0',
      newTrackId: () => 'ot0',
    ).apply(p);
    await pumpEditor(tester, initial: p);

    // Select overlay to reveal trim handles.
    await tester.tap(find.byType(LanePill));
    await tester.pump();
    final endHandle = find.byKey(const ValueKey('overlayTrimEnd'));
    expect(endHandle, findsOneWidget);

    // Drag right trim handle right -> lengthens still overlay past 3s.
    await tester.drag(endHandle, const Offset(46, 0));
    await tester.pumpAndSettle();
    final afterTrim = present(tester).overlayTracks.single.items.single;
    expect(afterTrim.clip.durationUs, greaterThan(3 * s));

    // Long-press drag pill right -> shifts startUs forward.
    final beforeMoveStart = afterTrim.startUs;
    final pillCenter = tester.getCenter(find.byType(LanePill));
    final gesture = await tester.startGesture(pillCenter);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(46, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final afterMove = present(tester).overlayTracks.single.items.single;
    expect(afterMove.startUs, greaterThan(beforeMoveStart));
  });

  testWidgets('a selected short overlay can still be long-press moved', (
    tester,
  ) async {
    var p = project(mainSeconds: [10]);
    p = AddOverlayCommand(
      [image(uri: 'content://overlay/photo')],
      atUs: 2 * s,
      newId: () => 'ov0',
      newTrackId: () => 'ot0',
    ).apply(p);
    // 1 s at the default zoom is narrower than two 48dp trim targets.
    p = const TrimOverlayCommand(
      'ov0',
      startUs: 2 * s,
      sourceInUs: 0,
      sourceOutUs: 1 * s,
    ).apply(p);
    await pumpEditor(tester, initial: p);
    await tester.tap(find.byType(LanePill));
    await tester.pump();
    expect(find.byKey(const ValueKey('overlayTrimEnd')), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(LanePill)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(46, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final item = present(tester).overlayTracks.single.items.single;
    expect(item.startUs, greaterThan(2 * s));
    expect(item.clip.durationUs, 1 * s);
  });

  testWidgets('undoing a lane move keeps the overlay selected', (tester) async {
    var p = project(mainSeconds: [10]);
    p = AddOverlayCommand(
      [image(uri: 'content://overlay/a')],
      atUs: 1 * s,
      newId: () => 'ovA',
      newTrackId: () => 'otA',
    ).apply(p);
    p = AddOverlayCommand(
      [image(uri: 'content://overlay/b')],
      atUs: 6 * s,
      newId: () => 'ovB',
      newTrackId: () => 'otB',
    ).apply(p);
    // Both share lane otA; ovB moves onto its own new top lane.
    expect(p.overlayTracks, hasLength(1));
    await pumpEditor(tester, initial: p);
    final pillB = find.byType(LanePill).at(1);
    await tester.tap(pillB);
    await tester.pump();

    final gesture = await tester.startGesture(tester.getCenter(pillB));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(present(tester).overlayTracks, hasLength(2));
    expect(find.byKey(const ValueKey('overlayTrimEnd')), findsOneWidget);

    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(present(tester).overlayTracks, hasLength(1));
    // Still selected on its old lane: clip tools and trim handles remain.
    expect(find.byTooltip('Split'), findsOneWidget);
    expect(find.byKey(const ValueKey('overlayTrimEnd')), findsOneWidget);
  });
}
