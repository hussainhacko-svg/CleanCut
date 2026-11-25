import 'package:cleancut/app/app.dart';
import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/app/theme/app_theme.dart';
import 'package:cleancut/features/media_import/domain/media_picker.dart';
import 'package:cleancut/features/media_import/presentation/media_picker_provider.dart';
import 'package:cleancut/features/projects/domain/model/media_ref.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:cleancut/features/projects/domain/project_repository.dart';
import 'package:cleancut/features/projects/presentation/project_providers.dart';
import 'package:cleancut/features/settings/domain/app_settings.dart';
import 'package:cleancut/features/settings/presentation/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../features/projects/domain/fixtures.dart';

/// In-memory [ProjectRepository] (real file IO stalls under fake async).
class InMemoryProjectRepository implements ProjectRepository {
  new([Iterable<Project> initial = const []])
    : projects = {for (final p in initial) p.id: p};

  final Map<String, Project> projects;
  DateTime now = testTime;
  int saveCount = 0;

  @override
  Future<List<Project>> loadAll() async =>
      projects.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<Project> load(String id) async =>
      projects[id] ?? (throw ProjectNotFoundException(id));

  @override
  Future<Project> save(Project project) async {
    saveCount++;
    final stored = project.copyWith(updatedAt: now);
    projects[project.id] = stored;
    return stored;
  }

  @override
  Future<void> delete(String id) async => projects.remove(id);
}

class InMemorySettingsRepository implements SettingsRepository {
  AppSettings stored = const AppSettings();

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async => stored = settings;
}

/// Returns [next] once per call; empty list means "cancelled".
class FakeMediaPicker implements MediaPicker {
  List<MediaRef> next = const [];
  int calls = 0;

  @override
  Future<List<MediaRef>> pickVisualMedia({bool allowMultiple = true}) async {
    calls++;
    return next;
  }
}

/// Test doubles wired into a [ProviderScope].
class TestEnv {
  new({Iterable<Project> projects = const []})
    : repo = InMemoryProjectRepository(projects);

  final InMemoryProjectRepository repo;
  final settings = InMemorySettingsRepository();
  final picker = FakeMediaPicker();
  final String Function() ids = sequentialIds('new');

  List<Override> get overrides => [
    projectRepositoryProvider.overrideWith((ref) async => repo),
    settingsRepositoryProvider.overrideWith((ref) async => settings),
    mediaPickerProvider.overrideWithValue(picker),
    idGeneratorProvider.overrideWithValue(ids),
    clockProvider.overrideWithValue(() => testTime),
  ];

  /// Pumps the whole app and lets the project list load.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const CleanCutApp()),
    );
    await tester.pumpAndSettle();
  }
}

/// A [MaterialApp] with the app's localizations and dark theme, for
/// widget tests of single components.
Widget localizedApp(Widget home) => MaterialApp(
  theme: AppTheme.dark(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);
