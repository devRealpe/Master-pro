/// Bloque de tiempo reservado para estudiar.
///
/// Es lo planificado. El tiempo realmente estudiado se registrará aparte, en
/// las sesiones de estudio.
class StudyBlock {
  const StudyBlock({
    required this.id,
    required this.title,
    required this.startsAt,
    this.durationMinutes = 60,
    this.subjectId,
    this.activityId,
    this.notes = '',
    this.deletedAt,
  });

  static const maxTitleLength = 80;
  static const durations = [30, 45, 60, 90, 120];

  final String id;
  final String title;

  /// Inicio, como instante UTC.
  final DateTime startsAt;
  final int durationMinutes;
  final String? subjectId;

  /// Actividad para la que se reserva el tiempo, si la hay.
  final String? activityId;
  final String notes;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  DateTime get endsAt => startsAt.add(Duration(minutes: durationMinutes));

  static const _keep = Object();

  StudyBlock copyWith({
    String? title,
    DateTime? startsAt,
    int? durationMinutes,
    Object? subjectId = _keep,
    Object? activityId = _keep,
    String? notes,
    Object? deletedAt = _keep,
  }) => StudyBlock(
    id: id,
    title: title ?? this.title,
    startsAt: startsAt ?? this.startsAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    subjectId: identical(subjectId, _keep)
        ? this.subjectId
        : subjectId as String?,
    activityId: identical(activityId, _keep)
        ? this.activityId
        : activityId as String?,
    notes: notes ?? this.notes,
    deletedAt: identical(deletedAt, _keep)
        ? this.deletedAt
        : deletedAt as DateTime?,
  );

  @override
  bool operator ==(Object other) =>
      other is StudyBlock &&
      other.id == id &&
      other.title == title &&
      other.startsAt == startsAt &&
      other.durationMinutes == durationMinutes &&
      other.subjectId == subjectId &&
      other.activityId == activityId &&
      other.notes == notes &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    startsAt,
    durationMinutes,
    subjectId,
    activityId,
    notes,
    deletedAt,
  );
}

abstract final class StudyBlockRules {
  static String? title(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Escribe qué vas a estudiar';
    if (trimmed.length > StudyBlock.maxTitleLength) {
      return 'Máximo ${StudyBlock.maxTitleLength} caracteres';
    }
    return null;
  }

  /// «45 min», «1 h», «1 h 30 min».
  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '$rest min';
    if (rest == 0) return '$hours h';
    return '$hours h $rest min';
  }
}
