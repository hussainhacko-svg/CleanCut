import 'package:cleancut/app/theme/app_theme.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/presentation/aspect_sheet.dart';
import 'package:cleancut/features/projects/presentation/home_screen.dart';
import 'package:cleancut/features/projects/presentation/playback/playback_controller.dart';
import 'package:cleancut/features/projects/presentation/project_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../domain/fixtures.dart';

void main() {
  group('ProjectCard', () {
    late FakeMediaEngine engine;
    setUp(() => engine = FakeMediaEngine());

    Future<List<Object>> pumpCard(WidgetTester tester) async {
      final events = <Object>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mediaEngineProvider.overrideWithValue(engine)],
          child: localizedApp(
            Scaffold(
              body: ProjectCard(
                project: project(mainSeconds: [65]),
                onOpen: () => events.add('open'),
                onAction: events.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return events;
    }

    testWidgets('shows the first frame when the engine has one', (
      tester,
    ) async {
      engine.thumbnailPath = 'missing.jpg';
      await pumpCard(tester);
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as ResizeImage).imageProvider, isA<FileImage>());
    });

    testWidgets('keeps the placeholder without a frame', (tester) async {
      await pumpCard(tester);
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    });

    testWidgets('shows name, VCLIP-style date and duration', (tester) async {
      await pumpCard(tester);
      expect(find.text('Test project'), findsOneWidget);
      expect(find.text('26, Nov, 2026'), findsOneWidget);
      expect(find.text('01:05'), findsOneWidget);
      expect(
        tester.getSize(find.byType(ProjectCard)).height,
        ProjectCard.height,
      );
    });

    testWidgets('tapping the card opens the project', (tester) async {
      final events = await pumpCard(tester);
      await tester.tap(find.text('Test project'));
      expect(events, ['open']);
    });

    testWidgets('menu button is a 48dp target and runs actions', (
      tester,
    ) async {
      final events = await pumpCard(tester);
      final menu = find.byTooltip('Options for Test project');
      final size = tester.getSize(menu);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      expect(events, [ProjectAction.duplicate]);
    });
  });

  group('NewProjectTile', () {
    testWidgets('shows the label and reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        localizedApp(Scaffold(body: NewProjectTile(onTap: () => taps++))),
      );
      expect(find.text('New project'), findsOneWidget);
      expect(tester.getSize(find.byType(InkWell)).height, 114);

      await tester.tap(find.byType(NewProjectTile));
      expect(taps, 1);
    });
  });

  group('AspectSheet', () {
    testWidgets('close button dismisses without a choice', (tester) async {
      CanvasAspect? result = CanvasAspect.square;
      await tester.pumpWidget(
        localizedApp(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await showAspectSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Canvas size'), findsNothing);
      expect(result, isNull);
    });
  });

  group('AppTheme', () {
    test('dark theme uses the VCLIP palette and font', () {
      final theme = AppTheme.dark();
      expect(theme.colorScheme.surface, const Color(0xFF030303));
      expect(theme.colorScheme.primary, const Color(0xFFCE50E0));
      expect(theme.textTheme.bodyMedium?.fontFamily, AppTokens.fontFamily);
    });

    test('light theme keeps the accent', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFFCE50E0));
    });
  });
}
