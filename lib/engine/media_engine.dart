import 'dart:async';

import 'package:cleancut/engine/engine_api.g.dart';

export 'package:cleancut/engine/engine_api.g.dart'
    show
        BackgroundSpec,
        ClipSpec,
        ClipStyleSpec,
        ColorAdjustmentsSpec,
        CompositionSpec,
        PlaybackStatus,
        PlayerStateEvent,
        SpecBackgroundKind,
        SpecFitMode,
        SpecMediaKind,
        SpeedStepSpec,
        TransformSampleSpec,
        WaveformData;

/// A playback position, tagged with the texture id of its preview.
typedef PositionUpdate = ({int textureId, int positionUs});

/// A playback error reported by the native engine.
final class EngineError {
  /// Creates an error of preview [textureId] with a Media3 error [code] and
  /// a [message].
  const new(this.textureId, this.code, this.message);

  /// The preview that failed.
  final int textureId;

  /// Media3 error code name, e.g. `ERROR_CODE_IO_FILE_NOT_FOUND`.
  final String code;

  /// Human-readable detail (not localized; for logs).
  final String message;

  @override
  String toString() => 'EngineError($textureId, $code, $message)';
}

/// The native media engine: one preview player plus thumbnail and waveform
/// extraction. Pixels come only from here (AGENTS.md §3).
abstract interface class MediaEngine {
  /// Player status changes (tagged with their preview's texture id).
  Stream<PlayerStateEvent> get states;

  /// Playback positions, about 30 times a second while playing.
  Stream<PositionUpdate> get positions;

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

  /// Renders cached JPEG preview thumbnails of [uri] at [timeUs] ([heightPx]
  /// tall) for each bundled LUT in [filterIds].
  Future<Map<String, String?>> filterPreviews(
    String uri,
    int timeUs, {
    required int heightPx,
    required List<String> filterIds,
  });
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
  final _positions = StreamController<PositionUpdate>.broadcast(sync: true);
  final _errors = StreamController<EngineError>.broadcast(sync: true);

  @override
  Stream<PlayerStateEvent> get states => _states.stream;

  @override
  Stream<PositionUpdate> get positions => _positions.stream;

  @override
  Stream<EngineError> get errors => _errors.stream;

  @override
  void onPlayerState(PlayerStateEvent state) => _states.add(state);

  @override
  void onPosition(int textureId, int positionUs) =>
      _positions.add((textureId: textureId, positionUs: positionUs));

  @override
  void onError(int textureId, String code, String message) =>
      _errors.add(EngineError(textureId, code, message));

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

  @override
  Future<Map<String, String?>> filterPreviews(
    String uri,
    int timeUs, {
    required int heightPx,
    required List<String> filterIds,
  }) => _api.filterPreviews(uri, timeUs, heightPx, filterIds);

  /// Stops receiving native events.
  void dispose() {
    EngineFlutterApi.setUp(null);
    unawaited(_states.close());
    unawaited(_positions.close());
    unawaited(_errors.close());
  }
}
