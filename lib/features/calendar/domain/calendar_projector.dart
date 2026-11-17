import '../../../core/time/dates.dart';
import '../../activities/domain/activity.dart';
import '../../classes/domain/class_session.dart';
import '../../subjects/domain/period.dart';
import 'study_block.dart';

enum CalendarEntryKind {
  deadline('Entrega'),
  target('Meta'),
  classSession('Clase'),
  studyBlock('Estudio'),
  keyDate('Fecha clave');

  const CalendarEntryKind(this.label);

  final String label;
}

/// Algo que aparece en el calendario. No es un dato guardado: es la vista de
/// una actividad, una clase, un bloque de estudio o una fecha clave, y
/// [sourceId] lleva a su origen.
class CalendarEntry {
  const CalendarEntry({
    required this.kind,
    required this.sourceId,
    required this.title,
    required this.day,
    this.startsAt,
    this.durationMinutes,
    this.subjectId,
    this.done = false,
    this.unconfirmed = false,
    this.keyDateKind,
    this.note = '',
  });

  final CalendarEntryKind kind;

  /// Identificador de la actividad, clase, bloque o periodo de origen.
  final String sourceId;
  final String title;

  /// Día del dispositivo en que aparece.
  final DateTime day;

  /// Instante de inicio. `null` en lo que dura todo el día.
  final DateTime? startsAt;
  final int? durationMinutes;
  final String? subjectId;

  /// Entregada, finalizada o con asistencia registrada.
  final bool done;

  /// Fecha de plantilla aún sin validar contra el calendario oficial.
  final bool unconfirmed;
  final KeyDateKind? keyDateKind;
  final String note;

  bool get allDay => startsAt == null;
}

/// Convierte los datos de la app en entradas de calendario.
///
/// Así una fecha solo vive en un sitio: la entrega en su actividad, la clase
/// en su registro. El calendario nunca guarda una copia.
abstract final class CalendarProjector {
  /// Entradas de los días entre [from] y [to] (inclusive), por día.
  ///
  /// Los instantes se ubican en el día que les corresponde en la hora del
  /// dispositivo ([toLocal]): una entrega a las 23:59 de España aparece el
  /// mismo día a las 17:59 en Colombia.
  static Map<DateTime, List<CalendarEntry>> project({
    required DateTime from,
    required DateTime to,
    required DateTime Function(DateTime) toLocal,
    Iterable<Activity> activities = const [],
    Iterable<ClassSession> classSessions = const [],
    Iterable<StudyBlock> studyBlocks = const [],
    Iterable<Period> periods = const [],
  }) {
    final first = Dates.dateOnly(from);
    final last = Dates.dateOnly(to);
    final byDay = <DateTime, List<CalendarEntry>>{};

    bool inWindow(DateTime day) => !day.isBefore(first) && !day.isAfter(last);

    void add(CalendarEntry entry) {
      if (inWindow(entry.day)) (byDay[entry.day] ??= []).add(entry);
    }

    DateTime dayOf(DateTime instant) => Dates.dateOnly(toLocal(instant));

    for (final activity in activities) {
      final due = activity.dueAt;
      if (activity.isDeleted || due == null) continue;
      add(
        CalendarEntry(
          kind: CalendarEntryKind.deadline,
          sourceId: activity.id,
          title: activity.title,
          day: dayOf(due),
          startsAt: due,
          subjectId: activity.subjectId,
          done: activity.isDone,
        ),
      );
      // La meta personal solo interesa mientras la actividad está abierta.
      final target = activity.targetAt;
      if (target != null && activity.bufferDays > 0 && !activity.isDone) {
        add(
          CalendarEntry(
            kind: CalendarEntryKind.target,
            sourceId: activity.id,
            title: activity.title,
            day: dayOf(target),
            startsAt: target,
            subjectId: activity.subjectId,
          ),
        );
      }
    }

    for (final session in classSessions) {
      if (session.isDeleted) continue;
      add(
        CalendarEntry(
          kind: CalendarEntryKind.classSession,
          sourceId: session.id,
          title: session.label,
          day: dayOf(session.startsAt),
          startsAt: session.startsAt,
          durationMinutes: session.durationMinutes,
          subjectId: session.subjectId,
          done: session.attended == true,
        ),
      );
    }

    for (final block in studyBlocks) {
      if (block.isDeleted) continue;
      add(
        CalendarEntry(
          kind: CalendarEntryKind.studyBlock,
          sourceId: block.id,
          title: block.title,
          day: dayOf(block.startsAt),
          startsAt: block.startsAt,
          durationMinutes: block.durationMinutes,
          subjectId: block.subjectId,
        ),
      );
    }

    for (final period in periods) {
      if (period.isDeleted) continue;
      for (final date in period.keyDates) {
        // Un intervalo (repaso, exámenes) aparece en cada uno de sus días,
        // pero solo se recorren los que caen en la ventana pedida.
        final start = date.start.isBefore(first) ? first : date.start;
        final rawEnd = date.end ?? date.start;
        final end = rawEnd.isAfter(last) ? last : rawEnd;
        for (
          var day = Dates.dateOnly(start);
          !day.isAfter(end);
          day = Dates.addDays(day, 1)
        ) {
          add(
            CalendarEntry(
              kind: CalendarEntryKind.keyDate,
              sourceId: period.id,
              title: date.title,
              day: day,
              unconfirmed: !date.confirmed,
              keyDateKind: date.kind,
              note: date.note,
            ),
          );
        }
      }
    }

    for (final entries in byDay.values) {
      entries.sort(_compare);
    }
    return byDay;
  }

  /// Primero lo de todo el día; después, por hora; a igual hora, por tipo.
  static int _compare(CalendarEntry a, CalendarEntry b) {
    final sa = a.startsAt;
    final sb = b.startsAt;
    if (sa == null && sb != null) return -1;
    if (sa != null && sb == null) return 1;
    if (sa != null && sb != null) {
      final byTime = sa.compareTo(sb);
      if (byTime != 0) return byTime;
    }
    final byKind = a.kind.index.compareTo(b.kind.index);
    if (byKind != 0) return byKind;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
}
