import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_router.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/sync/write_guard.dart';
import '../../../core/time/clock_providers.dart';
import '../../../core/time/deadline_clock.dart';
import '../../grades/domain/grading_scheme.dart';
import '../../subjects/domain/subject.dart';
import '../../subjects/presentation/subjects_providers.dart';
import '../domain/activity.dart';
import 'activities_providers.dart';
import 'activity_card.dart';
import 'activity_grade_card.dart';

/// Detalle de una actividad: fecha límite, estado, pasos y notas.
class ActivityDetailPage extends ConsumerWidget {
  const ActivityDetailPage({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(activityProvider(activityId))) {
      AsyncData(:final value?) => _Detail(activity: value),
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

class _Detail extends ConsumerWidget {
  const _Detail({required this.activity});

  final Activity activity;

  void _update(WidgetRef ref, Activity edited) {
    guardWrite(ref.read(activitiesRepositoryProvider).update(activity, edited));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta actividad?'),
        content: Text(
          '«${activity.title}» irá a la papelera. Puedes deshacerlo justo '
          'después de eliminarla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final repository = ref.read(activitiesRepositoryProvider);
    final deleted = activity.copyWith(deletedAt: DateTime.now().toUtc());
    guardWrite(repository.update(activity, deleted));
    context.pop();
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Actividad eliminada'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => guardWrite(repository.update(deleted, activity)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = context.text;
    final subjects = ref.watch(subjectsProvider).value ?? const <Subject>[];
    final subject = subjects
        .where((s) => s.id == activity.subjectId)
        .firstOrNull;
    final now = ref.watch(clockProvider);
    final estimate = activity.estimateMinutes;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(LucideIcons.pencil),
            onPressed: () => context.push(AppRoutes.editActivity(activity.id)),
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(LucideIcons.trash2),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subject != null)
                  SubjectLabel(
                    name: subject.name,
                    colorIndex: subject.colorIndex,
                  )
                else
                  const Overline('Sin asignatura'),
                const SizedBox(height: AppSpacing.xs),
                Semantics(
                  header: true,
                  child: Text(activity.title, style: text.headlineMedium),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    DeadlineTag(activity: activity),
                    AppTag(label: activity.type.label),
                    AppTag(
                      label:
                          'Prioridad ${activity.priority.label.toLowerCase()}',
                      tone: switch (activity.priority) {
                        ActivityPriority.urgent => AppTone.danger,
                        ActivityPriority.high => AppTone.warning,
                        _ => AppTone.neutral,
                      },
                    ),
                    if (estimate != null)
                      AppTag(
                        label: ActivityRules.formatEstimate(estimate),
                        icon: LucideIcons.clock,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FadeSlideIn(index: 1, child: _DeadlineCard(activity: activity)),
          const SizedBox(height: AppSpacing.sm),
          FadeSlideIn(
            index: 2,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Overline('Estado'),
                  const SizedBox(height: AppSpacing.xs),
                  AppChoiceChips<ActivityStatus>(
                    wrap: true,
                    selected: activity.status,
                    onChanged: (status) =>
                        _update(ref, activity.copyWith(status: status)),
                    choices: [
                      for (final status in ActivityStatus.values)
                        AppChoice(value: status, label: status.label),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (activity.isSubmitted)
                    AppButton(
                      label: 'Deshacer la entrega',
                      variant: AppButtonVariant.secondary,
                      icon: LucideIcons.rotateCcw,
                      expand: true,
                      onPressed: () => _update(ref, activity.unsubmit()),
                    )
                  else
                    AppButton(
                      label: 'Marcar como entregada',
                      icon: LucideIcons.send,
                      expand: true,
                      onPressed: () => _update(ref, activity.submit(now())),
                    ),
                ],
              ),
            ),
          ),
          if (activity.countsForGrade) ...[
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(
              index: 3,
              child: ActivityGradeCard(
                activity: activity,
                scheme: subject?.grading ?? GradingScheme.unir,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          FadeSlideIn(
            index: 3,
            child: _SubtasksCard(
              activity: activity,
              color: subject == null ? null : c.subject(subject.colorIndex),
            ),
          ),
          for (final (label, body) in [
            ('Descripción', activity.description),
            ('Notas', activity.notes),
          ])
            if (body.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Overline(label),
                    const SizedBox(height: AppSpacing.xs),
                    Text(body, style: text.bodyLarge),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

/// Fecha límite en tu hora y en la de España, con la fecha objetivo.
class _DeadlineCard extends ConsumerWidget {
  const _DeadlineCard({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = context.text;
    final toLocal = ref.watch(toLocalProvider);
    final due = activity.dueAt;
    final target = activity.targetAt;
    final submitted = activity.submittedAt;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Overline('Fecha límite'),
          const SizedBox(height: AppSpacing.xs),
          if (due == null)
            Text(
              'Sin fecha límite',
              style: text.titleMedium!.copyWith(color: c.inkSoft),
            )
          else ...[
            Text(
              DeadlineText.local(due, toLocal: toLocal),
              style: text.headlineSmall!.copyWith(
                fontFeatures: AppTypography.tabular,
              ),
            ),
            if (activity.dueZone == DeadlineZone.spain)
              Text(
                'Hora oficial: ${DeadlineText.spain(due, toLocal: toLocal)}',
                style: text.bodyMedium!.copyWith(color: c.inkSoft),
              ),
            if (target != null &&
                activity.bufferDays > 0 &&
                !activity.isDone) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(LucideIcons.target, size: 16, color: c.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tu meta: ${DeadlineText.local(target, toLocal: toLocal)}',
                      style: text.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (submitted != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(LucideIcons.circleCheck, size: 16, color: c.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Entregada: '
                    '${DeadlineText.local(submitted, toLocal: toLocal)}',
                    style: text.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Pasos de la actividad: marcar, agregar y quitar.
class _SubtasksCard extends ConsumerStatefulWidget {
  const _SubtasksCard({required this.activity, required this.color});

  final Activity activity;
  final Color? color;

  @override
  ConsumerState<_SubtasksCard> createState() => _SubtasksCardState();
}

class _SubtasksCardState extends ConsumerState<_SubtasksCard> {
  final _newTitle = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _newTitle.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _update(Activity edited) {
    guardWrite(
      ref.read(activitiesRepositoryProvider).update(widget.activity, edited),
    );
  }

  void _add() {
    if (ActivityRules.subtaskTitle(_newTitle.text) != null) return;
    final repository = ref.read(activitiesRepositoryProvider);
    _update(
      widget.activity.withSubtask(
        Subtask(id: repository.newId(), title: _newTitle.text.trim()),
      ),
    );
    _newTitle.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final activity = widget.activity;
    final subtasks = activity.subtasks;
    final full = subtasks.length >= Activity.maxSubtasks;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Overline('Pasos')),
              if (subtasks.isNotEmpty)
                Text(
                  '${activity.subtasksDone} de ${subtasks.length}',
                  style: text.labelMedium!.copyWith(
                    fontFeatures: AppTypography.tabular,
                  ),
                ),
            ],
          ),
          if (subtasks.isEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Divide el trabajo en pasos pequeños para ver cómo avanzas.',
              style: text.bodyMedium!.copyWith(color: c.inkSoft),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.xs),
            AppProgressBar(
              value: subtasks.isEmpty
                  ? 0
                  : activity.subtasksDone / subtasks.length,
              color: widget.color,
              semanticLabel: 'Pasos completados',
            ),
            const SizedBox(height: AppSpacing.xxs),
            for (final subtask in subtasks)
              Row(
                children: [
                  Checkbox(
                    value: subtask.done,
                    onChanged: (_) =>
                        _update(activity.toggleSubtask(subtask.id)),
                    semanticLabel: subtask.title,
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _update(activity.toggleSubtask(subtask.id)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          subtask.title,
                          style: text.bodyLarge!.copyWith(
                            color: subtask.done ? c.inkMuted : null,
                            decoration: subtask.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quitar paso: ${subtask.title}',
                    icon: Icon(LucideIcons.x, size: 18, color: c.inkMuted),
                    onPressed: () =>
                        _update(activity.withoutSubtask(subtask.id)),
                  ),
                ],
              ),
          ],
          const SizedBox(height: AppSpacing.xs),
          if (full)
            Text(
              'Llegaste al máximo de ${Activity.maxSubtasks} pasos.',
              style: text.bodySmall,
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTitle,
                    focusNode: _focus,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: Subtask.maxTitleLength,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(
                      hintText: 'Agregar un paso',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filledTonal(
                  tooltip: 'Agregar paso',
                  icon: const Icon(LucideIcons.plus),
                  onPressed: _add,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
