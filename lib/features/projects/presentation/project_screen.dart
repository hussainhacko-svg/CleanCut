import 'dart:async';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/domain/project_repository.dart';
import 'package:cleancut/features/projects/presentation/playback/playback_controller.dart';
import 'package:cleancut/features/projects/presentation/playback/preview_widgets.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The editor (VCLIP "Timeline", top half): home and export in the top
/// corners, the engine preview, and the transport row. The timeline and
/// tool dock below it arrive in Phase 3.
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
                aspectRatio: value.history.present.canvas.aspect.ratio,
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

class _Editor extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.aspectRatio,
    required this.onHome,
    required this.onUndo,
    required this.onRedo,
  });

  final String projectId;
  final double aspectRatio;
  final VoidCallback onHome;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  /// The kit's preview box is 282×360 on a 393×852 screen.
  static const double _sideInset = 56;
  static const double _heightFraction = 360 / 852;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textureId = ref.watch(
      playbackProvider(projectId).select((s) => s.textureId),
    );
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Home and export sit in the top corners beside the preview.
        SizedBox(
          height: screenHeight * _heightFraction + 14,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  _sideInset,
                  14,
                  _sideInset,
                  0,
                ),
                child: PreviewView(
                  textureId: textureId,
                  aspectRatio: aspectRatio,
                ),
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
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.editorExportSoon)),
                  ),
                  icon: AppIcon(AppIcons.export, color: scheme.onSurface),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        TransportBar(
          projectId: projectId,
          onUndo: onUndo,
          onRedo: onRedo,
          onFullscreen: () => unawaited(
            FullscreenPreview.open(
              context,
              projectId: projectId,
              aspectRatio: aspectRatio,
            ),
          ),
        ),
        // Timeline and tool dock: Phase 3.
        const Spacer(),
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
