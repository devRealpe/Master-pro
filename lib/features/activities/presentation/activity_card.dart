import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/time/clock_providers.dart';
import '../../../core/time/deadline_clock.dart';
import '../../subjects/domain/subject.dart';
import '../domain/activity.dart';

AppTone toneForUrgency(Urgency urgency) => switch (urgency) {
  Urgency.overdue => AppTone.danger,
  Urgency.today => AppTone.warning,
  Urgency.thisWeek => AppTone.primary,
  Urgency.later || Urgency.noDate => AppTone.neutral,
};

AppTone toneForActivityStatus(ActivityStatus status) => switch (status) {
  ActivityStatus.backlog => AppTone.neutral,
  ActivityStatus.next => AppTone.info,
  ActivityStatus.inProgress => AppTone.primary,
  ActivityStatus.inReview => AppTone.accent,
  ActivityStatus.done => AppTone.success,
};

/// Etiqueta con el estado de la entrega o con lo que falta para la fecha
/// límite. No aparece si la actividad no tiene fecha ni se ha entregado.
class DeadlineTag extends ConsumerWidget {
  const DeadlineTag({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (activity.isSubmitted) {
      return activity.submittedLate
          ? const AppTag(
              label: 'Entregada tarde',
              tone: AppTone.warning,
              icon: LucideIcons.triangleAlert,
            )
          : const AppTag(
              label: 'Entregada',
              tone: AppTone.success,
              icon: LucideIcons.check,
            );
    }
    final due = activity.dueAt;
    if (due == null || activity.isDone) return const SizedBox.shrink();

    final now = ref.watch(clockProvider)();
    final toLocal = ref.watch(toLocalProvider);
    final urgency = activity.urgency(now, toLocal: toLocal);
    return AppTag(
      label: DeadlineText.countdown(due, now: now, toLocal: toLocal),
      tone: toneForUrgency(urgency),
      icon: urgency == Urgency.overdue
          ? LucideIcons.triangleAlert
          : LucideIcons.clock,
    );
  }
}

/// Tarjeta de una actividad en las listas.
class ActivityCard extends ConsumerWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.subject,
    required this.onTap,
  });

  final Activity activity;
  final Subject? subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = context.text;
    final toLocal = ref.watch(toLocalProvider);
    final due = activity.dueAt;
    final subject = this.subject;
    final important = activity.priority.index >= ActivityPriority.high.index;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subject != null) ...[
            SubjectLabel(name: subject.name, colorIndex: subject.colorIndex),
            const SizedBox(height: AppSpacing.xxs),
          ],
          Text(
            activity.title,
            style: text.titleMedium!.copyWith(
              color: activity.isDone ? c.inkMuted : null,
              decoration: activity.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          if (due != null && !activity.isDone) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              [
                DeadlineText.local(due, toLocal: toLocal),
                if (activity.dueZone == DeadlineZone.spain)
                  DeadlineText.spain(due, toLocal: toLocal),
              ].join(' · '),
              style: text.bodySmall!.copyWith(
                fontFeatures: AppTypography.tabular,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              DeadlineTag(activity: activity),
              AppTag(label: activity.type.label),
              if (!activity.isDone && activity.status != ActivityStatus.backlog)
                AppTag(
                  label: activity.status.label,
                  tone: toneForActivityStatus(activity.status),
                ),
              if (important && !activity.isDone)
                AppTag(
                  label: 'Prioridad ${activity.priority.label.toLowerCase()}',
                  tone: activity.priority == ActivityPriority.urgent
                      ? AppTone.danger
                      : AppTone.warning,
                  icon: LucideIcons.flag,
                ),
            ],
          ),
          if (activity.subtasks.isNotEmpty && !activity.isDone) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppProgressBar(
                    value: activity.progress,
                    color: subject == null
                        ? null
                        : c.subject(subject.colorIndex),
                    semanticLabel: 'Pasos completados',
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${activity.subtasksDone}/${activity.subtasks.length}',
                  style: text.labelMedium!.copyWith(
                    fontFeatures: AppTypography.tabular,
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
