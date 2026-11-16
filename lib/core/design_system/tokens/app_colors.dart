import 'package:material_ui/material_ui.dart';

/// Tonos semánticos que usan etiquetas, avisos y estados.
enum AppTone { neutral, primary, accent, success, warning, danger, info }

/// Colores resueltos de un [AppTone]: fondo suave, texto sobre ese fondo y
/// color sólido para iconos o rellenos.
typedef ToneColors = ({Color background, Color foreground, Color solid});

/// Paleta de Master Pro. Cada tema (claro y oscuro) tiene su propio diseño;
/// el oscuro no es el claro invertido.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.outline,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.gradientStart,
    required this.gradientEnd,
    required this.onGradient,
    required this.subjects,
  });

  final Brightness brightness;

  /// Fondo de la aplicación.
  final Color canvas;

  /// Tarjetas y hojas.
  final Color surface;

  /// Campos de formulario y tarjetas anidadas.
  final Color surfaceRaised;

  /// Bordes y divisores.
  final Color outline;

  /// Texto principal.
  final Color ink;

  /// Texto secundario.
  final Color inkSoft;

  /// Metadatos y textos de apoyo.
  final Color inkMuted;

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;

  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color onAccentContainer;

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color onDangerContainer;

  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Degradado de marca. Solo para la tarjeta principal, los anillos de
  /// progreso y la pantalla de acceso.
  final Color gradientStart;
  final Color gradientEnd;
  final Color onGradient;

  /// Ocho colores para distinguir asignaturas, en el orden de [subjectNames].
  final List<Color> subjects;

  static const subjectNames = [
    'Índigo',
    'Violeta',
    'Cian',
    'Esmeralda',
    'Ámbar',
    'Coral',
    'Rosa',
    'Pizarra',
  ];

  static const light = AppColors(
    brightness: Brightness.light,
    canvas: Color(0xFFF6F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEEF0F7),
    outline: Color(0xFFE1E4EE),
    ink: Color(0xFF0F1429),
    inkSoft: Color(0xFF4A5170),
    inkMuted: Color(0xFF626A8A),
    primary: Color(0xFF3347D6),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE3E7FF),
    onPrimaryContainer: Color(0xFF1B2A8F),
    accent: Color(0xFF7A4FE0),
    onAccent: Color(0xFFFFFFFF),
    accentContainer: Color(0xFFEEE6FF),
    onAccentContainer: Color(0xFF4A2A9E),
    success: Color(0xFF1E9E6A),
    successContainer: Color(0xFFDDF5EA),
    onSuccessContainer: Color(0xFF0E5C3D),
    warning: Color(0xFFC97A06),
    warningContainer: Color(0xFFFCEFD6),
    onWarningContainer: Color(0xFF7A4703),
    danger: Color(0xFFD9364F),
    onDanger: Color(0xFFFFFFFF),
    dangerContainer: Color(0xFFFDE3E7),
    onDangerContainer: Color(0xFF8F1A2E),
    info: Color(0xFF1B8FD6),
    infoContainer: Color(0xFFDDF0FB),
    onInfoContainer: Color(0xFF0B4F7A),
    gradientStart: Color(0xFF2A3BC4),
    gradientEnd: Color(0xFF7A4FE0),
    onGradient: Color(0xFFFFFFFF),
    subjects: [
      Color(0xFF3347D6),
      Color(0xFF7A4FE0),
      Color(0xFF0E8FA8),
      Color(0xFF1E9E6A),
      Color(0xFFC97A06),
      Color(0xFFD9583A),
      Color(0xFFC93B84),
      Color(0xFF56607F),
    ],
  );

  static const dark = AppColors(
    brightness: Brightness.dark,
    canvas: Color(0xFF0B0E1A),
    surface: Color(0xFF131829),
    surfaceRaised: Color(0xFF1A2036),
    outline: Color(0xFF262D47),
    ink: Color(0xFFECEEF8),
    inkSoft: Color(0xFFA9B0CC),
    inkMuted: Color(0xFF858DAE),
    primary: Color(0xFF8C9BFF),
    onPrimary: Color(0xFF0B1033),
    primaryContainer: Color(0xFF232C66),
    onPrimaryContainer: Color(0xFFC9D0FF),
    accent: Color(0xFFB79CFF),
    onAccent: Color(0xFF1E1147),
    accentContainer: Color(0xFF33265F),
    onAccentContainer: Color(0xFFDCCFFF),
    success: Color(0xFF4CD3A0),
    successContainer: Color(0xFF123B2D),
    onSuccessContainer: Color(0xFFA5EBCF),
    warning: Color(0xFFF2B44C),
    warningContainer: Color(0xFF40300F),
    onWarningContainer: Color(0xFFFADDA3),
    danger: Color(0xFFFF7088),
    onDanger: Color(0xFF3B0A14),
    dangerContainer: Color(0xFF4A1722),
    onDangerContainer: Color(0xFFFFC2CC),
    info: Color(0xFF5CBBF5),
    infoContainer: Color(0xFF10354C),
    onInfoContainer: Color(0xFFBCE3FB),
    gradientStart: Color(0xFF2F3EC0),
    gradientEnd: Color(0xFF7347D6),
    onGradient: Color(0xFFFFFFFF),
    subjects: [
      Color(0xFF8C9BFF),
      Color(0xFFB79CFF),
      Color(0xFF56CDE3),
      Color(0xFF4CD3A0),
      Color(0xFFF2B44C),
      Color(0xFFFF9478),
      Color(0xFFF58CC0),
      Color(0xFFA3ADCC),
    ],
  );

  bool get isDark => brightness == Brightness.dark;

  LinearGradient get brandGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  ToneColors tone(AppTone tone) => switch (tone) {
    AppTone.neutral => (
      background: surfaceRaised,
      foreground: inkSoft,
      solid: inkMuted,
    ),
    AppTone.primary => (
      background: primaryContainer,
      foreground: onPrimaryContainer,
      solid: primary,
    ),
    AppTone.accent => (
      background: accentContainer,
      foreground: onAccentContainer,
      solid: accent,
    ),
    AppTone.success => (
      background: successContainer,
      foreground: onSuccessContainer,
      solid: success,
    ),
    AppTone.warning => (
      background: warningContainer,
      foreground: onWarningContainer,
      solid: warning,
    ),
    AppTone.danger => (
      background: dangerContainer,
      foreground: onDangerContainer,
      solid: danger,
    ),
    AppTone.info => (
      background: infoContainer,
      foreground: onInfoContainer,
      solid: info,
    ),
  };

  /// Color de la asignatura en la posición [index] de la paleta.
  Color subject(int index) => subjects[index % subjects.length];

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      outline: l(outline, other.outline),
      ink: l(ink, other.ink),
      inkSoft: l(inkSoft, other.inkSoft),
      inkMuted: l(inkMuted, other.inkMuted),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primaryContainer: l(primaryContainer, other.primaryContainer),
      onPrimaryContainer: l(onPrimaryContainer, other.onPrimaryContainer),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentContainer: l(accentContainer, other.accentContainer),
      onAccentContainer: l(onAccentContainer, other.onAccentContainer),
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      warning: l(warning, other.warning),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      danger: l(danger, other.danger),
      onDanger: l(onDanger, other.onDanger),
      dangerContainer: l(dangerContainer, other.dangerContainer),
      onDangerContainer: l(onDangerContainer, other.onDangerContainer),
      info: l(info, other.info),
      infoContainer: l(infoContainer, other.infoContainer),
      onInfoContainer: l(onInfoContainer, other.onInfoContainer),
      gradientStart: l(gradientStart, other.gradientStart),
      gradientEnd: l(gradientEnd, other.gradientEnd),
      onGradient: l(onGradient, other.onGradient),
      subjects: [
        for (var i = 0; i < subjects.length; i++)
          l(subjects[i], other.subjects[i]),
      ],
    );
  }
}

extension AppColorsContext on BuildContext {
  /// Paleta del tema activo.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
