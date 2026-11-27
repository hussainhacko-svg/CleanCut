// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Horizontal zoom of a project's timeline.

@ProviderFor(TimelineZoom)
final timelineZoomProvider = TimelineZoomFamily._();

/// Horizontal zoom of a project's timeline.
final class TimelineZoomProvider
    extends $NotifierProvider<TimelineZoom, TimelineScale> {
  /// Horizontal zoom of a project's timeline.
  TimelineZoomProvider._({
    required TimelineZoomFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'timelineZoomProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$timelineZoomHash();

  @override
  String toString() {
    return r'timelineZoomProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TimelineZoom create() => TimelineZoom();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimelineScale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimelineScale>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineZoomProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$timelineZoomHash() => r'ba403cb00851f50e086197c7f8104ccb5b4bba08';

/// Horizontal zoom of a project's timeline.

final class TimelineZoomFamily extends $Family
    with
        $ClassFamilyOverride<
          TimelineZoom,
          TimelineScale,
          TimelineScale,
          TimelineScale,
          String
        > {
  TimelineZoomFamily._()
    : super(
        retry: null,
        name: r'timelineZoomProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Horizontal zoom of a project's timeline.

  TimelineZoomProvider call(String projectId) =>
      TimelineZoomProvider._(argument: projectId, from: this);

  @override
  String toString() => r'timelineZoomProvider';
}

/// Horizontal zoom of a project's timeline.

abstract class _$TimelineZoom extends $Notifier<TimelineScale> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  TimelineScale build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TimelineScale, TimelineScale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TimelineScale, TimelineScale>,
              TimelineScale,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// What is selected on a project's timeline. Drops the selection when its
/// item disappears (delete, undo).

@ProviderFor(TimelineSelectionController)
final timelineSelectionControllerProvider =
    TimelineSelectionControllerFamily._();

/// What is selected on a project's timeline. Drops the selection when its
/// item disappears (delete, undo).
final class TimelineSelectionControllerProvider
    extends $NotifierProvider<TimelineSelectionController, TimelineSelection> {
  /// What is selected on a project's timeline. Drops the selection when its
  /// item disappears (delete, undo).
  TimelineSelectionControllerProvider._({
    required TimelineSelectionControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'timelineSelectionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$timelineSelectionControllerHash();

  @override
  String toString() {
    return r'timelineSelectionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TimelineSelectionController create() => TimelineSelectionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimelineSelection value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimelineSelection>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineSelectionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$timelineSelectionControllerHash() =>
    r'ad072c7a47508ee7f55178106c9ddf4f03cb3ff2';

/// What is selected on a project's timeline. Drops the selection when its
/// item disappears (delete, undo).

final class TimelineSelectionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TimelineSelectionController,
          TimelineSelection,
          TimelineSelection,
          TimelineSelection,
          String
        > {
  TimelineSelectionControllerFamily._()
    : super(
        retry: null,
        name: r'timelineSelectionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What is selected on a project's timeline. Drops the selection when its
  /// item disappears (delete, undo).

  TimelineSelectionControllerProvider call(String projectId) =>
      TimelineSelectionControllerProvider._(argument: projectId, from: this);

  @override
  String toString() => r'timelineSelectionControllerProvider';
}

/// What is selected on a project's timeline. Drops the selection when its
/// item disappears (delete, undo).

abstract class _$TimelineSelectionController
    extends $Notifier<TimelineSelection> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  TimelineSelection build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TimelineSelection, TimelineSelection>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TimelineSelection, TimelineSelection>,
              TimelineSelection,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The tool panel open in a project's editor, if any. Closes whenever the
/// selection changes, since every panel edits the selected clip.

@ProviderFor(OpenToolPanel)
final openToolPanelProvider = OpenToolPanelFamily._();

/// The tool panel open in a project's editor, if any. Closes whenever the
/// selection changes, since every panel edits the selected clip.
final class OpenToolPanelProvider
    extends $NotifierProvider<OpenToolPanel, ToolPanelKind?> {
  /// The tool panel open in a project's editor, if any. Closes whenever the
  /// selection changes, since every panel edits the selected clip.
  OpenToolPanelProvider._({
    required OpenToolPanelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'openToolPanelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$openToolPanelHash();

  @override
  String toString() {
    return r'openToolPanelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OpenToolPanel create() => OpenToolPanel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToolPanelKind? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToolPanelKind?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OpenToolPanelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$openToolPanelHash() => r'559f20834036961eb0c0648996e60ac8118fb238';

/// The tool panel open in a project's editor, if any. Closes whenever the
/// selection changes, since every panel edits the selected clip.

final class OpenToolPanelFamily extends $Family
    with
        $ClassFamilyOverride<
          OpenToolPanel,
          ToolPanelKind?,
          ToolPanelKind?,
          ToolPanelKind?,
          String
        > {
  OpenToolPanelFamily._()
    : super(
        retry: null,
        name: r'openToolPanelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The tool panel open in a project's editor, if any. Closes whenever the
  /// selection changes, since every panel edits the selected clip.

  OpenToolPanelProvider call(String projectId) =>
      OpenToolPanelProvider._(argument: projectId, from: this);

  @override
  String toString() => r'openToolPanelProvider';
}

/// The tool panel open in a project's editor, if any. Closes whenever the
/// selection changes, since every panel edits the selected clip.

abstract class _$OpenToolPanel extends $Notifier<ToolPanelKind?> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  ToolPanelKind? build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ToolPanelKind?, ToolPanelKind?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ToolPanelKind?, ToolPanelKind?>,
              ToolPanelKind?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Whether a project's preview is open full screen. The editor's own
/// preview tweaks (e.g. the uncropped clip under the crop handles) pause
/// while it is, so full screen always shows the real result.

@ProviderFor(PreviewFullscreen)
final previewFullscreenProvider = PreviewFullscreenFamily._();

/// Whether a project's preview is open full screen. The editor's own
/// preview tweaks (e.g. the uncropped clip under the crop handles) pause
/// while it is, so full screen always shows the real result.
final class PreviewFullscreenProvider
    extends $NotifierProvider<PreviewFullscreen, bool> {
  /// Whether a project's preview is open full screen. The editor's own
  /// preview tweaks (e.g. the uncropped clip under the crop handles) pause
  /// while it is, so full screen always shows the real result.
  PreviewFullscreenProvider._({
    required PreviewFullscreenFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'previewFullscreenProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$previewFullscreenHash();

  @override
  String toString() {
    return r'previewFullscreenProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PreviewFullscreen create() => PreviewFullscreen();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PreviewFullscreenProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$previewFullscreenHash() => r'3655c7a967dfc5112c1a1cca7d3b890f8198e74c';

/// Whether a project's preview is open full screen. The editor's own
/// preview tweaks (e.g. the uncropped clip under the crop handles) pause
/// while it is, so full screen always shows the real result.

final class PreviewFullscreenFamily extends $Family
    with $ClassFamilyOverride<PreviewFullscreen, bool, bool, bool, String> {
  PreviewFullscreenFamily._()
    : super(
        retry: null,
        name: r'previewFullscreenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether a project's preview is open full screen. The editor's own
  /// preview tweaks (e.g. the uncropped clip under the crop handles) pause
  /// while it is, so full screen always shows the real result.

  PreviewFullscreenProvider call(String projectId) =>
      PreviewFullscreenProvider._(argument: projectId, from: this);

  @override
  String toString() => r'previewFullscreenProvider';
}

/// Whether a project's preview is open full screen. The editor's own
/// preview tweaks (e.g. the uncropped clip under the crop handles) pause
/// while it is, so full screen always shows the real result.

abstract class _$PreviewFullscreen extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  bool build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Audio peaks of [uri] for an audio lane (null when it has no audio).

@ProviderFor(clipWaveform)
final clipWaveformProvider = ClipWaveformFamily._();

/// Audio peaks of [uri] for an audio lane (null when it has no audio).

final class ClipWaveformProvider
    extends
        $FunctionalProvider<
          AsyncValue<WaveformData?>,
          WaveformData?,
          FutureOr<WaveformData?>
        >
    with $FutureModifier<WaveformData?>, $FutureProvider<WaveformData?> {
  /// Audio peaks of [uri] for an audio lane (null when it has no audio).
  ClipWaveformProvider._({
    required ClipWaveformFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clipWaveformProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clipWaveformHash();

  @override
  String toString() {
    return r'clipWaveformProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WaveformData?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WaveformData?> create(Ref ref) {
    final argument = this.argument as String;
    return clipWaveform(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClipWaveformProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clipWaveformHash() => r'3513bafc7ba9a6ed9dbd55fff99c45929f71e112';

/// Audio peaks of [uri] for an audio lane (null when it has no audio).

final class ClipWaveformFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WaveformData?>, String> {
  ClipWaveformFamily._()
    : super(
        retry: null,
        name: r'clipWaveformProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Audio peaks of [uri] for an audio lane (null when it has no audio).

  ClipWaveformProvider call(String uri) =>
      ClipWaveformProvider._(argument: uri, from: this);

  @override
  String toString() => r'clipWaveformProvider';
}

/// Cached LUT-graded preview JPEG paths for every bundled [FilterPreset] on a
/// frame of [uri] at [timeUs].

@ProviderFor(clipFilterPreviews)
final clipFilterPreviewsProvider = ClipFilterPreviewsFamily._();

/// Cached LUT-graded preview JPEG paths for every bundled [FilterPreset] on a
/// frame of [uri] at [timeUs].

final class ClipFilterPreviewsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String?>>,
          Map<String, String?>,
          FutureOr<Map<String, String?>>
        >
    with
        $FutureModifier<Map<String, String?>>,
        $FutureProvider<Map<String, String?>> {
  /// Cached LUT-graded preview JPEG paths for every bundled [FilterPreset] on a
  /// frame of [uri] at [timeUs].
  ClipFilterPreviewsProvider._({
    required ClipFilterPreviewsFamily super.from,
    required (String, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'clipFilterPreviewsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clipFilterPreviewsHash();

  @override
  String toString() {
    return r'clipFilterPreviewsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, String?>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, String?>> create(Ref ref) {
    final argument = this.argument as (String, int, int);
    return clipFilterPreviews(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is ClipFilterPreviewsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clipFilterPreviewsHash() =>
    r'aa163ad3918304051aa211520991834e8db87fe0';

/// Cached LUT-graded preview JPEG paths for every bundled [FilterPreset] on a
/// frame of [uri] at [timeUs].

final class ClipFilterPreviewsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<String, String?>>,
          (String, int, int)
        > {
  ClipFilterPreviewsFamily._()
    : super(
        retry: null,
        name: r'clipFilterPreviewsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Cached LUT-graded preview JPEG paths for every bundled [FilterPreset] on a
  /// frame of [uri] at [timeUs].

  ClipFilterPreviewsProvider call(String uri, int timeUs, int heightPx) =>
      ClipFilterPreviewsProvider._(
        argument: (uri, timeUs, heightPx),
        from: this,
      );

  @override
  String toString() => r'clipFilterPreviewsProvider';
}
