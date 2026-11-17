import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/catalog/catalog_page.dart';
import '../../features/activities/presentation/activity_detail_page.dart';
import '../../features/activities/presentation/activity_form_page.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/sign_in_page.dart';
import '../../features/calendar/presentation/calendar_page.dart';
import '../../features/grades/presentation/simulator_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/plan/presentation/plan_page.dart';
import '../../features/subjects/presentation/periods_page.dart';
import '../../features/subjects/presentation/subject_detail_page.dart';
import '../../features/subjects/presentation/subject_form_page.dart';
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

  // Pantallas completas, por encima de las pestañas.
  static const newActivity = '/actividad/nueva';
  static String newActivityFor(String subjectId) =>
      '/actividad/nueva?asignatura=$subjectId';
  static String activity(String id) => '/actividad/$id';
  static String editActivity(String id) => '/actividad/$id/editar';
  static const newSubject = '/asignatura/nueva';
  static const periods = '/periodos';
  static String subject(String id) => '/asignatura/$id';
  static String editSubject(String id) => '/asignatura/$id/editar';
  static String simulator(String subjectId) =>
      '/asignatura/$subjectId/simulador';

  /// Mientras se restaura la sesión guardada.
  static const splash = '/abriendo';
  static const signIn = '/acceso';

  /// Solo existe en modo desarrollo.
  static const catalog = '/catalogo';
}

/// Decide a dónde va una navegación según la sesión: sin sesión, todo lleva
/// al acceso; con sesión, el acceso lleva a Inicio. Devuelve `null` cuando la
/// ruta pedida es válida.
String? redirectForSession({
  required bool restoring,
  required bool signedIn,
  required String location,
}) {
  if (restoring) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  if (!signedIn) {
    return location == AppRoutes.signIn ? null : AppRoutes.signIn;
  }
  if (location == AppRoutes.signIn || location == AppRoutes.splash) {
    return AppRoutes.home;
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // El router vuelve a evaluar la redirección cada vez que cambia la sesión.
  final sessionChanges = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => sessionChanges.value++);
  ref.onDispose(sessionChanges.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: sessionChanges,
    redirect: (context, state) {
      final session = ref.read(authStateProvider);
      return redirectForSession(
        restoring: session.isLoading && !session.hasValue,
        signedIn: session.value != null,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInPage()),
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
      GoRoute(
        path: AppRoutes.newActivity,
        builder: (_, state) => ActivityFormPage(
          subjectId: state.uri.queryParameters['asignatura'],
        ),
      ),
      GoRoute(
        path: '/actividad/:id',
        builder: (_, state) =>
            ActivityDetailPage(activityId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'editar',
            builder: (_, state) =>
                ActivityFormPage(activityId: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.newSubject,
        builder: (_, _) => const SubjectFormPage(),
      ),
      GoRoute(path: AppRoutes.periods, builder: (_, _) => const PeriodsPage()),
      GoRoute(
        path: '/asignatura/:id',
        builder: (_, state) =>
            SubjectDetailPage(subjectId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'editar',
            builder: (_, state) =>
                SubjectFormPage(subjectId: state.pathParameters['id']),
          ),
          GoRoute(
            path: 'simulador',
            builder: (_, state) =>
                SimulatorPage(subjectId: state.pathParameters['id']!),
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
