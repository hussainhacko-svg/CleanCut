import 'package:cleancut/engine/engine_api.g.dart';
import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/presentation/playback/playback_controller.dart';
import 'package:cleancut/features/projects/presentation/playback/preview_widgets.dart';
import 'package:cleancut/features/projects/presentation/project_screen.dart';
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
      // Keep the auto-disposed providers alive during the test.
      container
        ..listen(playbackProvider('p1'), (_, _) {})
        ..listen(playbackPositionProvider('p1'), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      final playback = container.read(playbackProvider('p1').notifier);
      return playback;
    }

    PlaybackState state() => container.read(playbackProvider('p1'));

    test('creates the preview and exposes its texture', () async {
      await start();
      expect(engine.calls, ['create']);
      expect(state().textureId, 7);
    });

    test('load sends the composition and clears errors', () async {
      final playback = await start();
      engine.emitError();
      expect(state().error, isNotNull);
      await playback.load(project(mainSeconds: [2]));
      expect(engine.specs.single.clips, hasLength(1));
      expect(state().error, isNull);
    });

    test('native events update state and position', () async {
      await start();
      engine.emitState(isPlaying: true, durationUs: 9000000, positionUs: 5);
      expect(state().isPlaying, isTrue);
      expect(state().durationUs, 9000000);
      expect(container.read(playbackPositionProvider('p1')), 5);
      engine.emitPosition(1234);
      expect(container.read(playbackPositionProvider('p1')), 1234);
    });

    test('togglePlay plays when paused and pauses when playing', () async {
      final playback = await start();
      await playback.togglePlay();
      engine.emitState(isPlaying: true);
      await playback.togglePlay();
      expect(engine.calls, ['create', 'play', 'pause']);
    });

    test('seek clamps to the duration and a burst collapses to the '
        'latest target', () async {
      final playback = await start();
      engine.emitState(durationUs: 1000);
      await Future.wait([
        playback.seekTo(400),
        playback.seekTo(-5),
        playback.seekTo(5000),
      ]);
      expect(engine.seeks, [1000]);
      expect(container.read(playbackPositionProvider('p1')), 1000);

      await playback.seekTo(-5);
      expect(engine.seeks, [1000, 0]);
    });

    test('an error stops playing', () async {
      await start();
      engine
        ..emitState(isPlaying: true)
        ..emitError();
      expect(state().isPlaying, isFalse);
      expect(state().error?.code, 'ERROR');
    });

    test('disposing releases only its own preview', () async {
      await start();
      container.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(engine.calls.last, 'dispose:7');
    });
  });

  group('Editor', () {
    Future<TestEnv> pumpEditor(WidgetTester tester) async {
      final env = TestEnv(
        projects: [
          project(mainSeconds: [12]),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: localizedApp(const ProjectScreen(projectId: 'p1')),
        ),
      );
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets('shows the preview texture and the timecode', (tester) async {
      final env = await pumpEditor(tester);
      expect(tester.widget<Texture>(find.byType(Texture)).textureId, 7);
      env.engine
        ..emitState()
        ..emitPosition(6000000);
      await tester.pump();
      expect(find.text('00:06 / 00:12'), findsOneWidget);
    });

    testWidgets('play button toggles and shows pause while playing', (
      tester,
    ) async {
      final env = await pumpEditor(tester);
      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      expect(env.engine.calls, contains('play'));
      env.engine.emitState(isPlaying: true);
      await tester.pump();
      expect(find.byTooltip('Pause'), findsOneWidget);
    });

    testWidgets('undo and redo are disabled without history', (tester) async {
      await pumpEditor(tester);
      final undo = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Undo'),
          matching: find.byType(IconButton),
        ),
      );
      expect(undo.onPressed, isNull);
    });

    testWidgets('controls are at least 48dp', (tester) async {
      await pumpEditor(tester);
      for (final label in ['Play', 'Undo', 'Redo', 'Full screen', 'Home']) {
        final size = tester.getSize(find.byTooltip(label));
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }
    });

    testWidgets('export explains that it is not ready yet', (tester) async {
      await pumpEditor(tester);
      await tester.tap(find.byTooltip('Export'));
      await tester.pump();
      expect(find.text('Export is coming in a later update.'), findsOneWidget);
    });

    testWidgets('a playback error shows a message', (tester) async {
      final env = await pumpEditor(tester);
      env.engine.emitError();
      await tester.pump();
      expect(find.text("Couldn't play this project's media."), findsOneWidget);
    });

    testWidgets('full screen scrubs with pause and resume', (tester) async {
      final env = await pumpEditor(tester);
      env.engine.emitState(isPlaying: true);
      await tester.tap(find.byTooltip('Full screen'));
      await tester.pumpAndSettle();
      expect(find.byType(FullscreenPreview), findsOneWidget);
      expect(tester.widget<Texture>(find.byType(Texture)).textureId, 7);

      env.engine.calls.clear();
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(80, 0));
      await tester.pumpAndSettle();
      expect(env.engine.calls.first, 'pause');
      expect(env.engine.seeks, isNotEmpty);
      // It was playing before the drag, so playback resumes.
      expect(env.engine.calls.last, 'play');
      expect(env.engine.calls, contains('seek'));

      await tester.tap(find.byTooltip('Exit full screen').first);
      await tester.pumpAndSettle();
      expect(find.byType(FullscreenPreview), findsNothing);
    });
  });

  group('PlatformMediaEngine', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('forwards native events to its streams', () async {
      final engine = PlatformMediaEngine(api: _NoopHostApi());
      addTearDown(engine.dispose);
      final positions = <int>[];
      final errors = <EngineError>[];
      engine.positions.listen(positions.add);
      engine.errors.listen(errors.add);
      engine
        ..onPosition(42)
        ..onError('E', 'msg');
      expect(positions, [42]);
      expect(errors.single.code, 'E');
    });

    test('delegates calls to the host API', () async {
      final api = _NoopHostApi();
      final engine = PlatformMediaEngine(api: api);
      addTearDown(engine.dispose);
      expect(await engine.createPreview(), 3);
      await engine.seekTo(10);
      expect(api.seeks, [10]);
    });
  });
}

class _NoopHostApi implements EngineHostApi {
  final seeks = <int>[];

  @override
  Future<int> createPreview() async => 3;

  @override
  Future<void> seekTo(int positionUs) async => seeks.add(positionUs);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
