import 'package:flutter_test/flutter_test.dart';
import 'package:master_pro/core/time/deadline_clock.dart';
import 'package:master_pro/features/activities/domain/activity.dart';
import 'package:master_pro/features/calendar/domain/study_block.dart';
import 'package:master_pro/features/classes/domain/class_session.dart';
import 'package:master_pro/features/subjects/domain/period.dart';
import 'package:master_pro/features/subjects/domain/subject.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/pump_app.dart';

/// Hoy es lunes 16 de noviembre de 2026, 12:00 en Colombia.
TestBackend _backend() => TestBackend(
  subjects: const [Subject(id: 's1', name: 'Asignatura 1', colorIndex: 2)],
  activities: [
    Activity(
      id: 'a1',
      title: 'Actividad 1',
      subjectId: 's1',
      dueAt: SpainTime.toInstant(DateTime(2026, 11, 19)),
    ),
  ],
  classSessions: [
    ClassSession(
      id: 'c1',
      subjectId: 's1',
      startsAt: fromBogota(DateTime(2026, 11, 17, 13)),
      topic: 'Tema 1',
      durationMinutes: 90,
    ),
  ],
  studyBlocks: [
    StudyBlock(
      id: 'b1',
      title: 'Repasar tema 1',
      startsAt: fromBogota(DateTime(2026, 11, 16, 19)),
    ),
  ],
  periods: [
    Period(
      id: 'p1',
      name: '1.er cuatrimestre',
      startDate: DateTime(2026, 11, 16),
      endDate: DateTime(2027, 3, 21),
      keyDates: [
        KeyDate(
          id: 'k1',
          title: 'Exámenes',
          start: DateTime(2026, 11, 20),
          end: DateTime(2026, 11, 21),
          kind: KeyDateKind.exams,
        ),
      ],
    ),
  ],
);

Future<TestBackend> openCalendar(
  WidgetTester tester, {
  TestBackend? backend,
}) async {
  useTallPhone(tester);
  final target = await pumpApp(tester, backend: backend ?? _backend());
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Calendario'),
    ),
  );
  await tester.pumpAndSettle();
  return target;
}

Future<void> selectDay(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^$label')));
  await tester.pumpAndSettle();
}

void main() {
  initializeTimeZones();

  group('Mes', () {
    testWidgets('abre en hoy y muestra lo del día', (tester) async {
      await openCalendar(tester);

      expect(find.text('Noviembre 2026'), findsOneWidget);
      expect(find.text('LUNES 16 DE NOVIEMBRE'), findsOneWidget);
      expect(find.text('Repasar tema 1'), findsOneWidget);
      expect(find.text('19:00'), findsOneWidget);
      expect(find.text('Estudio · 1 h'), findsOneWidget);
      // Hoy ya está elegido: no hace falta el botón para volver.
      expect(find.text('Hoy'), findsNothing);
    });

    testWidgets('cada día anuncia cuántos elementos tiene', (tester) async {
      await openCalendar(tester);

      expect(
        find.bySemanticsLabel('16 de noviembre, hoy, 1 elemento'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('19 de noviembre, 1 elemento'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('15 de noviembre'), findsOneWidget);
    });

    testWidgets('una entrega aparece en tu hora, con su asignatura', (
      tester,
    ) async {
      await openCalendar(tester);

      await selectDay(tester, '19 de noviembre');

      expect(find.text('JUEVES 19 DE NOVIEMBRE'), findsOneWidget);
      expect(find.text('Actividad 1'), findsOneWidget);
      // 23:59 de España.
      expect(find.text('17:59'), findsOneWidget);
      expect(find.text('Entrega · Asignatura 1'), findsOneWidget);
      expect(find.text('Hoy'), findsOneWidget);
    });

    testWidgets('la meta personal aparece el día del colchón', (tester) async {
      await openCalendar(tester);

      await selectDay(tester, '18 de noviembre');

      expect(find.text('Meta · Asignatura 1'), findsOneWidget);
    });

    testWidgets('las fechas de plantilla avisan que están por confirmar', (
      tester,
    ) async {
      await openCalendar(tester);

      await selectDay(tester, '20 de noviembre');

      expect(find.text('Exámenes'), findsOneWidget);
      expect(find.text('Exámenes · por confirmar'), findsOneWidget);
      expect(find.text('Todo\nel día'), findsOneWidget);
    });

    testWidgets('avanzar y volver a hoy', (tester) async {
      await openCalendar(tester);

      await tester.tap(find.byTooltip('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Diciembre 2026'), findsOneWidget);
      expect(find.text('MIÉRCOLES 16 DE DICIEMBRE'), findsOneWidget);

      await tester.tap(find.text('Hoy'));
      await tester.pumpAndSettle();
      expect(find.text('Noviembre 2026'), findsOneWidget);
      expect(find.text('LUNES 16 DE NOVIEMBRE'), findsOneWidget);
    });

    testWidgets('tocar una entrega abre su actividad', (tester) async {
      await openCalendar(tester);
      await selectDay(tester, '19 de noviembre');

      await tester.tap(find.text('Actividad 1'));
      await tester.pumpAndSettle();

      expect(find.text('Marcar como entregada'), findsOneWidget);
      expect(find.text('Hora oficial: 23:59 España'), findsOneWidget);
    });
  });

  group('Semana y día', () {
    testWidgets('la semana reúne lo de sus siete días', (tester) async {
      await openCalendar(tester);

      await tester.tap(find.text('Semana'));
      await tester.pumpAndSettle();

      expect(find.text('16 – 22 nov 2026'), findsOneWidget);
      for (final title in ['Repasar tema 1', 'Tema 1']) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      // La actividad aparece dos veces: su meta el 18 y su entrega el 19.
      expect(find.text('Actividad 1'), findsNWidgets(2));
      // Los exámenes ocupan el 20 y el 21.
      expect(find.text('Exámenes'), findsNWidgets(2));
      expect(find.text('Clase · Asignatura 1 · 1 h 30 min'), findsOneWidget);
      // Días sin nada no ocupan espacio.
      expect(find.text('DOMINGO 22 DE NOVIEMBRE'), findsNothing);

      await tester.tap(find.byTooltip('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('23 – 29 nov 2026'), findsOneWidget);
      expect(find.text('Nada esta semana'), findsOneWidget);
    });

    testWidgets('el día se recorre de uno en uno', (tester) async {
      await openCalendar(tester);

      await tester.tap(find.text('Día'));
      await tester.pumpAndSettle();
      expect(find.text('Lunes 16 de noviembre'), findsOneWidget);
      expect(find.text('Repasar tema 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Martes 17 de noviembre'), findsOneWidget);
      expect(find.text('Tema 1'), findsOneWidget);
      expect(find.text('13:00'), findsOneWidget);

      await tester.tap(find.byTooltip('Anterior'));
      await tester.tap(find.byTooltip('Anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Domingo 15 de noviembre'), findsOneWidget);
      expect(find.text('Nada este día'), findsOneWidget);
    });
  });

  group('Bloques de estudio', () {
    testWidgets('reservar un bloque lo muestra en el día elegido', (
      tester,
    ) async {
      final backend = await openCalendar(tester);
      await selectDay(tester, '18 de noviembre');

      await tester.tap(find.byTooltip('Reservar bloque de estudio'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, '¿Qué vas a estudiar?'),
        'Avanzar la actividad 1',
      );
      await tester.tap(find.text('1 h 30 min'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reservar bloque'));
      await tester.pumpAndSettle();

      final created = backend.studyBlocks.items.last;
      expect(created.title, 'Avanzar la actividad 1');
      expect(created.durationMinutes, 90);
      // Propone la siguiente hora en punto: 13:00 de Colombia, el día 18.
      expect(created.startsAt, fromBogota(DateTime(2026, 11, 18, 13)));
      expect(find.text('Avanzar la actividad 1'), findsOneWidget);
      expect(find.text('Estudio · 1 h 30 min'), findsOneWidget);
    });

    testWidgets('elegir una actividad propone su título y su asignatura', (
      tester,
    ) async {
      final backend = await openCalendar(tester);

      await tester.tap(find.byTooltip('Reservar bloque de estudio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ninguna'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Actividad 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reservar bloque'));
      await tester.pumpAndSettle();

      final created = backend.studyBlocks.items.last;
      expect(created.title, 'Actividad 1');
      expect(created.activityId, 'a1');
      expect(created.subjectId, 's1');
    });

    testWidgets('sin título no se reserva', (tester) async {
      final backend = await openCalendar(tester);

      await tester.tap(find.byTooltip('Reservar bloque de estudio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reservar bloque'));
      await tester.pumpAndSettle();

      expect(find.text('Escribe qué vas a estudiar'), findsOneWidget);
      expect(backend.studyBlocks.items, hasLength(1));
    });

    testWidgets('editar y eliminar, con deshacer', (tester) async {
      final backend = await openCalendar(tester);
      StudyBlock block() => backend.studyBlocks.items.single;

      await tester.tap(find.text('Repasar tema 1'));
      await tester.pumpAndSettle();
      expect(find.text('Editar bloque'), findsOneWidget);
      await tester.tap(find.text('2 h'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(block().durationMinutes, 120);
      expect(find.text('Estudio · 2 h'), findsOneWidget);

      await tester.tap(find.text('Repasar tema 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar bloque'));
      await tester.pumpAndSettle();
      expect(block().isDeleted, isTrue);
      expect(find.text('Nada este día'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(block().isDeleted, isFalse);
      expect(find.text('Repasar tema 1'), findsOneWidget);
    });
  });

  testWidgets('sin datos invita a reservar tiempo de estudio', (tester) async {
    await openCalendar(tester, backend: TestBackend());

    expect(find.text('Nada este día'), findsOneWidget);
    await tester.tap(find.text('Reservar bloque de estudio'));
    await tester.pumpAndSettle();
    expect(find.text('Bloque de estudio'), findsOneWidget);
  });
}
