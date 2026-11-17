import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/sync/write_guard.dart';
import '../../../core/time/clock_providers.dart';
import '../../../core/time/dates.dart';
import '../../activities/domain/activity.dart';
import '../../activities/presentation/activities_providers.dart';
import '../../subjects/domain/subject.dart';
import '../../subjects/presentation/subjects_providers.dart';
import '../domain/study_block.dart';
import 'calendar_providers.dart';

/// Abre la hoja para reservar un bloque de estudio el día [day] o editar
/// [original].
Future<void> showStudyBlockSheet(
  BuildContext context, {
  required DateTime day,
  StudyBlock? original,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _StudyBlockForm(day: day, original: original),
  );
}

class _StudyBlockForm extends ConsumerStatefulWidget {
  const _StudyBlockForm({required this.day, required this.original});

  final DateTime day;
  final StudyBlock? original;

  @override
  ConsumerState<_StudyBlockForm> createState() => _StudyBlockFormState();
}

class _StudyBlockFormState extends ConsumerState<_StudyBlockForm> {
  late final StudyBlock? _original = widget.original;
  late final _title = TextEditingController(text: _original?.title);
  late String? _subjectId = _original?.subjectId;
  late String? _activityId = _original?.activityId;
  late int _duration = _original?.durationMinutes ?? 60;
  late DateTime _date;
  late int _hour;
  late int _minute;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final start = _original?.startsAt;
    if (start == null) {
      // Un bloque nuevo propone la siguiente hora en punto.
      final now = ref.read(toLocalProvider)(ref.read(clockProvider)());
      _date = widget.day;
      _hour = (now.hour + 1) % 24;
      _minute = 0;
    } else {
      final wall = ref.read(toLocalProvider)(start);
      _date = Dates.dateOnly(wall);
      _hour = wall.hour;
      _minute = wall.minute;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  /// Al elegir una actividad se proponen su asignatura y su título.
  void _selectActivity(String? id, List<Activity> activities) {
    setState(() {
      _activityId = id;
      final activity = activities.where((a) => a.id == id).firstOrNull;
      if (activity == null) return;
      _subjectId = activity.subjectId ?? _subjectId;
      if (_title.text.trim().isEmpty) _title.text = activity.title;
    });
  }

  void _save() {
    setState(() => _submitted = true);
    if (StudyBlockRules.title(_title.text) != null) return;

    final repository = ref.read(studyBlocksRepositoryProvider);
    final startsAt = ref.read(fromLocalProvider)(
      DateTime(_date.year, _date.month, _date.day, _hour, _minute),
    );
    final original = _original;
    final edited =
        (original ??
                StudyBlock(
                  id: repository.newId(),
                  title: '',
                  startsAt: startsAt,
                ))
            .copyWith(
              title: _title.text.trim(),
              startsAt: startsAt,
              durationMinutes: _duration,
              subjectId: _subjectId,
              activityId: _activityId,
            );
    guardWrite(
      original == null
          ? repository.create(edited)
          : repository.update(original, edited),
    );
    ref.read(calendarControllerProvider.notifier).select(_date);
    Navigator.of(context).pop();
  }

  void _delete() {
    final original = _original;
    if (original == null) return;
    final repository = ref.read(studyBlocksRepositoryProvider);
    final deleted = original.copyWith(deletedAt: DateTime.now().toUtc());
    guardWrite(repository.update(original, deleted));
    Navigator.of(context).pop();
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Bloque eliminado'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => guardWrite(repository.update(deleted, original)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final subjects = ref.watch(subjectsProvider).value ?? const <Subject>[];
    final activities = [
      for (final a in ref.watch(activitiesProvider).value ?? const <Activity>[])
        if (!a.isDone || a.id == _activityId) a,
    ];
    final subjectValue = subjects.any((s) => s.id == _subjectId)
        ? _subjectId
        : null;
    final activityValue = activities.any((a) => a.id == _activityId)
        ? _activityId
        : null;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _original == null ? 'Bloque de estudio' : 'Editar bloque',
            style: text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            maxLength: StudyBlock.maxTitleLength,
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
            decoration: InputDecoration(
              labelText: '¿Qué vas a estudiar?',
              hintText: 'Avanzar la actividad 1',
              errorText: _submitted ? StudyBlockRules.title(_title.text) : null,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: DateField(
                  label: 'Día',
                  value: _date,
                  clearable: false,
                  onChanged: (date) => setState(() => _date = date ?? _date),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: TimeField(
                  label: 'Inicio',
                  hour: _hour,
                  minute: _minute,
                  onChanged: (hour, minute) => setState(() {
                    _hour = hour;
                    _minute = minute;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Duración', style: text.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          AppChoiceChips<int>(
            wrap: true,
            selected: _duration,
            onChanged: (minutes) => setState(() => _duration = minutes),
            choices: [
              for (final minutes in {...StudyBlock.durations, _duration})
                AppChoice(
                  value: minutes,
                  label: StudyBlockRules.formatDuration(minutes),
                ),
            ],
          ),
          if (activities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String?>(
              key: ValueKey('activity-$activityValue'),
              initialValue: activityValue,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Para la actividad'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Ninguna')),
                for (final activity in activities)
                  DropdownMenuItem(
                    value: activity.id,
                    child: Text(
                      activity.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) => _selectActivity(id, activities),
            ),
          ],
          if (subjects.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String?>(
              key: ValueKey('subject-$subjectValue'),
              initialValue: subjectValue,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Asignatura'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Sin asignatura'),
                ),
                for (final subject in subjects)
                  DropdownMenuItem(
                    value: subject.id,
                    child: Text(subject.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (id) => setState(() => _subjectId = id),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _original == null ? 'Reservar bloque' : 'Guardar cambios',
            icon: LucideIcons.check,
            onPressed: _save,
          ),
          if (_original != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: 'Eliminar bloque',
              variant: AppButtonVariant.ghost,
              icon: LucideIcons.trash2,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}
