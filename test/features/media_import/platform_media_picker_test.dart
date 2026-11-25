import 'package:cleancut/features/media_import/data/media_picker_api.g.dart';
import 'package:cleancut/features/media_import/data/platform_media_picker.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements MediaPickerHostApi;

void main() {
  test('maps picked files to MediaRefs in order', () async {
    final api = _MockApi();
    when(() => api.pickVisualMedia(allowMultiple: true)).thenAnswer(
      (_) async => [
        PickedMedia(
          uri: 'content://v',
          kind: PickedMediaKind.video,
          durationUs: 2000000,
          width: 1920,
          height: 1080,
          rotationDegrees: 90,
          displayName: 'a.mp4',
        ),
        PickedMedia(
          uri: 'content://i',
          kind: PickedMediaKind.image,
          width: 800,
          height: 600,
          rotationDegrees: 0,
        ),
      ],
    );

    final media = await PlatformMediaPicker(api: api).pickVisualMedia();

    expect(media, const [
      MediaRef(
        uri: 'content://v',
        kind: MediaKind.video,
        durationUs: 2000000,
        width: 1920,
        height: 1080,
        rotationDegrees: 90,
        displayName: 'a.mp4',
      ),
      MediaRef(
        uri: 'content://i',
        kind: MediaKind.image,
        width: 800,
        height: 600,
      ),
    ]);
  });

  test('cancel returns an empty list', () async {
    final api = _MockApi();
    when(() => api.pickVisualMedia(allowMultiple: false))
        .thenAnswer((_) async => []);
    expect(
      await PlatformMediaPicker(api: api).pickVisualMedia(allowMultiple: false),
      isEmpty,
    );
  });
}
