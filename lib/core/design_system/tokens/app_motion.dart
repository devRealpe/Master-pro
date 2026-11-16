import 'package:flutter/widgets.dart';

/// Duraciones de animación. Ninguna pantalla define las suyas.
abstract final class AppDurations {
  /// Pulsación de botón, casilla.
  static const instant = Duration(milliseconds: 120);

  /// Cambio de estado, aparición de elementos.
  static const quick = Duration(milliseconds: 220);

  /// Transición de pantalla, expandir y contraer.
  static const smooth = Duration(milliseconds: 360);

  /// Trazado de gráficos, barras y anillos de progreso.
  static const expressive = Duration(milliseconds: 600);

  /// Completar un sprint, alcanzar un objetivo.
  static const celebrate = Duration(milliseconds: 900);

  /// Separación entre elementos que aparecen escalonados.
  static const stagger = Duration(milliseconds: 40);

  /// A partir de este elemento, el resto de la lista entra a la vez.
  static const maxStaggered = 6;
}

abstract final class AppCurves {
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const standard = Curves.easeInOutCubic;
}

abstract final class AppMotion {
  /// Verdadero cuando el sistema pide reducir el movimiento.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// [duration], o cero si el sistema pide reducir el movimiento.
  static Duration duration(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
