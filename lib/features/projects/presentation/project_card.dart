import 'dart:io';

import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/core/theme/timeline_colors.dart';
import 'package:cleancut/core/utils/timecode.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/presentation/playback/playback_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Actions offered in a project card's menu.
enum ProjectAction {
  /// Rename the project.
  rename,

  /// Copy the project.
  duplicate,

  /// Delete the project (undoable from a snackbar).
  delete,
}

/// A project tile in the home grid (Clipcraft Home A): 16:10 rounded
/// thumbnail with a duration badge and overflow menu, title and edited date
/// underneath.
class ProjectCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.project,
    required this.onOpen,
    required this.onAction,
    super.key,
  });

  /// Aspect ratio of the card's thumbnail slot (Clipcraft 16:10).
  static const double thumbnailAspect = 16 / 10;

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
    const radius = BorderRadius.all(Radius.circular(AppTokens.cardRadius));

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: radius,
        onTap: onOpen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: thumbnailAspect,
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Thumbnail(project: project),
                    // Subtle border around the thumbnail frame.
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    // Duration badge at bottom-end.
                    PositionedDirectional(
                      bottom: 8,
                      end: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.scrim.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            formatClockUs(project.durationUs),
                            style: AppTokens.timecodeStyle(
                              context,
                              color: scheme.onPrimary,
                            ).copyWith(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                    // Overflow menu button at top-end (48dp touch target).
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: _MenuButton(project: project, onAction: onAction),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              project.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontVariations: const [FontVariation.weight(600)],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.projectCardDate(project.updatedAt.toLocal()),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// First frame of the first clip (16:10, cover), or a category-tinted gradient
/// placeholder while it loads or when there is no frame.
class _Thumbnail extends ConsumerWidget {
  const new({required this.project});

  final Project project;

  static const int _decodeHeightPx = 220;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clips = project.mainTrack.clips;
    final path = clips.isEmpty
        ? null
        : ref
              .watch(
                clipThumbnailProvider(
                  clips.first.media.uri,
                  clips.first.sourceInUs,
                  _decodeHeightPx,
                ),
              )
              .value;
    final placeholder = _Placeholder(project: project);
    if (path == null) return placeholder;
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      cacheHeight: _decodeHeightPx,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const new({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accents = TimelineColors.of(context).cardAccents;
    final seed = project.id.hashCode.abs() % accents.length;
    final accent = accents[seed];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.55), scheme.surfaceContainer],
        ),
      ),
      child: Center(
        child: AppIcon(
          AppIcons.film,
          size: 28,
          color: scheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// Round translucent "•••" chip with a 48dp touch target.
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
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.scrim.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: AppIcon(AppIcons.moreH, size: 18, color: scheme.onPrimary),
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
