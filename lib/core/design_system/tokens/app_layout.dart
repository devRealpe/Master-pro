import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Espaciado en retícula de 4.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 56;

  /// Margen lateral de pantalla.
  static const double screen = 20;

  /// Lado mínimo de un área táctil.
  static const double touchTarget = 48;
}

abstract final class AppRadii {
  /// Etiquetas.
  static const sm = BorderRadius.all(Radius.circular(8));

  /// Botones y campos.
  static const md = BorderRadius.all(Radius.circular(12));

  /// Tarjetas.
  static const lg = BorderRadius.all(Radius.circular(16));

  /// Hojas inferiores y tarjeta principal.
  static const xl = BorderRadius.all(Radius.circular(24));

  static const pill = BorderRadius.all(Radius.circular(999));
}

/// Elevación. En claro son sombras suaves teñidas de azul; en oscuro no hay
/// sombras: la profundidad la dan el escalón de superficie y el borde.
abstract final class AppShadows {
  static const _tint = Color(0xFF1B2452);

  static List<BoxShadow> rest(BuildContext context) => context.colors.isDark
      ? const []
      : [
          BoxShadow(
            color: _tint.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];

  static List<BoxShadow> raised(BuildContext context) => context.colors.isDark
      ? const []
      : [
          BoxShadow(
            color: _tint.withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ];
}
