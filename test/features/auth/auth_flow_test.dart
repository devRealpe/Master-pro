import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:master_pro/app/router/app_router.dart';
import 'package:master_pro/app/shell/app_shell.dart';
import 'package:master_pro/features/auth/domain/auth_failure.dart';
import 'package:master_pro/features/auth/domain/auth_user.dart';
import 'package:master_pro/features/auth/presentation/sign_in_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/pump_app.dart';

void main() {
  group('Acceso', () {
    testWidgets('sin sesión solo se ve la pantalla de acceso', (tester) async {
      await pumpApp(tester, auth: FakeAuthRepository());

      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('al iniciar sesión entra a Inicio', (tester) async {
      final auth = FakeAuthRepository();
      await pumpApp(tester, auth: auth);

      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();

      expect(auth.signInCalls, 1);
      expect(find.byType(SignInPage), findsNothing);
      expect(find.text('Tu centro académico'), findsOneWidget);
    });

    testWidgets('mientras entra, el botón no admite otro toque', (
      tester,
    ) async {
      final auth = FakeAuthRepository()..gate = Completer<void>();
      await pumpApp(tester, auth: auth);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();

      expect(auth.signInCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      auth.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('un fallo se explica y permite reintentar', (tester) async {
      final auth = FakeAuthRepository()..failure = AuthFailure.network;
      await pumpApp(tester, auth: auth);

      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();

      expect(find.text(AuthFailure.network.message), findsOneWidget);
      expect(find.byType(SignInPage), findsOneWidget);

      auth.failure = null;
      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('cancelar no muestra ningún error', (tester) async {
      final auth = FakeAuthRepository()..failure = AuthFailure.cancelled;
      await pumpApp(tester, auth: auth);

      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
      for (final failure in AuthFailure.values) {
        if (failure.message.isEmpty) continue;
        expect(find.text(failure.message), findsNothing);
      }
    });
  });

  group('Cerrar sesión', () {
    Future<void> openSignOutDialog(WidgetTester tester) async {
      await tester.tap(find.text('Mi espacio'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('ana@example.com'), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    }

    testWidgets('pide confirmación y vuelve al acceso', (tester) async {
      await pumpApp(tester);
      await openSignOutDialog(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('cancelar mantiene la sesión', (tester) async {
      await pumpApp(tester);
      await openSignOutDialog(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
    });
  });

  group('redirectForSession', () {
    String? go(
      String location, {
      bool restoring = false,
      bool signedIn = false,
    }) => redirectForSession(
      restoring: restoring,
      signedIn: signedIn,
      location: location,
    );

    test('mientras se restaura la sesión, todo espera en la portada', () {
      expect(go(AppRoutes.home, restoring: true), AppRoutes.splash);
      expect(go(AppRoutes.splash, restoring: true), isNull);
    });

    test('sin sesión, cualquier ruta lleva al acceso', () {
      expect(go(AppRoutes.home), AppRoutes.signIn);
      expect(go(AppRoutes.subjects), AppRoutes.signIn);
      expect(go(AppRoutes.catalog), AppRoutes.signIn);
      expect(go(AppRoutes.splash), AppRoutes.signIn);
      expect(go(AppRoutes.signIn), isNull);
    });

    test('con sesión, el acceso y la portada llevan a Inicio', () {
      expect(go(AppRoutes.signIn, signedIn: true), AppRoutes.home);
      expect(go(AppRoutes.splash, signedIn: true), AppRoutes.home);
      expect(go(AppRoutes.calendar, signedIn: true), isNull);
    });
  });

  group('AuthUser', () {
    test('usa el nombre, y si falta, el correo', () {
      expect(FakeAuthRepository.user.label, 'Ana Pérez');
      expect(
        const AuthUser(
          uid: '1',
          displayName: '  ',
          email: 'ana@example.com',
        ).label,
        'ana@example.com',
      );
      expect(const AuthUser(uid: '1').label, 'Tu cuenta');
    });

    test('saca hasta dos iniciales', () {
      expect(FakeAuthRepository.user.initials, 'AP');
      expect(const AuthUser(uid: '1', displayName: 'Ana').initials, 'A');
      expect(
        const AuthUser(uid: '1', displayName: 'Ana María Pérez Gómez').initials,
        'AM',
      );
      expect(
        const AuthUser(uid: '1', email: 'ana.perez@example.com').initials,
        'AP',
      );
    });
  });
}
