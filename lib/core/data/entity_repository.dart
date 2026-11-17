import 'dart:convert';

/// Almacén de una colección del usuario. Las pantallas y la lógica solo
/// conocen esta interfaz; Firestore queda detrás.
///
/// Las escrituras devuelven un `Future` que se completa cuando el servidor
/// confirma. Sin conexión eso puede tardar: la interfaz no debe esperarlo,
/// porque el cambio ya se ve en [watchAll] en cuanto se escribe en la caché.
abstract interface class EntityRepository<T> {
  /// Identificador nuevo, generado en el dispositivo (funciona sin conexión).
  String newId();

  /// Todos los elementos, incluidos los que están en la papelera.
  Stream<List<T>> watchAll();

  Future<void> create(T entity);

  /// Guarda solo los campos que cambian entre [before] y [after], para que
  /// dos dispositivos que editan campos distintos no se pisen.
  Future<void> update(T before, T after);
}

/// Campos de [after] cuyo valor difiere del de [before].
///
/// Los mapas solo contienen valores JSON (texto, números, booleanos, listas,
/// mapas y nulos), así que comparar su codificación es una igualdad profunda.
Map<String, Object?> changedFields(
  Map<String, Object?> before,
  Map<String, Object?> after,
) => {
  for (final MapEntry(:key, :value) in after.entries)
    if (!before.containsKey(key) ||
        jsonEncode(before[key]) != jsonEncode(value))
      key: value,
};
