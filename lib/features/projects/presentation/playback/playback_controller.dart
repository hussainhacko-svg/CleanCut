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

  /// The preview's texture id once known; events of other previews (e.g.
  /// one still closing during a route transition) are ignored.
  int? _id;
  CompositionSpec? _loadedSpec;
  int? _pendingSeekUs;
  Future<void>? _seekLoop;

  @override
  PlaybackState build(String projectId) {
    _engine = ref.watch(mediaEngineProvider);
    final subs = [
      _engine.states.listen((e) {
        if (e.textureId != _id) return;
        state = state._copyWith(
          status: e.status,
          isPlaying: e.isPlaying,
          durationUs: e.durationUs,
        );
        _setPosition(e.positionUs);
      }),
      _engine.positions.listen((u) {
        if (u.textureId == _id) _setPosition(u.positionUs);
      }),
      _engine.errors.listen((e) {
        if (e.textureId == _id) {
          state = state._copyWith(error: e, isPlaying: false);
        }
      }),
    ];
    _textureId = _engine.createPreview();
    unawaited(
      _textureId.then((id) {
        _id = id;
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

  /// Waits for the preview; false when this controller was disposed in the
  /// meantime (its native preview may already be gone).
  Future<bool> _ready() async {
    await _textureId;
    return ref.mounted;
  }

  /// Loads [project] into the preview. Edits that don't change what the
  /// engine plays (e.g. a rename) don't reload it.
  Future<void> load(Project project) async {
    final spec = compositionSpecOf(project);
    // Checked and recorded before awaiting, so two loads started together
    // can't both send the same composition.
    if (spec == _loadedSpec) return;
    _loadedSpec = spec;
    if (!await _ready()) return;
    state = state._copyWith(clearError: true);
    await _engine.setComposition(spec);
  }

  /// Plays, or pauses while playing.
  Future<void> togglePlay() async {
    if (!await _ready()) return;
    await _seekLoop;
    if (!ref.mounted) return;
    await (state.isPlaying ? _engine.pause() : _engine.play());
  }

  /// Starts playback, after any seek still in flight has been sent.
  Future<void> play() async {
    if (!await _ready()) return;
    await _seekLoop;
    if (ref.mounted) await _engine.play();
  }

  /// Pauses playback.
  Future<void> pause() async {
    if (await _ready()) await _engine.pause();
  }

  void _setPosition(int positionUs) =>
      ref.read(playbackPositionProvider(projectId).notifier).set(positionUs);

  /// Seeks to [positionUs] and shows that frame.
  ///
  /// While a seek is in flight only the latest target is kept, so a fast
  /// scrub never queues up stale seeks.
  Future<void> seekTo(int positionUs) {
    final clamped = positionUs.clamp(0, state.durationUs);
    _setPosition(clamped);
    _pendingSeekUs = clamped;
    return _seekLoop ??= _runSeeks().whenComplete(() => _seekLoop = null);
  }

  Future<void> _runSeeks() async {
    if (!await _ready()) return;
    for (var target = _pendingSeekUs; target != null; target = _pendingSeekUs) {
      _pendingSeekUs = null;
      if (!ref.mounted) return;
      await _engine.seekTo(target);
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
