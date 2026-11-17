import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_router.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/sync/write_guard.dart';
import '../../../core/time/dates.dart';
import '../../activities/domain/activity.dart';
import '../../activities/presentation/activities_providers.dart';
import '../../activities/presentation/activity_card.dart';
import '../../classes/presentation/classes_section.dart';
import '../../grades/presentation/grade_marker_card.dart';
import '../domain/period.dart';
import '../domain/subject.dart';
import 'subject_form_page.dart';
import 'subjects_page.dart';
import 'subjects_providers.dart';

/// Detalle de una asignatura. Irá reuniendo sus actividades, calificaciones,
/// clases y material a medida que esos módulos existan.
class SubjectDetailPage extends ConsumerWidget {
  const SubjectDetailPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subject = ref.watch(subjectProvider(subjectId));

    return switch (subject) {
      // Una asignatura recién eliminada se sigue mostrando mientras la
      // pantalla se cierra; desde la lista ya no se puede llegar a ella.
      AsyncData(:final value?) => _Detail(subject: value),
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

enum _Action { toggleFinished, delete }

class _Detail extends ConsumerWidget {
  const _Detail({required this.subject});

  final Subject subject;

  void _setStatus(WidgetRef ref, SubjectStatus status) {
    guardWrite(
      ref
          .read(subjectsRepositoryProvider)
          .update(subject, subject.copyWith(status: status)),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta asignatura?'),
        content: Text(
          '«${subject.name}» irá a la papelera. Puedes deshacerlo justo '
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

    final repository = ref.read(subjectsRepositoryProvider);
    final deleted = subject.copyWith(deletedAt: DateTime.now().toUtc());
    guardWrite(repository.update(subject, deleted));
    context.pop();

    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Asignatura eliminada'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => guardWrite(repository.update(deleted, subject)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = context.text;
    final color = c.subject(subject.colorIndex);
    final periods = ref.watch(periodsProvider).value ?? const <Period>[];
    final period = periods.where((p) => p.id == subject.periodId).firstOrNull;
    final finished = subject.status == SubjectStatus.finished;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(LucideIcons.pencil),
            onPressed: () => context.push(AppRoutes.editSubject(subject.id)),
          ),
          PopupMenuButton<_Action>(
            tooltip: 'Más acciones',
            icon: const Icon(LucideIcons.ellipsisVertical),
            onSelected: (action) => switch (action) {
              _Action.toggleFinished => _setStatus(
                ref,
                finished ? SubjectStatus.active : SubjectStatus.finished,
              ),
              _Action.delete => _delete(context, ref),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _Action.toggleFinished,
                child: Text(
                  finished ? 'Volver a «En curso»' : 'Marcar como finalizada',
                ),
              ),
              const PopupMenuItem(
                value: _Action.delete,
                child: Text('Eliminar'),
              ),
            ],
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
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 12),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: Overline(period?.name ?? 'Sin periodo')),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Semantics(
                  header: true,
                  child: Text(subject.name, style: text.headlineMedium),
                ),
                if (subject.teacher.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Icon(LucideIcons.user, size: 16, color: c.inkMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          subject.teacher,
                          style: text.bodyLarge!.copyWith(color: c.inkSoft),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                AppTag(
                  label: subject.status.label,
                  tone: toneForStatus(subject.status),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FadeSlideIn(index: 1, child: GradeMarkerCard(subject: subject)),
          const SizedBox(height: AppSpacing.sm),
          FadeSlideIn(index: 2, child: _TimelineCard(subject: subject)),
          if (subject.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(
              index: 2,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Overline('Descripción'),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subject.description, style: text.bodyLarge),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FadeSlideIn(index: 3, child: _SubjectActivities(subject: subject)),
          const SizedBox(height: AppSpacing.lg),
          FadeSlideIn(index: 4, child: ClassesSection(subject: subject)),
        ],
      ),
    );
  }
}

/// Fechas de la asignatura y cuánto del periodo ha transcurrido.
class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final today = Dates.today();
    final start = subject.startDate;
    final end = subject.endDate;
    final progress = subject.progressOn(today);

    final String status;
    if (start == null || end == null) {
      status = 'Agrega las fechas para ver el avance del periodo.';
    } else if (today.isBefore(start)) {
      final days = Dates.daysBetween(today, start);
      status = days == 1 ? 'Empieza mañana' : 'Empieza en $days días';
    } else if (today.isAfter(end)) {
      status = 'El periodo de clases terminó';
    } else {
      final days = Dates.daysBetween(today, end);
      status = switch (days) {
        0 => 'Hoy es el último día',
        1 => 'Falta 1 día',
        _ => 'Faltan $days días',
      };
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Overline('Periodo de clases'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            describeSubjectDates(subject),
            style: text.titleMedium!.copyWith(
              fontFeatures: AppTypography.tabular,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppProgressBar(
              value: progress,
              color: c.subject(subject.colorIndex),
              semanticLabel: 'Avance del periodo',
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(status, style: text.bodyMedium!.copyWith(color: c.inkSoft)),
        ],
      ),
    );
  }
}

/// Actividades pendientes de la asignatura.
class _SubjectActivities extends ConsumerWidget {
  const _SubjectActivities({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(activitiesProvider).value ?? const <Activity>[];
    final mine = [
      for (final a in all)
        if (a.subjectId == subject.id) a,
    ];
    final pending = [
      for (final a in mine)
        if (!a.isDone) a,
    ];
    final done = mine.length - pending.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Actividades',
          actionLabel: 'Agregar',
          onAction: () => context.push(AppRoutes.newActivityFor(subject.id)),
        ),
        if (done > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              done == 1 ? '1 hecha' : '$done hechas',
              style: context.text.bodySmall,
            ),
          ),
        if (pending.isEmpty)
          AppCard(
            child: EmptyState(
              icon: LucideIcons.listTodo,
              title: mine.isEmpty
                  ? 'Sin actividades todavía'
                  : 'Nada pendiente aquí',
              message: mine.isEmpty
                  ? 'Agrega los trabajos y test de esta asignatura.'
                  : 'Todas las actividades de esta asignatura están hechas.',
            ),
          )
        else
          for (final activity in pending)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ActivityCard(
                activity: activity,
                subject: null,
                onTap: () => context.push(AppRoutes.activity(activity.id)),
              ),
            ),
      ],
    );
  }
}
