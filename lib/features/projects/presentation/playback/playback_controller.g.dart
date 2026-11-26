// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's native engine (one per app).

@ProviderFor(mediaEngine)
final mediaEngineProvider = MediaEngineProvider._();

/// The app's native engine (one per app).

final class MediaEngineProvider
    extends $FunctionalProvider<MediaEngine, MediaEngine, MediaEngine>
    with $Provider<MediaEngine> {
  /// The app's native engine (one per app).
  MediaEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaEngineHash();

  @$internal
  @override
  $ProviderElement<MediaEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaEngine create(Ref ref) {
    return mediaEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaEngine>(value),
    );
  }
}

String _$mediaEngineHash() => r'54881979b603a516f8648da7c73ecc9de35f43f0';

/// Drives the preview player of one open project.

@ProviderFor(Playback)
final playbackProvider = PlaybackFamily._();

/// Drives the preview player of one open project.
final class PlaybackProvider
    extends $NotifierProvider<Playback, PlaybackState> {
  /// Drives the preview player of one open project.
  PlaybackProvider._({
    required PlaybackFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playbackProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playbackHash();

  @override
  String toString() {
    return r'playbackProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Playback create() => Playback();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaybackState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaybackState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlaybackProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playbackHash() => r'158599faff77aa59526ca02152c8c01d02b99bb3';

/// Drives the preview player of one open project.

final class PlaybackFamily extends $Family
    with
        $ClassFamilyOverride<
          Playback,
          PlaybackState,
          PlaybackState,
          PlaybackState,
          String
        > {
  PlaybackFamily._()
    : super(
        retry: null,
        name: r'playbackProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Drives the preview player of one open project.

  PlaybackProvider call(String projectId) =>
      PlaybackProvider._(argument: projectId, from: this);

  @override
  String toString() => r'playbackProvider';
}

/// Drives the preview player of one open project.

abstract class _$Playback extends $Notifier<PlaybackState> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  PlaybackState build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlaybackState, PlaybackState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlaybackState, PlaybackState>,
              PlaybackState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Current playback position in microseconds (updates ~30 Hz while
/// playing). Watch it only from small widgets.

@ProviderFor(PlaybackPosition)
final playbackPositionProvider = PlaybackPositionFamily._();

/// Current playback position in microseconds (updates ~30 Hz while
/// playing). Watch it only from small widgets.
final class PlaybackPositionProvider
    extends $NotifierProvider<PlaybackPosition, int> {
  /// Current playback position in microseconds (updates ~30 Hz while
  /// playing). Watch it only from small widgets.
  PlaybackPositionProvider._({
    required PlaybackPositionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playbackPositionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playbackPositionHash();

  @override
  String toString() {
    return r'playbackPositionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlaybackPosition create() => PlaybackPosition();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlaybackPositionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playbackPositionHash() => r'36ef932b06151975fd46f10f6cd378a914913bba';

/// Current playback position in microseconds (updates ~30 Hz while
/// playing). Watch it only from small widgets.

final class PlaybackPositionFamily extends $Family
    with $ClassFamilyOverride<PlaybackPosition, int, int, int, String> {
  PlaybackPositionFamily._()
    : super(
        retry: null,
        name: r'playbackPositionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Current playback position in microseconds (updates ~30 Hz while
  /// playing). Watch it only from small widgets.

  PlaybackPositionProvider call(String projectId) =>
      PlaybackPositionProvider._(argument: projectId, from: this);

  @override
  String toString() => r'playbackPositionProvider';
}

/// Current playback position in microseconds (updates ~30 Hz while
/// playing). Watch it only from small widgets.

abstract class _$PlaybackPosition extends $Notifier<int> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  int build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// A cached JPEG of the frame of [uri] at [timeUs], [heightPx] tall; null
/// when the frame can't be read.

@ProviderFor(clipThumbnail)
final clipThumbnailProvider = ClipThumbnailFamily._();

/// A cached JPEG of the frame of [uri] at [timeUs], [heightPx] tall; null
/// when the frame can't be read.

final class ClipThumbnailProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// A cached JPEG of the frame of [uri] at [timeUs], [heightPx] tall; null
  /// when the frame can't be read.
  ClipThumbnailProvider._({
    required ClipThumbnailFamily super.from,
    required (String, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'clipThumbnailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clipThumbnailHash();

  @override
  String toString() {
    return r'clipThumbnailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as (String, int, int);
    return clipThumbnail(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is ClipThumbnailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clipThumbnailHash() => r'd2872fa9333e11573606a22a2a5117c4040a90e1';

/// A cached JPEG of the frame of [uri] at [timeUs], [heightPx] tall; null
/// when the frame can't be read.

final class ClipThumbnailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, (String, int, int)> {
  ClipThumbnailFamily._()
    : super(
        retry: null,
        name: r'clipThumbnailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A cached JPEG of the frame of [uri] at [timeUs], [heightPx] tall; null
  /// when the frame can't be read.

  ClipThumbnailProvider call(String uri, int timeUs, int heightPx) =>
      ClipThumbnailProvider._(argument: (uri, timeUs, heightPx), from: this);

  @override
  String toString() => r'clipThumbnailProvider';
}

/// Batched frame cache for timeline thumbnail strips, keyed by timestamp (µs).
///
/// Call [ensure] with all timestamps currently needed by a clip's strip;
/// missing frames are fetched in a single native `thumbnails` call (one
/// `MediaMetadataRetriever` per batch instead of one per tile).

@ProviderFor(ClipThumbnails)
final clipThumbnailsProvider = ClipThumbnailsFamily._();

/// Batched frame cache for timeline thumbnail strips, keyed by timestamp (µs).
///
/// Call [ensure] with all timestamps currently needed by a clip's strip;
/// missing frames are fetched in a single native `thumbnails` call (one
/// `MediaMetadataRetriever` per batch instead of one per tile).
final class ClipThumbnailsProvider
    extends $NotifierProvider<ClipThumbnails, Map<int, String?>> {
  /// Batched frame cache for timeline thumbnail strips, keyed by timestamp (µs).
  ///
  /// Call [ensure] with all timestamps currently needed by a clip's strip;
  /// missing frames are fetched in a single native `thumbnails` call (one
  /// `MediaMetadataRetriever` per batch instead of one per tile).
  ClipThumbnailsProvider._({
    required ClipThumbnailsFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'clipThumbnailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clipThumbnailsHash();

  @override
  String toString() {
    return r'clipThumbnailsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ClipThumbnails create() => ClipThumbnails();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, String?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<int, String?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClipThumbnailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clipThumbnailsHash() => r'f3b114a9a81b24389b27b1ce2000f9e30e672177';

/// Batched frame cache for timeline thumbnail strips, keyed by timestamp (µs).
///
/// Call [ensure] with all timestamps currently needed by a clip's strip;
/// missing frames are fetched in a single native `thumbnails` call (one
/// `MediaMetadataRetriever` per batch instead of one per tile).

final class ClipThumbnailsFamily extends $Family
    with
        $ClassFamilyOverride<
          ClipThumbnails,
          Map<int, String?>,
          Map<int, String?>,
          Map<int, String?>,
          (String, int)
        > {
  ClipThumbnailsFamily._()
    : super(
        retry: null,
        name: r'clipThumbnailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Batched frame cache for timeline thumbnail strips, keyed by timestamp (µs).
  ///
  /// Call [ensure] with all timestamps currently needed by a clip's strip;
  /// missing frames are fetched in a single native `thumbnails` call (one
  /// `MediaMetadataRetriever` per batch instead of one per tile).

  ClipThumbnailsProvider call(String uri, int heightPx) =>
      ClipThumbnailsProvider._(argument: (uri, heightPx), from: this);

  @override
  String toString() => r'clipThumbnailsProvider';
}

/// Batched frame cache for timeline thumbnail strips, keyed by timestamp (µs).
///
/// Call [ensure] with all timestamps currently needed by a clip's strip;
/// missing frames are fetched in a single native `thumbnails` call (one
/// `MediaMetadataRetriever` per batch instead of one per tile).

abstract class _$ClipThumbnails extends $Notifier<Map<int, String?>> {
  late final _$args = ref.$arg as (String, int);
  String get uri => _$args.$1;
  int get heightPx => _$args.$2;

  Map<int, String?> build(String uri, int heightPx);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<int, String?>, Map<int, String?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<int, String?>, Map<int, String?>>,
              Map<int, String?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
