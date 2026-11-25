import 'package:cleancut/features/media_import/data/platform_media_picker.dart';
import 'package:cleancut/features/media_import/domain/media_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_picker_provider.g.dart';

/// The device media picker. Override with a fake in tests.
@Riverpod(keepAlive: true)
MediaPicker mediaPicker(Ref ref) => PlatformMediaPicker();
