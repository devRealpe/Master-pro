import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_repository.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

/// Sesión actual: cargando mientras se restaura, y después la persona o
/// `null`.
final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Estado del botón de acceso: en reposo, en curso o con un [AuthFailure].
class SignInController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Al entrar, la pantalla de acceso desaparece y este estado con ella.
      if (ref.mounted) state = const AsyncData(null);
    } on AuthFailure catch (failure, stack) {
      if (!ref.mounted) return;
      state = failure == AuthFailure.cancelled
          ? const AsyncData(null)
          : AsyncError(failure, stack);
    }
  }
}

final signInControllerProvider =
    NotifierProvider.autoDispose<SignInController, AsyncValue<void>>(
      SignInController.new,
    );
