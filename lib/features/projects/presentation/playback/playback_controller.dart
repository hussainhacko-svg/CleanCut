import 'dart:async';

import 'package:cleancut/engine/media_engine.dart';
import 'package:cleancut/features/projects/data/composition_mapper.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'playback_controller.g.dart';

/// The app's native engine (one per app).
@Riverpod(keepAlive: true)
MediaEngine mediaEngine(Ref ref) {
  final engine = PlatformMediaEngine();
  ref.onDispose(engine.dispose);
  return engine;
}

/// Low-frequency preview state; the position lives in
/// [PlaybackPosition] so playing does not rebuild the editor.
@immutable
final class PlaybackState {
  /// Creates a state.
  const new({
    this.textureId,
    this.status = PlaybackStatus.idle,
    this.isPlaying = false,
    this.durationUs = 0,
    this.error,
  });

  /// Texture showing the preview; null until the player exists.
  final int? textureId;

  /// Player status.
  final PlaybackStatus status;

  /// Whether the preview is playing.
  final bool isPlaying;

  /// Length of what is loaded, in microseconds.
  final int durationUs;

  /// Last playback error, cleared when a new composition loads.
  final EngineError? error;

  PlaybackState _copyWith({
    int? textureId,
    PlaybackStatus? status,
    bool? isPlaying,
    int? durationUs,
    EngineError? error,
    bool clearError = false,
  }) => PlaybackState(
    textureId: textureId ?? this.textureId,
    status: status ?? this.status,
    isPlaying: isPlaying ?? this.isPlaying,
    durationUs: durationUs ?? this.durationUs,
    error: clearError ? null : error ?? this.error,
  );
}

/// Drives the preview player of one open project.
@riverpod
class Playback extends _$Playback {
  late MediaEngine _engine;
  late Future<int> _textureId;
  int? _pendingSeekUs;
  bool _seeking = false;

  @override
  PlaybackState build(String projectId) {
    _engine = ref.watch(mediaEngineProvider);
    final subs = [
      _engine.states.listen((e) {
        state = state._copyWith(
          status: e.status,
          isPlaying: e.isPlaying,
          durationUs: e.durationUs,
        );
        _setPosition(e.positionUs);
      }),
      _engine.positions.listen(_setPosition),
      _engine.errors.listen(
        (e) => state = state._copyWith(error: e, isPlaying: false),
      ),
    ];
    _textureId = _engine.createPreview();
    unawaited(
      _textureId.then((id) {
        if (ref.mounted) state = state._copyWith(textureId: id);
      }),
    );
    ref.onDispose(() {
      for (final s in subs) {
        unawaited(s.cancel());
      }
      unawaited(_textureId.then(_engine.disposePreview));
    });
    return const PlaybackState();
  }

  /// Loads [project] into the preview (call again after every edit).
  Future<void> load(Project project) async {
    await _textureId;
    if (!ref.mounted) return;
    state = state._copyWith(clearError: true);
    await _engine.setComposition(compositionSpecOf(project));
  }

  /// Plays, or pauses while playing.
  Future<void> togglePlay() async {
    await _textureId;
    await (state.isPlaying ? _engine.pause() : _engine.play());
  }

  /// Starts playback.
  Future<void> play() async {
    await _textureId;
    await _engine.play();
  }

  /// Pauses playback.
  Future<void> pause() async {
    await _textureId;
    await _engine.pause();
  }

  void _setPosition(int positionUs) =>
      ref.read(playbackPositionProvider(projectId).notifier).set(positionUs);

  /// Seeks to [positionUs] and shows that frame.
  ///
  /// While a seek is in flight only the latest target is kept, so a fast
  /// scrub never queues up stale seeks.
  Future<void> seekTo(int positionUs) async {
    final clamped = positionUs.clamp(0, state.durationUs);
    _setPosition(clamped);
    _pendingSeekUs = clamped;
    if (_seeking) return;
    _seeking = true;
    try {
      await _textureId;
      for (
        var target = _pendingSeekUs;
        target != null;
        target = _pendingSeekUs
      ) {
        _pendingSeekUs = null;
        await _engine.seekTo(target);
      }
    } finally {
      _seeking = false;
    }
  }
}

/// Current playback position in microseconds (updates ~30 Hz while
/// playing). Watch it only from small widgets.
@riverpod
class PlaybackPosition extends _$PlaybackPosition {
  @override
  int build(String projectId) => 0;

  /// Updates the position.
  // A method (not a setter) so it can be passed as a stream listener.
  // ignore: use_setters_to_change_properties
  void set(int positionUs) => state = positionUs;
}

/// A cached JPEG of the frame of [uri] at [timeUs], [heightPx] tall; null
/// when the frame can't be read.
@riverpod
Future<String?> clipThumbnail(
  Ref ref,
  String uri,
  int timeUs,
  int heightPx,
) async {
  final paths = await ref.watch(mediaEngineProvider).thumbnails(uri, [
    timeUs,
  ], heightPx: heightPx);
  return paths.firstOrNull;
}
