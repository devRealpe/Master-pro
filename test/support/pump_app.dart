import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_pro/app/master_pro_app.dart';
import 'package:master_pro/core/settings/theme_mode_controller.dart';
import 'package:master_pro/features/auth/presentation/auth_providers.dart';
import 'package:master_pro/features/subjects/domain/period.dart';
import 'package:master_pro/features/subjects/domain/subject.dart';
import 'package:master_pro/features/subjects/presentation/subjects_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'in_memory_repository.dart';

/// Lo que la app tiene detrás durante una prueba, para poder inspeccionarlo.
class TestBackend {
  TestBackend({
    FakeAuthRepository? auth,
    List<Subject> subjects = const [],
    List<Period> periods = const [],
  }) : auth = auth ?? FakeAuthRepository.signedIn(),
       subjects = InMemoryRepository(idOf: (s) => s.id, initial: subjects),
       periods = InMemoryRepository(idOf: (p) => p.id, initial: periods);

  final FakeAuthRepository auth;
  final InMemoryRepository<Subject> subjects;
  final InMemoryRepository<Period> periods;
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
      ],
      child: const MasterProApp(),
    ),
  );
  await tester.pumpAndSettle();
  return target;
}
