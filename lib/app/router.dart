import 'package:cleancut/features/projects/presentation/home_screen.dart';
import 'package:cleancut/features/projects/presentation/project_screen.dart';
import 'package:cleancut/features/settings/presentation/settings_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// Route paths.
abstract final class AppRoutes {
  /// Project list.
  static const home = '/';

  /// App settings.
  static const settings = '/settings';

  /// Editor for the project with [id].
  static String editor(String id) => '/projects/${Uri.encodeComponent(id)}';
}

/// The app router.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(
          projectRoute: AppRoutes.editor,
          settingsRoute: AppRoutes.settings,
        ),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'projects/:id',
            builder: (context, state) =>
                ProjectScreen(projectId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
