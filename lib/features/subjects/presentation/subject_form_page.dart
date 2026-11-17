import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/sync/write_guard.dart';
import '../../../core/time/dates.dart';
import '../domain/period.dart';
import '../domain/subject.dart';
import 'subjects_providers.dart';

/// Alta y edición de una asignatura. Con [subjectId] edita; sin él, crea.
class SubjectFormPage extends ConsumerWidget {
  const SubjectFormPage({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = subjectId;
    if (id == null) return const _SubjectForm(original: null);

    return switch (ref.watch(subjectProvider(id))) {
      AsyncData(:final value?) => _SubjectForm(original: value),
      AsyncData() || AsyncError() => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: ErrorState(
            title: 'Asignatura no encontrada',
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

class _SubjectForm extends ConsumerStatefulWidget {
  const _SubjectForm({required this.original});

  final Subject? original;

  @override
  ConsumerState<_SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends ConsumerState<_SubjectForm> {
  late final _name = TextEditingController(text: widget.original?.name);
  late final _teacher = TextEditingController(text: widget.original?.teacher);
  late final _description = TextEditingController(
    text: widget.original?.description,
  );
  late String? _periodId = widget.original?.periodId;
  late DateTime? _start = widget.original?.startDate;
  late DateTime? _end = widget.original?.endDate;
  late SubjectStatus _status = widget.original?.status ?? SubjectStatus.active;
  late int _color = widget.original?.colorIndex ?? _firstFreeColor();
  bool _submitted = false;

  /// Propone un color que todavía no use otra asignatura.
  int _firstFreeColor() {
    final used = {
      for (final s in ref.read(subjectsProvider).value ?? const <Subject>[])
        s.colorIndex,
    };
    for (var i = 0; i < AppColors.subjectNames.length; i++) {
      if (!used.contains(i)) return i;
    }
    return 0;
  }

  @override
  void dispose() {
    _name.dispose();
    _teacher.dispose();
    _description.dispose();
    super.dispose();
  }

  void _selectPeriod(String? id, List<Period> periods) {
    setState(() {
      _periodId = id;
      final period = periods.where((p) => p.id == id).firstOrNull;
      // Al elegir periodo se proponen sus fechas, sin pisar las ya puestas.
      if (period != null) {
        _start ??= period.startDate;
        _end ??= period.endDate;
      }
    });
  }

  void _save() {
    setState(() => _submitted = true);
    if (SubjectRules.name(_name.text) != null ||
        SubjectRules.dates(_start, _end) != null) {
      return;
    }

    final repository = ref.read(subjectsRepositoryProvider);
    final original = widget.original;
    final edited = (original ?? Subject(id: repository.newId(), name: ''))
        .copyWith(
          name: _name.text.trim(),
          teacher: _teacher.text.trim(),
          description: _description.text.trim(),
          periodId: _periodId,
          startDate: _start,
          endDate: _end,
          status: _status,
          colorIndex: _color,
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
    final text = context.text;
    final periods = ref.watch(periodsProvider).value ?? const <Period>[];
    final editing = widget.original != null;
    final nameError = _submitted ? SubjectRules.name(_name.text) : null;
    final datesError = _submitted ? SubjectRules.dates(_start, _end) : null;
    // Si el periodo guardado ya no existe, el campo vuelve a «Sin periodo».
    final periodValue = periods.any((p) => p.id == _periodId)
        ? _periodId
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar asignatura' : 'Nueva asignatura'),
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
            controller: _name,
            autofocus: !editing,
            textCapitalization: TextCapitalization.sentences,
            maxLength: Subject.maxNameLength,
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
            decoration: InputDecoration(
              labelText: 'Nombre',
              errorText: nameError,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _teacher,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Docente'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _description,
            textCapitalization: TextCapitalization.sentences,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Periodo y fechas', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String?>(
            key: ValueKey(periodValue),
            initialValue: periodValue,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Periodo'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Sin periodo')),
              for (final period in periods)
                DropdownMenuItem(
                  value: period.id,
                  child: Text(period.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) => _selectPeriod(id, periods),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DateField(
                  label: 'Inicio',
                  value: _start,
                  onChanged: (date) => setState(() => _start = date),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DateField(
                  label: 'Fin',
                  value: _end,
                  onChanged: (date) => setState(() => _end = date),
                ),
              ),
            ],
          ),
          if (datesError != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              datesError,
              style: text.bodySmall!.copyWith(color: context.colors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Estado', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppSegmented<SubjectStatus>(
            selected: _status,
            onChanged: (status) => setState(() => _status = status),
            segments: [
              for (final status in SubjectStatus.values)
                AppSegment(value: status, label: status.label),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Color', style: text.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Para reconocerla en el calendario, el tablero y los gráficos.',
            style: text.bodyMedium!.copyWith(color: context.colors.inkSoft),
          ),
          const SizedBox(height: AppSpacing.xs),
          SubjectColorPicker(
            selected: _color,
            onChanged: (index) => setState(() => _color = index),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: editing ? 'Guardar cambios' : 'Agregar asignatura',
            icon: LucideIcons.check,
            expand: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

/// Texto de la fecha actual, para las pruebas y los resúmenes.
String describeSubjectDates(Subject subject) {
  final start = subject.startDate;
  if (start == null) return 'Sin fechas';
  return Dates.formatRange(start, subject.endDate);
}
