import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/utils/timecode.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:flutter/material.dart';

/// Actions offered in a project card's menu.
enum ProjectAction {
  /// Rename the project.
  rename,

  /// Copy the project.
  duplicate,

  /// Delete the project (undoable from a snackbar).
  delete,
}

/// A project tile in the home grid.
class ProjectCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.project,
    required this.onOpen,
    required this.onAction,
    super.key,
  });

  /// The project shown.
  final Project project;

  /// Opens the project.
  final VoidCallback onOpen;

  /// Runs a menu action.
  final ValueChanged<ProjectAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final aspect = project.canvas.aspect;

    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Stack(
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: aspect.ratio,
                        child: FractionallySizedBox(
                          widthFactor: 0.6,
                          heightFactor: 0.6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(color: scheme.outline),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.movie_outlined,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: 8,
                      bottom: 8,
                      child: _Badge(text: formatDurationUs(project.durationUs)),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 0, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          l10n.projectEditedOn(project.updatedAt.toLocal()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<ProjectAction>(
                    tooltip: l10n.homeProjectOptions(project.name),
                    onSelected: onAction,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: ProjectAction.rename,
                        child: Text(l10n.projectRename),
                      ),
                      PopupMenuItem(
                        value: ProjectAction.duplicate,
                        child: Text(l10n.projectDuplicate),
                      ),
                      PopupMenuItem(
                        value: ProjectAction.delete,
                        child: Text(l10n.projectDelete),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onInverseSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
