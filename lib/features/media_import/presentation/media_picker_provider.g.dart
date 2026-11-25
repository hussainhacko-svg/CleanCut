// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_picker_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The device media picker. Override with a fake in tests.

@ProviderFor(mediaPicker)
final mediaPickerProvider = MediaPickerProvider._();

/// The device media picker. Override with a fake in tests.

final class MediaPickerProvider
    extends $FunctionalProvider<MediaPicker, MediaPicker, MediaPicker>
    with $Provider<MediaPicker> {
  /// The device media picker. Override with a fake in tests.
  MediaPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaPickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaPickerHash();

  @$internal
  @override
  $ProviderElement<MediaPicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaPicker create(Ref ref) {
    return mediaPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaPicker>(value),
    );
  }
}

String _$mediaPickerHash() => r'bfe761c42f897ed65912a9f8e1ed9dd47a777fd8';
