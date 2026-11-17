/// Motivos por los que un inicio de sesión no termina, con el mensaje que ve
/// la persona. [cancelled] no es un error: no muestra nada.
enum AuthFailure implements Exception {
  cancelled(''),
  network('Sin conexión. Revisa tu internet e inténtalo de nuevo.'),
  notAllowed('Esta cuenta no tiene acceso. Master Pro es de uso personal.'),
  configuration('El inicio de sesión con Google todavía no está configurado.'),
  popupBlocked(
    'El navegador bloqueó la ventana de Google. Permite las ventanas '
    'emergentes e inténtalo de nuevo.',
  ),
  unknown('No se pudo iniciar sesión. Inténtalo de nuevo.');

  const AuthFailure(this.message);

  final String message;
}
