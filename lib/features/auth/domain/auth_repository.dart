import 'auth_failure.dart';
import 'auth_user.dart';

/// Acceso a la sesión. La app solo conoce esta interfaz; Firebase queda
/// detrás de ella.
abstract interface class AuthRepository {
  /// Emite la persona con sesión iniciada, o `null` si no hay sesión.
  /// El primer valor llega al restaurar la sesión guardada en el dispositivo.
  Stream<AuthUser?> authStateChanges();

  /// Inicia sesión con Google. Lanza un [AuthFailure] si no termina.
  Future<void> signInWithGoogle();

  Future<void> signOut();
}
