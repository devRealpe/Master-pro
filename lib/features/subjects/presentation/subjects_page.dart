import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_router.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/time/dates.dart';
import '../domain/period.dart';
import '../domain/subject.dart';
import 'subjects_providers.dart';

/// Asignaturas: las actuales y el historial de las finalizadas.
class SubjectsPage extends ConsumerStatefulWidget {
  const SubjectsPage({super.key});

  @override
  ConsumerState<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends ConsumerState<SubjectsPage> {
  bool _history = false;

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final periods = ref.watch(periodsProvider).value ?? const <Period>[];

    return AppPage(
      title: 'Asignaturas',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Periodos y fechas clave',
            icon: const Icon(LucideIcons.calendarRange),
            onPressed: () => context.push(AppRoutes.periods),
          ),
          IconButton(
            tooltip: 'Agregar asignatura',
            icon: const Icon(LucideIcons.plus),
            onPressed: () => context.push(AppRoutes.newSubject),
          ),
        ],
      ),
      children: switch (subjects) {
        AsyncData(:final value) => _content(value, periods),
        AsyncError() => [
          AppCard(
            child: ErrorState(
              message: 'No se pudieron leer tus asignaturas.',
              onRetry: () => retrySubjects(ref),
            ),
          ),
        ],
        _ => const [_LoadingList()],
      },
    );
  }

  List<Widget> _content(List<Subject> all, List<Period> periods) {
    if (all.isEmpty) {
      return [
        FadeSlideIn(
          child: AppCard(
            child: EmptyState(
              icon: LucideIcons.bookOpen,
              title: 'Registra tus asignaturas',
              message:
                  'Cada una reunirá sus actividades, calificaciones, '
                  'clases y material.',
              actionLabel: 'Agregar asignatura',
              onAction: () => context.push(AppRoutes.newSubject),
            ),
          ),
        ),
      ];
    }

    final current = [
      for (final s in all)
        if (s.status != SubjectStatus.finished) s,
    ];
    final finished = [
      for (final s in all)
        if (s.status == SubjectStatus.finished) s,
    ];
    final shown = _history ? finished : current;

    return [
      AppSegmented<bool>(
        selected: _history,
        onChanged: (value) => setState(() => _history = value),
        segments: [
          AppSegment(value: false, label: 'Actuales (${current.length})'),
          AppSegment(value: true, label: 'Historial (${finished.length})'),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      if (shown.isEmpty)
        AppCard(
          child: EmptyState(
            icon: _history ? LucideIcons.archive : LucideIcons.bookOpen,
            title: _history
                ? 'Aún no hay asignaturas finalizadas'
                : 'No tienes asignaturas en curso',
            message: _history
                ? 'Al finalizar una asignatura se guarda aquí con todo su '
                      'contenido.'
                : 'Agrega las de tu próximo periodo o revisa el historial.',
          ),
        )
      else
        for (final (index, subject) in shown.indexed) ...[
          FadeSlideIn(
            key: ValueKey(subject.id),
            index: index,
            child: SubjectCard(
              subject: subject,
              period: periods
                  .where((p) => p.id == subject.periodId)
                  .firstOrNull,
              onTap: () => context.push(AppRoutes.subject(subject.id)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
    ];
  }
}

AppTone toneForStatus(SubjectStatus status) => switch (status) {
  SubjectStatus.planned => AppTone.info,
  SubjectStatus.active => AppTone.primary,
  SubjectStatus.finished => AppTone.success,
};

class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    required this.period,
    required this.onTap,
  });

  final Subject subject;
  final Period? period;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final start = subject.startDate;
    final progress = subject.progressOn(Dates.today());

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.subject(subject.colorIndex),
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: 12),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.name, style: text.titleMedium),
                if (subject.teacher.isNotEmpty)
                  Text(
                    subject.teacher,
                    style: text.bodyMedium!.copyWith(color: c.inkSoft),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    AppTag(
                      label: subject.status.label,
                      tone: toneForStatus(subject.status),
                    ),
                    if (period != null) AppTag(label: period!.name),
                  ],
                ),
                if (start != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Dates.formatRange(start, subject.endDate),
                    style: text.bodySmall,
                  ),
                ],
                if (progress != null &&
                    subject.status == SubjectStatus.active) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppProgressBar(
                    value: progress,
                    color: c.subject(subject.colorIndex),
                    semanticLabel: 'Avance del periodo',
                  ),
                ],
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, color: c.inkMuted),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando asignaturas',
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 180, height: 18),
                  SizedBox(height: AppSpacing.xs),
                  Skeleton(width: 120),
                  SizedBox(height: AppSpacing.sm),
                  Skeleton(height: 6),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
