import 'package:cleancut/features/projects/domain/model/media_ref.dart';

/// Lets the user choose media from the device.
abstract interface class MediaPicker {
  /// Opens the picker for videos and images.
  ///
  /// Returns the chosen media in selection order, or an empty list when
  /// the user cancels. Read access to each URI is persisted.
  Future<List<MediaRef>> pickVisualMedia({bool allowMultiple = true});
}
