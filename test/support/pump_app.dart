import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:master_pro/app/master_pro_app.dart';
import 'package:master_pro/core/settings/theme_mode_controller.dart';
import 'package:master_pro/core/time/clock_providers.dart';
import 'package:master_pro/core/time/deadline_clock.dart';
import 'package:master_pro/features/activities/domain/activity.dart';
import 'package:master_pro/features/activities/presentation/activities_providers.dart';
import 'package:master_pro/features/auth/presentation/auth_providers.dart';
import 'package:master_pro/features/subjects/domain/period.dart';
import 'package:master_pro/features/subjects/domain/subject.dart';
import 'package:master_pro/features/subjects/presentation/subjects_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'fake_auth_repository.dart';
import 'in_memory_repository.dart';

/// «Ahora» en las pruebas: lunes 16 de noviembre de 2026, 12:00 en Colombia.
final testNow = DateTime.utc(2026, 11, 16, 17);

/// Hora de Colombia, fija, para que las pruebas no dependan de la zona del
/// computador donde corren.
DateTime toBogota(DateTime instant) =>
    tz.TZDateTime.from(instant, tz.getLocation('America/Bogota'));

/// Un teléfono alto, para que los formularios quepan sin desplazar.
void useTallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Lo que la app tiene detrás durante una prueba, para poder inspeccionarlo.
class TestBackend {
  TestBackend({
    FakeAuthRepository? auth,
    List<Subject> subjects = const [],
    List<Period> periods = const [],
    List<Activity> activities = const [],
  }) : auth = auth ?? FakeAuthRepository.signedIn(),
       activities = InMemoryRepository(idOf: (a) => a.id, initial: activities),
       subjects = InMemoryRepository(idOf: (s) => s.id, initial: subjects),
       periods = InMemoryRepository(idOf: (p) => p.id, initial: periods);

  final FakeAuthRepository auth;
  final InMemoryRepository<Subject> subjects;
  final InMemoryRepository<Period> periods;
  final InMemoryRepository<Activity> activities;
  late final SharedPreferences preferences;
}

/// Arranca la app completa con preferencias, sesión y datos en memoria. Por
/// defecto hay una sesión iniciada y no hay datos.
Future<TestBackend> pumpApp(
  WidgetTester tester, {
  Map<String, Object> stored = const {},
  FakeAuthRepository? auth,
  TestBackend? backend,
}) async {
  initializeTimeZones();
  final target = backend ?? TestBackend(auth: auth);
  SharedPreferences.setMockInitialValues(stored);
  target.preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(target.preferences),
        authRepositoryProvider.overrideWithValue(target.auth),
        subjectsRepositoryProvider.overrideWithValue(target.subjects),
        periodsRepositoryProvider.overrideWithValue(target.periods),
        activitiesRepositoryProvider.overrideWithValue(target.activities),
        clockProvider.overrideWithValue(() => testNow),
        toLocalProvider.overrideWithValue(toBogota),
      ],
      child: const MasterProApp(),
    ),
  );
  await tester.pumpAndSettle();
  return target;
}
