import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_effects.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:cleancut/features/projects/presentation/editor/overlays/mask_overlay.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/blur_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/mask_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/timeline/timeline_view.dart';
import 'package:cleancut/features/projects/presentation/project_screen.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../domain/fixtures.dart';

void main() {
  group('BlurPanel', () {
    testWidgets(
      'applies presets, drags slider, types value, keyframes and resets',
      (tester) async {
        var amount = 0.0;
        var dragged = 0;
        var ended = 0;
        var keyframeToggles = 0;
        var closed = 0;

        await tester.pumpWidget(
          localizedApp(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => BlurPanel(
                  amount: amount,
                  onDrag: (v) {
                    dragged++;
                    setState(() => amount = v);
                  },
                  onDragEnd: () => ended++,
                  onSet: (v) => setState(() => amount = v),
                  onToggleKeyframe: () => keyframeToggles++,
                  onClose: () => closed++,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Blur'), findsOneWidget);
        expect(find.text('Strength'), findsOneWidget);
        expect(find.text('0%'), findsOneWidget);

        // Tap 50% preset.
        await tester.tap(find.text('50%'));
        await tester.pump();
        expect(amount, 0.5);

        // Type exact 35%.
        await tester.tap(find.text('50%').last);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '35');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(amount, closeTo(0.35, 1e-9));

        // Drag slider.
        await tester.drag(find.byType(Slider), const Offset(40, 0));
        await tester.pump();
        expect(dragged, greaterThan(0));
        expect(ended, 1);

        // Keyframe button toggles.
        await tester.tap(find.byTooltip('Add Blur keyframe'));
        expect(keyframeToggles, 1);

        // Reset returns blur to 0%.
        await tester.tap(find.text('Reset'));
        await tester.pump();
        expect(amount, 0);

        await tester.tap(find.byTooltip('Close'));
        expect(closed, 1);
      },
    );
  });

  group('MaskPanel', () {
    testWidgets(
      'picks shapes, edits feather/rotation/size/invert, hides size for linear and resets',
      (tester) async {
        MaskShape? shape;
        var resolved = (
          center: Vec2.zero,
          size: MaskLimits.defaultSize,
          rotation: 0.0,
          feather: 0.0,
        );
        var isInverted = false;
        final toggled = <MaskProperty>[];

        await tester.pumpWidget(
          localizedApp(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => SingleChildScrollView(
                  child: MaskPanel(
                    shape: shape,
                    resolved: shape == null ? null : resolved,
                    invert: isInverted,
                    onSelectShape: (s) => setState(() => shape = s),
                    onDrag: ({center, size, rotation, feather, invert}) =>
                        setState(() {
                          resolved = (
                            center: center ?? resolved.center,
                            size: size ?? resolved.size,
                            rotation: rotation ?? resolved.rotation,
                            feather: feather ?? resolved.feather,
                          );
                          if (invert != null) isInverted = invert;
                        }),
                    onDragEnd: () {},
                    onSet: ({center, size, rotation, feather, invert}) =>
                        setState(() {
                          resolved = (
                            center: center ?? resolved.center,
                            size: size ?? resolved.size,
                            rotation: rotation ?? resolved.rotation,
                            feather: feather ?? resolved.feather,
                          );
                          if (invert != null) isInverted = invert;
                        }),
                    onToggleKeyframe: toggled.add,
                    onClose: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('None'), findsOneWidget);
        expect(find.text('Linear'), findsOneWidget);
        expect(find.text('Mirror'), findsOneWidget);
        expect(find.text('Circle'), findsOneWidget);
        expect(find.text('Feather'), findsNothing);

        // Pick Linear: Feather, Rotation, Invert appear, but Size stays hidden.
        await tester.tap(find.text('Linear'));
        await tester.pump();
        expect(shape, MaskShape.linear);
        expect(find.text('Feather'), findsOneWidget);
        expect(find.text('Rotation'), findsOneWidget);
        expect(find.text('Invert'), findsOneWidget);
        expect(find.text('Size'), findsNothing);

        // Pick Circle: Size appears too.
        await tester.tap(find.text('Circle'));
        await tester.pump();
        expect(shape, MaskShape.circle);
        expect(find.text('Size'), findsOneWidget);

        // Toggle Invert.
        await tester.tap(find.byType(Switch));
        await tester.pump();
        expect(isInverted, isTrue);

        // Toggle Feather keyframe.
        await tester.tap(find.byTooltip('Add Feather keyframe'));
        expect(toggled, [MaskProperty.feather]);

        // Reset clears back to None.
        await tester.tap(find.text('Reset'));
        await tester.pump();
        expect(shape, isNull);
        expect(find.text('Feather'), findsNothing);
      },
    );
  });

  group('MaskOverlay', () {
    testWidgets('drags center and handles on preview and seals on release', (
      tester,
    ) async {
      var mask = (
        center: Vec2.zero,
        size: const Vec2(x: 0.5, y: 0.5),
        rotation: 0.0,
        feather: 0.0,
      );
      var starts = 0;
      var ends = 0;

      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 300,
                child: StatefulBuilder(
                  builder: (context, setState) => MaskOverlay(
                    shape: MaskShape.circle,
                    mask: mask,
                    clipTransform: (
                      position: Vec2.zero,
                      scale: 1,
                      rotation: 0,
                      opacity: 1,
                    ),
                    sourceRatio: 1,
                    crop: CropRect.full,
                    fitMode: FitMode.fit,
                    onChangeStart: () => starts++,
                    onChanged: ({center, size, rotation, feather}) =>
                        setState(() {
                          mask = (
                            center: center ?? mask.center,
                            size: size ?? mask.size,
                            rotation: rotation ?? mask.rotation,
                            feather: feather ?? mask.feather,
                          );
                        }),
                    onChangeEnd: () => ends++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Drag center to the right.
      final box = tester.getRect(find.byKey(MaskOverlay.canvasKey));
      await tester.dragFrom(box.center, const Offset(60, 0));
      await tester.pump();
      expect(mask.center.x, greaterThan(0.2));
      expect(starts, 1);
      expect(ends, 1);

      // Drag the right width handle outward.
      final rightHandle = Offset(
        box.center.dx + mask.center.x * 150 + mask.size.x * 150,
        box.center.dy,
      );
      final beforeSizeX = mask.size.x;
      await tester.dragFrom(rightHandle, const Offset(30, 0));
      await tester.pump();
      expect(mask.size.x, greaterThan(beforeSizeX));
      expect(ends, 2);
    });
  });

  group('Editor integration (Phase 6B)', () {
    testWidgets(
      'Blur and Mask dock tools edit clip, show MaskOverlay and undo cleanly',
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

        // Select clip -> scroll dock to Blur -> open BlurPanel.
        await tester.tap(find.byType(MainClipView).first);
        await tester.pump();
        await tester.scrollUntilVisible(
          find.byTooltip('Blur'),
          100,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.byTooltip('Blur'));
        await tester.pumpAndSettle();
        expect(find.byType(BlurPanel), findsOneWidget);

        // Apply 50% preset and toggle a blur keyframe.
        await tester.tap(find.text('50%'));
        await tester.pump();
        expect(currentClip().blur.valueAt(0, lerpDouble), 0.5);
        expect(
          env.engine.specs.last.clips.first.style.transform.first.blur,
          0.5,
        );

        await tester.tap(find.byTooltip('Add Blur keyframe'));
        await tester.pump();
        expect(currentClip().blur.isAnimated, isTrue);
        expect(find.byType(ClipKeyframeMarkers), findsOneWidget);

        // Close Blur -> open Mask -> pick Circle -> MaskOverlay appears.
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byTooltip('Mask'),
          100,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.byTooltip('Mask'));
        await tester.pumpAndSettle();
        expect(find.byType(MaskPanel), findsOneWidget);
        expect(find.byType(MaskOverlay), findsNothing);

        await tester.tap(find.text('Circle'));
        await tester.pumpAndSettle();
        expect(currentClip().mask?.shape, MaskShape.circle);
        expect(find.byType(MaskOverlay), findsOneWidget);
        expect(
          env.engine.specs.last.clips.first.style.mask?.shape,
          SpecMaskShape.circle,
        );

        // Toggle Invert (scroll into view inside the compact phone sheet).
        await tester.ensureVisible(find.byType(Switch));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch));
        await tester.pump();
        expect(currentClip().mask?.invert, isTrue);
        expect(env.engine.specs.last.clips.first.style.mask?.invert, isTrue);

        // Undo reverts Invert -> Circle -> Blur keyframe -> Blur 50%.
        await tester.tap(find.byTooltip('Undo'));
        await tester.pump();
        expect(currentClip().mask?.invert, isFalse);

        await tester.tap(find.byTooltip('Undo'));
        await tester.pump();
        expect(currentClip().mask, isNull);
        expect(find.byType(MaskOverlay), findsNothing);

        await tester.tap(find.byTooltip('Undo'));
        await tester.pump();
        expect(currentClip().blur.isAnimated, isFalse);

        await tester.tap(find.byTooltip('Undo'));
        await tester.pump();
        expect(currentClip().blur.valueAt(0, lerpDouble), 0);
      },
    );
  });
}
