// Regression tests for the post-Phase-2 audit findings in playback and the
// editor screen.
import 'dart:async';

import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/domain/commands/project_commands.dart';
import 'package:cleancut/features/projects/presentation/home_screen.dart';
import 'package:cleancut/features/projects/presentation/playback/playback_controller.dart';
import 'package:cleancut/features/projects/presentation/playback/preview_widgets.dart';
import 'package:cleancut/features/projects/presentation/project_screen.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../domain/fixtures.dart';

void main() {
  group('Playback controller', () {
    late FakeMediaEngine engine;
    late ProviderContainer container;

    setUp(() {
      engine = FakeMediaEngine();
      container = ProviderContainer(
        overrides: [mediaEngineProvider.overrideWithValue(engine)],
      );
      addTearDown(container.dispose);
    });

    Future<Playback> start() async {
      container
        ..listen(playbackProvider('p1'), (_, _) {})
        ..listen(playbackPositionProvider('p1'), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      final playback = container.read(playbackProvider('p1').notifier);
      return playback;
    }

    test('ignores events of another preview', () async {
      await start();
      engine
        ..emitState(textureId: 99, durationUs: 1, isPlaying: true)
        ..emitPosition(5, textureId: 99)
        ..emitError(textureId: 99);
      final state = container.read(playbackProvider('p1'));
      expect(state.isPlaying, isFalse);
      expect(state.durationUs, 0);
      expect(state.error, isNull);
      expect(container.read(playbackPositionProvider('p1')), 0);
    });

    test('play waits for the seek still in flight', () async {
      final playback = await start();
      engine
        ..emitState(durationUs: 10000000)
        ..seekGate = Completer<void>();
      final seek = playback.seekTo(4000000);
      final play = playback.play();
      await Future<void>.delayed(Duration.zero);
      expect(engine.calls, isNot(contains('play')));
      engine.seekGate!.complete();
      await Future.wait([seek, play]);
      expect(engine.calls.sublist(engine.calls.indexOf('seek')), [
        'seek',
        'play',
      ]);
    });

    test('calls after dispose never reach the engine', () async {
      engine.createGate = Completer<void>();
      container.listen(playbackProvider('p1'), (_, _) {});
      final playback = container.read(playbackProvider('p1').notifier);
      final toggle = playback.togglePlay();
      final seek = playback.seekTo(5);
      container.dispose();
      engine.createGate!.complete();
      await Future.wait([toggle, seek]);
      expect(engine.calls, isNot(contains('play')));
      expect(engine.calls, isNot(contains('seek')));
    });

    test('loading the same composition twice sends it once', () async {
      final playback = await start();
      final p = project(mainSeconds: [2]);
      await playback.load(p);
      await playback.load(p.copyWith(name: 'Renamed'));
      expect(engine.specs, hasLength(1));
      await playback.load(project(mainSeconds: [3]));
      expect(engine.specs, hasLength(2));
    });
  });

  group('Editor screen', () {
    testWidgets('a project that fails to load creates no preview', (
      tester,
    ) async {
      final env = TestEnv();
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: localizedApp(const ProjectScreen(projectId: 'gone')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('This project no longer exists.'), findsOneWidget);
      expect(env.engine.calls, isNot(contains('create')));
    });

    testWidgets('renaming does not reload the preview', (tester) async {
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
      expect(env.engine.specs, hasLength(1));
      ProviderScope.containerOf(tester.element(find.byType(ProjectScreen)))
          .read(projectSessionProvider('p1').notifier)
          .apply(const RenameProjectCommand('Renamed'));
      await tester.pump();
      // Neither reloaded nor recreated.
      expect(env.engine.calls, ['create', 'set']);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('an empty project shows the canvas, not a stale frame', (
      tester,
    ) async {
      final env = TestEnv(projects: [project()]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: localizedApp(const ProjectScreen(projectId: 'p1')),
        ),
      );
      await tester.pumpAndSettle();
      // The native side reports an empty timeline for an empty project.
      env.engine.emitState(status: PlaybackStatus.idle, durationUs: 0);
      await tester.pump();
      expect(find.byType(Texture), findsNothing);
      env.engine.emitState(durationUs: 3000000);
      await tester.pump();
      expect(find.byType(Texture), findsOneWidget);
    });

    testWidgets('double-tapping Home leaves the editor only once', (
      tester,
    ) async {
      final env = TestEnv(
        projects: [
          project(mainSeconds: [1]),
        ],
      );
      await env.pumpApp(tester);
      await tester.tap(find.text('Test project'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Home'));
      await tester.tap(find.byTooltip('Home'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(ProjectScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('ScrubBar', () {
    Future<void> pumpBar(WidgetTester tester, TextDirection direction) async {
      final env = TestEnv();
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: localizedApp(
            Directionality(
              textDirection: direction,
              child: const Scaffold(body: ScrubBar(projectId: 'p1')),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('is a 48dp touch target', (tester) async {
      await pumpBar(tester, TextDirection.ltr);
      expect(
        tester.getSize(find.byType(Slider)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('runs left to right in RTL locales', (tester) async {
      await pumpBar(tester, TextDirection.rtl);
      final direction = Directionality.of(tester.element(find.byType(Slider)));
      expect(direction, TextDirection.ltr);
    });
  });
}
