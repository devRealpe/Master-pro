import '../../../core/time/dates.dart';

enum SubjectStatus {
  planned('Próxima'),
  active('En curso'),
  finished('Finalizada');

  const SubjectStatus(this.label);

  final String label;
}

/// Asignatura de la maestría. Es el eje del resto de la información:
/// actividades, clases, exámenes, documentos y apuntes se asocian a una.
///
/// El progreso y las calificaciones no se guardan aquí: se calculan.
class Subject {
  const Subject({
    required this.id,
    required this.name,
    this.teacher = '',
    this.description = '',
    this.periodId,
    this.startDate,
    this.endDate,
    this.status = SubjectStatus.active,
    this.colorIndex = 0,
    this.deletedAt,
  });

  static const maxNameLength = 80;

  final String id;
  final String name;
  final String teacher;
  final String description;
  final String? periodId;

  /// Fechas sin hora.
  final DateTime? startDate;
  final DateTime? endDate;
  final SubjectStatus status;

  /// Posición en la paleta de colores de asignatura del Design System.
  final int colorIndex;

  /// Momento en que se envió a la papelera, o `null` si está vigente.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Parte del periodo ya transcurrida en [today], entre 0 y 1. Es `null` si
  /// faltan las fechas o no forman un intervalo.
  double? progressOn(DateTime today) {
    final start = startDate;
    final end = endDate;
    if (start == null || end == null) return null;
    final total = Dates.daysBetween(start, end);
    if (total <= 0) return null;
    return (Dates.daysBetween(start, today) / total).clamp(0.0, 1.0);
  }

  static const _keep = Object();

  /// Copia con cambios. Los campos que admiten `null` usan un centinela para
  /// poder distinguir «no cambiar» de «dejar vacío».
  Subject copyWith({
    String? name,
    String? teacher,
    String? description,
    Object? periodId = _keep,
    Object? startDate = _keep,
    Object? endDate = _keep,
    SubjectStatus? status,
    int? colorIndex,
    Object? deletedAt = _keep,
  }) => Subject(
    id: id,
    name: name ?? this.name,
    teacher: teacher ?? this.teacher,
    description: description ?? this.description,
    periodId: identical(periodId, _keep) ? this.periodId : periodId as String?,
    startDate: identical(startDate, _keep)
        ? this.startDate
        : startDate as DateTime?,
    endDate: identical(endDate, _keep) ? this.endDate : endDate as DateTime?,
    status: status ?? this.status,
    colorIndex: colorIndex ?? this.colorIndex,
    deletedAt: identical(deletedAt, _keep)
        ? this.deletedAt
        : deletedAt as DateTime?,
  );

  @override
  bool operator ==(Object other) =>
      other is Subject &&
      other.id == id &&
      other.name == name &&
      other.teacher == teacher &&
      other.description == description &&
      other.periodId == periodId &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.status == status &&
      other.colorIndex == colorIndex &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    teacher,
    description,
    periodId,
    startDate,
    endDate,
    status,
    colorIndex,
    deletedAt,
  );
}

/// Reglas de validación de una asignatura. Devuelven el mensaje de error, o
/// `null` si el valor es válido.
abstract final class SubjectRules {
  static String? name(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Escribe el nombre de la asignatura';
    if (trimmed.length > Subject.maxNameLength) {
      return 'Máximo ${Subject.maxNameLength} caracteres';
    }
    return null;
  }

  static String? dates(DateTime? start, DateTime? end) {
    if (start != null && end != null && end.isBefore(start)) {
      return 'La fecha de fin no puede ser anterior a la de inicio';
    }
    return null;
  }
}

/// Orden de la lista: primero las que están en curso, luego las próximas y
/// al final las finalizadas; dentro de cada grupo, por nombre.
List<Subject> sortSubjects(Iterable<Subject> subjects) {
  const order = {
    SubjectStatus.active: 0,
    SubjectStatus.planned: 1,
    SubjectStatus.finished: 2,
  };
  return subjects.toList()..sort((a, b) {
    final byStatus = order[a.status]!.compareTo(order[b.status]!);
    if (byStatus != 0) return byStatus;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
}
