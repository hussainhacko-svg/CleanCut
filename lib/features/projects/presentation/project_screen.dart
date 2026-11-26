import 'dart:async';
import 'dart:math' as math;

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/domain/commands/clip_commands.dart';
import 'package:cleancut/features/projects/domain/commands/project_commands.dart';
import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/domain/project_repository.dart';
import 'package:cleancut/features/projects/domain/timeline/timeline_selection.dart';
import 'package:cleancut/features/projects/presentation/editor/editor_state.dart';
import 'package:cleancut/features/projects/presentation/editor/panels/speed_panel.dart';
import 'package:cleancut/features/projects/presentation/editor/timeline/timeline_view.dart';
import 'package:cleancut/features/projects/presentation/editor/tool_dock.dart';
import 'package:cleancut/features/projects/presentation/playback/playback_controller.dart';
import 'package:cleancut/features/projects/presentation/playback/preview_widgets.dart';
import 'package:cleancut/features/projects/presentation/project_providers.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The editor (VCLIP "Timeline"): preview, transport, timeline and the
/// contextual tool dock.
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
          backgroundColor: scheme.surfaceContainerLowest,
          body: SafeArea(
            child: switch (session) {
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
              AsyncError(:final error) => Center(
                child: Text(
                  error is ProjectNotFoundException
                      ? l10n.editorNotFound
                      : l10n.homeLoadFailed,
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
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
          DockTool.speed:
        final selection = ref.read(
          timelineSelectionControllerProvider(projectId),
        );
        // Overlay and audio clips get these tools with their phases.
        if (selection is! MainClipSelection) {
          _soon(messenger, l10n);
          return;
        }
        _onClipTool(ref, messenger, l10n, tool, selection.clipId);
      case DockTool.music ||
          DockTool.voice ||
          DockTool.text ||
          DockTool.effect ||
          DockTool.overlay ||
          DockTool.ratio ||
          DockTool.filters ||
          DockTool.crop ||
          DockTool.adjust ||
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
      // Only clip tools are routed here.
      case _:
        _soon(messenger, l10n);
    }
  }

  /// The open tool panel for the selected main clip, or null.
  Widget? _toolPanel(WidgetRef ref, TimelineSelection selection) {
    final kind = ref.watch(openToolPanelProvider(projectId));
    if (kind == null || selection is! MainClipSelection) return null;
    final clip = project.mainTrack.clips
        .where((c) => c.id == selection.clipId)
        .firstOrNull;
    if (clip == null) return null;
    return switch (kind) {
      ToolPanelKind.speed => _ClipSpeedPanel(projectId: projectId, clip: clip),
    };
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
    final selection = ref.watch(timelineSelectionControllerProvider(projectId));
    final tools = dockToolsFor(selection);
    final panel = _toolPanel(ref, selection);
    void onTool(DockTool t) => unawaited(_onTool(context, ref, t));
    final transport = TransportBar(
      projectId: projectId,
      onUndo: onUndo,
      onRedo: onRedo,
      onFullscreen: () => unawaited(
        FullscreenPreview.open(
          context,
          projectId: projectId,
          canvas: project.canvas,
        ),
      ),
    );
    final timeline = TimelineView(projectId: projectId, project: project);
    final preview = _PreviewArea(
      projectId: projectId,
      canvas: project.canvas,
      onHome: onHome,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= expandedWidth) {
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ToolRail(tools: tools, onTool: onTool),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: preview),
                          const SizedBox(height: 4),
                          transport,
                        ],
                      ),
                    ),
                    if (panel != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          0,
                          12,
                          12,
                          12,
                        ),
                        child: SizedBox(
                          width: PropertiesPanel.width,
                          child: Align(
                            alignment: AlignmentDirectional.topCenter,
                            child: SingleChildScrollView(child: panel),
                          ),
                        ),
                      )
                    else
                      PropertiesPanel(project: project, selection: selection),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(flex: 2, child: timeline),
            ],
          );
        }
        final screenHeight = MediaQuery.sizeOf(context).height;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              // The kit's preview box is 282×360 on a 393×852 screen.
              height: screenHeight * (360 / 852) + 14,
              child: preview,
            ),
            const SizedBox(height: 4),
            transport,
            const SizedBox(height: 6),
            if (panel != null)
              // An open tool panel slides over the dock (kit "Speed"). It
              // takes what it needs but leaves the timeline at least
              // [_minTimelineHeight], scrolling inside on short screens.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, area) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: timeline),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: math.max(
                            0,
                            area.maxHeight - _minTimelineHeight,
                          ),
                        ),
                        child: SingleChildScrollView(child: panel),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Expanded(child: timeline),
              ToolDock(tools: tools, onTool: onTool),
              const SizedBox(height: 4),
            ],
          ],
        );
      },
    );
  }
}

/// [SpeedPanel] bound to [clip]: each change is its own undo step.
class _ClipSpeedPanel extends ConsumerWidget {
  const new({required this.projectId, required this.clip});

  final String projectId;
  final Clip clip;

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
        final project = ref
            .read(projectSessionProvider(projectId))
            .value
            ?.history
            .present;
        final index =
            project?.mainTrack.clips.indexWhere((c) => c.id == clip.id) ?? -1;
        if (project == null || index < 0) return null;
        final offset = positionUs - project.mainTrack.startOf(index);
        if (offset < 0 || offset > clip.durationUs) return null;
        return (clip.sourceOffsetAt(offset) / clip.sourceDurationUs * 1000)
                .round() /
            1000;
      }),
    );

    return SpeedPanel(
      speed: clip.speed,
      keepPitch: clip.keepPitch,
      curve: clip.speedCurve,
      playheadProgress: progress,
      onChanged: (speed) => apply(SetClipSpeedCommand(clip.id, speed: speed)),
      onCurveChanged: (curve) =>
          apply(SetClipSpeedCurveCommand(clip.id, curve)),
      onKeepPitchChanged: clip.media.kind == MediaKind.image
          ? null
          : (keep) => apply(SetClipKeepPitchCommand(clip.id, keepPitch: keep)),
      onClose: ref.read(openToolPanelProvider(projectId).notifier).close,
    );
  }
}

/// Preview with home and export in the top corners beside it.
class _PreviewArea extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.canvas,
    required this.onHome,
  });

  final String projectId;
  final ProjectCanvas canvas;
  final VoidCallback onHome;

  /// The kit's 282-wide preview leaves 56dp on each side for the icons.
  static const double _sideInset = 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            _sideInset,
            14,
            _sideInset,
            0,
          ),
          child: PreviewView(projectId: projectId, canvas: canvas),
        ),
        PositionedDirectional(
          start: 3,
          top: 0,
          child: IconButton(
            tooltip: l10n.editorHome,
            onPressed: onHome,
            icon: AppIcon(AppIcons.home, color: scheme.onSurface),
          ),
        ),
        PositionedDirectional(
          end: 8,
          top: 0,
          child: IconButton(
            tooltip: l10n.editorExport,
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.editorExportSoon))),
            icon: AppIcon(AppIcons.export, color: scheme.onSurface),
          ),
        ),
      ],
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

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      projectSessionProvider(widget.projectId)
          .select((s) => s.value?.history.present),
      (_, project) {
        if (project == null) return;
        final playback = playbackProvider(widget.projectId);
        // The editor owns the preview from the first loaded project until it
        // closes. Without this, a rebuild that briefly drops every widget
        // listener (e.g. after a rename) let autoDispose tear down and
        // recreate the native player.
        _keepPreview ??= ref.listenManual(playback, (_, _) {});
        unawaited(ref.read(playback.notifier).load(project));
      },
      fireImmediately: true,
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
