import '../../../core/time/dates.dart';
import '../../../core/time/deadline_clock.dart';

enum ActivityType {
  work('Trabajo'),
  test('Test'),
  quiz('Cuestionario'),
  project('Proyecto'),
  reading('Lectura'),
  research('Investigación'),
  delivery('Entrega'),
  personal('Estudio personal');

  const ActivityType(this.label);

  final String label;
}

/// Estado en el flujo de trabajo. Coincide con las columnas del Kanban.
///
/// «Entregada» y «calificada» no son estados: son hechos que ocurren después
/// y se guardan aparte ([Activity.submittedAt]). «Vencida» tampoco se guarda:
/// se deduce de la fecha límite.
enum ActivityStatus {
  backlog('Pendiente'),
  next('Próximamente'),
  inProgress('En progreso'),
  inReview('En revisión'),
  done('Finalizada');

  const ActivityStatus(this.label);

  final String label;
}

enum ActivityPriority {
  low('Baja'),
  medium('Media'),
  high('Alta'),
  urgent('Urgente');

  const ActivityPriority(this.label);

  final String label;
}

/// Paso de un trabajo grande.
class Subtask {
  const Subtask({required this.id, required this.title, this.done = false});

  static const maxTitleLength = 120;

  final String id;
  final String title;
  final bool done;

  Subtask copyWith({String? title, bool? done}) =>
      Subtask(id: id, title: title ?? this.title, done: done ?? this.done);

  @override
  bool operator ==(Object other) =>
      other is Subtask &&
      other.id == id &&
      other.title == title &&
      other.done == done;

  @override
  int get hashCode => Object.hash(id, title, done);
}

/// Qué tan cerca está una actividad de su fecha.
enum Urgency { overdue, today, thisWeek, later, noDate }

/// Trabajo, test, lectura o tarea personal.
class Activity {
  const Activity({
    required this.id,
    required this.title,
    this.description = '',
    this.notes = '',
    this.subjectId,
    this.type = ActivityType.work,
    this.status = ActivityStatus.backlog,
    this.priority = ActivityPriority.medium,
    this.dueAt,
    this.dueZone = DeadlineZone.spain,
    this.bufferDays = defaultBufferDays,
    this.submittedAt,
    this.estimateMinutes,
    this.subtasks = const [],
    this.deletedAt,
  });

  static const maxTitleLength = 120;
  static const maxSubtasks = 50;
  static const defaultBufferDays = 1;
  static const maxBufferDays = 7;

  final String id;
  final String title;
  final String description;
  final String notes;

  /// `null` en las actividades personales que no son de una asignatura.
  final String? subjectId;
  final ActivityType type;
  final ActivityStatus status;
  final ActivityPriority priority;

  /// Fecha límite oficial, como instante UTC.
  final DateTime? dueAt;

  /// Zona en la que se escribió [dueAt]; decide cómo se muestra y se edita.
  final DeadlineZone dueZone;

  /// Colchón: cuántos días antes de [dueAt] quieres tenerla lista.
  final int bufferDays;

  /// Momento real de la entrega. Es lo que significa «entregada».
  final DateTime? submittedAt;
  final int? estimateMinutes;
  final List<Subtask> subtasks;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
  bool get isSubmitted => submittedAt != null;

  /// Hecha: finalizada en el flujo o ya entregada.
  bool get isDone => status == ActivityStatus.done || isSubmitted;

  /// Fecha objetivo personal: la límite menos el colchón.
  DateTime? get targetAt => dueAt?.subtract(Duration(days: bufferDays));

  /// Entregada después de la fecha límite.
  bool get submittedLate {
    final due = dueAt;
    final submitted = submittedAt;
    return due != null && submitted != null && submitted.isAfter(due);
  }

  bool isOverdue(DateTime now) {
    final due = dueAt;
    return due != null && !isDone && now.isAfter(due);
  }

  int get subtasksDone => subtasks.where((s) => s.done).length;

  /// Avance entre 0 y 1: el de las subtareas o, si no hay, hecha o no hecha.
  double get progress {
    if (isDone) return 1;
    if (subtasks.isEmpty) return 0;
    return subtasksDone / subtasks.length;
  }

  /// Cercanía de la fecha objetivo (o de la límite, si ya pasó la objetivo),
  /// en días de calendario del dispositivo.
  Urgency urgency(
    DateTime now, {
    required DateTime Function(DateTime) toLocal,
  }) {
    final due = dueAt;
    final target = targetAt;
    if (due == null || target == null) return Urgency.noDate;
    if (now.isAfter(due)) return Urgency.overdue;
    final days = Dates.daysBetween(toLocal(now), toLocal(target));
    if (days <= 0) return Urgency.today;
    if (days <= 7) return Urgency.thisWeek;
    return Urgency.later;
  }

  static const _keep = Object();

  Activity copyWith({
    String? title,
    String? description,
    String? notes,
    Object? subjectId = _keep,
    ActivityType? type,
    ActivityStatus? status,
    ActivityPriority? priority,
    Object? dueAt = _keep,
    DeadlineZone? dueZone,
    int? bufferDays,
    Object? submittedAt = _keep,
    Object? estimateMinutes = _keep,
    List<Subtask>? subtasks,
    Object? deletedAt = _keep,
  }) => Activity(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    notes: notes ?? this.notes,
    subjectId: identical(subjectId, _keep)
        ? this.subjectId
        : subjectId as String?,
    type: type ?? this.type,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    dueAt: identical(dueAt, _keep) ? this.dueAt : dueAt as DateTime?,
    dueZone: dueZone ?? this.dueZone,
    bufferDays: bufferDays ?? this.bufferDays,
    submittedAt: identical(submittedAt, _keep)
        ? this.submittedAt
        : submittedAt as DateTime?,
    estimateMinutes: identical(estimateMinutes, _keep)
        ? this.estimateMinutes
        : estimateMinutes as int?,
    subtasks: subtasks ?? this.subtasks,
    deletedAt: identical(deletedAt, _keep)
        ? this.deletedAt
        : deletedAt as DateTime?,
  );

  /// Marca la entrega en [at] y cierra el flujo.
  Activity submit(DateTime at) =>
      copyWith(submittedAt: at.toUtc(), status: ActivityStatus.done);

  /// Deshace la entrega y la devuelve a «En progreso».
  Activity unsubmit() =>
      copyWith(submittedAt: null, status: ActivityStatus.inProgress);

  Activity withSubtask(Subtask subtask) =>
      copyWith(subtasks: [...subtasks, subtask]);

  Activity withoutSubtask(String subtaskId) => copyWith(
    subtasks: [
      for (final s in subtasks)
        if (s.id != subtaskId) s,
    ],
  );

  Activity toggleSubtask(String subtaskId) => copyWith(
    subtasks: [
      for (final s in subtasks)
        s.id == subtaskId ? s.copyWith(done: !s.done) : s,
    ],
  );

  @override
  bool operator ==(Object other) =>
      other is Activity &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.notes == notes &&
      other.subjectId == subjectId &&
      other.type == type &&
      other.status == status &&
      other.priority == priority &&
      other.dueAt == dueAt &&
      other.dueZone == dueZone &&
      other.bufferDays == bufferDays &&
      other.submittedAt == submittedAt &&
      other.estimateMinutes == estimateMinutes &&
      other.deletedAt == deletedAt &&
      _sameSubtasks(other.subtasks, subtasks);

  static bool _sameSubtasks(List<Subtask> a, List<Subtask> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    notes,
    subjectId,
    type,
    status,
    priority,
    dueAt,
    dueZone,
    bufferDays,
    submittedAt,
    estimateMinutes,
    deletedAt,
    Object.hashAll(subtasks),
  );
}

abstract final class ActivityRules {
  static String? title(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Escribe el título de la actividad';
    if (trimmed.length > Activity.maxTitleLength) {
      return 'Máximo ${Activity.maxTitleLength} caracteres';
    }
    return null;
  }

  static String? subtaskTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Escribe el paso';
    if (trimmed.length > Subtask.maxTitleLength) {
      return 'Máximo ${Subtask.maxTitleLength} caracteres';
    }
    return null;
  }

  /// Lee un tiempo estimado en horas («1,5», «2»). Vacío es válido (sin
  /// estimación). Devuelve los minutos, o `null` si no es un número válido.
  static ({bool valid, int? minutes}) estimate(String value) {
    final text = value.trim().replaceAll(',', '.');
    if (text.isEmpty) return (valid: true, minutes: null);
    final hours = double.tryParse(text);
    if (hours == null || hours <= 0 || hours > 500) {
      return (valid: false, minutes: null);
    }
    return (valid: true, minutes: (hours * 60).round());
  }

  /// «1,5 h», «45 min».
  static String formatEstimate(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes / 60;
    final text = hours == hours.roundToDouble()
        ? hours.toStringAsFixed(0)
        : hours.toStringAsFixed(1).replaceAll('.', ',');
    return '$text h';
  }
}

/// Orden de trabajo: primero lo que vence antes (por fecha objetivo), sin
/// fecha al final; a igual fecha, lo más prioritario.
List<Activity> sortActivities(Iterable<Activity> activities) =>
    activities.toList()..sort((a, b) {
      final ta = a.targetAt;
      final tb = b.targetAt;
      if (ta != null && tb != null) {
        final byDate = ta.compareTo(tb);
        if (byDate != 0) return byDate;
      } else if (ta != null) {
        return -1;
      } else if (tb != null) {
        return 1;
      }
      final byPriority = b.priority.index.compareTo(a.priority.index);
      if (byPriority != 0) return byPriority;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

/// Filtro de la lista del Plan.
class ActivityFilter {
  const ActivityFilter({
    this.showDone = false,
    this.subjectId,
    this.type,
    this.priority,
  });

  final bool showDone;
  final String? subjectId;
  final ActivityType? type;
  final ActivityPriority? priority;

  /// Cuántos filtros de tipo y prioridad están activos.
  int get extraCount => (type == null ? 0 : 1) + (priority == null ? 0 : 1);

  bool matches(Activity activity) =>
      activity.isDone == showDone &&
      (subjectId == null || activity.subjectId == subjectId) &&
      (type == null || activity.type == type) &&
      (priority == null || activity.priority == priority);

  static const _keep = Object();

  ActivityFilter copyWith({
    bool? showDone,
    Object? subjectId = _keep,
    Object? type = _keep,
    Object? priority = _keep,
  }) => ActivityFilter(
    showDone: showDone ?? this.showDone,
    subjectId: identical(subjectId, _keep)
        ? this.subjectId
        : subjectId as String?,
    type: identical(type, _keep) ? this.type : type as ActivityType?,
    priority: identical(priority, _keep)
        ? this.priority
        : priority as ActivityPriority?,
  );
}
