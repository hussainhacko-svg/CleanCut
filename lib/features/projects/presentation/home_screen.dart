import 'dart:async';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/features/media_import/presentation/media_picker_provider.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/presentation/aspect_sheet.dart';
import 'package:cleancut/features/projects/presentation/project_card.dart';
import 'package:cleancut/features/projects/presentation/project_providers.dart';
import 'package:cleancut/features/projects/presentation/rename_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Route paths used by the home screen; injected by the app router so this
/// feature does not depend on `app/`.
typedef ProjectRoute = String Function(String projectId);

/// Home screen (VCLIP "Projects"): wordmark, "New project" tile and the
/// project list.
class HomeScreen extends ConsumerWidget {
  /// Creates the home screen. [projectRoute] builds the editor path and
  /// [settingsRoute] is the settings path.
  const new({
    required this.projectRoute,
    required this.settingsRoute,
    super.key,
  });

  /// Path of a project's editor.
  final ProjectRoute projectRoute;

  /// Path of the settings screen.
  final String settingsRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final projects = ref.watch(projectListProvider);

    final theme = Theme.of(context);
    void open(Project p) => unawaited(context.push(projectRoute(p.id)));
    void act(Project p, ProjectAction a) =>
        unawaited(_onAction(context, ref, p, a));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Semantics(
          header: true,
          child: Text(
            l10n.appTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: AppTokens.wordmarkFontFamily,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.tune),
            onPressed: () => context.push(settingsRoute),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppTokens.gutter,
              24,
              AppTokens.gutter,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: NewProjectTile(
                onTap: () => unawaited(_createProject(context, ref)),
              ),
            ),
          ),
          ...switch (projects) {
            AsyncData(value: final list) when list.isEmpty => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              ),
            ],
            AsyncData(value: final list) => [
              SliverPadding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 40, 24, 20),
                sliver: SliverToBoxAdapter(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.homeMyProjects,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              _ProjectList(projects: list, onOpen: open, onAction: act),
            ],
            AsyncError() => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  onRetry: () => ref.invalidate(projectListProvider),
                ),
              ),
            ],
            _ => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
        ],
      ),
    );
  }

  Future<void> _createProject(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final List<MediaRef> media;
    try {
      media = await ref.read(mediaPickerProvider).pickVisualMedia();
    } on PlatformException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.mediaPickerFailed)));
      return;
    }
    if (media.isEmpty || !context.mounted) return;

    final aspect = await showAspectSheet(
      context,
      original: originalAspectOf(media),
    );
    if (aspect == null || !context.mounted) return;

    try {
      final project = await ref
          .read(projectListProvider.notifier)
          .create(
            name: l10n.projectDefaultName(ref.read(clockProvider)()),
            aspect: aspect,
            media: media,
          );
      if (context.mounted) unawaited(context.push(projectRoute(project.id)));
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.projectActionFailed)));
    }
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    Project project,
    ProjectAction action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(projectListProvider.notifier);
    try {
      switch (action) {
        case ProjectAction.rename:
          final name = await showRenameDialog(context, project.name);
          if (name != null && name != project.name) {
            await notifier.rename(project.id, name);
          }
        case ProjectAction.duplicate:
          await notifier.duplicate(
            project.id,
            l10n.projectCopyName(project.name),
          );
        case ProjectAction.delete:
          final deleted = await notifier.delete(project.id);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                // A snackbar with an action persists by default; this one
                // should time out like any other notice.
                persist: false,
                content: Text(l10n.projectDeleted(deleted.name)),
                action: SnackBarAction(
                  label: l10n.commonUndo,
                  onPressed: () => unawaited(notifier.restore(deleted)),
                ),
              ),
            );
      }
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.projectActionFailed)));
    }
  }
}

/// The aspect of the first visual media with a known size, used for the
/// "Original" canvas choice.
CanvasAspect? originalAspectOf(List<MediaRef> media) {
  for (final m in media) {
    if (m.displayWidth > 0 && m.displayHeight > 0) {
      return CanvasAspect.reduced(m.displayWidth, m.displayHeight);
    }
  }
  return null;
}

/// Outlined "New project" tile at the top of the home screen.
class NewProjectTile extends StatelessWidget {
  /// Creates the tile; [onTap] starts project creation.
  const new({required this.onTap, super.key});

  /// Starts creating a project.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const radius = BorderRadius.all(Radius.circular(AppTokens.cardRadius));
    return Material(
      type: MaterialType.transparency,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outline),
      ),
      child: InkWell(
        customBorder: const RoundedRectangleBorder(borderRadius: radius),
        onTap: onTap,
        child: SizedBox(
          height: 114,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppTokens.chipSize,
                height: AppTokens.chipSize,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, size: 22, color: scheme.onSurface),
              ),
              const SizedBox(height: 10),
              Text(l10n.homeNewProject, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectList extends StatelessWidget {
  const new({
    required this.projects,
    required this.onOpen,
    required this.onAction,
  });

  final List<Project> projects;
  final ValueChanged<Project> onOpen;
  final void Function(Project, ProjectAction) onAction;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppTokens.gutter,
        0,
        AppTokens.gutter,
        24,
      ),
      // One column on phones; tablets fit two or three cards per row.
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 560,
          mainAxisExtent: ProjectCard.height,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: projects.length,
        itemBuilder: (context, i) {
          final p = projects[i];
          return ProjectCard(
            key: ValueKey(p.id),
            project: p,
            onOpen: () => onOpen(p),
            onAction: (a) => onAction(p, a),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(l10n.homeEmptyTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.homeEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.homeLoadFailed),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
