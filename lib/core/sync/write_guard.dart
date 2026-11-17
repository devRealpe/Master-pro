import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Llave del mensajero de avisos de la app, para avisar desde fuera de una
/// pantalla (por ejemplo, cuando la pantalla que originó el cambio ya cerró).
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Lanza una escritura sin esperarla y avisa si el servidor la rechaza.
///
/// Sin conexión la escritura no falla: queda en cola y este aviso no aparece.
/// Solo se muestra ante un rechazo real, como un permiso denegado.
void guardWrite(Future<void> write) {
  unawaited(
    write.catchError((Object _) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el cambio. Vuelve a intentarlo.'),
        ),
      );
    }),
  );
}
