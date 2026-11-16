import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/catalog/catalog_page.dart';
import '../../features/calendar/presentation/calendar_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/plan/presentation/plan_page.dart';
import '../../features/subjects/presentation/subjects_page.dart';
import '../../features/workspace/presentation/workspace_page.dart';
import '../shell/app_shell.dart';

/// Rutas de la aplicación.
abstract final class AppRoutes {
  static const home = '/inicio';
  static const plan = '/plan';
  static const calendar = '/calendario';
  static const subjects = '/asignaturas';
  static const workspace = '/mi-espacio';

  /// Solo existe en modo desarrollo.
  static const catalog = '/catalogo';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      // Cada pestaña es una rama con su propio historial, que se conserva al
      // cambiar a otra.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.plan,
                builder: (_, _) => const PlanPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                builder: (_, _) => const CalendarPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.subjects,
                builder: (_, _) => const SubjectsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.workspace,
                builder: (_, _) => const WorkspacePage(),
              ),
            ],
          ),
        ],
      ),
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.catalog,
          builder: (_, _) => const CatalogPage(),
        ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
