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
  int? _knownDurationUs;
  Future<void>? _loadFuture;
  Object? _loadToken;
  int _loadsInFlight = 0;
  int? _pendingSeekUs;
  Future<void>? _seekLoop;

  @override
  PlaybackState build(String projectId) {
    _engine = ref.watch(mediaEngineProvider);
    final subs = [
      _engine.states.listen((e) {
        if (e.textureId != _id) return;
        if (_loadsInFlight == 0) _knownDurationUs = e.durationUs;
        state = state._copyWith(
          status: e.status,
          isPlaying: e.isPlaying,
          durationUs: e.durationUs,
        );
        _setPosition(_withinDuration(e.positionUs));
      }),
      _engine.positions.listen((u) {
        if (u.textureId == _id) _setPosition(_withinDuration(u.positionUs));
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
  ///
  /// When [uncroppedClipId] is set (while the Crop panel is open), that clip
  /// renders uncropped and fitted so the on-preview crop handles can reach the
  /// whole frame.
  Future<void> load(Project project, {String? uncroppedClipId}) {
    final spec = compositionSpecOf(project, uncroppedClipId: uncroppedClipId);
    // Checked and recorded before awaiting, so two loads started together
    // can't both send the same composition.
    if (spec == _loadedSpec) return _loadFuture ?? Future<void>.value();
    _loadedSpec = spec;
    _knownDurationUs = project.durationUs;
    final token = Object();
    _loadToken = token;
    return _loadFuture = _runLoad(spec, token);
  }

  Future<void> _runLoad(CompositionSpec spec, Object token) async {
    _loadsInFlight++;
    try {
      if (!await _ready()) {
        if (_loadedSpec == spec) _loadedSpec = null;
        return;
      }
      // A newer load arrived while waiting for the preview; let it win.
      if (_loadedSpec != spec) return;
      state = state._copyWith(clearError: true);
      await _engine.setComposition(spec);
    } on Object {
      if (_loadedSpec == spec) _loadedSpec = null;
      rethrow;
    } finally {
      _loadsInFlight--;
      if (identical(_loadToken, token)) _loadFuture = null;
    }
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

  /// [positionUs] capped at the edit's length: Media3 keeps advancing its
  /// clock for a few hundred ms after the last frame, and the playhead must
  /// not run past the timeline.
  int _withinDuration(int positionUs) {
    final maxUs = _knownDurationUs ?? state.durationUs;
    return maxUs > 0 && positionUs > maxUs ? maxUs : positionUs;
  }

  void _setPosition(int positionUs) =>
      ref.read(playbackPositionProvider(projectId).notifier).set(positionUs);

  /// Seeks to [positionUs] and shows that frame.
  ///
  /// While a seek is in flight only the latest target is kept, so a fast
  /// scrub never queues up stale seeks.
  Future<void> seekTo(int positionUs) {
    final maxUs = _knownDurationUs ?? state.durationUs;
    final clamped = positionUs.clamp(0, maxUs);
    _setPosition(clamped);
    _pendingSeekUs = clamped;
    return _seekLoop ??= _runSeeks().whenComplete(() => _seekLoop = null);
  }

  Future<void> _runSeeks() async {
    if (!await _ready()) return;
    while (_pendingSeekUs != null) {
      final load = _loadFuture;
      if (load != null) {
        try {
          await load;
        } on Object {
          // A failed load belongs to its own caller.
        }
      }
      final target = _pendingSeekUs;
      if (target == null || !ref.mounted) return;
      _pendingSeekUs = null;
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

/// Batched frame cache for timeline thumbnail strips, keyed by timestamp (µs).
///
/// Call [ensure] with all timestamps currently needed by a clip's strip;
/// missing frames are fetched in a single native `thumbnails` call (one
/// `MediaMetadataRetriever` per batch instead of one per tile).
@riverpod
class ClipThumbnails extends _$ClipThumbnails {
  final Set<int> _inFlight = {};

  @override
  Map<int, String?> build(String uri, int heightPx) => const {};

  /// Fetches any timestamps in [timesUs] not yet cached or in flight.
  Future<void> ensure(Iterable<int> timesUs) async {
    final missing = <int>[];
    for (final t in timesUs) {
      if (!state.containsKey(t) && _inFlight.add(t)) {
        missing.add(t);
      }
    }
    if (missing.isEmpty) return;
    final engine = ref.read(mediaEngineProvider);
    try {
      List<String?> paths;
      try {
        paths = await engine.thumbnails(uri, missing, heightPx: heightPx);
      } on Object {
        // E.g. the media's permission was revoked. Cache the frames as
        // missing so scrolling doesn't retry the failing call; callers don't
        // await ensure(), so a rethrow would be an unhandled error.
        paths = const [];
      }
      if (!ref.mounted) return;
      final updated = Map<int, String?>.of(state);
      for (var i = 0; i < missing.length; i++) {
        updated[missing[i]] = i < paths.length ? paths[i] : null;
      }
      state = updated;
    } finally {
      _inFlight.removeAll(missing);
    }
  }
}
