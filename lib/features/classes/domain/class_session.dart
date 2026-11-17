/// Clase en vivo de una asignatura.
class ClassSession {
  const ClassSession({
    required this.id,
    required this.subjectId,
    required this.startsAt,
    this.topic = '',
    this.durationMinutes,
    this.attended,
    this.points = 0,
    this.guideUrl = '',
    this.notes = '',
    this.deletedAt,
  });

  static const maxTopicLength = 120;

  final String id;
  final String subjectId;

  /// Inicio de la clase, como instante UTC.
  final DateTime startsAt;
  final String topic;
  final int? durationMinutes;

  /// `true` si asististe, `false` si no, `null` si aún no lo registras.
  final bool? attended;

  /// Puntos de evaluación continua que da asistir. 0 si la clase no puntúa.
  final double points;

  /// Enlace a la guía de estudio de la clase.
  final String guideUrl;
  final String notes;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Título para listas: el tema o, si falta, «Clase en vivo».
  String get label => topic.isEmpty ? 'Clase en vivo' : topic;

  static const _keep = Object();

  ClassSession copyWith({
    DateTime? startsAt,
    String? topic,
    Object? durationMinutes = _keep,
    Object? attended = _keep,
    double? points,
    String? guideUrl,
    String? notes,
    Object? deletedAt = _keep,
  }) => ClassSession(
    id: id,
    subjectId: subjectId,
    startsAt: startsAt ?? this.startsAt,
    topic: topic ?? this.topic,
    durationMinutes: identical(durationMinutes, _keep)
        ? this.durationMinutes
        : durationMinutes as int?,
    attended: identical(attended, _keep) ? this.attended : attended as bool?,
    points: points ?? this.points,
    guideUrl: guideUrl ?? this.guideUrl,
    notes: notes ?? this.notes,
    deletedAt: identical(deletedAt, _keep)
        ? this.deletedAt
        : deletedAt as DateTime?,
  );

  @override
  bool operator ==(Object other) =>
      other is ClassSession &&
      other.id == id &&
      other.subjectId == subjectId &&
      other.startsAt == startsAt &&
      other.topic == topic &&
      other.durationMinutes == durationMinutes &&
      other.attended == attended &&
      other.points == points &&
      other.guideUrl == guideUrl &&
      other.notes == notes &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    subjectId,
    startsAt,
    topic,
    durationMinutes,
    attended,
    points,
    guideUrl,
    notes,
    deletedAt,
  );
}

/// Clases de la más reciente a la más antigua.
List<ClassSession> sortClassSessions(Iterable<ClassSession> sessions) =>
    sessions.toList()..sort((a, b) => b.startsAt.compareTo(a.startsAt));
