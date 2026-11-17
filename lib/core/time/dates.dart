import 'package:intl/intl.dart';

/// Utilidades para fechas sin hora (inicio de una asignatura, un examen).
///
/// Una fecha así no es un instante: «16 de noviembre» es el mismo día en
/// Colombia y en España. Por eso se guarda como texto `aaaa-mm-dd` y nunca se
/// convierte entre zonas horarias.
abstract final class Dates {
  static final _iso = DateFormat('yyyy-MM-dd');

  /// [value] sin hora.
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime today() => dateOnly(DateTime.now());

  static String? toIso(DateTime? date) =>
      date == null ? null : _iso.format(date);

  /// Lee `aaaa-mm-dd`. Devuelve `null` si falta o no es una fecha válida.
  static DateTime? fromIso(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    // DateTime acepta «31 de febrero» y lo desborda a marzo: se rechaza.
    if (date.month != month || date.day != day) return null;
    return date;
  }

  /// Días de calendario de [from] a [to]. No le afectan los cambios de hora.
  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// «16 nov 2026».
  static String format(DateTime date, {String locale = 'es'}) =>
      DateFormat('d MMM y', locale).format(date).replaceAll('.', '');

  /// «16 nov 2026 – 21 mar 2027», «9 – 11 abr 2027» o una sola fecha.
  static String formatRange(
    DateTime start,
    DateTime? end, {
    String locale = 'es',
  }) {
    if (end == null || daysBetween(start, end) == 0) {
      return format(start, locale: locale);
    }
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} – ${format(end, locale: locale)}';
    }
    if (start.year == end.year) {
      final first = DateFormat(
        'd MMM',
        locale,
      ).format(start).replaceAll('.', '');
      return '$first – ${format(end, locale: locale)}';
    }
    return '${format(start, locale: locale)} – ${format(end, locale: locale)}';
  }
}
