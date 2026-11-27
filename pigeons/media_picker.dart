// Pigeon definition for the native media picker.
// Regenerate: fvm dart run pigeon --input pigeons/media_picker.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/features/media_import/data/media_picker_api.g.dart',
    dartPackageName: 'cleancut',
    kotlinOut: 'android/app/src/main/kotlin/com/hussainhacko/cleancut/media/MediaPickerApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.hussainhacko.cleancut.media'),
  ),
)
/// Kind of a picked file.
enum PickedMediaKind { video, image }

/// A file chosen in the system picker. Read permission is persisted.
class PickedMedia {
  PickedMedia({
    required this.uri,
    required this.kind,
    required this.width,
    required this.height,
    required this.rotationDegrees,
    this.durationUs,
    this.displayName,
  });

  /// Content URI.
  final String uri;
  final PickedMediaKind kind;

  /// Length in microseconds; null for images.
  final int? durationUs;

  /// Encoded size in pixels, before rotation.
  final int width;
  final int height;

  /// Clockwise display rotation: 0, 90, 180 or 270.
  final int rotationDegrees;
  final String? displayName;
}

@HostApi()
abstract class MediaPickerHostApi {
  /// Opens the system photo picker for videos and images.
  ///
  /// Returns the picked files in selection order; empty when cancelled.
  /// Files whose metadata cannot be read are left out.
  @async
  List<PickedMedia> pickVisualMedia({required bool allowMultiple});

  /// Opens the system photo picker for a single image (e.g. canvas background).
  ///
  /// Returns the picked image, or null when cancelled or unreadable.
  @async
  PickedMedia? pickImage();
}
