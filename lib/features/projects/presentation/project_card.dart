import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
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

/// A project row in the home list (VCLIP "Projects" card): thumbnail, name,
/// date and duration, with a round "•••" menu button.
class ProjectCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.project,
    required this.onOpen,
    required this.onAction,
    super.key,
  });

  /// Height of the card.
  static const double height = 114;

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

    return SizedBox(
      height: height,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 13, 56, 13),
                child: Row(
                  children: [
                    _Thumbnail(project: project),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.projectCardDate(project.updatedAt.toLocal()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDurationUs(project.durationUs),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                top: 2,
                end: 2,
                child: _MenuButton(project: project, onAction: onAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Canvas-shaped placeholder until Phase 2 adds frame thumbnails.
class _Thumbnail extends StatelessWidget {
  const new({required this.project});

  final Project project;

  static const double _width = 72;
  static const double _height = 88;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = project.canvas.aspect.ratio.clamp(0.25, 4.0);
    // Fit the canvas shape inside the 72×88 slot.
    final fitsWidth = ratio >= _width / _height;
    final w = fitsWidth ? _width : _height * ratio;
    final h = fitsWidth ? _width / ratio : _height;
    return SizedBox(
      width: _width,
      height: _height,
      child: Center(
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(Icons.movie_outlined, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Round 32dp "•••" chip with a 48dp touch target.
class _MenuButton extends StatelessWidget {
  const new({required this.project, required this.onAction});

  final Project project;
  final ValueChanged<ProjectAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<ProjectAction>(
      tooltip: l10n.homeProjectOptions(project.name),
      onSelected: onAction,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        padding: EdgeInsets.zero,
      ),
      icon: Container(
        width: AppTokens.chipSize,
        height: AppTokens.chipSize,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_horiz, size: 20, color: scheme.onSurface),
      ),
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
    );
  }
}
