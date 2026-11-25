// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_directories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's private documents directory (projects, settings).
///
/// Override in tests with a temporary directory.

@ProviderFor(appDocumentsDirectory)
final appDocumentsDirectoryProvider = AppDocumentsDirectoryProvider._();

/// The app's private documents directory (projects, settings).
///
/// Override in tests with a temporary directory.

final class AppDocumentsDirectoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<Directory>,
          Directory,
          FutureOr<Directory>
        >
    with $FutureModifier<Directory>, $FutureProvider<Directory> {
  /// The app's private documents directory (projects, settings).
  ///
  /// Override in tests with a temporary directory.
  AppDocumentsDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDocumentsDirectoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDocumentsDirectoryHash();

  @$internal
  @override
  $FutureProviderElement<Directory> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Directory> create(Ref ref) {
    return appDocumentsDirectory(ref);
  }
}

String _$appDocumentsDirectoryHash() =>
    r'b297512b0545f61b58d7f5d9b67b9af84dc2723c';
