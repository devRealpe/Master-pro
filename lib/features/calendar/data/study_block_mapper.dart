import '../domain/study_block.dart';

/// Conversión entre [StudyBlock] y su documento de Firestore.

const _schemaVersion = 1;

String _text(Object? value) => value is String ? value : '';

DateTime? _instant(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

Map<String, Object?> studyBlockToMap(StudyBlock block) => {
  'title': block.title,
  'startsAt': block.startsAt.toUtc().toIso8601String(),
  'durationMinutes': block.durationMinutes,
  'subjectId': block.subjectId,
  'activityId': block.activityId,
  'notes': block.notes,
  'deletedAt': block.deletedAt?.toUtc().toIso8601String(),
  'schemaVersion': _schemaVersion,
};

/// Devuelve `null` si al documento le falta el inicio: un bloque sin hora no
/// se puede ubicar en el calendario.
StudyBlock? studyBlockFromMap(String id, Map<String, Object?> map) {
  final startsAt = _instant(map['startsAt']);
  if (startsAt == null) return null;
  final duration = map['durationMinutes'];
  return StudyBlock(
    id: id,
    title: _text(map['title']),
    startsAt: startsAt,
    durationMinutes: duration is int && duration > 0 && duration <= 24 * 60
        ? duration
        : 60,
    subjectId: map['subjectId'] is String ? map['subjectId']! as String : null,
    activityId: map['activityId'] is String
        ? map['activityId']! as String
        : null,
    notes: _text(map['notes']),
    deletedAt: _instant(map['deletedAt']),
  );
}
