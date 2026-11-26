// Phase 5 dock tools on the selected main clip: the Crop panel.
import 'package:cleancut/features/projects/domain/commands/style_commands.dart';
import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/canvas_background.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/domain/model/vec2.dart';
import 'package:cleancut/features/projects/presentation/editor/overlays/crop_overlay.dart';
import 'package:cleancut/features/projects/presentation/editor/overlays/transform_gizmo.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/crop_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/ratio_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/transform_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/timeline/timeline_view.dart';
import 'package:cleancut/features/projects/presentation/editor/tool_dock.dart';
import 'package:cleancut/features/projects/presentation/project_screen.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../domain/fixtures.dart';

const s = 1000000;

void main() {
  late TestEnv env;

  Future<void> pumpEditor(WidgetTester tester) async {
    env = TestEnv(
      projects: [
        project(mainSeconds: [2, 3]),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: env.overrides,
        child: localizedApp(const ProjectScreen(projectId: 'p1')),
      ),
    );
    await tester.pumpAndSettle();
    env.engine.emitState(durationUs: 5 * s);
    await tester.pump();
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(ProjectScreen)));

  Clip firstClip(WidgetTester tester) =>
      containerOf(tester)
          .read(projectSessionProvider('p1'))
          .requireValue
          .history
          .present
          .mainTrack
          .clips
          .first;

  Future<void> undo(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
  }

  CropPanel panel(WidgetTester tester) =>
      tester.widget<CropPanel>(find.byType(CropPanel));

  Future<void> openCrop(WidgetTester tester) async {
    await pumpEditor(tester);
    await tester.tap(find.byType(MainClipView).first);
    await tester.pump();
    await tester.tap(find.byTooltip('Crop'));
    await tester.pump();
  }

  testWidgets('Crop opens the panel over the dock', (tester) async {
    await openCrop(tester);
    expect(find.byType(CropPanel), findsOneWidget);
    expect(find.byType(ToolDock), findsNothing);
    // Nothing to reset yet.
    expect(panel(tester).onReset, isNull);
  });

  testWidgets('a preset crops the 16:9 video centered; Free unlocks it', (
    tester,
  ) async {
    await openCrop(tester);
    panel(tester).onAspect(CanvasAspect.square);
    await tester.pump();
    final crop = firstClip(tester).crop;
    expect(crop.aspect, CanvasAspect.square);
    expect(crop.width, closeTo(9 / 16, 1e-9));
    expect(panel(tester).aspect, CanvasAspect.square);

    panel(tester).onAspect(null);
    await tester.pump();
    expect(firstClip(tester).crop.aspect, isNull);
    // The rectangle stays; only the lock goes.
    expect(firstClip(tester).crop.width, closeTo(9 / 16, 1e-9));

    // Two separate undo steps.
    await undo(tester);
    expect(firstClip(tester).crop.aspect, CanvasAspect.square);
    await undo(tester);
    expect(firstClip(tester).crop, CropRect.full);
  });

  testWidgets('a ruler drag is one undo step; quarter turns are their own', (
    tester,
  ) async {
    await openCrop(tester);
    panel(tester)
      ..onRotationDrag(10)
      ..onRotationDrag(20)
      ..onRotationDrag(30)
      ..onRotationDragEnd();
    await tester.pump();
    expect(firstClip(tester).transform.at(0).rotation, 30);
    expect(panel(tester).rotation, 30);

    panel(tester).onRotateQuarter();
    await tester.pump();
    expect(firstClip(tester).transform.at(0).rotation, 90);

    await undo(tester);
    expect(firstClip(tester).transform.at(0).rotation, 30);
    await undo(tester);
    expect(firstClip(tester).transform.at(0).rotation, 0);
  });

  testWidgets('mirror, flip and Reset; Reset is one undo step', (tester) async {
    await openCrop(tester);
    panel(tester).onMirror();
    await tester.pump();
    panel(tester).onFlip();
    await tester.pump();
    panel(tester).onRotationSet(-45);
    await tester.pump();
    panel(tester).onAspect(CanvasAspect.portrait9x16);
    await tester.pump();
    var clip = firstClip(tester);
    expect((clip.transform.flipX, clip.transform.flipY), (true, true));
    expect(panel(tester).mirrored, isTrue);

    panel(tester).onReset!();
    await tester.pump();
    clip = firstClip(tester);
    expect(clip.crop, CropRect.full);
    expect((clip.transform.flipX, clip.transform.flipY), (false, false));
    expect(clip.transform.at(0).rotation, 0);
    expect(panel(tester).onReset, isNull);

    await undo(tester);
    clip = firstClip(tester);
    expect(clip.crop.aspect, CanvasAspect.portrait9x16);
    expect(clip.transform.at(0).rotation, -45);
  });

  testWidgets('dragging rotation while playing stays one undo step', (
    tester,
  ) async {
    await openCrop(tester);
    panel(tester).onRotationDrag(10);
    await tester.pump();
    env.engine.emitPosition(500000);
    await tester.pump();
    panel(tester).onRotationDrag(20);
    await tester.pump();
    env.engine.emitPosition(1000000);
    await tester.pump();
    panel(tester)
      ..onRotationDrag(30)
      ..onRotationDragEnd();
    await tester.pump();
    expect(firstClip(tester).transform.at(0).rotation, 30);

    await undo(tester);
    expect(firstClip(tester).transform.at(0).rotation, 0);
  });

  testWidgets('CropOverlay shows uncropped preview, drags in one undo step, '
      'and applies crop on close', (tester) async {
    await openCrop(tester);
    expect(find.byType(CropOverlay), findsOneWidget);

    // Drag the top-left corner inward on the preview.
    final rect = tester.getRect(find.byKey(CropOverlay.frameKey));
    final gesture = await tester.startGesture(
      rect.topLeft + const Offset(4, 4),
    );
    await gesture.moveBy(const Offset(20, 10));
    await tester.pump();
    await gesture.moveBy(const Offset(20, 10));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final dragged = firstClip(tester).crop;
    expect(dragged.left, greaterThan(0.05));
    expect(dragged.top, greaterThan(0.05));

    // While the Crop panel is open, the engine previews the clip uncropped.
    final whileOpen = env.engine.specs.last.clips.first.style;
    expect([whileOpen.cropLeft, whileOpen.cropTop], [0, 0]);

    // Closing the panel removes the overlay and applies the crop to the engine.
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    expect(find.byType(CropOverlay), findsNothing);
    final afterClose = env.engine.specs.last.clips.first.style;
    expect(afterClose.cropLeft, closeTo(dragged.left, 1e-6));
    expect(afterClose.cropTop, closeTo(dragged.top, 1e-6));

    // The whole handle drag is a single undo step.
    await undo(tester);
    expect(firstClip(tester).crop, CropRect.full);
  });

  testWidgets(
    'Transform opens from dock and edits fill, transform and border',
    (tester) async {
      await pumpEditor(tester);
      await tester.tap(find.byType(MainClipView).first);
      await tester.pump();
      await tester.tap(find.byTooltip('Transform'));
      await tester.pump();
      expect(find.byType(TransformPanel), findsOneWidget);

      final transformPanel = tester.widget<TransformPanel>(
        find.byType(TransformPanel),
      );
      transformPanel.onFitMode(FitMode.fill);
      await tester.pump();
      expect(firstClip(tester).fitMode, FitMode.fill);

      // Dragging scale while playing captures playhead time -> one undo step.
      transformPanel.onTransformDrag(scale: 1.5);
      await tester.pump();
      env.engine.emitPosition(500000);
      await tester.pump();
      transformPanel.onTransformDrag(scale: 2);
      await tester.pump();
      transformPanel.onTransformDragEnd();
      await tester.pump();
      expect(firstClip(tester).transform.at(0).scale, 2);

      // Border swatch tap is its own undo step.
      transformPanel.onBorderSet(
        const ClipBorder(width: 0.02, argb: 0xFFFF4D6D, radius: 0.1),
      );
      await tester.pump();
      expect(firstClip(tester).border.width, 0.02);

      await undo(tester);
      expect(firstClip(tester).border, const ClipBorder());
      await undo(tester);
      expect(firstClip(tester).transform.at(0).scale, 1);
      await undo(tester);
      expect(firstClip(tester).fitMode, FitMode.fit);
      expect(firstClip(tester).transform.at(0).position, Vec2.zero);
    },
  );

  testWidgets('Ratio dock tool opens Ratio | Background and edits canvas', (
    tester,
  ) async {
    await pumpEditor(tester);
    await tester.tap(find.byTooltip('Ratio'));
    await tester.pump();
    expect(find.byType(RatioPanel), findsOneWidget);

    await tester.tap(find.text('9:16'));
    await tester.pump();
    final canvas1 = containerOf(tester)
        .read(projectSessionProvider('p1'))
        .requireValue
        .history
        .present
        .canvas;
    expect(canvas1.aspect, CanvasAspect.portrait9x16);

    await tester.tap(find.text('Background'));
    await tester.pump();
    await tester.tap(find.text('Image'));
    await tester.pump();
    env.picker.nextImage = const MediaRef(
      uri: 'content://bg-img',
      kind: MediaKind.image,
      width: 1080,
      height: 1920,
    );
    await tester.ensureVisible(find.text('Choose image'));
    await tester.tap(find.text('Choose image'));
    await tester.pumpAndSettle();
    final canvas2 = containerOf(tester)
        .read(projectSessionProvider('p1'))
        .requireValue
        .history
        .present
        .canvas;
    expect(
      canvas2.background,
      const CanvasBackground.image(uri: 'content://bg-img'),
    );

    await undo(tester);
    final canvas3 = containerOf(tester)
        .read(projectSessionProvider('p1'))
        .requireValue
        .history
        .present
        .canvas;
    expect(canvas3.background, CanvasBackground.black);
  });

  testWidgets(
    'TransformGizmo is active when a clip is selected, hidden during Crop, '
    'and drags in one undo step',
    (tester) async {
      await pumpEditor(tester);
      // Nothing selected -> no gizmo.
      expect(find.byType(TransformGizmo), findsNothing);

      // Select clip -> TransformGizmo activates.
      await tester.tap(find.byType(MainClipView).first);
      await tester.pump();
      expect(find.byType(TransformGizmo), findsOneWidget);

      // Opening Crop swaps TransformGizmo out for CropOverlay.
      await tester.tap(find.byTooltip('Crop'));
      await tester.pump();
      expect(find.byType(CropOverlay), findsOneWidget);
      expect(find.byType(TransformGizmo), findsNothing);

      // Closing Crop restores TransformGizmo.
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      expect(find.byType(TransformGizmo), findsOneWidget);

      // Drag on the preview while playing -> single undo step.
      final center = tester.getCenter(find.byKey(TransformGizmo.canvasKey));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(24, 16));
      await tester.pump();
      env.engine.emitPosition(500000);
      await tester.pump();
      await gesture.moveBy(const Offset(24, 16));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final moved = firstClip(tester).transform.at(0).position;
      expect(moved.x, greaterThan(0.1));
      expect(moved.y, greaterThan(0.05));

      await undo(tester);
      expect(firstClip(tester).transform.at(0).position, Vec2.zero);
    },
  );

  testWidgets(
    'Transform keyframes toggle at playhead, render markers on the timeline '
    'clip, and undo cleanly',
    (tester) async {
      await pumpEditor(tester);
      await tester.tap(find.byType(MainClipView).first);
      await tester.pump();
      await tester.tap(find.byTooltip('Transform'));
      await tester.pump();
      await tester.tap(find.text('Position'));
      await tester.pump();

      expect(find.byType(ClipKeyframeMarkers), findsNothing);

      // Add a Scale keyframe at 0s -> diamond switches to Remove and timeline
      // clip shows the marker.
      final addScale = find.byTooltip('Add Scale keyframe');
      await tester.ensureVisible(addScale);
      await tester.pumpAndSettle();
      await tester.tap(addScale);
      await tester.pump();
      expect(find.byTooltip('Remove Scale keyframe'), findsOneWidget);
      expect(find.byType(ClipKeyframeMarkers), findsOneWidget);
      expect(
        tester
            .widget<ClipKeyframeMarkers>(find.byType(ClipKeyframeMarkers))
            .timesUs,
        [0],
      );

      // Advance playhead to 1s: Scale is animated elsewhere, so tooltip is Add.
      env.engine.emitPosition(s);
      await tester.pump();
      expect(find.byTooltip('Add Scale keyframe'), findsOneWidget);

      // Editing Scale at 1s auto-inserts a second keyframe there.
      tester
          .widget<TransformPanel>(find.byType(TransformPanel))
          .onTransformSet(scale: 2);
      await tester.pump();
      final removeScale = find.byTooltip('Remove Scale keyframe');
      expect(removeScale, findsOneWidget);
      expect(
        tester
            .widget<ClipKeyframeMarkers>(find.byType(ClipKeyframeMarkers))
            .timesUs,
        [0, s],
      );
      expect(firstClip(tester).transform.at(s ~/ 2).scale, closeTo(1.5, 1e-6));

      // Tapping Remove removes the 1s keyframe; Undo restores it.
      await tester.ensureVisible(removeScale);
      await tester.pumpAndSettle();
      await tester.tap(removeScale);
      await tester.pump();
      expect(
        tester
            .widget<ClipKeyframeMarkers>(find.byType(ClipKeyframeMarkers))
            .timesUs,
        [0],
      );

      await undo(tester);
      expect(
        tester
            .widget<ClipKeyframeMarkers>(find.byType(ClipKeyframeMarkers))
            .timesUs,
        [0, s],
      );
    },
  );

  testWidgets('a gizmo drag on an animated clip while playing edits the time '
      'it started at, and the next drag is its own undo step', (tester) async {
    await pumpEditor(tester);
    await tester.tap(find.byType(MainClipView).first);
    await tester.pump();
    final id = firstClip(tester).id;
    containerOf(tester).read(projectSessionProvider('p1').notifier)
      ..apply(
        ToggleClipKeyframeCommand(id, TransformProperty.position, atUs: 0),
      )
      ..apply(
        SetClipTransformValuesCommand(
          id,
          atUs: s,
          position: const Vec2(x: -0.4, y: 0),
          coalesce: false,
        ),
      )
      ..seal();
    await tester.pump();

    // First drag starts at 0 s; playback moves on mid-drag.
    final center = tester.getCenter(find.byKey(TransformGizmo.canvasKey));
    var gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    env.engine.emitPosition(s ~/ 2);
    await tester.pump();
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    var clip = firstClip(tester);
    expect(clip.transform.position.keyframeTimes, [0, s]);
    final afterFirst = clip.transform.at(0).position.x;
    expect(afterFirst, greaterThan(0.1));

    // Second drag starts at 0.5 s: it keys that time, not the old one.
    gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    clip = firstClip(tester);
    expect(clip.transform.position.keyframeTimes, [0, s ~/ 2, s]);
    expect(clip.transform.at(0).position.x, afterFirst);

    // Each drag is its own undo step.
    await undo(tester);
    clip = firstClip(tester);
    expect(clip.transform.position.keyframeTimes, [0, s]);
    expect(clip.transform.at(0).position.x, afterFirst);
    await undo(tester);
    expect(firstClip(tester).transform.at(0).position, Vec2.zero);
  });

  testWidgets('opening Crop moves the playhead onto the selected clip', (
    tester,
  ) async {
    await pumpEditor(tester);
    // The second clip starts at 2 s; the playhead is at 0.
    await tester.tap(find.byType(MainClipView).at(1));
    await tester.pump();
    await tester.tap(find.byTooltip('Crop'));
    await tester.pump();
    expect(env.engine.seeks.last, 2 * s);
  });

  testWidgets('full screen during Crop shows the clip cropped, and the crop '
      'handles get the uncropped frame back on return', (tester) async {
    await openCrop(tester);
    panel(tester).onAspect(CanvasAspect.square);
    await tester.pump();
    expect(env.engine.specs.last.clips.first.style.cropLeft, 0);

    await tester.tap(find.byTooltip('Full screen'));
    await tester.pumpAndSettle();
    expect(
      env.engine.specs.last.clips.first.style.cropLeft,
      closeTo((1 - 9 / 16) / 2, 1e-6),
    );

    await tester.tap(find.byTooltip('Exit full screen').first);
    await tester.pumpAndSettle();
    expect(find.byType(CropPanel), findsOneWidget);
    expect(env.engine.specs.last.clips.first.style.cropLeft, 0);
  });

  /// Keys position (x 0 → -0.4) and, with [animateScale], scale (1 → 2) on
  /// the first clip at 0 s and 1 s, as one sealed step.
  Future<String> keyFirstClip(
    WidgetTester tester, {
    bool animateScale = false,
  }) async {
    await tester.tap(find.byType(MainClipView).first);
    await tester.pump();
    final id = firstClip(tester).id;
    final session =
        containerOf(tester).read(projectSessionProvider('p1').notifier)..apply(
          ToggleClipKeyframeCommand(id, TransformProperty.position, atUs: 0),
        );
    if (animateScale) {
      session.apply(
        ToggleClipKeyframeCommand(id, TransformProperty.scale, atUs: 0),
      );
    }
    session
      ..apply(
        SetClipTransformValuesCommand(
          id,
          atUs: s,
          position: const Vec2(x: -0.4, y: 0),
          scale: animateScale ? 2 : null,
          coalesce: false,
        ),
      )
      ..seal();
    await tester.pump();
    return id;
  }

  /// Drags one finger from the gizmo's centre in three 15 dp steps to the
  /// right and returns the canvas width.
  Future<double> dragGizmoRight(WidgetTester tester) async {
    final rect = tester.getRect(find.byKey(TransformGizmo.canvasKey));
    final gesture = await tester.startGesture(rect.center);
    for (var i = 0; i < 3; i++) {
      await gesture.moveBy(const Offset(15, 0));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
    return rect.width;
  }

  testWidgets('a gizmo drag just beside a keyframe follows the finger to the '
      'end', (tester) async {
    // Regression: the drag updated the keyframe but read the value back half
    // a frame away, saw a different value and cancelled itself.
    await pumpEditor(tester);
    await keyFirstClip(tester);
    env.engine.emitPosition(s - 5000);
    await tester.pump();

    final width = await dragGizmoRight(tester);
    final clip = firstClip(tester);
    expect(clip.transform.position.keyframeTimes, [0, s]);
    expect(
      clip.transform.at(s).position.x,
      closeTo(-0.4 + 2 * 45 / width, 0.01),
    );
  });

  testWidgets('a gizmo drag that starts while playing on an animated clip '
      'is not cancelled by locking its time', (tester) async {
    // Regression: the gesture locked a newer playhead time than the values
    // it started from, and the rebuilt (different) scale cancelled it.
    await pumpEditor(tester);
    await keyFirstClip(tester, animateScale: true);
    // Playback moves on, but the gizmo hasn't rebuilt yet.
    env.engine.emitPosition(s ~/ 2);

    final width = await dragGizmoRight(tester);
    final clip = firstClip(tester);
    expect(clip.transform.position.keyframeTimes, [0, s ~/ 2, s]);
    // The whole drag landed, starting from where the clip was shown.
    expect(clip.transform.at(s ~/ 2).position.x, closeTo(2 * 45 / width, 0.01));
  });

  testWidgets('the gizmo and crop handles hide while the playhead is off the '
      'selected clip', (tester) async {
    await pumpEditor(tester);
    await tester.tap(find.byType(MainClipView).first);
    await tester.pump();
    expect(find.byType(TransformGizmo), findsOneWidget);

    // The second clip (2–5 s) is on screen: nothing to drag.
    env.engine.emitPosition(3 * s);
    await tester.pump();
    expect(find.byType(TransformGizmo), findsNothing);
    env.engine.emitPosition(2 * s);
    await tester.pump();
    expect(find.byType(TransformGizmo), findsNothing);

    env.engine.emitPosition(s);
    await tester.pump();
    expect(find.byType(TransformGizmo), findsOneWidget);

    await tester.tap(find.byTooltip('Crop'));
    await tester.pump();
    expect(find.byType(CropOverlay), findsOneWidget);
    env.engine.emitPosition(3 * s);
    await tester.pump();
    expect(find.byType(CropOverlay), findsNothing);
  });

  testWidgets('the last clip keeps its gizmo at the very end', (tester) async {
    await pumpEditor(tester);
    await tester.tap(find.byType(MainClipView).at(1));
    await tester.pump();
    env.engine.emitPosition(5 * s);
    await tester.pump();
    expect(find.byType(TransformGizmo), findsOneWidget);
  });
}
