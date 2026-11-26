import 'dart:async';

import 'package:cleancut/engine/engine_api.g.dart';

export 'package:cleancut/engine/engine_api.g.dart'
    show
        ClipSpec,
        CompositionSpec,
        PlaybackStatus,
        PlayerStateEvent,
        SpecMediaKind,
        WaveformData;

/// A playback error reported by the native engine.
final class EngineError {
  /// Creates an error with a Media3 error [code] and a [message].
  const new(this.code, this.message);

  /// Media3 error code name, e.g. `ERROR_CODE_IO_FILE_NOT_FOUND`.
  final String code;

  /// Human-readable detail (not localized; for logs).
  final String message;

  @override
  String toString() => 'EngineError($code, $message)';
}

/// The native media engine: one preview player plus thumbnail and waveform
/// extraction. Pixels come only from here (AGENTS.md §3).
abstract interface class MediaEngine {
  /// Player status changes.
  Stream<PlayerStateEvent> get states;

  /// Playback position in microseconds, about 30 times a second while
  /// playing.
  Stream<int> get positions;

  /// Playback errors.
  Stream<EngineError> get errors;

  /// Creates the preview player; returns its Flutter texture id.
  Future<int> createPreview();

  /// Replaces what the preview plays.
  Future<void> setComposition(CompositionSpec spec);

  /// Starts playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Seeks exactly to [positionUs].
  Future<void> seekTo(int positionUs);

  /// Releases the preview with [textureId] if it is still the current one.
  Future<void> disposePreview(int textureId);

  /// Frames of [uri] at [timesUs], [heightPx] tall, as cached JPEG paths
  /// (null where a frame could not be read).
  Future<List<String?>> thumbnails(
    String uri,
    List<int> timesUs, {
    required int heightPx,
  });

  /// Audio peaks of [uri]; null when it has no audio.
  Future<WaveformData?> waveform(String uri, {int peaksPerSecond = 50});
}

/// [MediaEngine] backed by the Kotlin engine over Pigeon.
final class PlatformMediaEngine implements MediaEngine, EngineFlutterApi {
  /// Creates the engine and starts receiving native events. Pass [api] to
  /// stub the platform in tests.
  new({EngineHostApi? api}) : _api = api ?? EngineHostApi() {
    EngineFlutterApi.setUp(this);
  }

  final EngineHostApi _api;
  final _states = StreamController<PlayerStateEvent>.broadcast(sync: true);
  final _positions = StreamController<int>.broadcast(sync: true);
  final _errors = StreamController<EngineError>.broadcast(sync: true);

  @override
  Stream<PlayerStateEvent> get states => _states.stream;

  @override
  Stream<int> get positions => _positions.stream;

  @override
  Stream<EngineError> get errors => _errors.stream;

  @override
  void onPlayerState(PlayerStateEvent state) => _states.add(state);

  @override
  void onPosition(int positionUs) => _positions.add(positionUs);

  @override
  void onError(String code, String message) =>
      _errors.add(EngineError(code, message));

  @override
  Future<int> createPreview() => _api.createPreview();

  @override
  Future<void> setComposition(CompositionSpec spec) =>
      _api.setComposition(spec);

  @override
  Future<void> play() => _api.play();

  @override
  Future<void> pause() => _api.pause();

  @override
  Future<void> seekTo(int positionUs) => _api.seekTo(positionUs);

  @override
  Future<void> disposePreview(int textureId) => _api.disposePreview(textureId);

  @override
  Future<List<String?>> thumbnails(
    String uri,
    List<int> timesUs, {
    required int heightPx,
  }) => _api.thumbnails(uri, timesUs, heightPx);

  @override
  Future<WaveformData?> waveform(String uri, {int peaksPerSecond = 50}) =>
      _api.waveform(uri, peaksPerSecond);

  /// Stops receiving native events.
  void dispose() {
    EngineFlutterApi.setUp(null);
    unawaited(_states.close());
    unawaited(_positions.close());
    unawaited(_errors.close());
  }
}
