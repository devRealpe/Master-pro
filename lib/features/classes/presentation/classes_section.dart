import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/format/decimals.dart';
import '../../../core/sync/write_guard.dart';
import '../../../core/time/clock_providers.dart';
import '../../../core/time/dates.dart';
import '../../../core/time/deadline_clock.dart';
import '../../grades/presentation/grades_providers.dart';
import '../../subjects/domain/subject.dart';
import '../domain/class_session.dart';

/// Clases en vivo de una asignatura: registrar asistencia y sus puntos.
class ClassesSection extends ConsumerWidget {
  const ClassesSection({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions =
        ref.watch(subjectClassSessionsProvider(subject.id)).value ??
        const <ClassSession>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Clases en vivo',
          actionLabel: 'Registrar',
          onAction: () => showClassForm(context, subject: subject),
        ),
        if (sessions.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: LucideIcons.video,
              title: 'Sin clases registradas',
              message:
                  'Registra cada clase en vivo para sumar sus puntos de '
                  'asistencia.',
            ),
          )
        else
          for (final session in sessions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ClassCard(subject: subject, session: session),
            ),
      ],
    );
  }
}

class _ClassCard extends ConsumerWidget {
  const _ClassCard({required this.subject, required this.session});

  final Subject subject;
  final ClassSession session;

  void _setAttended(WidgetRef ref, bool attended) {
    guardWrite(
      ref
          .read(classSessionsRepositoryProvider)
          .update(session, session.copyWith(attended: attended)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = context.text;
    final toLocal = ref.watch(toLocalProvider);
    final points = Decimals.format(session.points);

    return AppCard(
      onTap: () => showClassForm(context, subject: subject, original: session),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DeadlineText.local(session.startsAt, toLocal: toLocal),
            style: text.bodySmall!.copyWith(
              fontFeatures: AppTypography.tabular,
            ),
          ),
          Text(session.label, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          switch (session.attended) {
            true => AppTag(
              label: session.points > 0 ? 'Asististe · +$points' : 'Asististe',
              tone: AppTone.success,
              icon: LucideIcons.check,
            ),
            false => const AppTag(label: 'No asististe'),
            null => Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Asistí',
                    icon: LucideIcons.check,
                    variant: AppButtonVariant.secondary,
                    expand: true,
                    onPressed: () => _setAttended(ref, true),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppButton(
                    label: 'No asistí',
                    variant: AppButtonVariant.ghost,
                    expand: true,
                    onPressed: () => _setAttended(ref, false),
                  ),
                ),
              ],
            ),
          },
          if (session.attended == null && session.points > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                'Asistir suma $points puntos',
                style: text.bodySmall!.copyWith(color: c.inkMuted),
              ),
            ),
        ],
      ),
    );
  }
}

/// Abre la hoja para registrar una clase o editar [original].
Future<void> showClassForm(
  BuildContext context, {
  required Subject subject,
  ClassSession? original,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ClassForm(subject: subject, original: original),
  );
}

class _ClassForm extends ConsumerStatefulWidget {
  const _ClassForm({required this.subject, required this.original});

  final Subject subject;
  final ClassSession? original;

  @override
  ConsumerState<_ClassForm> createState() => _ClassFormState();
}

class _ClassFormState extends ConsumerState<_ClassForm> {
  late final ClassSession? _original = widget.original;
  late final _topic = TextEditingController(text: _original?.topic);
  late final _duration = TextEditingController(
    text: _original?.durationMinutes?.toString() ?? '',
  );
  late final _points = TextEditingController(
    text: Decimals.format(
      _original?.points ?? widget.subject.grading.attendancePoints,
    ),
  );
  late final _guideUrl = TextEditingController(text: _original?.guideUrl);
  late final _notes = TextEditingController(text: _original?.notes);
  late bool? _attended = _original?.attended;
  late DateTime _date;
  late int _hour;
  late int _minute;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Una clase nueva propone el momento actual, redondeado a la hora.
    final wall = ref.read(toLocalProvider)(
      _original?.startsAt ?? ref.read(clockProvider)(),
    );
    _date = Dates.dateOnly(wall);
    _hour = wall.hour;
    _minute = _original == null ? 0 : wall.minute;
  }

  @override
  void dispose() {
    for (final c in [_topic, _duration, _points, _guideUrl, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _parsedPoints => Decimals.parse(_points.text);

  /// Vacío es válido (sin duración); si hay texto, debe ser un entero > 0.
  bool get _durationValid {
    final text = _duration.text.trim();
    if (text.isEmpty) return true;
    final minutes = int.tryParse(text);
    return minutes != null && minutes > 0 && minutes <= 600;
  }

  void _save() {
    setState(() => _submitted = true);
    final points = _parsedPoints;
    if (points == null || points < 0 || !_durationValid) return;

    final repository = ref.read(classSessionsRepositoryProvider);
    final startsAt = ref.read(fromLocalProvider)(
      DateTime(_date.year, _date.month, _date.day, _hour, _minute),
    );
    final original = _original;
    final edited =
        (original ??
                ClassSession(
                  id: repository.newId(),
                  subjectId: widget.subject.id,
                  startsAt: startsAt,
                ))
            .copyWith(
              startsAt: startsAt,
              topic: _topic.text.trim(),
              durationMinutes: int.tryParse(_duration.text.trim()),
              attended: _attended,
              points: points,
              guideUrl: _guideUrl.text.trim(),
              notes: _notes.text.trim(),
            );
    guardWrite(
      original == null
          ? repository.create(edited)
          : repository.update(original, edited),
    );
    Navigator.of(context).pop();
  }

  void _delete() {
    final original = _original;
    if (original == null) return;
    final repository = ref.read(classSessionsRepositoryProvider);
    final deleted = original.copyWith(deletedAt: DateTime.now().toUtc());
    guardWrite(repository.update(original, deleted));
    Navigator.of(context).pop();
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Clase eliminada'),
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
    final pointsError = _submitted && (_parsedPoints ?? -1) < 0
        ? 'Escribe un número, por ejemplo 0,4'
        : null;
    final durationError = _submitted && !_durationValid
        ? 'Minutos, en números'
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
            _original == null ? 'Registrar clase' : 'Editar clase',
            style: text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _topic,
            textCapitalization: TextCapitalization.sentences,
            maxLength: ClassSession.maxTopicLength,
            decoration: const InputDecoration(
              labelText: 'Tema',
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
          const SizedBox(height: AppSpacing.md),
          Text('Asistencia', style: text.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          AppSegmented<bool?>(
            selected: _attended,
            onChanged: (value) => setState(() => _attended = value),
            segments: const [
              AppSegment(value: null, label: 'Sin registrar'),
              AppSegment(value: true, label: 'Asistí'),
              AppSegment(value: false, label: 'No asistí'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _points,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) {
                    if (_submitted) setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Puntos por asistir',
                    errorText: pointsError,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (_submitted) setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Duración',
                    suffixText: 'min',
                    errorText: durationError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _guideUrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Enlace a la guía de estudio',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _notes,
            textCapitalization: TextCapitalization.sentences,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Apuntes',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _original == null ? 'Registrar clase' : 'Guardar cambios',
            icon: LucideIcons.check,
            onPressed: _save,
          ),
          if (_original != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: 'Eliminar clase',
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
