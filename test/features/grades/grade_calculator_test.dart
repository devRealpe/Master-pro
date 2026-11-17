import 'package:flutter_test/flutter_test.dart';
import 'package:master_pro/core/format/decimals.dart';
import 'package:master_pro/features/activities/data/activity_mapper.dart';
import 'package:master_pro/features/activities/domain/activity.dart';
import 'package:master_pro/features/classes/data/class_session_mapper.dart';
import 'package:master_pro/features/classes/domain/class_session.dart';
import 'package:master_pro/features/grades/domain/grade_calculator.dart';
import 'package:master_pro/features/grades/domain/grading_scheme.dart';
import 'package:master_pro/features/subjects/data/subject_mappers.dart';
import 'package:master_pro/features/subjects/domain/subject.dart';

const _unir = GradingScheme.unir;
final _day = DateTime.utc(2026, 12, 1, 18);

Activity work(
  String id,
  double value, {
  double? score,
  bool delivered = false,
}) => Activity(
  id: id,
  title: 'Actividad $id',
  value: value,
  score: score,
  submittedAt: delivered ? _day : null,
  status: delivered ? ActivityStatus.done : ActivityStatus.backlog,
);

Activity quiz(String id, {bool done = false}) => Activity(
  id: id,
  title: 'Test $id',
  type: ActivityType.test,
  value: 0.1,
  status: done ? ActivityStatus.done : ActivityStatus.backlog,
);

ClassSession session(String id, {bool? attended, double points = 0.4}) =>
    ClassSession(
      id: id,
      subjectId: 's1',
      startsAt: _day,
      attended: attended,
      points: points,
    );

GradeSummary summarize({
  List<Activity> activities = const [],
  List<ClassSession> classes = const [],
  GradingScheme scheme = _unir,
  Map<String, double> hypotheticalScores = const {},
  Set<String> assumeDone = const {},
}) => GradeCalculator.summarize(
  scheme: scheme,
  activities: activities,
  classSessions: classes,
  hypotheticalScores: hypotheticalScores,
  assumeDone: assumeDone,
);

void main() {
  group('Reglas confirmadas de UNIR', () {
    test('una actividad aporta valor × nota / 10', () {
      double points(double value, double score) =>
          GradeCalculator.pointsFor(value: value, score: score, scheme: _unir);

      expect(points(5, 8), 4);
      expect(points(5, 8.5), 4.25);
      expect(points(5, 7.5), 3.75);
      expect(points(4, 8), 3.2);
      expect(points(5, 10), 5);
      expect(points(5, 0), 0);
    });

    test('la plantilla trae 0,4 por clase, 0,1 por test y meta de 5', () {
      expect(_unir.scaleMax, 10);
      expect(_unir.attendancePoints, 0.4);
      expect(_unir.testPoints, 0.1);
      expect(_unir.pointsGoal, 5);
      expect(_unir.continuousWeight + _unir.examWeight, 100);
      expect(_unir.confirmed, isFalse);
    });
  });

  group('Ejercicios de la guía de bienvenida', () {
    test('valores 4, 4 y 5 con un 6 y un 7: 5,2 puntos, meta alcanzada', () {
      final summary = summarize(
        activities: [
          work('1', 4, score: 6),
          work('2', 4, score: 7),
          work('3', 5),
        ],
      );

      expect(summary.earned, 5.2);
      expect(summary.goalReached, isTrue);
      expect(summary.remainingToGoal, 0);
      expect(summary.pending, 5);
      expect(summary.maxReachable, 10.2);
      expect(summary.requiredAverage, isNull);
    });

    test('4 test y 2 clases: hace falta un 7,6 en la actividad de valor 5', () {
      final summary = summarize(
        activities: [
          for (var i = 1; i <= 4; i++) quiz('t$i', done: true),
          work('a3', 5),
        ],
        classes: [session('c1', attended: true), session('c2', attended: true)],
      );

      expect(summary.earnedFrom(GradeSource.test), 0.4);
      expect(summary.earnedFrom(GradeSource.attendance), 0.8);
      expect(summary.earned, 1.2);
      expect(summary.remainingToGoal, 3.8);
      expect(summary.requiredScoreFor('a3'), 7.6);
      expect(summary.requiredAverage, 7.6);
    });

    test('solo la actividad 3 con 7,5: 3,75 puntos, por debajo de la meta', () {
      final summary = summarize(activities: [work('3', 5, score: 7.5)]);

      expect(summary.earned, 3.75);
      expect(summary.goalReached, isFalse);
      expect(summary.remainingToGoal, 1.25);
      expect(summary.goalReachable, isFalse);
    });
  });

  group('Estados', () {
    test('distingue calificada, entregada sin nota y por hacer', () {
      final summary = summarize(
        activities: [
          work('calificada', 4, score: 9),
          work('entregada', 4, delivered: true),
          work('pendiente', 5),
        ],
      );

      GradeState of(String id) =>
          summary.items.firstWhere((i) => i.id == id).state;
      expect(of('calificada'), GradeState.earned);
      expect(of('entregada'), GradeState.awaitingGrade);
      expect(of('pendiente'), GradeState.pending);

      expect(summary.earned, 3.6);
      expect(summary.awaiting, 4);
      expect(summary.pending, 5);
      expect(summary.maxReachable, 12.6);
      expect(summary.open.map((i) => i.id), ['entregada', 'pendiente']);
    });

    test('un test suma completo al hacerlo, sin nota', () {
      final summary = summarize(activities: [quiz('1', done: true), quiz('2')]);

      expect(summary.earned, 0.1);
      expect(summary.pending, 0.1);
      expect(summary.items.every((i) => !i.needsScore), isTrue);
    });

    test('la asistencia solo suma: faltar no resta ni queda pendiente', () {
      final summary = summarize(
        classes: [
          session('fui', attended: true),
          session('falté', attended: false),
          session('sin registrar'),
        ],
      );

      expect(summary.earned, 0.4);
      expect(summary.pending, 0.4);
      expect(summary.items.map((i) => i.id), ['fui', 'sin registrar']);
    });

    test('no cuenta lo eliminado ni lo que no puntúa', () {
      final summary = summarize(
        activities: [
          work('eliminada', 5, score: 10).copyWith(deletedAt: _day),
          const Activity(id: 'sin valor', title: 'Lectura', score: 10),
          work('valor cero', 0, score: 10),
        ],
        classes: [
          session('sin puntos', attended: true, points: 0),
          session('eliminada', attended: true).copyWith(deletedAt: _day),
        ],
      );

      expect(summary.items, isEmpty);
      expect(summary.earned, 0);
      expect(summary.requiredAverage, isNull);
    });

    test('las sumas no arrastran ruido decimal', () {
      final summary = summarize(
        activities: [for (var i = 0; i < 3; i++) quiz('t$i', done: true)],
      );
      expect(summary.earned, 0.3);
    });
  });

  group('Meta', () {
    test('sin nada todavía: todo pendiente y meta posible', () {
      final summary = summarize(
        activities: [work('1', 4), work('2', 4), work('3', 5)],
      );

      expect(summary.earned, 0);
      expect(summary.progress, 0);
      expect(summary.goalReachable, isTrue);
      // 5 puntos sobre 13 posibles: una media de 3,85.
      expect(summary.requiredAverage, 3.85);
    });

    test('la nota necesaria puede superar la máxima: esa actividad sola no alcanza', () {
      final summary = summarize(
        activities: [work('1', 4), work('2', 5, score: 0)],
      );

      expect(summary.requiredScoreFor('1'), 12.5);
      expect(summary.goalReachable, isFalse);
    });

    test('la meta puede seguir siendo posible gracias a test y clases', () {
      final summary = summarize(
        activities: [work('1', 4, score: 10), quiz('t1'), quiz('t2')],
        classes: [session('c1'), session('c2')],
      );

      // 4 puntos ya; quedan 0,2 de test y 0,8 de clases: justo 5.
      expect(summary.earned, 4);
      expect(summary.maxReachable, 5);
      expect(summary.goalReachable, isTrue);
      expect(summary.requiredAverage, isNull);
    });

    test('no se pide nota a lo ya calificado ni a lo que no lleva nota', () {
      final summary = summarize(
        activities: [work('1', 4, score: 5), quiz('t1')],
      );

      expect(summary.requiredScoreFor('1'), isNull);
      expect(summary.requiredScoreFor('t1'), isNull);
      expect(summary.requiredScoreFor('no existe'), isNull);
    });

    test('el avance no pasa de 1 aunque sobren puntos', () {
      final summary = summarize(
        activities: [work('1', 5, score: 10), work('2', 5, score: 10)],
      );
      expect(summary.earned, 10);
      expect(summary.progress, 1);
    });
  });

  group('Simulación', () {
    final activities = [
      work('real', 4, score: 6),
      work('a2', 4),
      work('a3', 5),
    ];
    final classes = [session('c1')];

    test('«si saco 8 y 9, ¿llego?»', () {
      final real = summarize(activities: activities, classes: classes);
      final simulated = summarize(
        activities: activities,
        classes: classes,
        hypotheticalScores: {'a2': 8, 'a3': 9},
      );

      expect(real.earned, 2.4);
      // 2,4 + 3,2 + 4,5
      expect(simulated.earned, 10.1);
      expect(simulated.goalReached, isTrue);
      expect(simulated.items.where((i) => i.simulated).map((i) => i.id), [
        'a2',
        'a3',
      ]);
    });

    test('una hipótesis nunca sustituye una nota real', () {
      final simulated = summarize(
        activities: activities,
        hypotheticalScores: {'real': 10},
      );

      expect(simulated.earned, 2.4);
      expect(simulated.items.first.simulated, isFalse);
    });

    test('dar por hechos test y clases pendientes', () {
      final simulated = summarize(
        activities: [quiz('t1'), quiz('t2', done: true)],
        classes: [session('c1'), session('falté', attended: false)],
        assumeDone: {'t1', 't2', 'c1', 'falté'},
      );

      // t2 ya estaba hecho; la clase a la que faltaste no se puede recuperar.
      expect(simulated.earned, 0.6);
      expect(simulated.items.where((i) => i.simulated).map((i) => i.id), [
        't1',
        'c1',
      ]);
    });

    test('simular no cambia los datos reales', () {
      final before = [...activities];
      summarize(activities: activities, hypotheticalScores: {'a2': 10});

      expect(activities, before);
      expect(activities[1].score, isNull);
      expect(summarize(activities: activities).earned, 2.4);
    });
  });

  group('Otras reglas', () {
    test('otra escala y otra meta', () {
      const scheme = GradingScheme(scaleMax: 5, pointsGoal: 3);
      final summary = summarize(
        scheme: scheme,
        activities: [work('1', 5, score: 4), work('2', 2)],
      );

      expect(summary.earned, 4);
      expect(summary.goalReached, isTrue);
      expect(
        GradeCalculator.pointsFor(value: 2, score: 2.5, scheme: scheme),
        1,
      );
    });

    test('valida escala, puntos, pesos y nota', () {
      expect(GradingRules.scale(10), isNull);
      expect(GradingRules.scale(0), isNotNull);
      expect(GradingRules.scale(null), isNotNull);
      expect(GradingRules.points(0), isNull);
      expect(GradingRules.points(0.4), isNull);
      expect(GradingRules.points(-1), isNotNull);
      expect(GradingRules.weights(40, 60), isNull);
      expect(GradingRules.weights(50, 60), isNotNull);
      expect(GradingRules.weights(null, 60), isNotNull);
      expect(GradingRules.score(8.5, _unir), isNull);
      expect(GradingRules.score(10, _unir), isNull);
      expect(GradingRules.score(10.5, _unir), 'Debe estar entre 0 y 10');
      expect(GradingRules.score(-1, _unir), isNotNull);
      expect(GradingRules.score(null, _unir), isNotNull);
    });
  });

  group('Decimals', () {
    test('lee coma o punto', () {
      expect(Decimals.parse('8,5'), 8.5);
      expect(Decimals.parse(' 8.5 '), 8.5);
      expect(Decimals.parse('8'), 8);
      expect(Decimals.parse(''), isNull);
      expect(Decimals.parse('ocho'), isNull);
    });

    test('escribe con coma y sin ceros de relleno', () {
      expect(Decimals.format(4), '4');
      expect(Decimals.format(0.1), '0,1');
      expect(Decimals.format(3.75), '3,75');
      expect(Decimals.format(4.249999), '4,25');
      expect(Decimals.format(5.2), '5,2');
      expect(Decimals.format(0), '0');
    });
  });

  group('Mapeo', () {
    test('una asignatura sin reglas guardadas recibe las de UNIR', () {
      expect(subjectFromMap('s', const {'name': 'Asignatura'}).grading, _unir);
      expect(gradingFromMap('texto'), _unir);
    });

    test('las reglas van y vuelven; lo inválido toma el valor de UNIR', () {
      const custom = GradingScheme(
        scaleMax: 5,
        pointsGoal: 3,
        attendancePoints: 0.5,
        testPoints: 0.2,
        continuousWeight: 30,
        examWeight: 70,
        confirmed: true,
      );
      const subject = Subject(id: 's', name: 'Asignatura', grading: custom);
      expect(subjectFromMap('s', subjectToMap(subject)), subject);

      final repaired = gradingFromMap(const {
        'scaleMax': 0,
        'pointsGoal': 'cinco',
        'testPoints': -1,
        'attendancePoints': 1,
      });
      expect(repaired.scaleMax, 10);
      expect(repaired.pointsGoal, 5);
      expect(repaired.testPoints, 0.1);
      // Firestore puede devolver un entero donde se guardó un decimal.
      expect(repaired.attendancePoints, 1.0);
    });

    test('valor y nota de una actividad van y vuelven', () {
      const activity = Activity(
        id: 'a',
        title: 'Actividad',
        value: 5,
        score: 8.5,
      );
      expect(activityFromMap('a', activityToMap(activity)), activity);
      expect(activityFromMap('a', const {'value': 4, 'score': 7}).value, 4.0);
      expect(activityFromMap('a', const {'value': -1}).value, isNull);
    });

    test('una clase va y vuelve; sin asignatura o fecha se descarta', () {
      final full = ClassSession(
        id: 'c1',
        subjectId: 's1',
        startsAt: _day,
        topic: 'Tema 1',
        durationMinutes: 90,
        attended: true,
        points: 0.4,
        guideUrl: 'https://example.com/guia',
        notes: 'Notas',
        deletedAt: DateTime.utc(2027, 1, 1),
      );
      expect(classSessionFromMap('c1', classSessionToMap(full)), full);

      final minimal = ClassSession(id: 'c2', subjectId: 's1', startsAt: _day);
      final read = classSessionFromMap('c2', classSessionToMap(minimal));
      expect(read, minimal);
      expect(read!.attended, isNull);
      expect(read.label, 'Clase en vivo');

      expect(classSessionFromMap('x', const {'subjectId': 's1'}), isNull);
      expect(
        classSessionFromMap('x', const {
          'startsAt': '2026-12-01T18:00:00.000Z',
        }),
        isNull,
      );
    });
  });
}
