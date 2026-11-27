import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui show Clip;

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/domain/commands/clip_commands.dart';
import 'package:cleancut/features/projects/domain/commands/project_commands.dart';
import 'package:cleancut/features/projects/domain/commands/style_commands.dart';
import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/model/canvas_background.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/clip_style.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/domain/project_repository.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_selection.dart';
import 'package:cleancut/features/projects/presentation/editor/editor_state.dart';
import 'package:cleancut/features/projects/presentation/editor/overlays/crop_overlay.dart';
import 'package:cleancut/features/projects/presentation/editor/overlays/transform_gizmo.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/adjust_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/crop_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/filters_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/ratio_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/speed_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/transform_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/timeline/timeline_view.dart';
import 'package:cleancut/features/projects/presentation/editor/tool_dock.dart';
import 'package:cleancut/features/projects/presentation/playback/playback_controller.dart';
import 'package:cleancut/features/projects/presentation/playback/preview_widgets.dart';
import 'package:cleancut/features/projects/presentation/project_providers.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter/material.dart' hide TransformProperty;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The editor (Clipcraft Editor B on phones, Neon Focus on tablets): preview,
/// transport, timeline and the contextual tool dock.
class ProjectScreen extends ConsumerWidget {
  /// Creates the screen for [projectId].
  const new({required this.projectId, super.key});

  /// The open project.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final provider = projectSessionProvider(projectId);
    final session = ref.watch(provider);

    ref.listen(provider.select((s) => s.value?.saveFailed ?? false), (
      _,
      failed,
    ) {
      if (failed) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.editorSaveFailed)));
      }
    });

    Future<void> leave() async {
      // Save before leaving so the project list is up to date.
      await ref.read(provider.notifier).flush();
      // A double tap runs this twice; only the first may pop this route.
      if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        Navigator.of(context).pop();
      }
    }

    final history = session.value?.history;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Back closes an open tool panel before leaving the editor.
        final panel = openToolPanelProvider(projectId);
        if (ref.read(panel) != null) {
          ref.read(panel.notifier).close();
          return;
        }
        await leave();
      },
      child: _PlaybackBinding(
        projectId: projectId,
        child: Scaffold(
          backgroundColor: scheme.surface,
          body: switch (session) {
            AsyncData(:final value) => _Editor(
              projectId: projectId,
              project: value.history.present,
              onHome: leave,
              onUndo: history?.canUndo ?? false
                  ? ref.read(provider.notifier).undo
                  : null,
              onRedo: history?.canRedo ?? false
                  ? ref.read(provider.notifier).redo
                  : null,
            ),
            AsyncError(:final error) => SafeArea(
              child: Center(
                child: Text(
                  error is ProjectNotFoundException
                      ? l10n.editorNotFound
                      : l10n.homeLoadFailed,
                ),
              ),
            ),
            _ => const SafeArea(
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ),
      ),
    );
  }
}

/// The editor layout (DESIGN.md §2, kit "Timeline"): on phones preview,
/// transport, timeline and dock stacked; on tablets (≥ 840dp) a tool rail,
/// the preview and a properties panel above a full-width timeline.
class _Editor extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.project,
    required this.onHome,
    required this.onUndo,
    required this.onRedo,
  });

  final String projectId;
  final Project project;
  final VoidCallback onHome;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  /// Width from which the tablet layout is used (AGENTS.md §8).
  static const double expandedWidth = 840;

  /// Timeline height kept visible above an open tool panel on phones.
  static const double _minTimelineHeight = 80;

  Future<void> _onTool(
    BuildContext context,
    WidgetRef ref,
    DockTool tool,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    switch (tool) {
      case DockTool.back:
        ref
            .read(timelineSelectionControllerProvider(projectId).notifier)
            .clear();
      case DockTool.add:
        final List<MediaRef> media;
        try {
          media = await ref.read(mediaPickerProvider).pickVisualMedia();
        } on PlatformException {
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.mediaPickerFailed)),
            );
          }
          return;
        }
        if (media.isEmpty || !context.mounted) return;
        ref
            .read(projectSessionProvider(projectId).notifier)
            .apply(
              AppendMediaCommand(media, newId: ref.read(idGeneratorProvider)),
            );
      case DockTool.split ||
          DockTool.duplicate ||
          DockTool.delete ||
          DockTool.speed ||
          DockTool.crop ||
          DockTool.transform ||
          DockTool.filters ||
          DockTool.adjust:
        final selection = ref.read(
          timelineSelectionControllerProvider(projectId),
        );
        // Overlay and audio clips get these tools with their phases.
        if (selection is! MainClipSelection) {
          _soon(messenger, l10n);
          return;
        }
        _onClipTool(ref, messenger, l10n, tool, selection.clipId);
      case DockTool.ratio:
        ref
            .read(openToolPanelProvider(projectId).notifier)
            .open(ToolPanelKind.ratio);
      case DockTool.music ||
          DockTool.voice ||
          DockTool.text ||
          DockTool.effect ||
          DockTool.overlay ||
          DockTool.animation ||
          DockTool.volume:
        _soon(messenger, l10n);
    }
  }

  void _soon(ScaffoldMessengerState messenger, AppLocalizations l10n) =>
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.editorToolSoon)));

  /// Tools that act on the selected main-track clip [clipId].
  void _onClipTool(
    WidgetRef ref,
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
    DockTool tool,
    String clipId,
  ) {
    final session = ref.read(projectSessionProvider(projectId).notifier);
    final newId = ref.read(idGeneratorProvider);
    switch (tool) {
      case DockTool.split:
        final timeUs = ref.read(playbackPositionProvider(projectId));
        if (!canSplitAt(project, clipId, timeUs)) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.editorSplitOutside)));
          return;
        }
        session.apply(SplitClipCommand(clipId, timeUs: timeUs, newId: newId));
      case DockTool.duplicate:
        session.apply(DuplicateClipCommand(clipId, newId: newId));
      case DockTool.delete:
        // Undoable, so no confirmation (AGENTS.md section 8).
        session.apply(DeleteClipCommand(clipId));
      case DockTool.speed:
        ref
            .read(openToolPanelProvider(projectId).notifier)
            .open(ToolPanelKind.speed);
      case DockTool.crop:
        // The crop handles sit over the frame on screen, so show this clip.
        final index = project.mainTrack.clips.indexWhere((c) => c.id == clipId);
        if (index >= 0) {
          final startUs = project.mainTrack.startOf(index);
          final endUs = startUs + project.mainTrack.clips[index].durationUs;
          final positionUs = ref.read(playbackPositionProvider(projectId));
          if (positionUs < startUs || positionUs >= endUs) {
            unawaited(
              ref.read(playbackProvider(projectId).notifier).seekTo(startUs),
            );
          }
        }
        ref
            .read(openToolPanelProvider(projectId).notifier)
            .open(ToolPanelKind.crop);
      case DockTool.transform:
        ref
            .read(openToolPanelProvider(projectId).notifier)
            .open(ToolPanelKind.transform);
      case DockTool.filters:
        ref
            .read(openToolPanelProvider(projectId).notifier)
            .open(ToolPanelKind.filters);
      case DockTool.adjust:
        ref
            .read(openToolPanelProvider(projectId).notifier)
            .open(ToolPanelKind.adjust);
      // Only clip tools are routed here.
      case _:
        _soon(messenger, l10n);
    }
  }

  /// Opens the full screen preview, flagging it so the editor's preview
  /// tweaks (the uncropped clip under the crop handles) pause meanwhile.
  Future<void> _openFullscreen(BuildContext context, WidgetRef ref) async {
    final fullscreen = previewFullscreenProvider(projectId);
    ref.read(fullscreen.notifier).set(open: true);
    try {
      await FullscreenPreview.open(
        context,
        projectId: projectId,
        canvas: project.canvas,
      );
    } finally {
      if (context.mounted) ref.read(fullscreen.notifier).set(open: false);
    }
  }

  /// The open tool panel, or null.
  Widget? _toolPanel(WidgetRef ref, TimelineSelection selection) {
    final kind = ref.watch(openToolPanelProvider(projectId));
    if (kind == null) return null;
    if (kind == ToolPanelKind.ratio) {
      return _ProjectRatioPanel(projectId: projectId, project: project);
    }
    if (selection is! MainClipSelection) return null;
    final index = project.mainTrack.clips.indexWhere(
      (c) => c.id == selection.clipId,
    );
    if (index < 0) return null;
    final clip = project.mainTrack.clips[index];
    final clipStartUs = project.mainTrack.startOf(index);
    return switch (kind) {
      ToolPanelKind.speed => _ClipSpeedPanel(
        projectId: projectId,
        clip: clip,
        clipStartUs: clipStartUs,
      ),
      ToolPanelKind.crop => _ClipCropPanel(
        projectId: projectId,
        clip: clip,
        clipStartUs: clipStartUs,
        canvasRatio: project.canvas.aspect.ratio,
        keyframeToleranceUs: keyframeToleranceUs(project),
      ),
      ToolPanelKind.transform => _ClipTransformPanel(
        projectId: projectId,
        clip: clip,
        clipStartUs: clipStartUs,
        keyframeToleranceUs: keyframeToleranceUs(project),
      ),
      ToolPanelKind.filters => _ClipFiltersPanel(
        projectId: projectId,
        clip: clip,
      ),
      ToolPanelKind.adjust => _ClipAdjustPanel(
        projectId: projectId,
        clip: clip,
      ),
      ToolPanelKind.ratio => const SizedBox.shrink(),
    };
  }

  /// The active preview overlay (crop handles while Crop is open, or the
  /// direct-manipulation transform gizmo whenever a main clip is selected),
  /// shown only while the playhead is on that clip.
  Widget? _previewOverlay(WidgetRef ref, TimelineSelection selection) {
    if (selection is! MainClipSelection) return null;
    final clips = project.mainTrack.clips;
    final index = clips.indexWhere((c) => c.id == selection.clipId);
    if (index < 0) return null;
    final clip = clips[index];
    final clipStartUs = project.mainTrack.startOf(index);
    final canvasRatio = project.canvas.aspect.ratio;
    final kind = ref.watch(openToolPanelProvider(projectId));
    final overlay = kind == ToolPanelKind.crop
        ? _ClipCropOverlay(
            projectId: projectId,
            clip: clip,
            clipStartUs: clipStartUs,
            canvasRatio: canvasRatio,
          )
        : _ClipTransformGizmo(
            projectId: projectId,
            clip: clip,
            clipStartUs: clipStartUs,
            canvasRatio: canvasRatio,
            showFrame: kind == ToolPanelKind.transform,
            keyframeToleranceUs: keyframeToleranceUs(project),
          );
    return _OnClipOnly(
      projectId: projectId,
      startUs: clipStartUs,
      endUs: clipStartUs + clip.durationUs,
      // At the very end of the project the preview still shows the last
      // clip's final frame.
      includeEnd: index == clips.length - 1,
      child: overlay,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Listened to here, not in ProjectScreen, so no native preview is
    // created for a project that failed to load.
    ref.listen(playbackProvider(projectId).select((s) => s.error), (_, e) {
      if (e != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.editorPlaybackFailed)));
      }
    });
    final scheme = Theme.of(context).colorScheme;
    final selection = ref.watch(timelineSelectionControllerProvider(projectId));
    final tools = dockToolsFor(selection);
    final panel = _toolPanel(ref, selection);
    final overlay = _previewOverlay(ref, selection);
    void onTool(DockTool t) => unawaited(_onTool(context, ref, t));
    final transport = TransportBar(
      projectId: projectId,
      onUndo: onUndo,
      onRedo: onRedo,
      onFullscreen: () => unawaited(_openFullscreen(context, ref)),
    );
    final timeline = TimelineView(projectId: projectId, project: project);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tablet (Clipcraft Neon Focus): top bar, large preview + floating
        // right inspector/panel, PlayRow, full-width timeline, bottom ToolTray.
        if (constraints.maxWidth >= expandedWidth) {
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EditorTopBar(onHome: onHome, floating: false),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTokens.cardRadius,
                            ),
                            child: ColoredBox(
                              color: scheme.surfaceContainerLowest,
                              child: PreviewView(
                                projectId: projectId,
                                canvas: project.canvas,
                                overlay: overlay,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: PropertiesPanel.width,
                          child: Align(
                            alignment: AlignmentDirectional.topCenter,
                            child: panel != null
                                ? Material(
                                    color: scheme.surfaceContainer,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTokens.inspectorRadius,
                                      ),
                                      side: BorderSide(
                                        color: scheme.outlineVariant,
                                      ),
                                    ),
                                    clipBehavior: ui.Clip.antiAlias,
                                    child: SingleChildScrollView(child: panel),
                                  )
                                : PropertiesPanel(
                                    project: project,
                                    selection: selection,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                transport,
                Expanded(flex: 2, child: timeline),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    border: Border(
                      top: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  child: ToolDock(tools: tools, onTool: onTool),
                ),
              ],
            ),
          );
        }

        // Phone (Clipcraft Editor B): floating top bar and a rounded bottom
        // sheet holding PlayRow, timeline & tray; the preview fits between.
        final viewportHeight = constraints.maxHeight;
        final sheetHeight = panel == null
            ? math.min<double>(340, viewportHeight * 0.44)
            : math.min<double>(430, viewportHeight * 0.62);
        const sheetRadius = BorderRadius.vertical(
          top: Radius.circular(AppTokens.sheetRadius),
        );
        return ColoredBox(
          color: scheme.surfaceContainerLowest,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The preview fits the space between the top bar and the sheet,
              // so no part of the video or its crop/transform handles hides
              // behind them.
              Positioned(
                top: MediaQuery.paddingOf(context).top + _EditorTopBar.height,
                left: 0,
                right: 0,
                bottom: sheetHeight,
                child: PreviewView(
                  projectId: projectId,
                  canvas: project.canvas,
                  overlay: overlay,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: _EditorTopBar(onHome: onHome, floating: true),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: sheetHeight,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: sheetRadius,
                      border: Border(
                        top: BorderSide(color: scheme.outlineVariant),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.shadow.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: sheetRadius,
                      child: SafeArea(
                        top: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.onSurfaceVariant.withValues(
                                    alpha: 0.45,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            transport,
                            // Keep TimelineView in the same tree slot whether a
                            // tool panel or the tray is below it so opening or
                            // closing a panel preserves its scroll state.
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, area) => Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: timeline),
                                    if (panel != null)
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: math.max(
                                            0,
                                            area.maxHeight - _minTimelineHeight,
                                          ),
                                        ),
                                        child: SingleChildScrollView(
                                          child: panel,
                                        ),
                                      )
                                    else
                                      ToolDock(tools: tools, onTool: onTool),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// [SpeedPanel] bound to [clip]: each change is its own undo step.
class _ClipSpeedPanel extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.clip,
    required this.clipStartUs,
  });

  final String projectId;
  final Clip clip;
  final int clipStartUs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.read(projectSessionProvider(projectId).notifier);
    void apply(EditCommand command) {
      session
        ..apply(command)
        ..seal();
    }

    // Where the playhead is inside the clip, for the curve editor. Only
    // rebuilds when that changes, not on every position tick elsewhere.
    final progress = ref.watch(
      playbackPositionProvider(projectId).select((positionUs) {
        final offset = positionUs - clipStartUs;
        if (offset < 0 || offset > clip.durationUs) return null;
        return (clip.sourceOffsetAt(offset) / clip.sourceDurationUs * 1000)
                .round() /
            1000;
      }),
    );

    final isImage = clip.media.kind == MediaKind.image;
    return SpeedPanel(
      speed: clip.speed,
      keepPitch: clip.keepPitch,
      curve: isImage ? null : clip.speedCurve,
      playheadProgress: progress,
      onChanged: (speed) => apply(SetClipSpeedCommand(clip.id, speed: speed)),
      onCurveChanged: isImage
          ? null
          : (curve) => apply(SetClipSpeedCurveCommand(clip.id, curve)),
      onKeepPitchChanged: isImage
          ? null
          : (keep) => apply(SetClipKeepPitchCommand(clip.id, keepPitch: keep)),
      onClose: ref.read(openToolPanelProvider(projectId).notifier).close,
    );
  }
}

/// [CropPanel] bound to [clip]. Ruler drags are one undo step; every other
/// control is its own.
class _ClipCropPanel extends ConsumerStatefulWidget {
  const new({
    required this.projectId,
    required this.clip,
    required this.clipStartUs,
    required this.canvasRatio,
    required this.keyframeToleranceUs,
  });

  final String projectId;
  final Clip clip;
  final int clipStartUs;

  /// Used for the crop presets when the media's size is unknown.
  final double canvasRatio;

  /// How near a keyframe an edit updates it instead of adding one.
  final int keyframeToleranceUs;

  @override
  ConsumerState<_ClipCropPanel> createState() => _ClipCropPanelState();
}

class _ClipCropPanelState extends ConsumerState<_ClipCropPanel> {
  /// Playhead time captured when a ruler drag starts, so dragging while
  /// playing edits one timestamp and coalesces into one undo step.
  int? _dragAtUs;

  @override
  void didUpdateWidget(_ClipCropPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clip.id != oldWidget.clip.id) _dragAtUs = null;
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final clipStartUs = widget.clipStartUs;
    final session = ref.read(projectSessionProvider(widget.projectId).notifier);
    final position = playbackPositionProvider(widget.projectId);
    // Clip-relative playhead, read when an edit happens (not watched, so
    // playback doesn't rebuild the panel).
    int atUs() => ref.read(position) - clipStartUs;
    void apply(EditCommand command) {
      session
        ..apply(command)
        ..seal();
    }

    // The rotation an edit at the playhead (or at the ruler drag's time
    // while dragging) changes; only rebuilds when it changes.
    final dragAtUs = _dragAtUs;
    final toleranceUs = widget.keyframeToleranceUs;
    final rotation = ref.watch(
      position.select(
        (positionUs) => clip.transform
            .editableAt(
              (dragAtUs ?? positionUs - clipStartUs).clamp(0, clip.durationUs),
              toleranceUs: toleranceUs,
            )
            .rotation,
      ),
    );
    final media = clip.media;
    final sourceRatio = media.displayWidth > 0 && media.displayHeight > 0
        ? media.displayWidth / media.displayHeight
        : widget.canvasRatio;
    final transform = clip.transform;
    final crop = clip.crop;
    final untouched =
        crop.isFull &&
        crop.aspect == null &&
        !transform.flipX &&
        !transform.flipY &&
        sameAngle(rotation, 0);
    return CropPanel(
      aspect: crop.aspect,
      rotation: rotation,
      mirrored: transform.flipX,
      flipped: transform.flipY,
      onAspect: (aspect) {
        if (aspect == crop.aspect) return;
        apply(
          SetClipCropCommand(
            clip.id,
            aspect == null
                ? crop.copyWith(aspect: null)
                : CropRect.centered(aspect, sourceRatio),
            coalesce: false,
          ),
        );
      },
      onRotationDrag: (degrees) {
        final dragAt = _dragAtUs ??= atUs();
        session.apply(
          SetClipTransformValuesCommand(
            clip.id,
            atUs: dragAt,
            rotation: degrees,
          ),
        );
      },
      onRotationDragEnd: () {
        // May run after a frame (the panel closed mid-drag), when this is
        // gone.
        if (mounted) setState(() => _dragAtUs = null);
        session.seal();
      },
      onRotationSet: (degrees) => apply(
        SetClipTransformValuesCommand(
          clip.id,
          atUs: atUs(),
          rotation: degrees,
          coalesce: false,
        ),
      ),
      onMirror: () => apply(ToggleClipFlipCommand(clip.id, horizontal: true)),
      onFlip: () => apply(ToggleClipFlipCommand(clip.id, horizontal: false)),
      onRotateQuarter: () =>
          apply(RotateClipQuarterCommand(clip.id, atUs: atUs())),
      onReset: untouched
          ? null
          : () => apply(ResetClipCropCommand(clip.id, atUs: atUs())),
      onClose: ref.read(openToolPanelProvider(widget.projectId).notifier).close,
    );
  }
}

/// [TransformPanel] bound to [clip]: slider drags coalesce into one undo step
/// (at a captured playhead time); discrete taps, swatches and resets each form
/// their own undo step.
class _ClipTransformPanel extends ConsumerStatefulWidget {
  const new({
    required this.projectId,
    required this.clip,
    required this.clipStartUs,
    required this.keyframeToleranceUs,
  });

  final String projectId;
  final Clip clip;
  final int clipStartUs;
  final int keyframeToleranceUs;

  @override
  ConsumerState<_ClipTransformPanel> createState() =>
      _ClipTransformPanelState();
}

class _ClipTransformPanelState extends ConsumerState<_ClipTransformPanel> {
  int? _dragAtUs;

  @override
  void didUpdateWidget(_ClipTransformPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clip.id != oldWidget.clip.id) _dragAtUs = null;
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final clipStartUs = widget.clipStartUs;
    final toleranceUs = widget.keyframeToleranceUs;
    final session = ref.read(projectSessionProvider(widget.projectId).notifier);
    final position = playbackPositionProvider(widget.projectId);
    int atUs() => ref.read(position) - clipStartUs;
    void applyDiscrete(EditCommand command) {
      session
        ..apply(command)
        ..seal();
    }

    // While a slider drags, show the values at the drag's time so playback
    // moving on doesn't make the thumb jump.
    final dragAtUs = _dragAtUs;
    final snapshot = ref.watch(
      position.select((positionUs) {
        final at = (dragAtUs ?? positionUs - clipStartUs).clamp(
          0,
          clip.durationUs,
        );
        final t = clip.transform;
        return (
          // What an edit here changes: a keyframe within tolerance reads
          // as the value just dragged to, not the interpolated one.
          resolved: t.editableAt(at, toleranceUs: toleranceUs),
          posKf: t.hasKeyframeNear(
            TransformProperty.position,
            at,
            toleranceUs: toleranceUs,
          ),
          scaleKf: t.hasKeyframeNear(
            TransformProperty.scale,
            at,
            toleranceUs: toleranceUs,
          ),
          rotKf: t.hasKeyframeNear(
            TransformProperty.rotation,
            at,
            toleranceUs: toleranceUs,
          ),
          opKf: t.hasKeyframeNear(
            TransformProperty.opacity,
            at,
            toleranceUs: toleranceUs,
          ),
        );
      }),
    );
    final animatedProperties = {
      for (final prop in TransformProperty.values)
        if (clip.transform.isAnimatedProperty(prop)) prop,
    };
    final activeKeyframes = {
      if (snapshot.posKf) TransformProperty.position,
      if (snapshot.scaleKf) TransformProperty.scale,
      if (snapshot.rotKf) TransformProperty.rotation,
      if (snapshot.opKf) TransformProperty.opacity,
    };
    final resolved = snapshot.resolved;
    return TransformPanel(
      fitMode: clip.fitMode,
      position: resolved.position,
      scale: resolved.scale,
      rotation: resolved.rotation,
      opacity: resolved.opacity,
      border: clip.border,
      animatedProperties: animatedProperties,
      activeKeyframes: activeKeyframes,
      onToggleKeyframe: (property) => applyDiscrete(
        ToggleClipKeyframeCommand(clip.id, property, atUs: atUs()),
      ),
      onFitMode: (mode) => applyDiscrete(SetClipFitModeCommand(clip.id, mode)),
      onTransformDrag: ({position, scale, rotation, opacity}) {
        final dragAt = _dragAtUs ??= atUs();
        session.apply(
          SetClipTransformValuesCommand(
            clip.id,
            atUs: dragAt,
            position: position,
            scale: scale,
            rotation: rotation,
            opacity: opacity,
          ),
        );
      },
      onTransformDragEnd: () {
        if (mounted) setState(() => _dragAtUs = null);
        session.seal();
      },
      onTransformSet: ({position, scale, rotation, opacity}) => applyDiscrete(
        SetClipTransformValuesCommand(
          clip.id,
          atUs: atUs(),
          position: position,
          scale: scale,
          rotation: rotation,
          opacity: opacity,
          coalesce: false,
        ),
      ),
      onBorderDrag: (border) =>
          session.apply(SetClipBorderCommand(clip.id, border)),
      onBorderDragEnd: session.seal,
      onBorderSet: (border) =>
          applyDiscrete(SetClipBorderCommand(clip.id, border, coalesce: false)),
      onClose: ref.read(openToolPanelProvider(widget.projectId).notifier).close,
    );
  }
}

/// [FiltersPanel] bound to [clip]: preset taps and Reset are single undo
/// steps; intensity slider drags coalesce and seal on release.
class _ClipFiltersPanel extends ConsumerWidget {
  const new({required this.projectId, required this.clip});

  final String projectId;
  final Clip clip;

  static const int _previewHeightPx = 128;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.read(projectSessionProvider(projectId).notifier);
    final previewTimeUs = clip.media.kind == MediaKind.image
        ? 0
        : clip.sourceInUs;
    final baseThumb = ref
        .watch(
          clipThumbnailProvider(
            clip.media.uri,
            previewTimeUs,
            _previewHeightPx,
          ),
        )
        .value;
    final previews =
        ref
            .watch(
              clipFilterPreviewsProvider(
                clip.media.uri,
                previewTimeUs,
                _previewHeightPx,
              ),
            )
            .value ??
        const <String, String?>{};
    return FiltersPanel(
      filter: clip.filter,
      baseThumbnailPath: baseThumb,
      previewPaths: previews,
      onSelect: (next) => session
        ..apply(SetClipFilterCommand(clip.id, next))
        ..seal(),
      onIntensityDrag: (intensity) {
        final current = clip.filter;
        if (current == null) return;
        session.apply(
          SetClipFilterCommand(
            clip.id,
            current.copyWith(intensity: intensity),
            coalesce: true,
          ),
        );
      },
      onIntensityDragEnd: session.seal,
      onIntensitySet: (intensity) {
        final current = clip.filter;
        if (current == null) return;
        session
          ..apply(
            SetClipFilterCommand(
              clip.id,
              current.copyWith(intensity: intensity),
            ),
          )
          ..seal();
      },
      onClose: ref.read(openToolPanelProvider(projectId).notifier).close,
    );
  }
}

/// [AdjustPanel] bound to [clip]: slider drags coalesce and seal on release;
/// typed values and resets are discrete undo steps.
class _ClipAdjustPanel extends ConsumerWidget {
  const new({required this.projectId, required this.clip});

  final String projectId;
  final Clip clip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.read(projectSessionProvider(projectId).notifier);
    return AdjustPanel(
      adjustments: clip.adjustments,
      onDrag: (next) => session.apply(SetClipAdjustmentsCommand(clip.id, next)),
      onDragEnd: session.seal,
      onSet: (next) => session
        ..apply(SetClipAdjustmentsCommand(clip.id, next, coalesce: false))
        ..seal(),
      onClose: ref.read(openToolPanelProvider(projectId).notifier).close,
    );
  }
}

/// [RatioPanel] bound to [project]'s canvas aspect and background.
class _ProjectRatioPanel extends ConsumerWidget {
  const new({required this.projectId, required this.project});

  final String projectId;
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final session = ref.read(projectSessionProvider(projectId).notifier);
    final first = project.mainTrack.clips.firstOrNull?.media;
    final original =
        first != null && first.displayWidth > 0 && first.displayHeight > 0
        ? CanvasAspect.reduced(first.displayWidth, first.displayHeight)
        : null;

    Future<void> pickImage() async {
      final MediaRef? picked;
      try {
        picked = await ref.read(mediaPickerProvider).pickImage();
      } on PlatformException {
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.mediaPickerFailed)),
          );
        }
        return;
      }
      if (picked == null || !context.mounted) return;
      final existing = project.canvas.background;
      final blur = existing is ImageBackground ? existing.blur : 0.0;
      session
        ..apply(
          SetCanvasBackgroundCommand(
            CanvasBackground.image(uri: picked.uri, blur: blur),
          ),
        )
        ..seal();
    }

    return RatioPanel(
      aspect: project.canvas.aspect,
      original: original,
      background: project.canvas.background,
      onAspect: (aspect) => session
        ..apply(SetCanvasAspectCommand(aspect))
        ..seal(),
      onBackgroundDrag: (bg) =>
          session.apply(SetCanvasBackgroundCommand(bg, coalesce: true)),
      onBackgroundDragEnd: session.seal,
      onBackgroundSet: (bg) => session
        ..apply(SetCanvasBackgroundCommand(bg))
        ..seal(),
      onPickImage: () => unawaited(pickImage()),
      onClose: ref.read(openToolPanelProvider(projectId).notifier).close,
    );
  }
}

/// [CropOverlay] bound to [clip]: drags coalesce into one undo step and seal
/// on release.
class _ClipCropOverlay extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.clip,
    required this.clipStartUs,
    required this.canvasRatio,
  });

  final String projectId;
  final Clip clip;
  final int clipStartUs;
  final double canvasRatio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.read(projectSessionProvider(projectId).notifier);
    final position = playbackPositionProvider(projectId);
    final rotation = ref.watch(
      position.select(
        (positionUs) => clip.transform
            .at((positionUs - clipStartUs).clamp(0, clip.durationUs))
            .rotation,
      ),
    );
    final media = clip.media;
    final sourceRatio = media.displayWidth > 0 && media.displayHeight > 0
        ? media.displayWidth / media.displayHeight
        : canvasRatio;
    return CropOverlay(
      crop: clip.crop,
      sourceRatio: sourceRatio,
      rotationDegrees: rotation,
      flipX: clip.transform.flipX,
      flipY: clip.transform.flipY,
      onChanged: (next) => session.apply(SetClipCropCommand(clip.id, next)),
      onChangeEnd: session.seal,
    );
  }
}

/// [TransformGizmo] bound to [clip]: drags and pinches coalesce into one undo
/// step at a playhead time captured on gesture start, and seal on release.
class _ClipTransformGizmo extends ConsumerStatefulWidget {
  const new({
    required this.projectId,
    required this.clip,
    required this.clipStartUs,
    required this.canvasRatio,
    required this.showFrame,
    required this.keyframeToleranceUs,
  });

  final String projectId;
  final Clip clip;
  final int clipStartUs;
  final double canvasRatio;
  final bool showFrame;

  /// How near a keyframe an edit updates it instead of adding one.
  final int keyframeToleranceUs;

  @override
  ConsumerState<_ClipTransformGizmo> createState() =>
      _ClipTransformGizmoState();
}

class _ClipTransformGizmoState extends ConsumerState<_ClipTransformGizmo> {
  /// Clip-relative time captured when a gesture starts. While set, the gizmo
  /// shows and edits the values at this time, so playback moving on can't
  /// cancel the gesture or spread it over several keyframes.
  int? _gestureAtUs;

  @override
  void didUpdateWidget(_ClipTransformGizmo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clip.id != oldWidget.clip.id) _gestureAtUs = null;
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final clipStartUs = widget.clipStartUs;
    final session = ref.read(projectSessionProvider(widget.projectId).notifier);
    final positionProvider = playbackPositionProvider(widget.projectId);
    final gestureAtUs = _gestureAtUs;
    final toleranceUs = widget.keyframeToleranceUs;
    // What an edit at the playhead (or the gesture's time) changes, so the
    // values the gizmo wrote read back unchanged beside a keyframe.
    final resolved = ref.watch(
      positionProvider.select(
        (positionUs) => clip.transform.editableAt(
          (gestureAtUs ?? positionUs - clipStartUs).clamp(0, clip.durationUs),
          toleranceUs: toleranceUs,
        ),
      ),
    );
    final media = clip.media;
    final sourceRatio = media.displayWidth > 0 && media.displayHeight > 0
        ? media.displayWidth / media.displayHeight
        : widget.canvasRatio;
    return TransformGizmo(
      position: resolved.position,
      scale: resolved.scale,
      rotation: resolved.rotation,
      sourceRatio: sourceRatio,
      crop: clip.crop,
      fitMode: clip.fitMode,
      showFrame: widget.showFrame,
      onChangeStart: () => setState(
        () => _gestureAtUs = ref.read(positionProvider) - clipStartUs,
      ),
      onChanged: ({position, scale, rotation}) {
        final atUs = _gestureAtUs ??= ref.read(positionProvider) - clipStartUs;
        session.apply(
          SetClipTransformValuesCommand(
            clip.id,
            atUs: atUs,
            position: position,
            scale: scale,
            rotation: rotation,
          ),
        );
      },
      onChangeEnd: () {
        // May run after a frame (a cancelled gesture), when this is gone.
        if (mounted) setState(() => _gestureAtUs = null);
        session.seal();
      },
    );
  }
}

/// Shows [child] only while the playhead is within `[startUs, endUs)` (or
/// at [endUs] too with [includeEnd]), so an overlay never edits a clip the
/// preview isn't showing. Rebuilds only when that changes.
class _OnClipOnly extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.startUs,
    required this.endUs,
    required this.includeEnd,
    required this.child,
  });

  final String projectId;
  final int startUs;
  final int endUs;
  final bool includeEnd;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onClip = ref.watch(
      playbackPositionProvider(projectId).select(
        (p) => p >= startUs && (p < endUs || (includeEnd && p == endUs)),
      ),
    );
    return onClip ? child : const SizedBox.shrink();
  }
}

/// Clipcraft EditorTopBar: back chevron on the left and a primary Export
/// button on the right. When [floating] over the phone editor's backdrop, the
/// back icon sits inside a subtle translucent circle for contrast.
class _EditorTopBar extends StatelessWidget {
  const new({required this.onHome, required this.floating});

  /// Height of the bar below the status bar.
  static const double height = 56;

  final VoidCallback onHome;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final backIcon = AppIcon(AppIcons.home, size: 22, color: scheme.onSurface);
    return Container(
      height: height,
      padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 12, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.editorHome,
            onPressed: onHome,
            icon: floating
                ? Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                    ),
                    child: backIcon,
                  )
                : backIcon,
          ),
          const Spacer(),
          Tooltip(
            message: l10n.editorExport,
            child: FilledButton(
              onPressed: () => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l10n.editorExportSoon))),
              style: FilledButton.styleFrom(
                minimumSize: const Size(76, 38),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
              ),
              child: Text(l10n.editorExport),
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps the preview in sync with the project (every edit, undo and redo
/// reloads it) and pauses it when the app goes to the background.
class _PlaybackBinding extends ConsumerStatefulWidget {
  const new({required this.projectId, required this.child});

  final String projectId;
  final Widget child;

  @override
  ConsumerState<_PlaybackBinding> createState() => _PlaybackBindingState();
}

class _PlaybackBindingState extends ConsumerState<_PlaybackBinding> {
  late final AppLifecycleListener _listener;
  ProviderSubscription<PlaybackState>? _keepPreview;

  String? _uncroppedClipId() {
    if (ref.read(openToolPanelProvider(widget.projectId)) !=
            ToolPanelKind.crop ||
        ref.read(previewFullscreenProvider(widget.projectId))) {
      return null;
    }
    final selection = ref.read(
      timelineSelectionControllerProvider(widget.projectId),
    );
    return selection is MainClipSelection ? selection.clipId : null;
  }

  void _resyncPreview() => _syncPreview(
    ref.read(projectSessionProvider(widget.projectId)).value?.history.present,
  );

  void _syncPreview(Project? project) {
    if (project == null) return;
    final playback = playbackProvider(widget.projectId);
    // The editor owns the preview from the first loaded project until it
    // closes. Without this, a rebuild that briefly drops every widget
    // listener (e.g. after a rename) let autoDispose tear down and
    // recreate the native player.
    _keepPreview ??= ref.listenManual(playback, (_, _) {});
    unawaited(
      ref
          .read(playback.notifier)
          .load(project, uncroppedClipId: _uncroppedClipId()),
    );
  }

  @override
  void initState() {
    super.initState();
    ref
      ..listenManual(
        projectSessionProvider(widget.projectId)
            .select((s) => s.value?.history.present),
        (_, project) => _syncPreview(project),
        fireImmediately: true,
      )
      ..listenManual(
        openToolPanelProvider(widget.projectId),
        (_, _) => _resyncPreview(),
      )
      ..listenManual(
        previewFullscreenProvider(widget.projectId),
        (_, _) => _resyncPreview(),
      );
    _listener = AppLifecycleListener(
      onHide: () {
        // Don't create a preview just to pause it (e.g. after a load error).
        final playback = playbackProvider(widget.projectId);
        if (ref.read(playback.exists)) {
          unawaited(ref.read(playback.notifier).pause());
        }
      },
    );
  }

  @override
  void dispose() {
    _keepPreview?.close();
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
