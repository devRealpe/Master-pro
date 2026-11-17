import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_router.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/time/clock_providers.dart';
import '../../activities/domain/activity.dart';
import '../../activities/presentation/activities_providers.dart';
import '../../activities/presentation/activity_card.dart';
import '../../subjects/domain/subject.dart';
import '../../subjects/presentation/subjects_providers.dart';

/// Plan: las actividades en lista. Kanban y sprints llegan en la Fase 2 como
/// otras vistas de estos mismos datos.
class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activitiesProvider);
    final filter = ref.watch(activityFilterProvider);

    return AppPage(
      title: 'Plan',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: filter.extraCount == 0
                ? 'Filtrar por tipo y prioridad'
                : 'Filtros activos: ${filter.extraCount}',
            icon: Badge(
              isLabelVisible: filter.extraCount > 0,
              label: Text('${filter.extraCount}'),
              child: const Icon(LucideIcons.listFilter),
            ),
            onPressed: () => showActivityFilters(context),
          ),
          IconButton(
            tooltip: 'Agregar actividad',
            icon: const Icon(LucideIcons.plus),
            onPressed: () => context.push(AppRoutes.newActivity),
          ),
        ],
      ),
      children: switch (activities) {
        AsyncData(:final value) => [_PlanList(all: value)],
        AsyncError() => [
          AppCard(
            child: ErrorState(
              message: 'No se pudieron leer tus actividades.',
              onRetry: () => retryActivities(ref),
            ),
          ),
        ],
        _ => const [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 90, height: 12),
                SizedBox(height: AppSpacing.xs),
                Skeleton(width: 220, height: 18),
                SizedBox(height: AppSpacing.sm),
                Skeleton(width: 140),
              ],
            ),
          ),
        ],
      },
    );
  }
}

const _sectionTitles = {
  Urgency.overdue: 'Vencidas',
  Urgency.today: 'Para hoy',
  Urgency.thisWeek: 'Esta semana',
  Urgency.later: 'Más adelante',
  Urgency.noDate: 'Sin fecha',
};

class _PlanList extends ConsumerWidget {
  const _PlanList({required this.all});

  final List<Activity> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (all.isEmpty) {
      return FadeSlideIn(
        child: AppCard(
          child: EmptyState(
            icon: LucideIcons.listTodo,
            title: 'Aún no hay actividades',
            message:
                'Registra tus trabajos, test y lecturas para ver qué '
                'vence primero.',
            actionLabel: 'Agregar actividad',
            onAction: () => context.push(AppRoutes.newActivity),
          ),
        ),
      );
    }

    final filter = ref.watch(activityFilterProvider);
    final controller = ref.read(activityFilterProvider.notifier);
    final subjects = ref.watch(subjectsProvider).value ?? const <Subject>[];
    final now = ref.watch(clockProvider)();
    final toLocal = ref.watch(toLocalProvider);
    final c = context.colors;

    Subject? subjectOf(Activity activity) =>
        subjects.where((s) => s.id == activity.subjectId).firstOrNull;

    final pending = all.where((a) => !a.isDone).length;
    final shown = [
      for (final a in all)
        if (filter.matches(a)) a,
    ];

    Widget card(Activity activity, int index) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FadeSlideIn(
        key: ValueKey(activity.id),
        index: index,
        child: ActivityCard(
          activity: activity,
          subject: subjectOf(activity),
          onTap: () => context.push(AppRoutes.activity(activity.id)),
        ),
      ),
    );

    final List<Widget> list;
    if (shown.isEmpty) {
      list = [
        AppCard(
          child: EmptyState(
            icon: filter.showDone ? LucideIcons.circleCheck : LucideIcons.inbox,
            title: filter.showDone
                ? 'Nada hecho con este filtro'
                : 'Nada pendiente con este filtro',
            message: 'Cambia la asignatura o los filtros para ver más.',
          ),
        ),
      ];
    } else if (filter.showDone) {
      list = [for (final (i, a) in shown.indexed) card(a, i)];
    } else {
      var index = 0;
      list = [
        for (final urgency in Urgency.values)
          if (shown.any(
            (a) => a.urgency(now, toLocal: toLocal) == urgency,
          )) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                bottom: AppSpacing.xs,
              ),
              child: Overline(
                _sectionTitles[urgency]!,
                color: urgency == Urgency.overdue ? c.danger : null,
              ),
            ),
            for (final a in shown)
              if (a.urgency(now, toLocal: toLocal) == urgency) card(a, index++),
          ],
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSegmented<bool>(
          selected: filter.showDone,
          onChanged: (done) =>
              controller.update(filter.copyWith(showDone: done)),
          segments: [
            AppSegment(value: false, label: 'Por hacer ($pending)'),
            AppSegment(value: true, label: 'Hechas (${all.length - pending})'),
          ],
        ),
        if (subjects.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          AppChoiceChips<String?>(
            selected: subjects.any((s) => s.id == filter.subjectId)
                ? filter.subjectId
                : null,
            onChanged: (id) =>
                controller.update(filter.copyWith(subjectId: id)),
            choices: [
              const AppChoice(value: null, label: 'Todas'),
              for (final s in subjects)
                AppChoice(
                  value: s.id,
                  label: s.name,
                  dotColor: c.subject(s.colorIndex),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        ...list,
      ],
    );
  }
}

/// Hoja con los filtros por tipo y prioridad.
Future<void> showActivityFilters(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(activityFilterProvider);
    final controller = ref.read(activityFilterProvider.notifier);
    final text = context.text;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Filtros', style: text.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Text('Tipo', style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          AppChoiceChips<ActivityType?>(
            wrap: true,
            selected: filter.type,
            onChanged: (type) => controller.update(filter.copyWith(type: type)),
            choices: [
              const AppChoice(value: null, label: 'Todos'),
              for (final type in ActivityType.values)
                AppChoice(value: type, label: type.label),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Prioridad', style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          AppChoiceChips<ActivityPriority?>(
            wrap: true,
            selected: filter.priority,
            onChanged: (priority) =>
                controller.update(filter.copyWith(priority: priority)),
            choices: [
              const AppChoice(value: null, label: 'Todas'),
              for (final priority in ActivityPriority.values)
                AppChoice(value: priority, label: priority.label),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Ver resultados',
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
