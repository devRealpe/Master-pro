import 'package:intl/intl.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'dates.dart';

/// Carga la base de zonas horarias. Se llama una vez al arrancar.
void initializeTimeZones() => tzdata.initializeTimeZones();

/// Zona en la que se definió una fecha límite.
enum DeadlineZone {
  /// Hora peninsular española: la de todas las entregas de UNIR.
  spain('España'),

  /// La hora del dispositivo.
  local('Mi hora');

  const DeadlineZone(this.label);

  final String label;
}

/// Conversión entre la hora de España y un instante universal.
///
/// Las entregas de UNIR vencen a las 23:59 de España. La diferencia con
/// Colombia no es fija: son 6 horas en invierno y 7 en verano, y España
/// cambia de horario el último domingo de marzo y de octubre. Por eso la
/// fecha límite se guarda como instante y cada pantalla la muestra en la
/// hora del dispositivo.
abstract final class SpainTime {
  static const defaultHour = 23;
  static const defaultMinute = 59;

  static tz.Location get _madrid => tz.getLocation('Europe/Madrid');

  /// Instante UTC de [date] a las [hour]:[minute] de España.
  static DateTime toInstant(
    DateTime date, {
    int hour = defaultHour,
    int minute = defaultMinute,
  }) => tz.TZDateTime(
    _madrid,
    date.year,
    date.month,
    date.day,
    hour,
    minute,
  ).toUtc();

  /// Fecha y hora de pared en España para [instant].
  static DateTime wallTime(DateTime instant) {
    final local = tz.TZDateTime.from(instant, _madrid);
    return DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
  }
}

/// Instante de una fecha límite escrita como fecha y hora en [zone].
DateTime deadlineInstant({
  required DateTime date,
  required int hour,
  required int minute,
  required DeadlineZone zone,
}) => switch (zone) {
  DeadlineZone.spain => SpainTime.toInstant(date, hour: hour, minute: minute),
  DeadlineZone.local => DateTime(
    date.year,
    date.month,
    date.day,
    hour,
    minute,
  ).toUtc(),
};

/// Textos de una fecha límite.
abstract final class DeadlineText {
  static String _clock(DateTime wall) => DateFormat('HH:mm').format(wall);

  static String _day(DateTime wall, String locale) =>
      DateFormat('EEE d MMM', locale).format(wall).replaceAll('.', '');

  /// «jue 19 nov, 17:59» en la hora del dispositivo.
  static String local(
    DateTime instant, {
    required DateTime Function(DateTime) toLocal,
    String locale = 'es',
  }) {
    final wall = toLocal(instant);
    return '${_day(wall, locale)}, ${_clock(wall)}';
  }

  /// «23:59 España». Si en España ya es otro día, lo indica: «23:59 del 20
  /// nov en España».
  static String spain(
    DateTime instant, {
    required DateTime Function(DateTime) toLocal,
    String locale = 'es',
  }) {
    final wall = SpainTime.wallTime(instant);
    final sameDay = Dates.daysBetween(toLocal(instant), wall) == 0;
    if (sameDay) return '${_clock(wall)} España';
    final day = DateFormat('d MMM', locale).format(wall).replaceAll('.', '');
    return '${_clock(wall)} del $day en España';
  }

  /// Cuánto falta, contado en días de calendario del dispositivo.
  static String countdown(
    DateTime instant, {
    required DateTime now,
    required DateTime Function(DateTime) toLocal,
  }) {
    if (now.isAfter(instant)) {
      final days = Dates.daysBetween(toLocal(instant), toLocal(now));
      return switch (days) {
        0 => 'Venció hoy',
        1 => 'Venció ayer',
        _ => 'Venció hace $days días',
      };
    }
    final days = Dates.daysBetween(toLocal(now), toLocal(instant));
    return switch (days) {
      0 => 'Vence hoy',
      1 => 'Vence mañana',
      _ => 'Faltan $days días',
    };
  }
}
