import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'auth_error_mapper.dart';

/// Sesión con Firebase Authentication y cuenta de Google.
///
/// En Android e iOS usa el selector de cuentas del sistema; en la web (solo
/// vista previa de desarrollo), la ventana emergente de Google.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleReady;

  /// Google exige inicializarse una sola vez. Si falla, se reintenta en la
  /// siguiente llamada.
  Future<void> _ensureGoogle() {
    return _googleReady ??= _google.initialize().catchError((Object error) {
      _googleReady = null;
      throw error;
    });
  }

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(
    (user) => user == null
        ? null
        : AuthUser(
            uid: user.uid,
            displayName: user.displayName,
            email: user.email,
          ),
  );

  @override
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(GoogleAuthProvider());
        return;
      }
      await _ensureGoogle();
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw AuthFailure.configuration;
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } catch (error) {
      throw mapAuthError(error);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (kIsWeb) return;
    try {
      // Sin esto, el siguiente inicio de sesión reutilizaría la cuenta sin
      // preguntar.
      await _ensureGoogle();
      await _google.signOut();
    } catch (_) {
      // La sesión de Firebase ya está cerrada, que es lo que importa.
    }
  }
}
