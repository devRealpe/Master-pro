import 'period.dart';

/// Calendario 2026–2027 del máster, tal como se mostró en la sesión de
/// bienvenida con la mentora.
///
/// Todas las fechas entran **sin confirmar**: en esa sesión una diapositiva
/// traía fechas cruzadas, así que hay que validarlas contra el PDF oficial
/// (Aula de Información General → Otros accesos → Calendario Académico).
///
/// El fin de clases del 2.º cuatrimestre no se dijo de forma explícita; se
/// usa el 31 de julio porque agosto figura como no lectivo.
List<Period> unirCalendar2026({required String Function() newId}) {
  KeyDate date(
    String title,
    DateTime start, {
    DateTime? end,
    required KeyDateKind kind,
    String note = '',
  }) => KeyDate(
    id: newId(),
    title: title,
    start: start,
    end: end,
    kind: kind,
    note: note,
  );

  return [
    Period(
      id: newId(),
      name: '1.er cuatrimestre 2026–2027',
      startDate: DateTime(2026, 11, 16),
      endDate: DateTime(2027, 3, 21),
      datesConfirmed: false,
      keyDates: [
        date(
          'Inicio de clases',
          DateTime(2026, 11, 16),
          kind: KeyDateKind.classes,
        ),
        date(
          'Periodo de repaso',
          DateTime(2026, 12, 21),
          end: DateTime(2027, 1, 10),
          kind: KeyDateKind.review,
        ),
        date(
          'Repaso antes de exámenes',
          DateTime(2027, 3, 22),
          end: DateTime(2027, 4, 4),
          kind: KeyDateKind.review,
        ),
        date(
          'Exámenes',
          DateTime(2027, 4, 9),
          end: DateTime(2027, 4, 11),
          kind: KeyDateKind.exams,
          note: 'Presenciales de viernes a domingo; en línea hay 6 días.',
        ),
      ],
    ),
    Period(
      id: newId(),
      name: '2.º cuatrimestre 2026–2027',
      startDate: DateTime(2027, 4, 19),
      endDate: DateTime(2027, 7, 31),
      datesConfirmed: false,
      keyDates: [
        date(
          'Inicio de clases',
          DateTime(2027, 4, 19),
          kind: KeyDateKind.classes,
        ),
        date(
          'Informe final de prácticas',
          DateTime(2027, 7, 29),
          kind: KeyDateKind.delivery,
          note: 'Solo si tienes prácticas inscritas.',
        ),
        date(
          'Agosto no lectivo',
          DateTime(2027, 8, 1),
          end: DateTime(2027, 8, 31),
          kind: KeyDateKind.nonTeaching,
        ),
        date(
          'Exámenes',
          DateTime(2027, 9, 10),
          end: DateTime(2027, 9, 12),
          kind: KeyDateKind.exams,
        ),
        date(
          'Entrega del TFM (ordinaria)',
          DateTime(2027, 9, 22),
          kind: KeyDateKind.delivery,
        ),
        date(
          'Exámenes extraordinarios',
          DateTime(2027, 10, 8),
          end: DateTime(2027, 10, 10),
          kind: KeyDateKind.exams,
        ),
        date(
          'Entrega del TFM (extraordinaria)',
          DateTime(2027, 10, 20),
          kind: KeyDateKind.delivery,
        ),
      ],
    ),
  ];
}
