import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/utils/timecode.dart';
import 'package:cleancut/features/projects/domain/project_repository.dart';
import 'package:cleancut/features/projects/presentation/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens a project. Phase 1 placeholder: shows the project summary with
/// undo/redo; the editor shell replaces it in Phase 3.
class ProjectScreen extends ConsumerWidget {
  /// Creates the screen for [projectId].
  const new({required this.projectId, super.key});

  /// The open project.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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

    final history = session.value?.history;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Save before leaving so the project list is up to date.
        await ref.read(provider.notifier).flush();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(history?.present.name ?? ''),
          actions: [
            IconButton(
              tooltip: l10n.commonUndo,
              icon: const Icon(Icons.undo),
              onPressed: history?.canUndo ?? false
                  ? ref.read(provider.notifier).undo
                  : null,
            ),
            IconButton(
              tooltip: l10n.commonRedo,
              icon: const Icon(Icons.redo),
              onPressed: history?.canRedo ?? false
                  ? ref.read(provider.notifier).redo
                  : null,
            ),
          ],
        ),
        body: switch (session) {
          AsyncData(:final value) => _Summary(state: value),
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
    );
  }
}

class _Summary extends StatelessWidget {
  const new({required this.state});

  final SessionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final project = state.history.present;
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.editorClipSummary(
                project.clipCount,
                formatDurationUs(project.durationUs),
              ),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.editorPlaceholder,
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
