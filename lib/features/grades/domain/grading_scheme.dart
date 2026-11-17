/// Reglas de evaluación de una asignatura.
///
/// Los valores por omisión son los de UNIR, confirmados por el estudiante:
/// notas de 0 a 10; una actividad aporta `valor × nota / 10`; cada clase
/// asistida da 0,4 puntos y cada test 0,1; la meta son 5 puntos de evaluación
/// continua, que aseguran el 40 %; el 60 % restante es el examen.
///
/// Lo que **no** está confirmado es cómo se convierten esos puntos y la nota
/// del examen en la nota final de 0 a 10. Por eso el motor calcula puntos y
/// no una nota final.
class GradingScheme {
  const GradingScheme({
    this.scaleMax = 10,
    this.pointsGoal = 5,
    this.attendancePoints = 0.4,
    this.testPoints = 0.1,
    this.continuousWeight = 40,
    this.examWeight = 60,
    this.confirmed = false,
  });

  /// Plantilla de UNIR.
  static const unir = GradingScheme();

  /// Nota máxima de la escala de calificación.
  final double scaleMax;

  /// Puntos de evaluación continua que quieres reunir.
  final double pointsGoal;

  /// Puntos que da cada clase en vivo a la que asistes.
  final double attendancePoints;

  /// Puntos que da cada test hecho.
  final double testPoints;

  /// Peso de la evaluación continua en la nota final, en porcentaje.
  final double continuousWeight;

  /// Peso del examen en la nota final, en porcentaje.
  final double examWeight;

  /// Verdadero cuando validaste estas reglas con la guía docente.
  final bool confirmed;

  GradingScheme copyWith({
    double? scaleMax,
    double? pointsGoal,
    double? attendancePoints,
    double? testPoints,
    double? continuousWeight,
    double? examWeight,
    bool? confirmed,
  }) => GradingScheme(
    scaleMax: scaleMax ?? this.scaleMax,
    pointsGoal: pointsGoal ?? this.pointsGoal,
    attendancePoints: attendancePoints ?? this.attendancePoints,
    testPoints: testPoints ?? this.testPoints,
    continuousWeight: continuousWeight ?? this.continuousWeight,
    examWeight: examWeight ?? this.examWeight,
    confirmed: confirmed ?? this.confirmed,
  );

  @override
  bool operator ==(Object other) =>
      other is GradingScheme &&
      other.scaleMax == scaleMax &&
      other.pointsGoal == pointsGoal &&
      other.attendancePoints == attendancePoints &&
      other.testPoints == testPoints &&
      other.continuousWeight == continuousWeight &&
      other.examWeight == examWeight &&
      other.confirmed == confirmed;

  @override
  int get hashCode => Object.hash(
    scaleMax,
    pointsGoal,
    attendancePoints,
    testPoints,
    continuousWeight,
    examWeight,
    confirmed,
  );
}

/// Validaciones de los campos de calificación. Devuelven el mensaje de error
/// o `null`.
abstract final class GradingRules {
  /// Nota máxima de la escala: mayor que 0 y razonable.
  static String? scale(double? value) =>
      value == null || value <= 0 || value > 100
      ? 'Escribe un número mayor que 0'
      : null;

  /// Puntos (meta, valor de una actividad, de una clase): 0 o más.
  static String? points(double? value) =>
      value == null || value < 0 || value > 1000
      ? 'Escribe un número, por ejemplo 0,4'
      : null;

  static String? weights(double? continuous, double? exam) {
    if (continuous == null || exam == null || continuous < 0 || exam < 0) {
      return 'Escribe los dos porcentajes';
    }
    if ((continuous + exam - 100).abs() > 0.001) {
      return 'Los dos porcentajes deben sumar 100';
    }
    return null;
  }

  /// Nota obtenida: entre 0 y la máxima de la escala.
  static String? score(double? value, GradingScheme scheme) {
    if (value == null || value < 0 || value > scheme.scaleMax) {
      final max = scheme.scaleMax == scheme.scaleMax.roundToDouble()
          ? scheme.scaleMax.toStringAsFixed(0)
          : scheme.scaleMax.toString().replaceAll('.', ',');
      return 'Debe estar entre 0 y $max';
    }
    return null;
  }
}
