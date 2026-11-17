enum KeyDateKind {
  classes('Clases'),
  review('Repaso'),
  exams('Exámenes'),
  delivery('Entrega'),
  nonTeaching('No lectivo'),
  other('Otro');

  const KeyDateKind(this.label);

  final String label;
}

/// Fecha clave de un periodo: un día o un intervalo (repaso, exámenes).
class KeyDate {
  const KeyDate({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    this.kind = KeyDateKind.other,
    this.confirmed = false,
    this.note = '',
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final KeyDateKind kind;

  /// Falso mientras no se haya validado contra el calendario oficial.
  final bool confirmed;
  final String note;

  KeyDate copyWith({bool? confirmed}) => KeyDate(
    id: id,
    title: title,
    start: start,
    end: end,
    kind: kind,
    confirmed: confirmed ?? this.confirmed,
    note: note,
  );

  @override
  bool operator ==(Object other) =>
      other is KeyDate &&
      other.id == id &&
      other.title == title &&
      other.start == start &&
      other.end == end &&
      other.kind == kind &&
      other.confirmed == confirmed &&
      other.note == note;

  @override
  int get hashCode => Object.hash(id, title, start, end, kind, confirmed, note);
}

/// Periodo académico (un cuatrimestre) con sus fechas clave.
class Period {
  const Period({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.datesConfirmed = true,
    this.keyDates = const [],
    this.deletedAt,
  });

  static const maxNameLength = 60;

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  /// Falso cuando las fechas del periodo vienen de una plantilla sin validar.
  final bool datesConfirmed;
  final List<KeyDate> keyDates;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Cuántas fechas (las del periodo y las clave) siguen sin confirmar.
  int get pendingConfirmations =>
      (datesConfirmed ? 0 : 1) + keyDates.where((d) => !d.confirmed).length;

  static const _keep = Object();

  Period copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? datesConfirmed,
    List<KeyDate>? keyDates,
    Object? deletedAt = _keep,
  }) => Period(
    id: id,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    datesConfirmed: datesConfirmed ?? this.datesConfirmed,
    keyDates: keyDates ?? this.keyDates,
    deletedAt: identical(deletedAt, _keep)
        ? this.deletedAt
        : deletedAt as DateTime?,
  );

  /// Copia con la fecha clave [keyDateId] marcada como confirmada o no.
  Period withKeyDateConfirmed(String keyDateId, {required bool confirmed}) =>
      copyWith(
        keyDates: [
          for (final date in keyDates)
            date.id == keyDateId ? date.copyWith(confirmed: confirmed) : date,
        ],
      );

  @override
  bool operator ==(Object other) =>
      other is Period &&
      other.id == id &&
      other.name == name &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.datesConfirmed == datesConfirmed &&
      other.deletedAt == deletedAt &&
      _sameDates(other.keyDates, keyDates);

  static bool _sameDates(List<KeyDate> a, List<KeyDate> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    startDate,
    endDate,
    datesConfirmed,
    deletedAt,
    Object.hashAll(keyDates),
  );
}

abstract final class PeriodRules {
  static String? name(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Escribe el nombre del periodo';
    if (trimmed.length > Period.maxNameLength) {
      return 'Máximo ${Period.maxNameLength} caracteres';
    }
    return null;
  }

  static String? dates(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Elige las dos fechas';
    if (!end.isAfter(start)) {
      return 'La fecha de fin debe ser posterior a la de inicio';
    }
    return null;
  }
}

/// Periodos ordenados del más antiguo al más reciente.
List<Period> sortPeriods(Iterable<Period> periods) =>
    periods.toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
