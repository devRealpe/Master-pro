import '../../../core/time/deadline_clock.dart';
import '../domain/activity.dart';

/// Conversión entre [Activity] y su documento de Firestore.
///
/// Los instantes se guardan como texto ISO en UTC, que además ordena igual
/// que el tiempo. La lectura es tolerante: lo que falta o no se reconoce toma
/// su valor por omisión.

const _schemaVersion = 1;

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

String _text(Object? value) => value is String ? value : '';

DateTime? _instant(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

/// Firestore devuelve los números como `int` o `double` según su valor.
double? _nonNegative(Object? value) =>
    value is num && value >= 0 ? value.toDouble() : null;

String? _iso(DateTime? instant) => instant?.toUtc().toIso8601String();

Map<String, Object?> activityToMap(Activity activity) => {
  'title': activity.title,
  'description': activity.description,
  'notes': activity.notes,
  'subjectId': activity.subjectId,
  'type': activity.type.name,
  'status': activity.status.name,
  'priority': activity.priority.name,
  'dueAt': _iso(activity.dueAt),
  'dueZone': activity.dueZone.name,
  'bufferDays': activity.bufferDays,
  'submittedAt': _iso(activity.submittedAt),
  'estimateMinutes': activity.estimateMinutes,
  'value': activity.value,
  'score': activity.score,
  'subtasks': [
    for (final subtask in activity.subtasks)
      {'id': subtask.id, 'title': subtask.title, 'done': subtask.done},
  ],
  'deletedAt': _iso(activity.deletedAt),
  'schemaVersion': _schemaVersion,
};

Subtask? _subtaskFromMap(Object? value) {
  if (value is! Map) return null;
  final id = value['id'];
  if (id is! String) return null;
  return Subtask(
    id: id,
    title: _text(value['title']),
    done: value['done'] == true,
  );
}

Activity activityFromMap(String id, Map<String, Object?> map) {
  final buffer = map['bufferDays'];
  final estimate = map['estimateMinutes'];
  final subtasks = map['subtasks'];
  return Activity(
    id: id,
    title: _text(map['title']),
    description: _text(map['description']),
    notes: _text(map['notes']),
    subjectId: map['subjectId'] is String ? map['subjectId']! as String : null,
    type: _enumByName(ActivityType.values, map['type'], ActivityType.work),
    status: _enumByName(
      ActivityStatus.values,
      map['status'],
      ActivityStatus.backlog,
    ),
    priority: _enumByName(
      ActivityPriority.values,
      map['priority'],
      ActivityPriority.medium,
    ),
    dueAt: _instant(map['dueAt']),
    dueZone: _enumByName(
      DeadlineZone.values,
      map['dueZone'],
      DeadlineZone.spain,
    ),
    bufferDays: buffer is int && buffer >= 0 && buffer <= Activity.maxBufferDays
        ? buffer
        : Activity.defaultBufferDays,
    submittedAt: _instant(map['submittedAt']),
    estimateMinutes: estimate is int && estimate > 0 ? estimate : null,
    value: _nonNegative(map['value']),
    score: _nonNegative(map['score']),
    subtasks: [
      if (subtasks is List)
        for (final raw in subtasks) ?_subtaskFromMap(raw),
    ],
    deletedAt: _instant(map['deletedAt']),
  );
}
