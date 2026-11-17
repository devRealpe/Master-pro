import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/entity_repository.dart';
import '../../../core/firebase/firestore_entity_store.dart';
import '../data/subject_mappers.dart';
import '../domain/period.dart';
import '../domain/subject.dart';

final subjectsRepositoryProvider = Provider<EntityRepository<Subject>>(
  (ref) => FirestoreEntityStore<Subject>(
    collection: ref.watch(userDocProvider).collection('subjects'),
    fromMap: subjectFromMap,
    toMap: subjectToMap,
    idOf: (subject) => subject.id,
  ),
);

final periodsRepositoryProvider = Provider<EntityRepository<Period>>(
  (ref) => FirestoreEntityStore<Period>(
    collection: ref.watch(userDocProvider).collection('periods'),
    fromMap: periodFromMap,
    toMap: periodToMap,
    idOf: (period) => period.id,
  ),
);

final _allSubjectsProvider = StreamProvider<List<Subject>>(
  (ref) => ref.watch(subjectsRepositoryProvider).watchAll(),
);

final _allPeriodsProvider = StreamProvider<List<Period>>(
  (ref) => ref.watch(periodsRepositoryProvider).watchAll(),
);

/// Asignaturas vigentes (sin las de la papelera), ordenadas.
final subjectsProvider = Provider<AsyncValue<List<Subject>>>(
  (ref) => ref
      .watch(_allSubjectsProvider)
      .whenData((all) => sortSubjects(all.where((s) => !s.isDeleted))),
);

/// Periodos vigentes, del más antiguo al más reciente.
final periodsProvider = Provider<AsyncValue<List<Period>>>(
  (ref) => ref
      .watch(_allPeriodsProvider)
      .whenData((all) => sortPeriods(all.where((p) => !p.isDeleted))),
);

/// Una asignatura por su identificador, incluida si está en la papelera
/// (para poder deshacer su eliminación). `null` si no existe.
final subjectProvider = Provider.family<AsyncValue<Subject?>, String>(
  (ref, id) => ref
      .watch(_allSubjectsProvider)
      .whenData((all) => all.where((s) => s.id == id).firstOrNull),
);

/// Vuelve a suscribirse a las colecciones; lo usa «Reintentar».
void retrySubjects(WidgetRef ref) {
  ref
    ..invalidate(_allSubjectsProvider)
    ..invalidate(_allPeriodsProvider);
}
