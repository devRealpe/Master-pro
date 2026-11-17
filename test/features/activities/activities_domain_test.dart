import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:master_pro/core/time/deadline_clock.dart';
import 'package:master_pro/features/activities/data/activity_mapper.dart';
import 'package:master_pro/features/activities/domain/activity.dart';

import '../../support/pump_app.dart';

void main() {
  initializeTimeZones();
  setUpAll(() => initializeDateFormatting('es'));

  group('Hora de España', () {
    test('en invierno las 23:59 de España son las 17:59 de Colombia', () {
      // Ejercicio de la guía de bienvenida: entrega del 25 de enero.
      final due = SpainTime.toInstant(DateTime(2027, 1, 25));
      expect(due, DateTime.utc(2027, 1, 25, 22, 59));
      expect(toBogota(due).hour, 17);
      expect(toBogota(due).minute, 59);
      expect(toBogota(due).day, 25);
    });

    test('en verano son las 16:59 de Colombia', () {
      // Ejercicio de la guía de bienvenida: entrega del 10 de mayo.
      final due = SpainTime.toInstant(DateTime(2027, 5, 10));
      expect(due, DateTime.utc(2027, 5, 10, 21, 59));
      expect(toBogota(due).hour, 16);
    });

    test('el cambio ocurre el 28 de marzo de 2027', () {
      expect(
        SpainTime.toInstant(DateTime(2027, 3, 27)),
        DateTime.utc(2027, 3, 27, 22, 59),
      );
      expect(
        SpainTime.toInstant(DateTime(2027, 3, 28)),
        DateTime.utc(2027, 3, 28, 21, 59),
      );
    });

    test('ida y vuelta: del instante se recupera la hora de pared', () {
      for (final date in [DateTime(2027, 1, 25), DateTime(2027, 7, 1)]) {
        final instant = SpainTime.toInstant(date, hour: 9, minute: 30);
        expect(
          SpainTime.wallTime(instant),
          DateTime(date.year, date.month, date.day, 9, 30),
        );
      }
    });

    test('una fecha en «mi hora» no pasa por España', () {
      final instant = deadlineInstant(
        date: DateTime(2027, 1, 25),
        hour: 8,
        minute: 0,
        zone: DeadlineZone.local,
      );
      expect(instant.toLocal(), DateTime(2027, 1, 25, 8));
      expect(
        deadlineInstant(
          date: DateTime(2027, 1, 25),
          hour: 23,
          minute: 59,
          zone: DeadlineZone.spain,
        ),
        DateTime.utc(2027, 1, 25, 22, 59),
      );
    });
  });

  group('Textos de la fecha límite', () {
    final due = SpainTime.toInstant(DateTime(2027, 1, 25));

    test('muestra tu hora y la de España', () {
      expect(DeadlineText.local(due, toLocal: toBogota), 'lun 25 ene, 17:59');
      expect(DeadlineText.spain(due, toLocal: toBogota), '23:59 España');
    });

    test('avisa cuando en España ya es otro día', () {
      // 21:00 del 25 en Colombia son las 03:00 del 26 en España.
      final late = DateTime.utc(2027, 1, 26, 2);
      expect(
        DeadlineText.spain(late, toLocal: toBogota),
        '03:00 del 26 ene en España',
      );
    });

    test('cuenta lo que falta en días de calendario', () {
      String at(DateTime instant) =>
          DeadlineText.countdown(instant, now: testNow, toLocal: toBogota);

      expect(at(SpainTime.toInstant(DateTime(2026, 11, 16))), 'Vence hoy');
      expect(at(SpainTime.toInstant(DateTime(2026, 11, 17))), 'Vence mañana');
      expect(at(SpainTime.toInstant(DateTime(2026, 11, 19))), 'Faltan 3 días');
      expect(at(SpainTime.toInstant(DateTime(2026, 11, 15))), 'Venció ayer');
      expect(
        at(SpainTime.toInstant(DateTime(2026, 11, 10))),
        'Venció hace 6 días',
      );
      // Venció hoy mismo, hace una hora.
      expect(at(testNow.subtract(const Duration(hours: 1))), 'Venció hoy');
    });
  });

  group('Activity', () {
    Activity dueOn(int day, {int buffer = 1}) => Activity(
      id: 'a$day',
      title: 'Actividad',
      dueAt: SpainTime.toInstant(DateTime(2026, 11, day)),
      bufferDays: buffer,
    );

    Urgency urgencyOf(Activity a) => a.urgency(testNow, toLocal: toBogota);

    test('la fecha objetivo es la límite menos el colchón', () {
      expect(dueOn(19).targetAt, SpainTime.toInstant(DateTime(2026, 11, 18)));
      expect(dueOn(19, buffer: 0).targetAt, dueOn(19).dueAt);
      expect(const Activity(id: 'x', title: 'x').targetAt, isNull);
    });

    test('la urgencia se mide contra la fecha objetivo', () {
      expect(urgencyOf(dueOn(15)), Urgency.overdue);
      // Vence mañana, pero la meta (colchón de 1 día) es hoy.
      expect(urgencyOf(dueOn(17)), Urgency.today);
      expect(urgencyOf(dueOn(17, buffer: 0)), Urgency.thisWeek);
      expect(urgencyOf(dueOn(24)), Urgency.thisWeek);
      expect(urgencyOf(dueOn(25)), Urgency.later);
      expect(urgencyOf(const Activity(id: 'x', title: 'x')), Urgency.noDate);
    });

    test('la meta ya pasó pero la límite no: sigue siendo «para hoy»', () {
      // Vence hoy a las 17:59 de Colombia; la meta era ayer.
      final activity = dueOn(16);
      expect(activity.isOverdue(testNow), isFalse);
      expect(urgencyOf(activity), Urgency.today);
    });

    test('vencida solo si no está hecha', () {
      final late = dueOn(15);
      expect(late.isOverdue(testNow), isTrue);
      expect(
        late.copyWith(status: ActivityStatus.done).isOverdue(testNow),
        isFalse,
      );
      expect(late.submit(testNow).isOverdue(testNow), isFalse);
    });

    test('entregar cierra el flujo y registra el momento', () {
      final submitted = dueOn(19).submit(testNow);
      expect(submitted.isSubmitted, isTrue);
      expect(submitted.isDone, isTrue);
      expect(submitted.status, ActivityStatus.done);
      expect(submitted.submittedAt, testNow);
      expect(submitted.submittedLate, isFalse);
      expect(dueOn(15).submit(testNow).submittedLate, isTrue);
    });

    test('deshacer la entrega la devuelve a «En progreso»', () {
      final back = dueOn(19).submit(testNow).unsubmit();
      expect(back.isSubmitted, isFalse);
      expect(back.isDone, isFalse);
      expect(back.status, ActivityStatus.inProgress);
    });

    test('el avance sale de los pasos', () {
      var activity = const Activity(id: 'a', title: 'a');
      expect(activity.progress, 0);

      activity = activity
          .withSubtask(const Subtask(id: '1', title: 'Uno'))
          .withSubtask(const Subtask(id: '2', title: 'Dos'))
          .toggleSubtask('1');
      expect(activity.subtasksDone, 1);
      expect(activity.progress, 0.5);

      expect(activity.toggleSubtask('1').progress, 0);
      expect(activity.withoutSubtask('2').progress, 1);
      expect(activity.copyWith(status: ActivityStatus.done).progress, 1);
    });

    test('copyWith puede vaciar la fecha y la asignatura', () {
      final activity = dueOn(19).copyWith(subjectId: 's1', estimateMinutes: 90);
      final cleared = activity.copyWith(
        dueAt: null,
        subjectId: null,
        estimateMinutes: null,
      );
      expect(cleared.dueAt, isNull);
      expect(cleared.subjectId, isNull);
      expect(cleared.estimateMinutes, isNull);
      expect(activity.copyWith(title: 'Otra').dueAt, activity.dueAt);
    });

    test('ordena por fecha objetivo, luego prioridad; sin fecha al final', () {
      final sorted = sortActivities([
        const Activity(id: '1', title: 'Sin fecha'),
        dueOn(25).copyWith(title: 'Lejana'),
        dueOn(18).copyWith(title: 'Media'),
        dueOn(18).copyWith(title: 'Urgente', priority: ActivityPriority.urgent),
        // Vence el 19 pero con 3 días de colchón: su meta es antes.
        dueOn(19, buffer: 3).copyWith(title: 'Con colchón'),
      ]);
      expect(
        [for (final a in sorted) a.title],
        ['Con colchón', 'Urgente', 'Media', 'Lejana', 'Sin fecha'],
      );
    });
  });

  group('ActivityFilter', () {
    const pending = Activity(id: '1', title: 'a', subjectId: 's1');
    const done = Activity(
      id: '2',
      title: 'b',
      subjectId: 's2',
      type: ActivityType.test,
      status: ActivityStatus.done,
      priority: ActivityPriority.high,
    );

    test('separa por hacer y hechas', () {
      expect(const ActivityFilter().matches(pending), isTrue);
      expect(const ActivityFilter().matches(done), isFalse);
      expect(const ActivityFilter(showDone: true).matches(done), isTrue);
    });

    test('combina asignatura, tipo y prioridad', () {
      const filter = ActivityFilter(
        showDone: true,
        subjectId: 's2',
        type: ActivityType.test,
        priority: ActivityPriority.high,
      );
      expect(filter.matches(done), isTrue);
      expect(filter.extraCount, 2);
      expect(filter.copyWith(subjectId: 's1').matches(done), isFalse);
      expect(filter.copyWith(type: ActivityType.work).matches(done), isFalse);
      expect(filter.copyWith(type: null, priority: null).extraCount, 0);
    });
  });

  group('Reglas', () {
    test('título obligatorio y acotado', () {
      expect(ActivityRules.title('  '), isNotNull);
      expect(ActivityRules.title('a' * 121), isNotNull);
      expect(ActivityRules.title('Actividad 1'), isNull);
    });

    test('lee el tiempo estimado en horas con coma o punto', () {
      expect(ActivityRules.estimate(''), (valid: true, minutes: null));
      expect(ActivityRules.estimate('1,5'), (valid: true, minutes: 90));
      expect(ActivityRules.estimate('2'), (valid: true, minutes: 120));
      expect(ActivityRules.estimate('0.25'), (valid: true, minutes: 15));
      expect(ActivityRules.estimate('abc').valid, isFalse);
      expect(ActivityRules.estimate('0').valid, isFalse);
      expect(ActivityRules.estimate('-1').valid, isFalse);
    });

    test('muestra el tiempo estimado', () {
      expect(ActivityRules.formatEstimate(45), '45 min');
      expect(ActivityRules.formatEstimate(90), '1,5 h');
      expect(ActivityRules.formatEstimate(120), '2 h');
    });
  });

  group('Mapeo', () {
    final full = Activity(
      id: 'a1',
      title: 'Actividad 1',
      description: 'Descripción',
      notes: 'Notas',
      subjectId: 's1',
      type: ActivityType.project,
      status: ActivityStatus.inReview,
      priority: ActivityPriority.urgent,
      dueAt: SpainTime.toInstant(DateTime(2027, 1, 25)),
      dueZone: DeadlineZone.local,
      bufferDays: 2,
      submittedAt: DateTime.utc(2027, 1, 24, 15),
      estimateMinutes: 180,
      subtasks: const [
        Subtask(id: '1', title: 'Uno', done: true),
        Subtask(id: '2', title: 'Dos'),
      ],
      deletedAt: DateTime.utc(2027, 2, 1),
    );

    test('ida y vuelta sin pérdidas', () {
      expect(activityFromMap('a1', activityToMap(full)), full);
      const minimal = Activity(id: 'a2', title: 'Mínima');
      expect(activityFromMap('a2', activityToMap(minimal)), minimal);
    });

    test('los instantes se guardan en UTC y ordenan como el tiempo', () {
      final map = activityToMap(full);
      expect(map['dueAt'], '2027-01-25T22:59:00.000Z');
      expect(
        activityToMap(const Activity(id: 'x', title: 'x'))['dueAt'],
        isNull,
      );
    });

    test('lo que falta o no se reconoce toma su valor por omisión', () {
      final read = activityFromMap('a9', const {
        'title': 'Solo título',
        'type': 'inventado',
        'status': 7,
        'bufferDays': 99,
        'estimateMinutes': -5,
        'dueAt': 'no es una fecha',
        'subtasks': [
          {'id': '1', 'title': 'Buena', 'done': true},
          {'title': 'Sin id'},
          'texto suelto',
        ],
      });
      expect(read.type, ActivityType.work);
      expect(read.status, ActivityStatus.backlog);
      expect(read.bufferDays, Activity.defaultBufferDays);
      expect(read.estimateMinutes, isNull);
      expect(read.dueAt, isNull);
      expect(read.dueZone, DeadlineZone.spain);
      expect(read.subtasks, const [
        Subtask(id: '1', title: 'Buena', done: true),
      ]);
    });
  });
}
