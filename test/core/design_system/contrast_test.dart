import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_pro/core/design_system/design_system.dart';

/// Contraste WCAG entre dos colores opacos.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

/// Pares texto/fondo que deben cumplir AA para texto normal (4,5:1).
Map<String, (Color, Color)> textPairs(AppColors c) => {
  'ink / canvas': (c.ink, c.canvas),
  'ink / surface': (c.ink, c.surface),
  'ink / surfaceRaised': (c.ink, c.surfaceRaised),
  'inkSoft / canvas': (c.inkSoft, c.canvas),
  'inkSoft / surface': (c.inkSoft, c.surface),
  'inkSoft / surfaceRaised': (c.inkSoft, c.surfaceRaised),
  'inkMuted / canvas': (c.inkMuted, c.canvas),
  'inkMuted / surface': (c.inkMuted, c.surface),
  'inkMuted / surfaceRaised': (c.inkMuted, c.surfaceRaised),
  'primary / canvas': (c.primary, c.canvas),
  'primary / surface': (c.primary, c.surface),
  'onPrimary / primary': (c.onPrimary, c.primary),
  'onPrimaryContainer / primaryContainer': (
    c.onPrimaryContainer,
    c.primaryContainer,
  ),
  'onAccent / accent': (c.onAccent, c.accent),
  'onAccentContainer / accentContainer': (
    c.onAccentContainer,
    c.accentContainer,
  ),
  'onSuccessContainer / successContainer': (
    c.onSuccessContainer,
    c.successContainer,
  ),
  'onWarningContainer / warningContainer': (
    c.onWarningContainer,
    c.warningContainer,
  ),
  'onDanger / danger': (c.onDanger, c.danger),
  'onDangerContainer / dangerContainer': (
    c.onDangerContainer,
    c.dangerContainer,
  ),
  'onInfoContainer / infoContainer': (c.onInfoContainer, c.infoContainer),
  'onGradient / gradientStart': (c.onGradient, c.gradientStart),
  'onGradient / gradientEnd': (c.onGradient, c.gradientEnd),
  'canvas / ink (aviso breve)': (c.canvas, c.ink),
};

/// Colores de iconos, anillos y puntos: AA para elementos gráficos (3:1).
Map<String, (Color, Color)> graphicPairs(AppColors c) => {
  'accent / surface': (c.accent, c.surface),
  'success / surface': (c.success, c.surface),
  'warning / surface': (c.warning, c.surface),
  'danger / surface': (c.danger, c.surface),
  'info / surface': (c.info, c.surface),
  for (var i = 0; i < c.subjects.length; i++)
    'asignatura ${AppColors.subjectNames[i]} / surface': (
      c.subjects[i],
      c.surface,
    ),
};

void main() {
  for (final (name, colors) in [
    ('claro', AppColors.light),
    ('oscuro', AppColors.dark),
  ]) {
    group('Tema $name', () {
      test('los textos cumplen AA (4,5:1)', () {
        textPairs(colors).forEach((pair, value) {
          expect(
            contrast(value.$1, value.$2),
            greaterThanOrEqualTo(4.5),
            reason: pair,
          );
        });
      });

      test('los elementos gráficos cumplen AA (3:1)', () {
        graphicPairs(colors).forEach((pair, value) {
          expect(
            contrast(value.$1, value.$2),
            greaterThanOrEqualTo(3),
            reason: pair,
          );
        });
      });

      test('hay un color por cada nombre de asignatura', () {
        expect(colors.subjects, hasLength(AppColors.subjectNames.length));
      });
    });
  }

  test('lerp interpola entre los dos temas', () {
    final half = AppColors.light.lerp(AppColors.dark, 0.5);
    expect(
      half.canvas,
      Color.lerp(AppColors.light.canvas, AppColors.dark.canvas, 0.5),
    );
    expect(AppColors.light.lerp(AppColors.dark, 1).ink, AppColors.dark.ink);
    expect(half.subjects, hasLength(AppColors.light.subjects.length));
  });
}
