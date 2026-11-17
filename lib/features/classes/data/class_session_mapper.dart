import '../domain/class_session.dart';

/// Conversión entre [ClassSession] y su documento de Firestore.

const _schemaVersion = 1;

String _text(Object? value) => value is String ? value : '';

DateTime? _instant(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

Map<String, Object?> classSessionToMap(ClassSession session) => {
  'subjectId': session.subjectId,
  'startsAt': session.startsAt.toUtc().toIso8601String(),
  'topic': session.topic,
  'durationMinutes': session.durationMinutes,
  'attended': session.attended,
  'points': session.points,
  'guideUrl': session.guideUrl,
  'notes': session.notes,
  'deletedAt': session.deletedAt?.toUtc().toIso8601String(),
  'schemaVersion': _schemaVersion,
};

/// Devuelve `null` si al documento le falta la asignatura o la fecha: sin
/// ellas la clase no se puede ubicar.
ClassSession? classSessionFromMap(String id, Map<String, Object?> map) {
  final subjectId = map['subjectId'];
  final startsAt = _instant(map['startsAt']);
  if (subjectId is! String || startsAt == null) return null;

  final duration = map['durationMinutes'];
  final points = map['points'];
  final attended = map['attended'];
  return ClassSession(
    id: id,
    subjectId: subjectId,
    startsAt: startsAt,
    topic: _text(map['topic']),
    durationMinutes: duration is int && duration > 0 ? duration : null,
    attended: attended is bool ? attended : null,
    points: points is num && points >= 0 ? points.toDouble() : 0,
    guideUrl: _text(map['guideUrl']),
    notes: _text(map['notes']),
    deletedAt: _instant(map['deletedAt']),
  );
}
