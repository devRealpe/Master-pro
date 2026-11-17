import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_router.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/time/clock_providers.dart';
import '../../../core/time/dates.dart';
import '../../activities/domain/activity.dart';
import '../../activities/presentation/activities_providers.dart';
import '../../classes/domain/class_session.dart';
import '../../grades/presentation/grades_providers.dart';
import '../../subjects/domain/period.dart';
import '../../subjects/domain/subject.dart';
import '../../subjects/presentation/subjects_providers.dart';
import '../domain/calendar_projector.dart';
import '../domain/study_block.dart';
import 'calendar_providers.dart';
import 'study_block_sheet.dart';

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// «Lunes 16 de noviembre».
String longDay(DateTime day, {String locale = 'es'}) =>
    _capitalize(DateFormat("EEEE d 'de' MMMM", locale).format(day));

/// Calendario: una vista de todo lo que tiene fecha. No guarda nada propio
/// salvo los bloques de estudio.
class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarControllerProvider);
    final controller = ref.read(calendarControllerProvider.notifier);
    final toLocal = ref.watch(toLocalProvider);
    final today = Dates.dateOnly(toLocal(ref.watch(clockProvider)()));
    final subjects = ref.watch(subjectsProvider).value ?? const <Subject>[];
    final window = state.window;

    final entries = CalendarProjector.project(
      from: window.from,
      to: window.to,
      toLocal: toLocal,
      activities: ref.watch(activitiesProvider).value ?? const <Activity>[],
      classSessions:
          ref.watch(classSessionsProvider).value ?? const <ClassSession>[],
      studyBlocks: ref.watch(studyBlocksProvider).value ?? const <StudyBlock>[],
      periods: ref.watch(periodsProvider).value ?? const <Period>[],
    );

    final title = switch (state.view) {
      CalendarView.month => _capitalize(
        DateFormat('MMMM y', 'es').format(state.selected),
      ),
      CalendarView.week => Dates.formatRange(window.from, window.to),
      CalendarView.day => longDay(state.selected),
    };

    return AppPage(
      title: 'Calendario',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!Dates.sameDay(state.selected, today))
            TextButton(
              onPressed: controller.goToToday,
              child: const Text('Hoy'),
            ),
          IconButton(
            tooltip: 'Reservar bloque de estudio',
            icon: const Icon(LucideIcons.plus),
            onPressed: () => showStudyBlockSheet(context, day: state.selected),
          ),
        ],
      ),
      children: [
        AppSegmented<CalendarView>(
          selected: state.view,
          onChanged: controller.setView,
          segments: [
            for (final view in CalendarView.values)
              AppSegment(value: view, label: view.label),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            IconButton(
              tooltip: 'Anterior',
              icon: const Icon(LucideIcons.chevronLeft),
              onPressed: () => controller.step(-1),
            ),
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Siguiente',
              icon: const Icon(LucideIcons.chevronRight),
              onPressed: () => controller.step(1),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ...switch (state.view) {
          CalendarView.month => [
            _DayGrid(
              days: Dates.monthGrid(state.selected),
              month: state.selected.month,
              selected: state.selected,
              today: today,
              entries: entries,
              subjects: subjects,
              onSelect: controller.select,
            ),
            const SizedBox(height: AppSpacing.md),
            _DayAgenda(
              day: state.selected,
              entries: entries[state.selected] ?? const [],
              subjects: subjects,
              showHeader: true,
            ),
          ],
          CalendarView.week => [
            _DayGrid(
              days: [for (var i = 0; i < 7; i++) Dates.addDays(window.from, i)],
              month: null,
              selected: state.selected,
              today: today,
              entries: entries,
              subjects: subjects,
              onSelect: controller.select,
            ),
            const SizedBox(height: AppSpacing.md),
            if (entries.isEmpty)
              _EmptyDay(day: state.selected, message: 'Nada esta semana')
            else
              for (var i = 0; i < 7; i++)
                if (entries[Dates.addDays(window.from, i)] case final list?)
                  _DayAgenda(
                    day: Dates.addDays(window.from, i),
                    entries: list,
                    subjects: subjects,
                    showHeader: true,
                  ),
          ],
          CalendarView.day => [
            _DayAgenda(
              day: state.selected,
              entries: entries[state.selected] ?? const [],
              subjects: subjects,
              showHeader: false,
            ),
          ],
        },
      ],
    );
  }
}

/// Color de una entrada: el de su asignatura o, si no tiene, el de su tipo.
Color entryColor(
  BuildContext context,
  CalendarEntry entry,
  List<Subject> subjects,
) {
  final c = context.colors;
  final subject = subjects.where((s) => s.id == entry.subjectId).firstOrNull;
  if (subject != null) return c.subject(subject.colorIndex);
  return switch (entry.kind) {
    CalendarEntryKind.deadline => c.warning,
    CalendarEntryKind.target => c.accent,
    CalendarEntryKind.classSession => c.info,
    CalendarEntryKind.studyBlock => c.success,
    CalendarEntryKind.keyDate => switch (entry.keyDateKind) {
      KeyDateKind.exams => c.danger,
      KeyDateKind.review => c.info,
      KeyDateKind.classes => c.primary,
      KeyDateKind.delivery => c.accent,
      _ => c.inkMuted,
    },
  };
}

const _weekdayInitials = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

/// Cuadrícula de días: el mes completo o una sola semana.
class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.days,
    required this.month,
    required this.selected,
    required this.today,
    required this.entries,
    required this.subjects,
    required this.onSelect,
  });

  final List<DateTime> days;

  /// Mes que se está viendo; los días de otros meses se atenúan. `null` en la
  /// vista de semana.
  final int? month;
  final DateTime selected;
  final DateTime today;
  final Map<DateTime, List<CalendarEntry>> entries;
  final List<Subject> subjects;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                for (final initial in _weekdayInitials)
                  Expanded(
                    child: Center(
                      child: Text(
                        initial,
                        style: text.labelSmall!.copyWith(color: c.inkMuted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          for (var week = 0; week < days.length; week += 7)
            Row(
              children: [
                for (final day in days.skip(week).take(7))
                  Expanded(
                    child: _DayCell(
                      day: day,
                      dimmed: month != null && day.month != month,
                      selected: Dates.sameDay(day, selected),
                      today: Dates.sameDay(day, today),
                      entries: entries[day] ?? const [],
                      subjects: subjects,
                      onTap: () => onSelect(day),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.dimmed,
    required this.selected,
    required this.today,
    required this.entries,
    required this.subjects,
    required this.onTap,
  });

  final DateTime day;
  final bool dimmed;
  final bool selected;
  final bool today;
  final List<CalendarEntry> entries;
  final List<Subject> subjects;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = entries.length;
    final numberColor = selected
        ? c.onPrimary
        : dimmed
        ? c.inkMuted
        : c.ink;

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${DateFormat("d 'de' MMMM", 'es').format(day)}'
          '${today ? ', hoy' : ''}'
          '${count == 0
              ? ''
              : count == 1
              ? ', 1 elemento'
              : ', $count elementos'}',
      excludeSemantics: true,
      child: InkResponse(
        radius: 26,
        onTap: onTap,
        child: SizedBox(
          height: AppSpacing.touchTarget + 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppMotion.duration(context, AppDurations.instant),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? c.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: today && !selected ? c.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: context.text.labelLarge!.copyWith(
                    color: numberColor,
                    fontWeight: today || selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontFeatures: AppTypography.tabular,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final entry in entries.take(3))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: entryColor(context, entry, subjects),
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(dimension: 5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lo que hay en un día, en orden.
class _DayAgenda extends StatelessWidget {
  const _DayAgenda({
    required this.day,
    required this.entries,
    required this.subjects,
    required this.showHeader,
  });

  final DateTime day;
  final List<CalendarEntry> entries;
  final List<Subject> subjects;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Overline(longDay(day)),
          ),
        if (entries.isEmpty)
          _EmptyDay(day: day, message: 'Nada este día')
        else
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _EntryTile(entry: entry, subjects: subjects),
            ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.day, required this.message});

  final DateTime day;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: EmptyState(
        icon: LucideIcons.calendarDays,
        title: message,
        message:
            'Las entregas, clases y fechas clave aparecen aquí solas. '
            'También puedes reservar tiempo para estudiar.',
        actionLabel: 'Reservar bloque de estudio',
        onAction: () => showStudyBlockSheet(context, day: day),
      ),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry, required this.subjects});

  final CalendarEntry entry;
  final List<Subject> subjects;

  void _open(BuildContext context, WidgetRef ref) {
    switch (entry.kind) {
      case CalendarEntryKind.deadline || CalendarEntryKind.target:
        context.push(AppRoutes.activity(entry.sourceId));
      case CalendarEntryKind.classSession:
        final subjectId = entry.subjectId;
        if (subjectId != null) context.push(AppRoutes.subject(subjectId));
      case CalendarEntryKind.keyDate:
        context.push(AppRoutes.periods);
      case CalendarEntryKind.studyBlock:
        showStudyBlockSheet(
          context,
          day: entry.day,
          original: ref.read(studyBlockProvider(entry.sourceId)),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = context.text;
    final toLocal = ref.watch(toLocalProvider);
    final color = entryColor(context, entry, subjects);
    final subject = subjects.where((s) => s.id == entry.subjectId).firstOrNull;
    final start = entry.startsAt;
    final duration = entry.durationMinutes;

    final details = [
      entry.kind == CalendarEntryKind.keyDate
          ? (entry.keyDateKind?.label ?? entry.kind.label)
          : entry.kind.label,
      if (subject != null) subject.name,
      if (duration != null) StudyBlockRules.formatDuration(duration),
      if (entry.unconfirmed) 'por confirmar',
    ].join(' · ');

    return AppCard(
      onTap: () => _open(context, ref),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 46,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  start == null
                      ? 'Todo\nel día'
                      : DateFormat('HH:mm').format(toLocal(start)),
                  style: text.labelMedium!.copyWith(
                    color: c.inkSoft,
                    fontFeatures: AppTypography.tabular,
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadii.pill,
              ),
              child: const SizedBox(width: 4),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.title,
                    style: text.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: entry.done ? c.inkMuted : null,
                      decoration:
                          entry.done && entry.kind == CalendarEntryKind.deadline
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  Text(details, style: text.bodySmall),
                  if (entry.note.isNotEmpty)
                    Text(
                      entry.note,
                      style: text.bodySmall!.copyWith(color: c.inkMuted),
                    ),
                ],
              ),
            ),
            if (entry.done)
              Icon(LucideIcons.circleCheck, size: 18, color: c.success),
          ],
        ),
      ),
    );
  }
}
