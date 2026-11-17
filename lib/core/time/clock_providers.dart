import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Momento actual. Las pruebas lo sustituyen por un instante fijo.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Convierte un instante a la hora del dispositivo. Las pruebas lo sustituyen
/// por una zona fija para no depender del computador donde corren.
final toLocalProvider = Provider<DateTime Function(DateTime)>(
  (ref) =>
      (instant) => instant.toLocal(),
);
