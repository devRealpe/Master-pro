import '../../../core/time/dates.dart';
import '../../grades/domain/grading_scheme.dart';
import '../domain/period.dart';
import '../domain/subject.dart';

/// Conversión entre las entidades y los documentos de Firestore.
///
/// Las fechas sin hora se guardan como `aaaa-mm-dd`; `deletedAt`, como
/// instante ISO en UTC. La lectura es tolerante: un campo ausente o con un
/// valor desconocido toma su valor por omisión en vez de romper la lista.

const _schemaVersion = 1;

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

String _text(Object? value) => value is String ? value : '';

DateTime? _instant(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

Map<String, Object?> gradingToMap(GradingScheme scheme) => {
  'scaleMax': scheme.scaleMax,
  'pointsGoal': scheme.pointsGoal,
  'attendancePoints': scheme.attendancePoints,
  'testPoints': scheme.testPoints,
  'continuousWeight': scheme.continuousWeight,
  'examWeight': scheme.examWeight,
  'confirmed': scheme.confirmed,
};

/// Lee las reglas de evaluación. Lo que falta o no es válido toma el valor de
/// la plantilla de UNIR; un documento sin reglas las recibe completas.
GradingScheme gradingFromMap(Object? value) {
  if (value is! Map) return GradingScheme.unir;
  double read(String key, double fallback, {bool positive = false}) {
    final raw = value[key];
    if (raw is! num || raw < 0 || (positive && raw <= 0)) return fallback;
    return raw.toDouble();
  }

  const base = GradingScheme.unir;
  return GradingScheme(
    scaleMax: read('scaleMax', base.scaleMax, positive: true),
    pointsGoal: read('pointsGoal', base.pointsGoal),
    attendancePoints: read('attendancePoints', base.attendancePoints),
    testPoints: read('testPoints', base.testPoints),
    continuousWeight: read('continuousWeight', base.continuousWeight),
    examWeight: read('examWeight', base.examWeight),
    confirmed: value['confirmed'] == true,
  );
}

Map<String, Object?> subjectToMap(Subject subject) => {
  'name': subject.name,
  'teacher': subject.teacher,
  'description': subject.description,
  'periodId': subject.periodId,
  'startDate': Dates.toIso(subject.startDate),
  'endDate': Dates.toIso(subject.endDate),
  'status': subject.status.name,
  'colorIndex': subject.colorIndex,
  'grading': gradingToMap(subject.grading),
  'deletedAt': subject.deletedAt?.toUtc().toIso8601String(),
  'schemaVersion': _schemaVersion,
};

Subject subjectFromMap(String id, Map<String, Object?> map) => Subject(
  id: id,
  name: _text(map['name']),
  teacher: _text(map['teacher']),
  description: _text(map['description']),
  periodId: map['periodId'] is String ? map['periodId']! as String : null,
  startDate: Dates.fromIso(map['startDate']),
  endDate: Dates.fromIso(map['endDate']),
  status: _enumByName(
    SubjectStatus.values,
    map['status'],
    SubjectStatus.active,
  ),
  colorIndex: map['colorIndex'] is int ? map['colorIndex']! as int : 0,
  grading: gradingFromMap(map['grading']),
  deletedAt: _instant(map['deletedAt']),
);

Map<String, Object?> _keyDateToMap(KeyDate date) => {
  'id': date.id,
  'title': date.title,
  'start': Dates.toIso(date.start),
  'end': Dates.toIso(date.end),
  'kind': date.kind.name,
  'confirmed': date.confirmed,
  'note': date.note,
};

KeyDate? _keyDateFromMap(Object? value) {
  if (value is! Map) return null;
  final start = Dates.fromIso(value['start']);
  final id = value['id'];
  // Una fecha clave sin identificador o sin fecha no se puede mostrar ni
  // confirmar: se descarta.
  if (start == null || id is! String) return null;
  return KeyDate(
    id: id,
    title: _text(value['title']),
    start: start,
    end: Dates.fromIso(value['end']),
    kind: _enumByName(KeyDateKind.values, value['kind'], KeyDateKind.other),
    confirmed: value['confirmed'] == true,
    note: _text(value['note']),
  );
}

Map<String, Object?> periodToMap(Period period) => {
  'name': period.name,
  'startDate': Dates.toIso(period.startDate),
  'endDate': Dates.toIso(period.endDate),
  'datesConfirmed': period.datesConfirmed,
  'keyDates': [for (final date in period.keyDates) _keyDateToMap(date)],
  'deletedAt': period.deletedAt?.toUtc().toIso8601String(),
  'schemaVersion': _schemaVersion,
};

/// Devuelve `null` si el documento no tiene fechas válidas: un periodo sin
/// fechas no se puede representar.
Period? periodFromMap(String id, Map<String, Object?> map) {
  final start = Dates.fromIso(map['startDate']);
  final end = Dates.fromIso(map['endDate']);
  if (start == null || end == null) return null;
  final rawDates = map['keyDates'];
  return Period(
    id: id,
    name: _text(map['name']),
    startDate: start,
    endDate: end,
    datesConfirmed: map['datesConfirmed'] != false,
    keyDates: [
      if (rawDates is List)
        for (final raw in rawDates) ?_keyDateFromMap(raw),
    ],
    deletedAt: _instant(map['deletedAt']),
  );
}
