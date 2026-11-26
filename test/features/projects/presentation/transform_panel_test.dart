import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/panel_widgets.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/transform_panel.dart';
import 'package:flutter/material.dart' hide TransformProperty;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('TransformScale', () {
    test('places 100% at the midpoint and covers 5%..1000%', () {
      expect(TransformScale.positionOf(0.05), 0);
      expect(TransformScale.positionOf(1), 0.5);
      expect(TransformScale.positionOf(10), 1);
      expect(TransformScale.positionOf(double.nan), 0.5);

      expect(TransformScale.scaleAt(0), 0.05);
      expect(TransformScale.scaleAt(0.5), 1);
      expect(TransformScale.scaleAt(1), 10);
      expect(TransformScale.scaleAt(double.nan), 1);
    });

    test('positionOf and scaleAt round-trip at every mark', () {
      for (final mark in TransformScale.marks) {
        expect(
          TransformScale.scaleAt(TransformScale.positionOf(mark)),
          closeTo(mark, 1e-9),
        );
      }
    });
  });

  group('TransformPanel', () {
    late List<FitMode> fitModes;
    late List<Map<String, Object?>> transformDrags;
    late List<Map<String, Object?>> transformSets;
    late List<ClipBorder> borderDrags;
    late List<ClipBorder> borderSets;
    late List<TransformProperty> toggledKeyframes;
    late List<String> events;

    Future<void> pumpPanel(
      WidgetTester tester, {
      FitMode fitMode = FitMode.fit,
      Vec2 position = Vec2.zero,
      double scale = 1,
      double rotation = 0,
      double opacity = 1,
      ClipBorder border = const ClipBorder(),
      TransformTab initialTab = TransformTab.fill,
      Set<TransformProperty> animatedProperties = const {},
      Set<TransformProperty> activeKeyframes = const {},
      bool enableKeyframes = true,
    }) async {
      fitModes = [];
      transformDrags = [];
      transformSets = [];
      borderDrags = [];
      borderSets = [];
      toggledKeyframes = [];
      events = [];
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: TransformPanel(
                fitMode: fitMode,
                position: position,
                scale: scale,
                rotation: rotation,
                opacity: opacity,
                border: border,
                initialTab: initialTab,
                animatedProperties: animatedProperties,
                activeKeyframes: activeKeyframes,
                onToggleKeyframe: enableKeyframes ? toggledKeyframes.add : null,
                onFitMode: fitModes.add,
                onTransformDrag: ({position, scale, rotation, opacity}) =>
                    transformDrags.add({
                      'position': position,
                      'scale': scale,
                      'rotation': rotation,
                      'opacity': opacity,
                    }),
                onTransformDragEnd: () => events.add('transformDragEnd'),
                onTransformSet: ({position, scale, rotation, opacity}) =>
                    transformSets.add({
                      'position': position,
                      'scale': scale,
                      'rotation': rotation,
                      'opacity': opacity,
                    }),
                onBorderDrag: borderDrags.add,
                onBorderDragEnd: () => events.add('borderDragEnd'),
                onBorderSet: borderSets.add,
                onClose: () => events.add('close'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows Fill | Position | Opacity | Border tabs', (
      tester,
    ) async {
      await pumpPanel(tester);
      expect(find.text('Transform'), findsOneWidget);
      for (final tab in ['Fill', 'Position', 'Opacity', 'Border']) {
        expect(
          find.descendant(of: find.byType(PanelTabs), matching: find.text(tab)),
          findsOneWidget,
        );
      }
      expect(find.text('Fit'), findsOneWidget);
      expect(find.text('Stretch'), findsOneWidget);
    });

    testWidgets('Fill tab selects modes and Reset restores Fit', (
      tester,
    ) async {
      await pumpPanel(tester, fitMode: FitMode.stretch);
      await tester.tap(find.text('Reset'));
      expect(fitModes, [FitMode.fit]);
    });

    testWidgets('Position tab supports tap-to-type and tab-scoped Reset', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        position: const Vec2(x: 0.25, y: -0.5),
        scale: 2,
        rotation: 30,
        opacity: 0.4,
        initialTab: TransformTab.position,
      );
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('-50%'), findsOneWidget);
      expect(find.text('200%'), findsOneWidget);
      expect(find.text('30°'), findsOneWidget);

      // Tap scale value to type an exact percentage.
      await tester.tap(find.text('200%'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '150');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(transformSets.last['scale'], 1.5);

      // Reset on Position tab resets X/Y/Scale/Rotation only (leaves opacity).
      await tester.tap(find.text('Reset'));
      expect(transformSets.last, {
        'position': Vec2.zero,
        'scale': 1.0,
        'rotation': 0.0,
        'opacity': null,
      });
    });

    testWidgets('Opacity tab types exact percent and resets only opacity', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        scale: 2,
        opacity: 0.6,
        initialTab: TransformTab.opacity,
      );
      await tester.tap(find.text('60%'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '80');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(transformSets.last['opacity'], 0.8);

      await tester.tap(find.text('Reset'));
      expect(transformSets.last, {
        'position': null,
        'scale': null,
        'rotation': null,
        'opacity': 1.0,
      });
    });

    testWidgets('Border tab picks swatches and resets border', (tester) async {
      await pumpPanel(
        tester,
        border: const ClipBorder(width: 0.02, radius: 0.25),
        initialTab: TransformTab.border,
      );
      await tester.tap(find.bySemanticsLabel('Color 2'));
      expect(borderSets.last.argb, styleColorSwatches[1]);

      await tester.tap(find.text('Reset'));
      expect(borderSets.last, const ClipBorder());
    });

    testWidgets('keyframe toggles fire for Position rows and Opacity', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        initialTab: TransformTab.position,
        animatedProperties: const {TransformProperty.scale},
        activeKeyframes: const {TransformProperty.scale},
      );
      await tester.tap(find.byTooltip('Add X keyframe'));
      await tester.tap(find.byTooltip('Add Y keyframe'));
      await tester.tap(find.byTooltip('Remove Scale keyframe'));
      await tester.tap(find.byTooltip('Add Rotation keyframe'));
      expect(toggledKeyframes, [
        TransformProperty.position,
        TransformProperty.position,
        TransformProperty.scale,
        TransformProperty.rotation,
      ]);

      await tester.tap(find.text('Opacity'));
      await tester.pump();
      await tester.tap(find.byTooltip('Add Opacity keyframe'));
      expect(toggledKeyframes.last, TransformProperty.opacity);
    });

    testWidgets('renders cleanly at 2x text scale across all tabs', (
      tester,
    ) async {
      for (final tab in TransformTab.values) {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: localizedApp(
              Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: TransformPanel(
                    fitMode: FitMode.fit,
                    position: Vec2.zero,
                    scale: 1,
                    rotation: 0,
                    opacity: 1,
                    border: const ClipBorder(),
                    initialTab: tab,
                    animatedProperties: const {TransformProperty.scale},
                    activeKeyframes: const {TransformProperty.scale},
                    onToggleKeyframe: (_) {},
                    onFitMode: (_) {},
                    onTransformDrag: ({position, scale, rotation, opacity}) {},
                    onTransformDragEnd: () {},
                    onTransformSet: ({position, scale, rotation, opacity}) {},
                    onBorderDrag: (_) {},
                    onBorderDragEnd: () {},
                    onBorderSet: (_) {},
                    onClose: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$tab');
      }
    });
  });
}
