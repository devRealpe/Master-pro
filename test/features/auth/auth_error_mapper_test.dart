import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:master_pro/features/auth/data/auth_error_mapper.dart';
import 'package:master_pro/features/auth/domain/auth_failure.dart';

void main() {
  AuthFailure firebase(String code) =>
      mapAuthError(FirebaseAuthException(code: code));
  AuthFailure google(GoogleSignInExceptionCode code) =>
      mapAuthError(GoogleSignInException(code: code));

  test('cerrar la ventana o el selector es una cancelación', () {
    expect(firebase('popup-closed-by-user'), AuthFailure.cancelled);
    expect(firebase('cancelled-popup-request'), AuthFailure.cancelled);
    expect(google(GoogleSignInExceptionCode.canceled), AuthFailure.cancelled);
  });

  test('ventana emergente bloqueada por el navegador', () {
    expect(firebase('popup-blocked'), AuthFailure.popupBlocked);
  });

  test('sin red', () {
    expect(firebase('network-request-failed'), AuthFailure.network);
  });

  test('registro desactivado o cuenta deshabilitada: sin acceso', () {
    expect(firebase('admin-restricted-operation'), AuthFailure.notAllowed);
    expect(firebase('user-disabled'), AuthFailure.notAllowed);
  });

  test('proveedor sin activar o cliente mal configurado', () {
    expect(firebase('operation-not-allowed'), AuthFailure.configuration);
    expect(
      google(GoogleSignInExceptionCode.clientConfigurationError),
      AuthFailure.configuration,
    );
    expect(
      google(GoogleSignInExceptionCode.providerConfigurationError),
      AuthFailure.configuration,
    );
  });

  test('lo desconocido no se disfraza de otra cosa', () {
    expect(firebase('too-many-requests'), AuthFailure.unknown);
    expect(google(GoogleSignInExceptionCode.interrupted), AuthFailure.unknown);
    expect(mapAuthError(StateError('otro')), AuthFailure.unknown);
  });

  test('un AuthFailure pasa tal cual', () {
    expect(mapAuthError(AuthFailure.network), AuthFailure.network);
  });

  test('todo fallo visible tiene un mensaje', () {
    for (final failure in AuthFailure.values) {
      expect(
        failure.message.isEmpty,
        failure == AuthFailure.cancelled,
        reason: failure.name,
      );
    }
  });
}
