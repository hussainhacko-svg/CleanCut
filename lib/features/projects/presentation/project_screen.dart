import 'dart:async';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/media_import/presentation/media_picker_provider.dart';
import 'package:cleancut/features/projects/domain/commands/project_commands.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/project_repository.dart';
import 'package:cleancut/features/projects/presentation/editor/editor_state.dart';
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

    ref
      ..listen(provider.select((s) => s.value?.saveFailed ?? false), (
        _,
        failed,
      ) {
        if (failed) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.editorSaveFailed)));
        }
      })
      ..listen(playbackProvider(projectId).select((s) => s.error), (_, error) {
        if (error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.editorPlaybackFailed)));
        }
      });

    Future<void> leave() async {
      // Save before leaving so the project list is up to date.
      await ref.read(provider.notifier).flush();
      if (context.mounted) Navigator.of(context).pop();
    }

    final history = session.value?.history;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await leave();
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
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.mediaPickerFailed)),
          );
          return;
        }
        if (media.isEmpty) return;
        ref
            .read(projectSessionProvider(projectId).notifier)
            .apply(
              AppendMediaCommand(media, newId: ref.read(idGeneratorProvider)),
            );
      case DockTool.music ||
          DockTool.voice ||
          DockTool.text ||
          DockTool.effect ||
          DockTool.overlay ||
          DockTool.ratio ||
          DockTool.split ||
          DockTool.filters ||
          DockTool.crop ||
          DockTool.adjust ||
          DockTool.speed ||
          DockTool.animation ||
          DockTool.volume ||
          DockTool.delete:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.editorToolSoon)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(timelineSelectionControllerProvider(projectId));
    final tools = dockToolsFor(selection);
    void onTool(DockTool t) => unawaited(_onTool(context, ref, t));
    final transport = TransportBar(
      projectId: projectId,
      onUndo: onUndo,
      onRedo: onRedo,
      onFullscreen: () => unawaited(
        FullscreenPreview.open(
          context,
          projectId: projectId,
          aspectRatio: project.canvas.aspect.ratio,
        ),
      ),
    );
    final timeline = TimelineView(projectId: projectId, project: project);
    final preview = _PreviewArea(
      projectId: projectId,
      aspectRatio: project.canvas.aspect.ratio,
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
            Expanded(child: timeline),
            ToolDock(tools: tools, onTool: onTool),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

/// Preview with home and export in the top corners beside it.
class _PreviewArea extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.aspectRatio,
    required this.onHome,
  });

  final String projectId;
  final double aspectRatio;
  final VoidCallback onHome;

  /// The kit's 282-wide preview leaves 56dp on each side for the icons.
  static const double _sideInset = 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textureId = ref.watch(
      playbackProvider(projectId).select((s) => s.textureId),
    );
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            _sideInset,
            14,
            _sideInset,
            0,
          ),
          child: PreviewView(textureId: textureId, aspectRatio: aspectRatio),
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

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      projectSessionProvider(widget.projectId)
          .select((s) => s.value?.history.present),
      (_, project) {
        if (project != null) {
          unawaited(
            ref.read(playbackProvider(widget.projectId).notifier).load(project),
          );
        }
      },
      fireImmediately: true,
    );
    _listener = AppLifecycleListener(
      onHide: () => unawaited(
        ref.read(playbackProvider(widget.projectId).notifier).pause(),
      ),
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
