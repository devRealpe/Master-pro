import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../data/entity_repository.dart';

/// Firestore con caché persistente: las lecturas responden sin conexión y
/// las escrituras se encolan hasta que vuelve.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  final firestore = FirebaseFirestore.instance;
  firestore.settings = const Settings(persistenceEnabled: true);
  return firestore;
});

/// Documento raíz de la persona con sesión iniciada: `users/{uid}`. Todo su
/// contenido cuelga de aquí, que es lo que protegen las reglas de seguridad.
final userDocProvider = Provider<DocumentReference<Map<String, dynamic>>>((
  ref,
) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    throw StateError('No hay sesión: no se puede acceder a los datos.');
  }
  return ref.watch(firestoreProvider).collection('users').doc(user.uid);
});

/// [EntityRepository] sobre una colección de Firestore.
class FirestoreEntityStore<T> implements EntityRepository<T> {
  FirestoreEntityStore({
    required this.collection,
    required this.fromMap,
    required this.toMap,
    required this.idOf,
  });

  final CollectionReference<Map<String, dynamic>> collection;

  /// Devuelve `null` para descartar un documento que no se puede leer.
  final T? Function(String id, Map<String, Object?> map) fromMap;
  final Map<String, Object?> Function(T entity) toMap;
  final String Function(T entity) idOf;

  @override
  String newId() => collection.doc().id;

  @override
  Stream<List<T>> watchAll() => collection.snapshots().map(
    (snapshot) => [
      for (final doc in snapshot.docs) ?fromMap(doc.id, doc.data()),
    ],
  );

  @override
  Future<void> create(T entity) => collection.doc(idOf(entity)).set({
    ...toMap(entity),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> update(T before, T after) {
    final changes = changedFields(toMap(before), toMap(after));
    if (changes.isEmpty) return Future.value();
    return collection.doc(idOf(after)).update({
      ...changes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
