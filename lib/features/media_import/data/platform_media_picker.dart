import 'package:cleancut/features/media_import/data/media_picker_api.g.dart';
import 'package:cleancut/features/media_import/domain/media_picker.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';

/// [MediaPicker] backed by the native Android Photo Picker.
final class PlatformMediaPicker implements MediaPicker {
  /// Creates the picker; pass [api] to stub the platform in tests.
  new({MediaPickerHostApi? api}) : _api = api ?? MediaPickerHostApi();

  final MediaPickerHostApi _api;
  Future<List<MediaRef>>? _open;

  /// A second call while the picker is still open (e.g. a double tap)
  /// gets the same result instead of failing natively.
  @override
  Future<List<MediaRef>> pickVisualMedia({bool allowMultiple = true}) =>
      _open ??= _pick(allowMultiple).whenComplete(() => _open = null);

  Future<List<MediaRef>> _pick(bool allowMultiple) async {
    final picked = await _api.pickVisualMedia(allowMultiple: allowMultiple);
    return [for (final p in picked) toMediaRef(p)];
  }

  /// Converts a platform result into the model type.
  static MediaRef toMediaRef(PickedMedia picked) => MediaRef(
    uri: picked.uri,
    kind: switch (picked.kind) {
      PickedMediaKind.video => MediaKind.video,
      PickedMediaKind.image => MediaKind.image,
    },
    durationUs: picked.durationUs,
    width: picked.width,
    height: picked.height,
    rotationDegrees: picked.rotationDegrees,
    displayName: picked.displayName,
  );
}
