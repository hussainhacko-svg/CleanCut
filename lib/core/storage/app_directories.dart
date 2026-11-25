import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_directories.g.dart';

/// The app's private documents directory (projects, settings).
///
/// Override in tests with a temporary directory.
@Riverpod(keepAlive: true)
Future<Directory> appDocumentsDirectory(Ref ref) =>
    getApplicationDocumentsDirectory();

/// Joins [parts] onto [base] with the platform separator.
String joinPath(Directory base, List<String> parts) =>
    [base.path, ...parts].join(Platform.pathSeparator);
