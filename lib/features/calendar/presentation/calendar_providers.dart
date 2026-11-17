import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/entity_repository.dart';
import '../../../core/firebase/firestore_entity_store.dart';
import '../../../core/time/clock_providers.dart';
import '../../../core/time/dates.dart';
import '../data/study_block_mapper.dart';
import '../domain/study_block.dart';

final studyBlocksRepositoryProvider = Provider<EntityRepository<StudyBlock>>(
  (ref) => FirestoreEntityStore<StudyBlock>(
    collection: ref.watch(userDocProvider).collection('studyBlocks'),
    fromMap: studyBlockFromMap,
    toMap: studyBlockToMap,
    idOf: (block) => block.id,
  ),
);

final _allStudyBlocksProvider = StreamProvider<List<StudyBlock>>(
  (ref) => ref.watch(studyBlocksRepositoryProvider).watchAll(),
);

/// Bloques de estudio vigentes.
final studyBlocksProvider = Provider<AsyncValue<List<StudyBlock>>>(
  (ref) => ref
      .watch(_allStudyBlocksProvider)
      .whenData(
        (all) => [
          for (final block in all)
            if (!block.isDeleted) block,
        ],
      ),
);

/// Un bloque por su identificador, incluido si está en la papelera.
final studyBlockProvider = Provider.family<StudyBlock?, String>(
  (ref, id) => ref
      .watch(_allStudyBlocksProvider)
      .value
      ?.where((block) => block.id == id)
      .firstOrNull,
);

enum CalendarView {
  month('Mes'),
  week('Semana'),
  day('Día');

  const CalendarView(this.label);

  final String label;
}

/// Qué se está viendo en el calendario: la vista y el día elegido.
class CalendarState {
  const CalendarState({required this.view, required this.selected});

  final CalendarView view;

  /// Día elegido, sin hora.
  final DateTime selected;

  /// Primer y último día que la vista necesita tener cargados.
  ({DateTime from, DateTime to}) get window => switch (view) {
    CalendarView.month => (
      from: Dates.monthGrid(selected).first,
      to: Dates.monthGrid(selected).last,
    ),
    CalendarView.week => (
      from: Dates.startOfWeek(selected),
      to: Dates.addDays(Dates.startOfWeek(selected), 6),
    ),
    CalendarView.day => (from: selected, to: selected),
  };
}

class CalendarController extends Notifier<CalendarState> {
  @override
  CalendarState build() =>
      CalendarState(view: CalendarView.month, selected: _today());

  DateTime _today() =>
      Dates.dateOnly(ref.read(toLocalProvider)(ref.read(clockProvider)()));

  void setView(CalendarView view) =>
      state = CalendarState(view: view, selected: state.selected);

  void select(DateTime day) =>
      state = CalendarState(view: state.view, selected: Dates.dateOnly(day));

  void goToToday() => select(_today());

  /// Avanza o retrocede un mes, una semana o un día, según la vista.
  void step(int direction) => select(switch (state.view) {
    CalendarView.month => Dates.addMonths(state.selected, direction),
    CalendarView.week => Dates.addDays(state.selected, 7 * direction),
    CalendarView.day => Dates.addDays(state.selected, direction),
  });
}

final calendarControllerProvider =
    NotifierProvider<CalendarController, CalendarState>(CalendarController.new);
