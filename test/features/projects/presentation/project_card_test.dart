import 'package:cleancut/app/theme/app_theme.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/presentation/aspect_sheet.dart';
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
              body: SizedBox(
                width: 220,
                child: ProjectCard(
                  project: project(mainSeconds: [65]),
                  onOpen: () => events.add('open'),
                  onAction: events.add,
                ),
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
      expect(
        find.byWidgetPredicate((w) => w is AppIcon && w.icon == AppIcons.film),
        findsOneWidget,
      );
    });

    testWidgets('shows name, date, duration badge and 16:10 thumbnail', (
      tester,
    ) async {
      await pumpCard(tester);
      expect(find.text('Test project'), findsOneWidget);
      expect(find.text('26, Nov, 2026'), findsOneWidget);
      expect(find.text('01:05'), findsOneWidget);
      final aspect = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspect.aspectRatio, ProjectCard.thumbnailAspect);
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
    void expectManropeVariations(TextTheme textTheme) {
      final styles = [
        textTheme.displayLarge,
        textTheme.displayMedium,
        textTheme.displaySmall,
        textTheme.headlineLarge,
        textTheme.headlineMedium,
        textTheme.headlineSmall,
        textTheme.titleLarge,
        textTheme.titleMedium,
        textTheme.titleSmall,
        textTheme.bodyLarge,
        textTheme.bodyMedium,
        textTheme.bodySmall,
        textTheme.labelLarge,
        textTheme.labelMedium,
        textTheme.labelSmall,
      ];
      for (final style in styles) {
        expect(style?.fontFamily, AppTokens.fontFamily);
        final w = style?.fontWeight?.value.toDouble();
        expect(style?.fontVariations, [FontVariation.weight(w!)]);
      }
    }

    test('dark theme uses the Clipcraft palette and variable Manrope font', () {
      final theme = AppTheme.dark();
      expect(theme.colorScheme.surface, const Color(0xFF16171B));
      expect(theme.colorScheme.primary, const Color(0xFF7C8CFF));
      expectManropeVariations(theme.textTheme);
      expectManropeVariations(theme.primaryTextTheme);
    });
  });
}
