import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:master_pro/core/data/entity_repository.dart';
import 'package:master_pro/core/time/dates.dart';
import 'package:master_pro/features/subjects/data/subject_mappers.dart';
import 'package:master_pro/features/subjects/domain/period.dart';
import 'package:master_pro/features/subjects/domain/subject.dart';
import 'package:master_pro/features/subjects/domain/unir_calendar.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('Dates', () {
    test('lee y escribe aaaa-mm-dd', () {
      expect(Dates.toIso(DateTime(2026, 11, 16)), '2026-11-16');
      expect(Dates.fromIso('2027-03-21'), DateTime(2027, 3, 21));
      expect(Dates.toIso(null), isNull);
    });

    test('rechaza lo que no es una fecha real', () {
      expect(Dates.fromIso('2027-02-31'), isNull);
      expect(Dates.fromIso('2027-13-01'), isNull);
      expect(Dates.fromIso('21/03/2027'), isNull);
      expect(Dates.fromIso(''), isNull);
      expect(Dates.fromIso(20270321), isNull);
      expect(Dates.fromIso(null), isNull);
    });

    test('cuenta días de calendario aunque cambie la hora en medio', () {
      // El 28 de marzo de 2027 España pasa al horario de verano.
      expect(
        Dates.daysBetween(DateTime(2027, 3, 27), DateTime(2027, 3, 29)),
        2,
      );
      expect(
        Dates.daysBetween(DateTime(2026, 11, 16), DateTime(2027, 3, 21)),
        125,
      );
      expect(
        Dates.daysBetween(DateTime(2027, 3, 21), DateTime(2026, 11, 16)),
        -125,
      );
    });

    test('formatea fechas e intervalos en español', () {
      expect(Dates.format(DateTime(2026, 11, 16)), '16 nov 2026');
      expect(
        Dates.formatRange(DateTime(2027, 4, 9), DateTime(2027, 4, 11)),
        '9 – 11 abr 2027',
      );
      expect(
        Dates.formatRange(DateTime(2027, 4, 19), DateTime(2027, 7, 31)),
        '19 abr – 31 jul 2027',
      );
      expect(
        Dates.formatRange(DateTime(2026, 11, 16), DateTime(2027, 3, 21)),
        '16 nov 2026 – 21 mar 2027',
      );
      expect(Dates.formatRange(DateTime(2027, 9, 22), null), '22 sept 2027');
    });
  });

  group('Subject', () {
    final subject = Subject(
      id: 's1',
      name: 'Asignatura 1',
      periodId: 'p1',
      startDate: DateTime(2026, 11, 16),
      endDate: DateTime(2027, 3, 21),
    );

    test('calcula la parte del periodo transcurrida', () {
      expect(subject.progressOn(DateTime(2026, 11, 16)), 0);
      expect(subject.progressOn(DateTime(2027, 3, 21)), 1);
      expect(
        subject.progressOn(DateTime(2026, 12, 11)),
        closeTo(25 / 125, 1e-9),
      );
    });

    test('el avance no baja de 0 ni pasa de 1', () {
      expect(subject.progressOn(DateTime(2026, 1, 1)), 0);
      expect(subject.progressOn(DateTime(2028, 1, 1)), 1);
    });

    test('sin fechas, o con fechas que no forman intervalo, no hay avance', () {
      final today = DateTime(2026, 12, 1);
      expect(const Subject(id: 'x', name: 'x').progressOn(today), isNull);
      expect(subject.copyWith(endDate: null).progressOn(today), isNull);
      expect(
        subject.copyWith(endDate: subject.startDate).progressOn(today),
        isNull,
      );
    });

    test('copyWith distingue «no cambiar» de «dejar vacío»', () {
      final renamed = subject.copyWith(name: 'Otra');
      expect(renamed.periodId, 'p1');
      expect(renamed.startDate, subject.startDate);

      final cleared = subject.copyWith(periodId: null, startDate: null);
      expect(cleared.periodId, isNull);
      expect(cleared.startDate, isNull);
      expect(cleared.endDate, subject.endDate);
    });

    test('valida el nombre', () {
      expect(SubjectRules.name('   '), isNotNull);
      expect(SubjectRules.name('a' * 81), isNotNull);
      expect(SubjectRules.name('a' * 80), isNull);
      expect(SubjectRules.name('Asignatura 1'), isNull);
    });

    test('valida que el fin no sea anterior al inicio', () {
      final start = DateTime(2027, 1, 10);
      expect(SubjectRules.dates(start, DateTime(2027, 1, 9)), isNotNull);
      expect(SubjectRules.dates(start, start), isNull);
      expect(SubjectRules.dates(start, null), isNull);
      expect(SubjectRules.dates(null, null), isNull);
    });

    test('ordena: en curso, próximas y finalizadas; luego por nombre', () {
      final sorted = sortSubjects(const [
        Subject(id: '1', name: 'Zeta', status: SubjectStatus.finished),
        Subject(id: '2', name: 'beta'),
        Subject(id: '3', name: 'Gamma', status: SubjectStatus.planned),
        Subject(id: '4', name: 'Alfa'),
      ]);
      expect(
        [for (final s in sorted) s.name],
        ['Alfa', 'beta', 'Gamma', 'Zeta'],
      );
    });
  });

  group('Mapeo de asignaturas', () {
    final subject = Subject(
      id: 's1',
      name: 'Asignatura 1',
      teacher: 'Docente de prueba',
      description: 'Descripción',
      periodId: 'p1',
      startDate: DateTime(2026, 11, 16),
      endDate: DateTime(2027, 3, 21),
      status: SubjectStatus.finished,
      colorIndex: 3,
      deletedAt: DateTime.utc(2027, 1, 2, 3, 4, 5),
    );

    test('ida y vuelta sin pérdidas', () {
      expect(subjectFromMap('s1', subjectToMap(subject)), subject);
      const minimal = Subject(id: 's2', name: 'Mínima');
      expect(subjectFromMap('s2', subjectToMap(minimal)), minimal);
    });

    test('guarda las fechas como texto y los vacíos como null', () {
      final map = subjectToMap(const Subject(id: 's2', name: 'Mínima'));
      expect(map['startDate'], isNull);
      expect(map['deletedAt'], isNull);
      expect(map.containsKey('deletedAt'), isTrue);
      expect(subjectToMap(subject)['startDate'], '2026-11-16');
      expect(subjectToMap(subject)['status'], 'finished');
    });

    test('un documento incompleto o con valores raros no rompe la lectura', () {
      final read = subjectFromMap('s9', {
        'name': 'Solo nombre',
        'status': 'inventado',
        'colorIndex': 'azul',
        'startDate': '2027-02-31',
        'periodId': 42,
      });
      expect(read.name, 'Solo nombre');
      expect(read.status, SubjectStatus.active);
      expect(read.colorIndex, 0);
      expect(read.startDate, isNull);
      expect(read.periodId, isNull);
      expect(subjectFromMap('vacío', const {}).name, '');
    });
  });

  group('changedFields', () {
    test('devuelve solo lo que cambió', () {
      final before = subjectToMap(const Subject(id: 's', name: 'A'));
      final after = subjectToMap(
        const Subject(id: 's', name: 'B', status: SubjectStatus.finished),
      );
      expect(changedFields(before, after), {'name': 'B', 'status': 'finished'});
      expect(changedFields(before, before), isEmpty);
    });

    test('detecta cambios dentro de listas y el paso a null', () {
      expect(
        changedFields(
          {
            'a': [
              {'x': 1},
            ],
            'b': 'texto',
          },
          {
            'a': [
              {'x': 2},
            ],
            'b': null,
          },
        ),
        {
          'a': [
            {'x': 2},
          ],
          'b': null,
        },
      );
    });
  });

  group('Period', () {
    var next = 0;
    final periods = unirCalendar2026(newId: () => 'k${next++}');
    final first = periods.first;

    test('la plantilla de UNIR entra completa y sin confirmar', () {
      expect(periods, hasLength(2));
      expect(first.startDate, DateTime(2026, 11, 16));
      expect(first.endDate, DateTime(2027, 3, 21));
      expect(periods.last.startDate, DateTime(2027, 4, 19));
      for (final period in periods) {
        expect(period.datesConfirmed, isFalse, reason: period.name);
        expect(PeriodRules.dates(period.startDate, period.endDate), isNull);
        for (final date in period.keyDates) {
          expect(date.confirmed, isFalse, reason: date.title);
          final end = date.end;
          if (end != null) {
            expect(end.isAfter(date.start), isTrue, reason: date.title);
          }
        }
      }
    });

    test('la plantilla no repite identificadores', () {
      final ids = [
        for (final period in periods) ...[
          period.id,
          for (final date in period.keyDates) date.id,
        ],
      ];
      expect(ids.toSet(), hasLength(ids.length));
    });

    test(
      'incluye las fechas de examen y de TFM de la sesión de bienvenida',
      () {
        KeyDate find(Period period, String title) =>
            period.keyDates.firstWhere((d) => d.title == title);

        final exams = find(first, 'Exámenes');
        expect(exams.start, DateTime(2027, 4, 9));
        expect(exams.end, DateTime(2027, 4, 11));
        expect(
          find(periods.last, 'Entrega del TFM (ordinaria)').start,
          DateTime(2027, 9, 22),
        );
        expect(
          find(periods.last, 'Exámenes extraordinarios').start,
          DateTime(2027, 10, 8),
        );
      },
    );

    test('cuenta lo que falta por confirmar', () {
      expect(first.pendingConfirmations, 1 + first.keyDates.length);

      final dateId = first.keyDates.first.id;
      final confirmed = first
          .copyWith(datesConfirmed: true)
          .withKeyDateConfirmed(dateId, confirmed: true);
      expect(confirmed.pendingConfirmations, first.keyDates.length - 1);
      expect(confirmed.keyDates.first.confirmed, isTrue);
      expect(confirmed.keyDates[1].confirmed, isFalse);
    });

    test('ida y vuelta por el mapa sin pérdidas', () {
      for (final period in periods) {
        expect(periodFromMap(period.id, periodToMap(period)), period);
      }
    });

    test('un periodo sin fechas válidas se descarta', () {
      expect(periodFromMap('p', const {'name': 'Sin fechas'}), isNull);
      expect(
        periodFromMap('p', const {
          'name': 'Mal',
          'startDate': '2027-99-99',
          'endDate': '2027-01-01',
        }),
        isNull,
      );
    });

    test('una fecha clave ilegible se omite sin perder las demás', () {
      final read = periodFromMap('p', const {
        'name': 'Periodo',
        'startDate': '2027-01-01',
        'endDate': '2027-06-30',
        'keyDates': [
          {'id': 'a', 'title': 'Buena', 'start': '2027-02-01', 'kind': 'exams'},
          {'title': 'Sin id', 'start': '2027-02-01'},
          {'id': 'c', 'title': 'Sin fecha'},
          'texto suelto',
        ],
      });
      expect(read!.keyDates, hasLength(1));
      expect(read.keyDates.single.kind, KeyDateKind.exams);
      expect(read.datesConfirmed, isTrue);
    });

    test('valida nombre y fechas', () {
      expect(PeriodRules.name(''), isNotNull);
      expect(PeriodRules.name('1.er cuatrimestre'), isNull);
      final day = DateTime(2027, 1, 1);
      expect(PeriodRules.dates(null, day), isNotNull);
      expect(PeriodRules.dates(day, day), isNotNull);
      expect(PeriodRules.dates(day, DateTime(2027, 1, 2)), isNull);
    });
  });
}
