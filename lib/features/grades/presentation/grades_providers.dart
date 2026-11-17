import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/entity_repository.dart';
import '../../../core/firebase/firestore_entity_store.dart';
import '../../activities/domain/activity.dart';
import '../../activities/presentation/activities_providers.dart';
import '../../classes/data/class_session_mapper.dart';
import '../../classes/domain/class_session.dart';
import '../../subjects/domain/subject.dart';
import '../domain/grade_calculator.dart';

final classSessionsRepositoryProvider =
    Provider<EntityRepository<ClassSession>>(
      (ref) => FirestoreEntityStore<ClassSession>(
        collection: ref.watch(userDocProvider).collection('classSessions'),
        fromMap: classSessionFromMap,
        toMap: classSessionToMap,
        idOf: (session) => session.id,
      ),
    );

final _allClassSessionsProvider = StreamProvider<List<ClassSession>>(
  (ref) => ref.watch(classSessionsRepositoryProvider).watchAll(),
);

/// Todas las clases vigentes, de la más reciente a la más antigua.
final classSessionsProvider = Provider<AsyncValue<List<ClassSession>>>(
  (ref) => ref
      .watch(_allClassSessionsProvider)
      .whenData((all) => sortClassSessions(all.where((s) => !s.isDeleted))),
);

/// Clases vigentes de una asignatura, de la más reciente a la más antigua.
final subjectClassSessionsProvider =
    Provider.family<AsyncValue<List<ClassSession>>, String>(
      (ref, subjectId) => ref
          .watch(_allClassSessionsProvider)
          .whenData(
            (all) => sortClassSessions(
              all.where((s) => !s.isDeleted && s.subjectId == subjectId),
            ),
          ),
    );

/// Actividades y clases de una asignatura que entran en el cálculo.
typedef GradeInputs = ({List<Activity> activities, List<ClassSession> classes});

final gradeInputsProvider = Provider.family<GradeInputs, String>((
  ref,
  subjectId,
) {
  final activities = ref.watch(activitiesProvider).value ?? const <Activity>[];
  final classes =
      ref.watch(subjectClassSessionsProvider(subjectId)).value ??
      const <ClassSession>[];
  return (
    activities: [
      for (final a in activities)
        if (a.subjectId == subjectId) a,
    ],
    classes: classes,
  );
});

/// Evaluación continua de [subject] con los datos reales.
GradeSummary watchGradeSummary(WidgetRef ref, Subject subject) {
  final inputs = ref.watch(gradeInputsProvider(subject.id));
  return GradeCalculator.summarize(
    scheme: subject.grading,
    activities: inputs.activities,
    classSessions: inputs.classes,
  );
}
