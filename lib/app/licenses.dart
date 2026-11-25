import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the licenses of bundled assets (fonts) to the app's license page.
void registerAssetLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (package, file) in const [
      ('Plus Jakarta Sans', 'assets/fonts/OFL-PlusJakartaSans.txt'),
      ('Bebas Neue', 'assets/fonts/OFL-BebasNeue.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        package,
      ], await rootBundle.loadString(file));
    }
  });
}
