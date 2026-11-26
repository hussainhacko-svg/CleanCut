import 'package:cleancut/app/app.dart';
import 'package:cleancut/app/licenses.dart';
import 'package:cleancut/features/media_import/data/platform_media_picker.dart';
import 'package:cleancut/features/projects/presentation/project_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  registerAssetLicenses();
  runApp(
    ProviderScope(
      // The composition root wires platform implementations into features.
      overrides: [mediaPickerProvider.overrideWithValue(PlatformMediaPicker())],
      child: const CleanCutApp(),
    ),
  );
}
