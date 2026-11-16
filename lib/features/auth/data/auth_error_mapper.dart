import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_failure.dart';

/// Traduce los errores de Firebase y de Google a un [AuthFailure].
AuthFailure mapAuthError(Object error) {
  if (error is AuthFailure) return error;

  if (error is GoogleSignInException) {
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled => AuthFailure.cancelled,
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        AuthFailure.configuration,
      _ => AuthFailure.unknown,
    };
  }

  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'popup-closed-by-user' ||
      'cancelled-popup-request' ||
      'web-context-cancelled' ||
      'canceled' => AuthFailure.cancelled,
      'network-request-failed' => AuthFailure.network,
      // Registro de cuentas nuevas desactivado, o cuenta deshabilitada.
      'admin-restricted-operation' || 'user-disabled' => AuthFailure.notAllowed,
      // Proveedor de Google sin activar en la consola.
      'operation-not-allowed' ||
      'invalid-credential' => AuthFailure.configuration,
      _ => AuthFailure.unknown,
    };
  }

  return AuthFailure.unknown;
}
