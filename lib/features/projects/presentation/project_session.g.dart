// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// An open project: applies [EditCommand]s, undo/redo and autosave.

@ProviderFor(ProjectSession)
final projectSessionProvider = ProjectSessionFamily._();

/// An open project: applies [EditCommand]s, undo/redo and autosave.
final class ProjectSessionProvider
    extends $AsyncNotifierProvider<ProjectSession, SessionState> {
  /// An open project: applies [EditCommand]s, undo/redo and autosave.
  ProjectSessionProvider._({
    required ProjectSessionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'projectSessionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectSessionHash();

  @override
  String toString() {
    return r'projectSessionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProjectSession create() => ProjectSession();

  @override
  bool operator ==(Object other) {
    return other is ProjectSessionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectSessionHash() => r'0c1de3eeb694d265df8475169baa7b1d2ca6bf68';

/// An open project: applies [EditCommand]s, undo/redo and autosave.

final class ProjectSessionFamily extends $Family
    with
        $ClassFamilyOverride<
          ProjectSession,
          AsyncValue<SessionState>,
          SessionState,
          FutureOr<SessionState>,
          String
        > {
  ProjectSessionFamily._()
    : super(
        retry: null,
        name: r'projectSessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// An open project: applies [EditCommand]s, undo/redo and autosave.

  ProjectSessionProvider call(String projectId) =>
      ProjectSessionProvider._(argument: projectId, from: this);

  @override
  String toString() => r'projectSessionProvider';
}

/// An open project: applies [EditCommand]s, undo/redo and autosave.

abstract class _$ProjectSession extends $AsyncNotifier<SessionState> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  FutureOr<SessionState> build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SessionState>, SessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SessionState>, SessionState>,
              AsyncValue<SessionState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
