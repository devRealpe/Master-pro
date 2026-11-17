import '../../../core/format/decimals.dart';
import '../../activities/domain/activity.dart';
import '../../classes/domain/class_session.dart';
import 'grading_scheme.dart';

enum GradeSource {
  activity('Actividades'),
  test('Test'),
  attendance('Asistencia');

  const GradeSource(this.label);

  final String label;
}

/// En qué punto está un elemento que puntúa.
enum GradeState {
  /// Ya sumó sus puntos: actividad calificada, test hecho o clase asistida.
  earned,

  /// Entregada pero sin nota todavía.
  awaitingGrade,

  /// Aún no se ha hecho.
  pending,
}

/// Algo que suma puntos de evaluación continua.
class GradeItem {
  const GradeItem({
    required this.id,
    required this.title,
    required this.source,
    required this.maxPoints,
    required this.points,
    required this.state,
    this.simulated = false,
  });

  final String id;
  final String title;
  final GradeSource source;

  /// Lo máximo que puede aportar.
  final double maxPoints;

  /// Lo que aporta: sus puntos si ya sumó, 0 si no.
  final double points;
  final GradeState state;

  /// Verdadero si [points] sale de una hipótesis del simulador.
  final bool simulated;

  /// Necesita una nota para sumar (las actividades que no son test).
  bool get needsScore => source == GradeSource.activity;
}

/// Situación de la evaluación continua de una asignatura.
class GradeSummary {
  const GradeSummary({required this.scheme, required this.items});

  final GradingScheme scheme;
  final List<GradeItem> items;

  double _sum(Iterable<double> values) =>
      Decimals.round(values.fold(0, (total, value) => total + value));

  /// Puntos acumulados.
  double get earned => _sum(
    items.where((i) => i.state == GradeState.earned).map((i) => i.points),
  );

  double earnedFrom(GradeSource source) => _sum(
    items
        .where((i) => i.state == GradeState.earned && i.source == source)
        .map((i) => i.points),
  );

  /// Máximo que pueden aportar las actividades entregadas y sin calificar.
  double get awaiting => _sum(
    items
        .where((i) => i.state == GradeState.awaitingGrade)
        .map((i) => i.maxPoints),
  );

  /// Máximo que puede aportar lo que aún no se ha hecho.
  double get pending => _sum(
    items.where((i) => i.state == GradeState.pending).map((i) => i.maxPoints),
  );

  /// Lo más que se puede llegar a tener.
  double get maxReachable => Decimals.round(earned + awaiting + pending);

  double get goal => scheme.pointsGoal;

  /// Cuánto falta para la meta. Nunca es negativo.
  double get remainingToGoal {
    final remaining = Decimals.round(goal - earned);
    return remaining > 0 ? remaining : 0;
  }

  bool get goalReached => remainingToGoal == 0;

  /// La meta sigue siendo posible con lo que queda por sumar.
  bool get goalReachable => maxReachable + 1e-9 >= goal;

  /// Avance hacia la meta, entre 0 y 1.
  double get progress => goal <= 0 ? 1 : (earned / goal).clamp(0.0, 1.0);

  /// Elementos que todavía pueden sumar.
  List<GradeItem> get open => [
    for (final item in items)
      if (item.state != GradeState.earned) item,
  ];

  /// Nota media que necesitas en las actividades sin nota para llegar a la
  /// meta **sin contar** test ni asistencia futuros. Es `null` si ya llegaste
  /// o si no queda ninguna actividad por calificar. Puede superar la nota
  /// máxima: entonces las actividades solas no alcanzan.
  double? get requiredAverage {
    if (goalReached) return null;
    final value = _sum(
      items
          .where((i) => i.needsScore && i.state != GradeState.earned)
          .map((i) => i.maxPoints),
    );
    if (value <= 0) return null;
    return Decimals.round(remainingToGoal / value * scheme.scaleMax, 2);
  }

  /// Nota que necesitas en el elemento [itemId] para llegar a la meta solo
  /// con él. Es `null` si ya llegaste, si el elemento no existe o si no
  /// necesita nota. Puede superar la nota máxima.
  double? requiredScoreFor(String itemId) {
    if (goalReached) return null;
    final item = items.where((i) => i.id == itemId).firstOrNull;
    if (item == null || !item.needsScore || item.state == GradeState.earned) {
      return null;
    }
    if (item.maxPoints <= 0) return null;
    return Decimals.round(
      remainingToGoal / item.maxPoints * scheme.scaleMax,
      2,
    );
  }
}

/// Motor de puntos. Es lógica pura: no lee ni escribe datos.
abstract final class GradeCalculator {
  /// Puntos que aporta una nota [score] en una actividad de valor [value].
  static double pointsFor({
    required double value,
    required double score,
    required GradingScheme scheme,
  }) => Decimals.round(value * score / scheme.scaleMax);

  /// Resume la evaluación continua con los datos reales.
  ///
  /// El simulador pasa hipótesis que **solo** afectan a lo que aún no tiene
  /// resultado real: [hypotheticalScores] da una nota a actividades sin
  /// calificar y [assumeDone] da por hechos test y clases pendientes. Un
  /// resultado real nunca se sustituye, y nada de esto se guarda.
  static GradeSummary summarize({
    required GradingScheme scheme,
    required Iterable<Activity> activities,
    required Iterable<ClassSession> classSessions,
    Map<String, double> hypotheticalScores = const {},
    Set<String> assumeDone = const {},
  }) {
    final items = <GradeItem>[];

    for (final activity in activities) {
      final value = activity.value;
      if (activity.isDeleted || value == null || value <= 0) continue;

      if (activity.type == ActivityType.test) {
        // Un test suma su valor completo por hacerlo.
        final done = activity.isDone;
        final assumed = !done && assumeDone.contains(activity.id);
        items.add(
          GradeItem(
            id: activity.id,
            title: activity.title,
            source: GradeSource.test,
            maxPoints: value,
            points: done || assumed ? value : 0,
            state: done || assumed ? GradeState.earned : GradeState.pending,
            simulated: assumed,
          ),
        );
        continue;
      }

      final real = activity.score;
      final hypothetical = real == null
          ? hypotheticalScores[activity.id]
          : null;
      final score = real ?? hypothetical;
      items.add(
        GradeItem(
          id: activity.id,
          title: activity.title,
          source: GradeSource.activity,
          maxPoints: value,
          points: score == null
              ? 0
              : pointsFor(value: value, score: score, scheme: scheme),
          state: score != null
              ? GradeState.earned
              : activity.isDone
              ? GradeState.awaitingGrade
              : GradeState.pending,
          simulated: hypothetical != null,
        ),
      );
    }

    for (final session in classSessions) {
      if (session.isDeleted || session.points <= 0) continue;
      // Una clase a la que no asististe no suma ni queda pendiente.
      if (session.attended == false) continue;

      final attended = session.attended == true;
      final assumed = !attended && assumeDone.contains(session.id);
      items.add(
        GradeItem(
          id: session.id,
          title: session.label,
          source: GradeSource.attendance,
          maxPoints: session.points,
          points: attended || assumed ? session.points : 0,
          state: attended || assumed ? GradeState.earned : GradeState.pending,
          simulated: assumed,
        ),
      );
    }

    return GradeSummary(scheme: scheme, items: items);
  }
}
