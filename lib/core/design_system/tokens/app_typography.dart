import 'package:material_ui/material_ui.dart';

/// Jerarquía tipográfica de Master Pro, toda en Inter.
///
/// | Rol         | Estilo de Material |
/// |-------------|--------------------|
/// | Display     | displaySmall       |
/// | Título 1    | headlineMedium     |
/// | Título 2    | headlineSmall, titleLarge |
/// | Título 3    | titleMedium        |
/// | Cuerpo L    | bodyLarge          |
/// | Cuerpo      | bodyMedium         |
/// | Etiqueta    | labelLarge, titleSmall |
/// | Detalle     | bodySmall, labelMedium |
/// | Sobretítulo | labelSmall         |
abstract final class AppTypography {
  static const fontFamily = 'Inter';

  /// Cifras de ancho fijo, para que los números no se muevan al animarse.
  static const tabular = [FontFeature.tabularFigures()];

  static TextStyle _style(
    double size,
    double lineHeight,
    FontWeight weight, {
    double spacing = 0,
    required Color color,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    letterSpacing: spacing,
    color: color,
  );

  static TextTheme textTheme({required Color ink, required Color inkSoft}) {
    final display = _style(40, 44, FontWeight.w700, spacing: -1, color: ink);
    final title1 = _style(28, 34, FontWeight.w700, spacing: -0.5, color: ink);
    final title2 = _style(22, 28, FontWeight.w600, spacing: -0.3, color: ink);
    final title3 = _style(18, 24, FontWeight.w600, spacing: -0.2, color: ink);
    final label = _style(14, 20, FontWeight.w600, color: ink);
    final detail = _style(12, 16, FontWeight.w500, color: inkSoft);

    return TextTheme(
      displayLarge: display,
      displayMedium: display,
      displaySmall: display,
      headlineLarge: title1,
      headlineMedium: title1,
      headlineSmall: title2,
      titleLarge: title2,
      titleMedium: title3,
      titleSmall: label,
      bodyLarge: _style(16, 24, FontWeight.w400, color: ink),
      bodyMedium: _style(14, 20, FontWeight.w400, color: ink),
      bodySmall: detail,
      labelLarge: label,
      labelMedium: detail.copyWith(fontWeight: FontWeight.w600),
      labelSmall: _style(11, 14, FontWeight.w600, spacing: 0.6, color: inkSoft),
    );
  }
}

extension AppTextContext on BuildContext {
  /// Estilos de texto del tema activo.
  TextTheme get text => Theme.of(this).textTheme;
}
