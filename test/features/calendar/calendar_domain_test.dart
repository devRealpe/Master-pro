import 'package:flutter_test/flutter_test.dart';
import 'package:master_pro/core/time/dates.dart';
import 'package:master_pro/core/time/deadline_clock.dart';
import 'package:master_pro/features/activities/domain/activity.dart';
import 'package:master_pro/features/calendar/data/study_block_mapper.dart';
import 'package:master_pro/features/calendar/domain/calendar_projector.dart';
import 'package:master_pro/features/calendar/domain/study_block.dart';
import 'package:master_pro/features/classes/domain/class_session.dart';
import 'package:master_pro/features/subjects/domain/period.dart';

import '../../support/pump_app.dart';

void main() {
  initializeTimeZones();

  group('Dates para el calendario', () {
    test('la semana empieza el lunes', () {
      final monday = DateTime(2026, 11, 16);
      expect(Dates.startOfWeek(monday), monday);
      expect(Dates.startOfWeek(DateTime(2026, 11, 18, 15, 30)), monday);
      expect(Dates.startOfWeek(DateTime(2026, 11, 22)), monday);
      expect(Dates.startOfWeek(DateTime(2026, 11, 23)), DateTime(2026, 11, 23));
    });

    test('sumar días cruza meses y años', () {
      expect(Dates.addDays(DateTime(2026, 11, 30), 1), DateTime(2026, 12, 1));
      expect(Dates.addDays(DateTime(2027, 1, 1), -1), DateTime(2026, 12, 31));
      expect(Dates.addDays(DateTime(2027, 3, 27), 2), DateTime(2027, 3, 29));
    });

    test('la cuadrícula del mes son semanas completas de lunes a domingo', () {
      // Noviembre de 2026 empieza en domingo: necesita 6 semanas.
      final november = Dates.monthGrid(DateTime(2026, 11, 16));
      expect(november.first, DateTime(2026, 10, 26));
      expect(november.last, DateTime(2026, 12, 6));
      expect(november, hasLength(42));

      // Febrero de 2027 empieza en lunes y cabe en 4 semanas exactas.
      final february = Dates.monthGrid(DateTime(2027, 2, 10));
      expect(february.first, DateTime(2027, 2, 1));
      expect(february.last, DateTime(2027, 2, 28));
      expect(february, hasLength(28));

      for (final grid in [november, february]) {
        expect(grid.length % 7, 0);
        expect(grid.first.weekday, DateTime.monday);
        expect(grid.last.weekday, DateTime.sunday);
      }
    });

    test('cambiar de mes conserva el día o usa el último del mes', () {
      expect(
        Dates.addMonths(DateTime(2026, 11, 16), 1),
        DateTime(2026, 12, 16),
      );
      expect(Dates.addMonths(DateTime(2027, 1, 31), 1), DateTime(2027, 2, 28));
      expect(
        Dates.addMonths(DateTime(2027, 1, 15), -1),
        DateTime(2026, 12, 15),
      );
      expect(Dates.addMonths(DateTime(2027, 3, 31), -1), DateTime(2027, 2, 28));
    });
  });

  group('Proyección', () {
    final from = DateTime(2026, 11, 16);
    final to = DateTime(2026, 11, 22);

    Map<DateTime, List<CalendarEntry>> project({
      List<Activity> activities = const [],
      List<ClassSession> classes = const [],
      List<StudyBlock> blocks = const [],
      List<Period> periods = const [],
      DateTime? windowFrom,
      DateTime? windowTo,
    }) => CalendarProjector.project(
      from: windowFrom ?? from,
      to: windowTo ?? to,
      toLocal: toBogota,
      activities: activities,
      classSessions: classes,
      studyBlocks: blocks,
      periods: periods,
    );

    Activity dueOn(int day, {int buffer = 1, String id = 'a'}) => Activity(
      id: id,
      title: 'Actividad $id',
      subjectId: 's1',
      dueAt: SpainTime.toInstant(DateTime(2026, 11, day)),
      bufferDays: buffer,
    );

    test('una entrega aparece en el día local de su hora de España', () {
      final days = project(activities: [dueOn(19, buffer: 0)]);

      // 23:59 del 19 en España son las 17:59 del 19 en Colombia.
      final entry = days[DateTime(2026, 11, 19)]!.single;
      expect(entry.kind, CalendarEntryKind.deadline);
      expect(entry.sourceId, 'a');
      expect(entry.subjectId, 's1');
      expect(entry.allDay, isFalse);
      expect(toBogota(entry.startsAt!).hour, 17);
      expect(days.keys, [DateTime(2026, 11, 19)]);
    });

    test('la meta personal aparece el día del colchón', () {
      final days = project(activities: [dueOn(19, buffer: 2)]);

      expect(
        days[DateTime(2026, 11, 17)]!.single.kind,
        CalendarEntryKind.target,
      );
      expect(
        days[DateTime(2026, 11, 19)]!.single.kind,
        CalendarEntryKind.deadline,
      );
    });

    test('una actividad hecha conserva su entrega pero ya no su meta', () {
      final done = dueOn(19).copyWith(status: ActivityStatus.done);
      final days = project(activities: [done]);

      expect(days.keys, [DateTime(2026, 11, 19)]);
      expect(days.values.single.single.done, isTrue);
    });

    test('lo que no tiene fecha o está eliminado no aparece', () {
      final days = project(
        activities: [
          const Activity(id: 'sin fecha', title: 'Lectura'),
          dueOn(19).copyWith(deletedAt: testNow),
        ],
        classes: [
          ClassSession(
            id: 'c',
            subjectId: 's1',
            startsAt: fromBogota(DateTime(2026, 11, 17, 13)),
            deletedAt: testNow,
          ),
        ],
        blocks: [
          StudyBlock(
            id: 'b',
            title: 'Estudio',
            startsAt: fromBogota(DateTime(2026, 11, 17, 19)),
            deletedAt: testNow,
          ),
        ],
      );

      expect(days, isEmpty);
    });

    test('clases y bloques llevan su duración y su asignatura', () {
      final days = project(
        classes: [
          ClassSession(
            id: 'c1',
            subjectId: 's1',
            startsAt: fromBogota(DateTime(2026, 11, 17, 13)),
            topic: 'Tema 1',
            durationMinutes: 90,
            attended: true,
          ),
        ],
        blocks: [
          StudyBlock(
            id: 'b1',
            title: 'Avanzar actividad',
            startsAt: fromBogota(DateTime(2026, 11, 17, 19)),
            durationMinutes: 120,
            subjectId: 's2',
          ),
        ],
      );

      final entries = days[DateTime(2026, 11, 17)]!;
      expect(entries.map((e) => e.kind), [
        CalendarEntryKind.classSession,
        CalendarEntryKind.studyBlock,
      ]);
      expect(entries.first.title, 'Tema 1');
      expect(entries.first.durationMinutes, 90);
      expect(entries.first.done, isTrue);
      expect(entries.last.subjectId, 's2');
      expect(entries.last.durationMinutes, 120);
    });

    test('un instante de madrugada cae en el día local, no en el de UTC', () {
      // 22:00 del 17 en Colombia son las 03:00 del 18 en UTC.
      final days = project(
        blocks: [
          StudyBlock(
            id: 'b',
            title: 'Repaso',
            startsAt: fromBogota(DateTime(2026, 11, 17, 22)),
          ),
        ],
      );
      expect(days.keys, [DateTime(2026, 11, 17)]);
    });

    test('un intervalo de fechas clave aparece en cada uno de sus días', () {
      final period = Period(
        id: 'p1',
        name: 'Periodo',
        startDate: DateTime(2026, 11, 16),
        endDate: DateTime(2027, 3, 21),
        keyDates: [
          KeyDate(
            id: 'k1',
            title: 'Repaso',
            start: DateTime(2026, 11, 20),
            end: DateTime(2026, 11, 25),
            kind: KeyDateKind.review,
          ),
          KeyDate(
            id: 'k2',
            title: 'Inicio de clases',
            start: DateTime(2026, 11, 16),
            kind: KeyDateKind.classes,
            confirmed: true,
          ),
        ],
      );
      final days = project(periods: [period]);

      // El repaso sigue hasta el 25, pero la ventana termina el 22.
      expect(days.keys.toList()..sort(), [
        DateTime(2026, 11, 16),
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 21),
        DateTime(2026, 11, 22),
      ]);
      final review = days[DateTime(2026, 11, 21)]!.single;
      expect(review.allDay, isTrue);
      expect(review.unconfirmed, isTrue);
      expect(review.keyDateKind, KeyDateKind.review);
      expect(review.sourceId, 'p1');
      expect(days[DateTime(2026, 11, 16)]!.single.unconfirmed, isFalse);
    });

    test(
      'un intervalo que empezó antes de la ventana se ve desde su inicio',
      () {
        final period = Period(
          id: 'p1',
          name: 'Periodo',
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2027, 3, 21),
          keyDates: [
            KeyDate(
              id: 'k',
              title: 'Repaso',
              start: DateTime(2026, 11, 10),
              end: DateTime(2026, 11, 17),
            ),
          ],
        );
        final days = project(periods: [period]);

        expect(days.keys.toList()..sort(), [
          DateTime(2026, 11, 16),
          DateTime(2026, 11, 17),
        ]);
      },
    );

    test('nada fuera de la ventana pedida', () {
      final days = project(
        activities: [
          dueOn(15, buffer: 0, id: 'antes'),
          dueOn(23, buffer: 0),
        ],
      );
      expect(days, isEmpty);
    });

    test('en un día, primero lo de todo el día y después por hora', () {
      final period = Period(
        id: 'p1',
        name: 'Periodo',
        startDate: DateTime(2026, 11, 16),
        endDate: DateTime(2027, 3, 21),
        keyDates: [
          KeyDate(id: 'k', title: 'Exámenes', start: DateTime(2026, 11, 19)),
        ],
      );
      final days = project(
        periods: [period],
        activities: [dueOn(19, buffer: 0)],
        classes: [
          ClassSession(
            id: 'c',
            subjectId: 's1',
            startsAt: fromBogota(DateTime(2026, 11, 19, 13)),
          ),
        ],
        blocks: [
          StudyBlock(
            id: 'b',
            title: 'Madrugar',
            startsAt: fromBogota(DateTime(2026, 11, 19, 6)),
          ),
        ],
      );

      expect(days[DateTime(2026, 11, 19)]!.map((e) => e.kind), [
        CalendarEntryKind.keyDate,
        CalendarEntryKind.studyBlock,
        CalendarEntryKind.classSession,
        CalendarEntryKind.deadline,
      ]);
    });
  });

  group('StudyBlock', () {
    final block = StudyBlock(
      id: 'b1',
      title: 'Avanzar actividad 1',
      startsAt: DateTime.utc(2026, 11, 17, 23),
      durationMinutes: 90,
      subjectId: 's1',
      activityId: 'a1',
      notes: 'Notas',
      deletedAt: DateTime.utc(2026, 12, 1),
    );

    test('termina al sumar su duración', () {
      expect(block.endsAt, DateTime.utc(2026, 11, 18, 0, 30));
    });

    test('ida y vuelta por el mapa; sin inicio se descarta', () {
      expect(studyBlockFromMap('b1', studyBlockToMap(block)), block);
      final minimal = StudyBlock(
        id: 'b2',
        title: 'Estudio',
        startsAt: DateTime.utc(2026, 11, 17, 23),
      );
      expect(studyBlockFromMap('b2', studyBlockToMap(minimal)), minimal);
      expect(studyBlockFromMap('x', const {'title': 'Sin hora'}), isNull);
      expect(
        studyBlockFromMap('x', const {
          'startsAt': '2026-11-17T23:00:00.000Z',
          'durationMinutes': -5,
        })!.durationMinutes,
        60,
      );
    });

    test('copyWith puede quitar la asignatura y la actividad', () {
      final cleared = block.copyWith(subjectId: null, activityId: null);
      expect(cleared.subjectId, isNull);
      expect(cleared.activityId, isNull);
      expect(block.copyWith(title: 'Otro').subjectId, 's1');
    });

    test('valida el título y muestra la duración', () {
      expect(StudyBlockRules.title('  '), isNotNull);
      expect(StudyBlockRules.title('Repasar tema 2'), isNull);
      expect(StudyBlockRules.formatDuration(45), '45 min');
      expect(StudyBlockRules.formatDuration(60), '1 h');
      expect(StudyBlockRules.formatDuration(90), '1 h 30 min');
    });
  });
}
