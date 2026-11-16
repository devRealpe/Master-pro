import 'dart:async';

import 'package:master_pro/features/auth/domain/auth_failure.dart';
import 'package:master_pro/features/auth/domain/auth_repository.dart';
import 'package:master_pro/features/auth/domain/auth_user.dart';

/// Sesión en memoria para las pruebas. Los datos son ficticios.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? signedInAs}) : _current = signedInAs;

  FakeAuthRepository.signedIn() : _current = user;

  static const user = AuthUser(
    uid: 'usuario-de-prueba',
    displayName: 'Ana Pérez',
    email: 'ana@example.com',
  );

  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _current;

  /// Si se asigna, el siguiente inicio de sesión falla con este motivo.
  AuthFailure? failure;

  /// Si se asigna, el inicio de sesión espera a que se complete.
  Completer<void>? gate;

  int signInCalls = 0;

  void _emit(AuthUser? value) {
    _current = value;
    _changes.add(value);
  }

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _current;
    yield* _changes.stream;
  }

  @override
  Future<void> signInWithGoogle() async {
    signInCalls++;
    await gate?.future;
    final failure = this.failure;
    if (failure != null) throw failure;
    _emit(user);
  }

  @override
  Future<void> signOut() async => _emit(null);
}
