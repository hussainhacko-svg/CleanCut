import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the licenses of bundled assets (fonts) to the app's license page.
void registerAssetLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (package, file) in const [
      ('Manrope', 'assets/fonts/OFL-Manrope.txt'),
      ('JetBrains Mono', 'assets/fonts/OFL-JetBrainsMono.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        package,
      ], await rootBundle.loadString(file));
    }
  });
}
