import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/accent_gradient.dart';
import 'package:cleancut/core/utils/timecode.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/presentation/playback/playback_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The engine's preview texture, letterboxed to the canvas [aspectRatio].
class PreviewView extends StatelessWidget {
  /// Creates the view; shows black until [textureId] is known.
  const new({required this.textureId, required this.aspectRatio, super.key});

  /// Texture from the engine, or null while it is created.
  final int? textureId;

  /// Canvas width / height.
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final id = textureId;
    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ColoredBox(
          color: Colors.black,
          child: id == null
              ? null
              : Texture(textureId: id, filterQuality: FilterQuality.medium),
        ),
      ),
    );
  }
}

/// A 40dp round dark button (VCLIP play / full-screen buttons) with a 48dp
/// touch target.
class RoundIconButton extends StatelessWidget {
  /// Creates the button.
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 14,
    super.key,
  });

  /// Glyph inside the circle.
  final AppIcons icon;

  /// Accessible label.
  final String tooltip;

  /// Tap handler; null disables the button.
  final VoidCallback? onPressed;

  /// Glyph box size.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 48dp target; the visible circle is 40dp as in the kit.
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(48),
        padding: EdgeInsets.zero,
      ),
      icon: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: AppIcon(icon, size: iconSize, color: scheme.onSurface),
      ),
    );
  }
}

/// "00:06 / 00:12" readout. Watches the position on its own so playback
/// only rebuilds this text.
class Timecode extends ConsumerWidget {
  /// Creates the readout for [projectId].
  const new({required this.projectId, this.style, super.key});

  /// The open project.
  final String projectId;

  /// Text style; defaults to 12px body text.
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final position = ref.watch(playbackPositionProvider(projectId));
    final duration = ref.watch(
      playbackProvider(projectId).select((s) => s.durationUs),
    );
    return Text(
      l10n.editorTimecode(formatClockUs(position), formatClockUs(duration)),
      maxLines: 1,
      textAlign: TextAlign.center,
      style: (style ?? Theme.of(context).textTheme.bodySmall)?.copyWith(
        fontSize: 12,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// The row under the preview (VCLIP "Timeline"): play, undo · time · redo,
/// full screen.
class TransportBar extends ConsumerWidget {
  /// Creates the bar.
  const new({
    required this.projectId,
    required this.onUndo,
    required this.onRedo,
    required this.onFullscreen,
    super.key,
  });

  /// The open project.
  final String projectId;

  /// Undo handler; null when there is nothing to undo.
  final VoidCallback? onUndo;

  /// Redo handler; null when there is nothing to redo.
  final VoidCallback? onRedo;

  /// Opens the full-screen preview.
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isPlaying = ref.watch(
      playbackProvider(projectId).select((s) => s.isPlaying),
    );
    final controller = ref.read(playbackProvider(projectId).notifier);

    Widget history(AppIcons icon, String tooltip, VoidCallback? onPressed) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          // The kit shows these small and grey; they turn white when usable.
          icon: AppIcon(
            icon,
            size: 11,
            color: onPressed == null ? scheme.outline : scheme.onSurface,
          ),
        );

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 9),
      // Circles sit 13dp from the edges, as in the kit.
      child: Row(
        children: [
          RoundIconButton(
            icon: isPlaying ? AppIcons.pause : AppIcons.play,
            iconSize: 13,
            tooltip: isPlaying ? l10n.editorPause : l10n.editorPlay,
            onPressed: controller.togglePlay,
          ),
          const Spacer(),
          history(AppIcons.undo, l10n.commonUndo, onUndo),
          // The kit's readout box is 98dp wide.
          SizedBox(width: 98, child: Timecode(projectId: projectId)),
          history(AppIcons.redo, l10n.commonRedo, onRedo),
          const Spacer(),
          RoundIconButton(
            icon: AppIcons.fullscreen,
            tooltip: l10n.editorFullscreen,
            onPressed: onFullscreen,
          ),
        ],
      ),
    );
  }
}

/// Full-screen preview (VCLIP "Full screen"): the video edge to edge, a close
/// mark, and a floating bar with play, times, scrub bar and exit.
class FullscreenPreview extends ConsumerWidget {
  /// Creates the page for [projectId] with the canvas [aspectRatio].
  const new({required this.projectId, required this.aspectRatio, super.key});

  /// The open project.
  final String projectId;

  /// Canvas width / height.
  final double aspectRatio;

  /// Opens the page over the editor.
  static Future<void> open(
    BuildContext context, {
    required String projectId,
    required double aspectRatio,
  }) => Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) =>
          FullscreenPreview(projectId: projectId, aspectRatio: aspectRatio),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textureId = ref.watch(
      playbackProvider(projectId).select((s) => s.textureId),
    );
    final isPlaying = ref.watch(
      playbackProvider(projectId).select((s) => s.isPlaying),
    );
    final controller = ref.read(playbackProvider(projectId).notifier);
    void close() => Navigator.of(context).pop();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PreviewView(textureId: textureId, aspectRatio: aspectRatio),
          SafeArea(
            child: Stack(
              children: [
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: IconButton(
                    tooltip: l10n.editorExitFullscreen,
                    onPressed: close,
                    icon: AppIcon(
                      AppIcons.close,
                      size: 14,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 18,
                  end: 18,
                  bottom: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: isPlaying
                                ? l10n.editorPause
                                : l10n.editorPlay,
                            onPressed: controller.togglePlay,
                            icon: AppIcon(
                              isPlaying ? AppIcons.pause : AppIcons.play,
                              size: 13,
                              color: scheme.onSurface,
                            ),
                          ),
                          Expanded(child: ScrubBar(projectId: projectId)),
                          IconButton(
                            tooltip: l10n.editorExitFullscreen,
                            onPressed: close,
                            icon: AppIcon(
                              AppIcons.exitFullscreen,
                              size: 14,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Position, gradient scrub bar and duration. Dragging pauses playback and
/// seeks frame-accurately; playback resumes on release if it was playing.
class ScrubBar extends ConsumerStatefulWidget {
  /// Creates the bar for [projectId].
  const new({required this.projectId, super.key});

  /// The open project.
  final String projectId;

  @override
  ConsumerState<ScrubBar> createState() => _ScrubBarState();
}

class _ScrubBarState extends ConsumerState<ScrubBar> {
  // Ephemeral drag state (AGENTS.md §4 allows local widget state).
  double? _dragUs;
  bool _resumeAfterDrag = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gradient = AccentGradient.of(context);
    final provider = playbackProvider(widget.projectId);
    final duration = ref.watch(provider.select((s) => s.durationUs));
    final position = ref.watch(playbackPositionProvider(widget.projectId));
    final controller = ref.read(provider.notifier);
    final max = duration <= 0 ? 1.0 : duration.toDouble();
    final value = (_dragUs ?? position.toDouble()).clamp(0.0, max);
    final timeStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 10,
      color: theme.colorScheme.outline,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Row(
      children: [
        Text(formatClockUs(value.round()), style: timeStyle),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              trackShape: _GradientTrackShape(gradient),
              inactiveTrackColor: theme.colorScheme.outlineVariant,
              thumbColor: gradient.end,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value,
              max: max,
              semanticFormatterCallback: (v) => formatClockUs(v.round()),
              label: l10n.editorSeek,
              onChangeStart: duration <= 0
                  ? null
                  : (v) {
                      _resumeAfterDrag = ref.read(provider).isPlaying;
                      if (_resumeAfterDrag) {
                        // Fire and forget: the drag must not wait for it.
                        controller.pause().ignore();
                      }
                    },
              onChanged: duration <= 0
                  ? null
                  : (v) {
                      setState(() => _dragUs = v);
                      controller.seekTo(v.round()).ignore();
                    },
              onChangeEnd: (v) {
                setState(() => _dragUs = null);
                if (_resumeAfterDrag) controller.play().ignore();
              },
            ),
          ),
        ),
        Text(formatClockUs(duration), style: timeStyle),
      ],
    );
  }
}

/// A slider track whose played part is the accent gradient.
class _GradientTrackShape extends RoundedRectSliderTrackShape {
  const new(this.gradient);

  final AccentGradient gradient;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final radius = Radius.circular(rect.height / 2);
    context.canvas
      ..drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = sliderTheme.inactiveTrackColor ?? Colors.grey,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(rect.left, rect.top, thumbCenter.dx, rect.bottom),
          radius,
        ),
        Paint()
          ..shader = LinearGradient(colors: [gradient.start, gradient.end])
              .createShader(rect),
      );
  }
}
