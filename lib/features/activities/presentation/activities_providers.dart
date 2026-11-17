import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/entity_repository.dart';
import '../../../core/firebase/firestore_entity_store.dart';
import '../data/activity_mapper.dart';
import '../domain/activity.dart';

final activitiesRepositoryProvider = Provider<EntityRepository<Activity>>(
  (ref) => FirestoreEntityStore<Activity>(
    collection: ref.watch(userDocProvider).collection('activities'),
    fromMap: activityFromMap,
    toMap: activityToMap,
    idOf: (activity) => activity.id,
  ),
);

final _allActivitiesProvider = StreamProvider<List<Activity>>(
  (ref) => ref.watch(activitiesRepositoryProvider).watchAll(),
);

/// Actividades vigentes (sin las de la papelera), en orden de trabajo.
final activitiesProvider = Provider<AsyncValue<List<Activity>>>(
  (ref) => ref
      .watch(_allActivitiesProvider)
      .whenData((all) => sortActivities(all.where((a) => !a.isDeleted))),
);

/// Una actividad por su identificador, incluida si está en la papelera.
final activityProvider = Provider.family<AsyncValue<Activity?>, String>(
  (ref, id) => ref
      .watch(_allActivitiesProvider)
      .whenData((all) => all.where((a) => a.id == id).firstOrNull),
);

/// Filtro elegido en la lista del Plan. Se conserva al cambiar de pestaña.
class ActivityFilterController extends Notifier<ActivityFilter> {
  @override
  ActivityFilter build() => const ActivityFilter();

  void update(ActivityFilter filter) => state = filter;
}

final activityFilterProvider =
    NotifierProvider<ActivityFilterController, ActivityFilter>(
      ActivityFilterController.new,
    );

void retryActivities(WidgetRef ref) => ref.invalidate(_allActivitiesProvider);
