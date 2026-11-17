import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/sync/write_guard.dart';
import '../../../core/time/clock_providers.dart';
import '../../../core/time/dates.dart';
import '../../../core/time/deadline_clock.dart';
import '../../subjects/domain/subject.dart';
import '../../subjects/presentation/subjects_providers.dart';
import '../domain/activity.dart';
import 'activities_providers.dart';

/// Alta y edición de una actividad. Con [activityId] edita; sin él, crea.
class ActivityFormPage extends ConsumerWidget {
  const ActivityFormPage({super.key, this.activityId, this.subjectId});

  final String? activityId;

  /// Asignatura propuesta al crear desde el detalle de una asignatura.
  final String? subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = activityId;
    if (id == null) return _ActivityForm(original: null, subjectId: subjectId);

    return switch (ref.watch(activityProvider(id))) {
      AsyncData(:final value?) => _ActivityForm(original: value),
      AsyncData() || AsyncError() => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: ErrorState(
            title: 'Actividad no encontrada',
            message: 'Puede que la hayas eliminado desde otro dispositivo.',
          ),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _ActivityForm extends ConsumerStatefulWidget {
  const _ActivityForm({required this.original, this.subjectId});

  final Activity? original;
  final String? subjectId;

  @override
  ConsumerState<_ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends ConsumerState<_ActivityForm> {
  late final Activity? _original = widget.original;
  late final _title = TextEditingController(text: _original?.title);
  late final _description = TextEditingController(text: _original?.description);
  late final _notes = TextEditingController(text: _original?.notes);
  late final _estimate = TextEditingController(
    text: switch (_original?.estimateMinutes) {
      final minutes? =>
        (minutes / 60)
            .toStringAsFixed(minutes % 60 == 0 ? 0 : 2)
            .replaceAll('.', ','),
      null => '',
    },
  );

  late String? _subjectId = _original?.subjectId ?? widget.subjectId;
  late ActivityType _type = _original?.type ?? ActivityType.work;
  late ActivityStatus _status = _original?.status ?? ActivityStatus.backlog;
  late ActivityPriority _priority =
      _original?.priority ?? ActivityPriority.medium;
  late DeadlineZone _zone = _original?.dueZone ?? DeadlineZone.spain;
  late int _buffer = _original?.bufferDays ?? Activity.defaultBufferDays;

  DateTime? _date;
  int _hour = SpainTime.defaultHour;
  int _minute = SpainTime.defaultMinute;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final due = _original?.dueAt;
    if (due != null) {
      // La fecha se edita en la misma zona en que se escribió.
      final wall = _zone == DeadlineZone.spain
          ? SpainTime.wallTime(due)
          : ref.read(toLocalProvider)(due);
      _date = Dates.dateOnly(wall);
      _hour = wall.hour;
      _minute = wall.minute;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _notes.dispose();
    _estimate.dispose();
    super.dispose();
  }

  DateTime? get _dueAt {
    final date = _date;
    if (date == null) return null;
    return deadlineInstant(
      date: date,
      hour: _hour,
      minute: _minute,
      zone: _zone,
    );
  }

  void _save() {
    setState(() => _submitted = true);
    final estimate = ActivityRules.estimate(_estimate.text);
    if (ActivityRules.title(_title.text) != null || !estimate.valid) return;

    final repository = ref.read(activitiesRepositoryProvider);
    final original = _original;
    final edited = (original ?? Activity(id: repository.newId(), title: ''))
        .copyWith(
          title: _title.text.trim(),
          description: _description.text.trim(),
          notes: _notes.text.trim(),
          subjectId: _subjectId,
          type: _type,
          status: _status,
          priority: _priority,
          dueAt: _dueAt,
          dueZone: _zone,
          bufferDays: _buffer,
          estimateMinutes: estimate.minutes,
        );

    guardWrite(
      original == null
          ? repository.create(edited)
          : repository.update(original, edited),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final subjects = ref.watch(subjectsProvider).value ?? const <Subject>[];
    final toLocal = ref.watch(toLocalProvider);
    final editing = _original != null;
    final titleError = _submitted ? ActivityRules.title(_title.text) : null;
    final estimateError =
        _submitted && !ActivityRules.estimate(_estimate.text).valid
        ? 'Escribe las horas como número, por ejemplo 1,5'
        : null;
    final subjectValue = subjects.any((s) => s.id == _subjectId)
        ? _subjectId
        : null;
    final due = _dueAt;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar actividad' : 'Nueva actividad'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        children: [
          TextField(
            controller: _title,
            autofocus: !editing,
            textCapitalization: TextCapitalization.sentences,
            maxLength: Activity.maxTitleLength,
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
            decoration: InputDecoration(
              labelText: 'Título',
              errorText: titleError,
              counterText: '',
            ),
          ),
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
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<ActivityType>(
            initialValue: _type,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: [
              for (final type in ActivityType.values)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: (type) => setState(() => _type = type ?? _type),
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('Fecha límite', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: DateField(
                  label: 'Día',
                  value: _date,
                  onChanged: (date) => setState(() => _date = date),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: TimeField(
                  label: 'Hora',
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
          const SizedBox(height: AppSpacing.sm),
          AppSegmented<DeadlineZone>(
            selected: _zone,
            onChanged: (zone) => setState(() => _zone = zone),
            segments: const [
              AppSegment(value: DeadlineZone.spain, label: 'Hora de España'),
              AppSegment(value: DeadlineZone.local, label: 'Mi hora'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            due == null
                ? 'Las entregas de UNIR vencen a las 23:59 de España. '
                      'Elige el día y la app calcula tu hora.'
                : _zone == DeadlineZone.spain
                ? 'En tu hora: ${DeadlineText.local(due, toLocal: toLocal)}'
                : 'En España: ${DeadlineText.spain(due, toLocal: toLocal)}',
            style: text.bodyMedium!.copyWith(color: c.inkSoft),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Colchón', style: text.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Cuántos días antes quieres tenerla lista. La fecha del campus '
            'es la máxima, no el día para entregar.',
            style: text.bodyMedium!.copyWith(color: c.inkSoft),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppSegmented<int>(
            selected: _buffer,
            onChanged: (days) => setState(() => _buffer = days),
            segments: [
              const AppSegment(value: 0, label: 'Ninguno'),
              const AppSegment(value: 1, label: '1 día'),
              const AppSegment(value: 2, label: '2 días'),
              const AppSegment(value: 3, label: '3 días'),
              // Un colchón mayor, puesto antes, se conserva como opción.
              if (_buffer > 3)
                AppSegment(value: _buffer, label: '$_buffer días'),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('Organización', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('Prioridad', style: text.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          AppSegmented<ActivityPriority>(
            selected: _priority,
            onChanged: (priority) => setState(() => _priority = priority),
            segments: [
              for (final priority in ActivityPriority.values)
                AppSegment(value: priority, label: priority.label),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<ActivityStatus>(
            initialValue: _status,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Estado'),
            items: [
              for (final status in ActivityStatus.values)
                DropdownMenuItem(value: status, child: Text(status.label)),
            ],
            onChanged: (status) => setState(() => _status = status ?? _status),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _estimate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
            decoration: InputDecoration(
              labelText: 'Tiempo estimado',
              hintText: '1,5',
              suffixText: 'horas',
              errorText: estimateError,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _description,
            textCapitalization: TextCapitalization.sentences,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _notes,
            textCapitalization: TextCapitalization.sentences,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Notas',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: editing ? 'Guardar cambios' : 'Agregar actividad',
            icon: LucideIcons.check,
            expand: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
