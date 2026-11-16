import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_pro/app/master_pro_app.dart';
import 'package:master_pro/core/settings/theme_mode_controller.dart';
import 'package:master_pro/features/auth/presentation/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';

/// Arranca la app completa con preferencias y sesión en memoria. Por defecto
/// hay una sesión iniciada.
Future<SharedPreferences> pumpApp(
  WidgetTester tester, {
  Map<String, Object> stored = const {},
  FakeAuthRepository? auth,
}) async {
  SharedPreferences.setMockInitialValues(stored);
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(
          auth ?? FakeAuthRepository.signedIn(),
        ),
      ],
      child: const MasterProApp(),
    ),
  );
  await tester.pumpAndSettle();
  return preferences;
}
