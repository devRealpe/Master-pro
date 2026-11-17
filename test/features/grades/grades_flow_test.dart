import 'package:flutter_test/flutter_test.dart';
import 'package:master_pro/core/time/deadline_clock.dart';
import 'package:master_pro/features/activities/domain/activity.dart';
import 'package:master_pro/features/classes/domain/class_session.dart';
import 'package:master_pro/features/grades/domain/grading_scheme.dart';
import 'package:master_pro/features/subjects/domain/subject.dart';
import 'package:master_pro/features/subjects/presentation/subjects_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/pump_app.dart';

const _subject = Subject(id: 's1', name: 'Asignatura 1');

Activity _work(String id, double value, {double? score}) => Activity(
  id: id,
  title: 'Actividad $id',
  subjectId: 's1',
  value: value,
  score: score,
  status: score == null ? ActivityStatus.backlog : ActivityStatus.done,
);

Activity _quiz(String id, {bool done = false}) => Activity(
  id: id,
  title: 'Test $id',
  subjectId: 's1',
  type: ActivityType.test,
  value: 0.1,
  status: done ? ActivityStatus.done : ActivityStatus.backlog,
);

ClassSession _class(String id, String topic, {bool? attended}) => ClassSession(
  id: id,
  subjectId: 's1',
  // Una clase de la semana anterior, a las 13:00 de Colombia.
  startsAt: DateTime.utc(2026, 11, 12, 18),
  topic: topic,
  attended: attended,
  points: 0.4,
);

/// 2,4 de actividades + 0,1 de test + 0,4 de asistencia = 2,9 puntos.
TestBackend _backend() => TestBackend(
  subjects: [_subject],
  activities: [
    _work('1', 4, score: 6),
    _work('2', 4),
    _work('3', 5),
    _quiz('t1', done: true),
    _quiz('t2'),
  ],
  classSessions: [
    _class('c1', 'Tema 1', attended: true),
    _class('c2', 'Tema 2'),
  ],
);

Future<TestBackend> openSubject(WidgetTester tester) async {
  useTallPhone(tester);
  final backend = await pumpApp(tester, backend: _backend());
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Asignaturas'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(SubjectCard));
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  initializeTimeZones();

  group('Marcador', () {
    testWidgets('suma actividades, test y asistencia', (tester) async {
      await openSubject(tester);

      expect(find.text('2,9 de 5 puntos'), findsOneWidget);
      expect(find.text('Actividades 2,4'), findsOneWidget);
      expect(find.text('Test 0,1'), findsOneWidget);
      expect(find.text('Asistencia 0,4'), findsOneWidget);
      // Quedan 4 + 5 de actividades, 0,1 de test y 0,4 de una clase.
      expect(find.text('Aún puedes sumar 9,5'), findsOneWidget);
      // Faltan 2,1 sobre 9 puntos de actividades: media de 2,3.
      expect(
        find.text(
          'Te faltan 2,1 puntos: una media de 2,3 en las actividades que '
          'quedan.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('40 % evaluación continua · 60 % examen'),
        findsOneWidget,
      );
      expect(
        find.text('Reglas sin confirmar con la guía docente'),
        findsOneWidget,
      );
    });

    testWidgets('registrar asistencia suma sus puntos al instante', (
      tester,
    ) async {
      final backend = await openSubject(tester);

      await tester.tap(find.text('Asistí'));
      await tester.pumpAndSettle();

      expect(find.text('3,3 de 5 puntos'), findsOneWidget);
      expect(find.text('Asistencia 0,8'), findsOneWidget);
      expect(find.text('Asististe · +0,4'), findsNWidgets(2));
      expect(
        backend.classSessions.items.firstWhere((c) => c.id == 'c2').attended,
        isTrue,
      );
    });

    testWidgets('no asistir no suma ni resta', (tester) async {
      final backend = await openSubject(tester);

      await tester.tap(find.text('No asistí'));
      await tester.pumpAndSettle();

      expect(find.text('2,9 de 5 puntos'), findsOneWidget);
      expect(find.text('No asististe'), findsOneWidget);
      // Esa clase ya no cuenta como algo que se pueda sumar.
      expect(find.text('Aún puedes sumar 9,1'), findsOneWidget);
      expect(
        backend.classSessions.items.firstWhere((c) => c.id == 'c2').attended,
        isFalse,
      );
    });
  });

  group('Clases', () {
    testWidgets('una clase nueva trae los puntos de la asignatura', (
      tester,
    ) async {
      final backend = await openSubject(tester);

      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Tema'), 'Tema 3');
      await tester.tap(find.widgetWithText(FilledButton, 'Registrar clase'));
      await tester.pumpAndSettle();

      final created = backend.classSessions.items.last;
      expect(created.topic, 'Tema 3');
      expect(created.subjectId, 's1');
      expect(created.points, 0.4);
      expect(created.attended, isNull);
      // Propone la hora actual en punto: 12:00 de Colombia.
      expect(created.startsAt, DateTime.utc(2026, 11, 16, 17));
      expect(find.text('Tema 3'), findsOneWidget);
      expect(find.text('lun 16 nov, 12:00'), findsOneWidget);
    });

    testWidgets('eliminar una clase se puede deshacer', (tester) async {
      final backend = await openSubject(tester);
      ClassSession first() =>
          backend.classSessions.items.firstWhere((c) => c.id == 'c1');

      await tester.tap(find.text('Tema 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar clase'));
      await tester.pumpAndSettle();

      expect(first().isDeleted, isTrue);
      expect(find.text('2,5 de 5 puntos'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      expect(first().isDeleted, isFalse);
      expect(find.text('2,9 de 5 puntos'), findsOneWidget);
    });
  });

  group('Nota de una actividad', () {
    Future<TestBackend> openActivity(WidgetTester tester) async {
      final backend = await openSubject(tester);
      await tester.tap(find.text('Actividad 2'));
      await tester.pumpAndSettle();
      return backend;
    }

    testWidgets('registrar la nota muestra lo que aporta', (tester) async {
      final backend = await openActivity(tester);
      expect(find.text('Vale hasta 4 puntos'), findsOneWidget);

      await tester.tap(find.text('Registrar nota'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '8,5');
      await tester.pumpAndSettle();
      expect(find.text('Aporta 3,4 de 4 puntos'), findsOneWidget);

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final saved = backend.activities.items.firstWhere((a) => a.id == '2');
      expect(saved.score, 8.5);
      expect(saved.status, ActivityStatus.done);
      expect(find.text('Nota 8,5'), findsOneWidget);
      expect(find.text('Aporta 3,4 de 4 puntos'), findsOneWidget);
    });

    testWidgets('una nota fuera de la escala no se guarda', (tester) async {
      final backend = await openActivity(tester);

      await tester.tap(find.text('Registrar nota'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '11');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Debe estar entre 0 y 10'), findsOneWidget);
      expect(
        backend.activities.items.firstWhere((a) => a.id == '2').score,
        isNull,
      );
    });

    testWidgets('la nota se puede quitar', (tester) async {
      final backend = await openSubject(tester);
      // La actividad 1 ya está calificada: se llega desde el Plan.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Plan'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hechas (2)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Actividad 1'));
      await tester.pumpAndSettle();
      expect(find.text('Nota 6'), findsOneWidget);
      expect(find.text('Aporta 2,4 de 4 puntos'), findsOneWidget);

      await tester.tap(find.text('Cambiar nota'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitar nota'));
      await tester.pumpAndSettle();

      expect(
        backend.activities.items.firstWhere((a) => a.id == '1').score,
        isNull,
      );
    });
  });

  group('Reglas', () {
    testWidgets('cambiar la meta y confirmarlas', (tester) async {
      final backend = await openSubject(tester);

      await tester.tap(find.text('Reglas'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Meta de puntos'),
        '6',
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar reglas'));
      await tester.pumpAndSettle();

      expect(
        backend.subjects.items.single.grading,
        const GradingScheme(pointsGoal: 6, confirmed: true),
      );
      expect(find.text('2,9 de 6 puntos'), findsOneWidget);
      expect(
        find.text('Reglas sin confirmar con la guía docente'),
        findsNothing,
      );
    });

    testWidgets('los porcentajes deben sumar 100', (tester) async {
      final backend = await openSubject(tester);

      await tester.tap(find.text('Reglas'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Ev. continua'),
        '50',
      );
      await tester.tap(find.text('Guardar reglas'));
      await tester.pumpAndSettle();

      expect(find.text('Los dos porcentajes deben sumar 100'), findsOneWidget);
      expect(backend.subjects.items.single.grading, GradingScheme.unir);
    });
  });

  group('Simulador', () {
    testWidgets('prueba notas sin guardar nada', (tester) async {
      final backend = await openSubject(tester);
      final before = [...backend.activities.items];

      await tester.tap(find.text('Simular'));
      await tester.pumpAndSettle();
      expect(find.text('TU SITUACIÓN REAL'), findsOneWidget);
      expect(find.text('2,9 de 5 puntos'), findsOneWidget);
      // 2,1 puntos sobre una actividad de valor 4: hace falta un 5,3.
      expect(find.text('Con un 5,3 aquí llegas a la meta'), findsOneWidget);

      // «Si saco 8 en la actividad 2…»
      tester.widget<Slider>(find.byType(Slider).first).onChanged!(8);
      await tester.pumpAndSettle();

      expect(find.text('SIMULACIÓN'), findsOneWidget);
      expect(find.text('6,1 de 5 puntos'), findsOneWidget);
      expect(find.text('Hoy tienes 2,9'), findsOneWidget);
      expect(find.text('Con un 8 sumas 3,2'), findsOneWidget);

      // «…y además hago el test pendiente».
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(find.text('6,2 de 5 puntos'), findsOneWidget);

      await tester.tap(find.text('Restablecer'));
      await tester.pumpAndSettle();
      expect(find.text('2,9 de 5 puntos'), findsOneWidget);

      expect(backend.activities.items, before);
    });
  });

  group('Formulario de actividad', () {
    testWidgets('un test propone su valor en puntos', (tester) async {
      final backend = await openSubject(tester);

      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Test del tema 3');
      await tester.tap(find.text('Trabajo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '0,1'), findsOneWidget);

      await tester.tap(find.text('Agregar actividad'));
      await tester.pumpAndSettle();

      final created = backend.activities.items.last;
      expect(created.type, ActivityType.test);
      expect(created.value, 0.1);
      expect(find.text('Aún puedes sumar 9,6'), findsOneWidget);
    });

    testWidgets('un valor que no es un número no se guarda', (tester) async {
      final backend = await openSubject(tester);
      final count = backend.activities.items.length;

      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Actividad 4');
      await tester.enterText(find.widgetWithText(TextField, 'Valor'), 'cinco');
      await tester.tap(find.text('Agregar actividad'));
      await tester.pumpAndSettle();

      expect(
        find.text('Escribe un número, por ejemplo 5 o 0,1'),
        findsOneWidget,
      );
      expect(backend.activities.items, hasLength(count));
    });
  });
}
