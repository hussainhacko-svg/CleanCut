import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/tracks.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_scale.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_selection.dart';
import 'package:cleancut/features/projects/presentation/editor/editor_state.dart';
import 'package:cleancut/features/projects/presentation/editor/timeline/timeline_view.dart';
import 'package:cleancut/features/projects/presentation/editor/tool_dock.dart';
import 'package:cleancut/features/projects/presentation/playback/playback_controller.dart';
import 'package:cleancut/features/projects/presentation/project_screen.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../domain/fixtures.dart';

/// A project with two main clips (2 s + 3 s), one overlay and one audio
/// clip.
Project richProject() {
  final p = project(mainSeconds: [2, 3]);
  return p.copyWith(
    overlayTracks: [
      LayerTrack(
        id: 'o1',
        items: [
          PlacedClip(
            startUs: 1000000,
            clip: Clip.fromMedia(id: 'ov', media: image()),
          ),
        ],
      ),
    ],
    audioTracks: [
      AudioTrack(
        id: 'a1',
        items: [
          PlacedAudioClip(
            startUs: 0,
            clip: AudioClip(
              id: 'au',
              media: audio(),
              sourceInUs: 0,
              sourceOutUs: 4000000,
            ),
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('dockToolsFor', () {
    test('nothing selected shows the add tools in kit order', () {
      expect(dockToolsFor(TimelineSelection.none), [
        DockTool.add,
        DockTool.music,
        DockTool.voice,
        DockTool.text,
        DockTool.effect,
        DockTool.overlay,
        DockTool.ratio,
      ]);
    });

    test('a clip shows back first, then its tools', () {
      final tools = dockToolsFor(const MainClipSelection('c'));
      expect(tools.first, DockTool.back);
      expect(tools.take(7), [
        DockTool.back,
        DockTool.split,
        DockTool.filters,
        DockTool.crop,
        DockTool.adjust,
        DockTool.speed,
        DockTool.animation,
      ]);
      expect(
        dockToolsFor(const AudioSelection(trackId: 't', clipId: 'c')),
        contains(DockTool.volume),
      );
    });
  });

  group('Editor (phone)', () {
    Future<TestEnv> pumpEditor(WidgetTester tester, {Project? initial}) async {
      final env = TestEnv(projects: [initial ?? richProject()]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: localizedApp(const ProjectScreen(projectId: 'p1')),
        ),
      );
      await tester.pumpAndSettle();
      env.engine.emitState(durationUs: 5000000);
      await tester.pump();
      return env;
    }

    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(ProjectScreen)));

    testWidgets('shows the add dock, lanes and a transition marker', (
      tester,
    ) async {
      await pumpEditor(tester);
      for (final label in ['Music', 'Voice', 'Text', 'Effect', 'Ratio']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // "Overlay" is both a dock tool and the overlay pill's label.
      expect(find.text('Overlay'), findsNWidgets(2));
      expect(find.byTooltip('Add media'), findsOneWidget);
      expect(find.byType(MainClipView), findsNWidgets(2));
      expect(find.byType(LanePill), findsNWidgets(2));
      // One marker between the two main clips.
      expect(
        find.byWidgetPredicate(
          (w) => w is AppIcon && w.icon == AppIcons.transition,
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping a clip selects it and switches the dock', (
      tester,
    ) async {
      await pumpEditor(tester);
      await tester.tap(find.byType(MainClipView).first);
      await tester.pump();
      final view = tester.widget<MainClipView>(find.byType(MainClipView).first);
      expect(view.selected, isTrue);
      expect(find.text('Split'), findsOneWidget);
      // Other lanes step back while a main clip is selected.
      expect(
        tester.widgetList<LanePill>(find.byType(LanePill)).map((p) => p.dimmed),
        everyElement(isTrue),
      );

      await tester.tap(find.byTooltip('Back'));
      await tester.pump();
      expect(find.text('Music'), findsOneWidget);
      expect(
        containerOf(tester).read(timelineSelectionControllerProvider('p1')),
        TimelineSelection.none,
      );
    });

    testWidgets('tapping a selected pill again deselects it', (tester) async {
      await pumpEditor(tester);
      final overlay = find.byWidgetPredicate(
        (w) => w is LanePill && w.label == 'Overlay',
      );
      await tester.tap(overlay);
      await tester.pump();
      expect(tester.widget<LanePill>(overlay).selected, isTrue);
      await tester.tap(overlay);
      await tester.pump();
      expect(tester.widget<LanePill>(overlay).selected, isFalse);
    });

    testWidgets('selection is dropped when its clip disappears (undo)', (
      tester,
    ) async {
      final env = await pumpEditor(tester, initial: project(mainSeconds: [1]));
      env.picker.next = [video(seconds: 2)];
      await tester.tap(find.byTooltip('Add media'));
      await tester.pumpAndSettle();
      final container = containerOf(tester);
      final added = container
          .read(projectSessionProvider('p1'))
          .value!
          .history
          .present
          .mainTrack
          .clips
          .last;
      container
          .read(timelineSelectionControllerProvider('p1').notifier)
          .toggle(MainClipSelection(added.id));
      await tester.pump();
      expect(find.text('Split'), findsOneWidget);

      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(
        container.read(timelineSelectionControllerProvider('p1')),
        TimelineSelection.none,
      );
      expect(find.text('Music'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('add media appends the picked clips', (tester) async {
      final env = TestEnv(
        projects: [
          project(mainSeconds: [1]),
        ],
      );
      env.picker.next = [video(seconds: 2), image()];
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: localizedApp(const ProjectScreen(projectId: 'p1')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add media'));
      await tester.pumpAndSettle();
      final container = containerOf(tester);
      final present = container
          .read(projectSessionProvider('p1'))
          .value!
          .history
          .present;
      expect(present.mainTrack.clips, hasLength(3));
      // The preview reloaded with the new clips.
      expect(env.engine.specs.last.clips, hasLength(3));
      // Undo removes them again.
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(env.engine.specs.last.clips, hasLength(1));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('tools from later phases say they are coming', (tester) async {
      await pumpEditor(tester);
      await tester.tap(find.text('Music'));
      await tester.pump();
      expect(find.text('Coming in a later update.'), findsOneWidget);
    });

    testWidgets('dock items are at least 48dp', (tester) async {
      await pumpEditor(tester);
      for (final label in ['Add media', 'Music', 'Ratio']) {
        final size = tester.getSize(find.byTooltip(label));
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }
    });

    testWidgets('dragging the timeline scrubs and snaps to clip edges', (
      tester,
    ) async {
      final env = await pumpEditor(tester);
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final timeline = find.byType(TimelineView);
      // At the kit zoom 2 s = 45.6 px. The first 18 px are touch slop, so
      // 63 px of finger travel scrolls ~45 px: just short of the 2 s edge.
      final gesture = await tester.startGesture(tester.getCenter(timeline));
      for (var i = 0; i < 13; i++) {
        await gesture.moveBy(const Offset(-4.85, 0));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(env.engine.seeks, isNotEmpty);
      // The last seek landed exactly on the 2 s edge…
      expect(env.engine.seeks.last, 2000000);
      // …with a haptic tick.
      expect(
        calls.where((c) => c.method == 'HapticFeedback.vibrate'),
        isNotEmpty,
      );
    });

    testWidgets('the timeline follows playback', (tester) async {
      final env = await pumpEditor(tester);
      final scrollable = find.descendant(
        of: find.byType(TimelineView),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.pixels, 0);
      env.engine.emitPosition(5000000);
      await tester.pump();
      expect(position.pixels, closeTo(114, 0.5));
    });

    testWidgets('pinching zooms the timeline', (tester) async {
      await pumpEditor(tester);
      final center = tester.getCenter(find.byType(TimelineView));
      final a = await tester.startGesture(center - const Offset(20, 0));
      final b = await tester.startGesture(center + const Offset(20, 0));
      await tester.pump();
      await a.moveBy(const Offset(-20, 0));
      await b.moveBy(const Offset(20, 0));
      await tester.pump();
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
      final scale = containerOf(tester).read(timelineZoomProvider('p1'));
      expect(
        scale.pxPerSecond,
        closeTo(TimelineScale.defaultPxPerSecond * 2, 0.01),
      );
    });

    testWidgets('audio lanes draw the waveform', (tester) async {
      final env = TestEnv(projects: [richProject()]);
      env.engine.waveformData = WaveformData(
        peaks: Uint8List.fromList([0, 128, 255]),
        peaksPerSecond: 1,
        durationUs: 3000000,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: localizedApp(const ProjectScreen(projectId: 'p1')),
        ),
      );
      await tester.pumpAndSettle();
      final audioPill = find.byWidgetPredicate(
        (w) => w is LanePill && w.label == 'Audio',
      );
      expect(
        find.descendant(of: audioPill, matching: find.byType(CustomPaint)),
        findsWidgets,
      );
    });
  });

  group('Editor (tablet)', () {
    testWidgets('uses the rail and the properties panel', (tester) async {
      tester.view
        ..physicalSize = const Size(1280, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final env = TestEnv(projects: [richProject()]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: localizedApp(const ProjectScreen(projectId: 'p1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ToolRail), findsOneWidget);
      expect(find.byType(ToolDock), findsNothing);
      expect(find.byType(PropertiesPanel), findsOneWidget);
      expect(
        find.text('Select a clip on the timeline to edit it.'),
        findsOneWidget,
      );
      await tester.tap(find.byType(MainClipView).first);
      await tester.pump();
      expect(find.text('0:02'), findsOneWidget);
    });
  });

  test('the playback position provider starts at zero', () {
    final container = ProviderContainer(
      overrides: [mediaEngineProvider.overrideWithValue(FakeMediaEngine())],
    );
    addTearDown(container.dispose);
    expect(container.read(playbackPositionProvider('x')), 0);
  });
}
