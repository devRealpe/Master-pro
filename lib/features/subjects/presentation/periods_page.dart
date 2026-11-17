import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/sync/write_guard.dart';
import '../../../core/time/dates.dart';
import '../domain/period.dart';
import '../domain/unir_calendar.dart';
import 'subjects_providers.dart';

/// Periodos académicos y sus fechas clave.
class PeriodsPage extends ConsumerWidget {
  const PeriodsPage({super.key});

  void _loadUnirCalendar(WidgetRef ref) {
    final repository = ref.read(periodsRepositoryProvider);
    for (final period in unirCalendar2026(newId: repository.newId)) {
      guardWrite(repository.create(period));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periods = ref.watch(periodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Periodos'),
        actions: [
          IconButton(
            tooltip: 'Agregar periodo',
            icon: const Icon(LucideIcons.plus),
            onPressed: () => showPeriodForm(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: switch (periods) {
          AsyncData(:final value) when value.isEmpty => [
            AppCard(
              child: EmptyState(
                icon: LucideIcons.calendarRange,
                title: 'Organiza tu año académico',
                message:
                    'Carga el calendario 2026–2027 del máster o crea tus '
                    'periodos a mano. Las fechas cargadas quedan «por '
                    'confirmar» hasta que las valides con el PDF oficial.',
                actionLabel: 'Cargar calendario UNIR',
                onAction: () => _loadUnirCalendar(ref),
                footer: AppButton(
                  label: 'Crear un periodo',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => showPeriodForm(context),
                ),
              ),
            ),
          ],
          AsyncData(:final value) => [
            for (final (index, period) in value.indexed) ...[
              FadeSlideIn(
                key: ValueKey(period.id),
                index: index,
                child: _PeriodCard(period: period),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          AsyncError() => [
            AppCard(
              child: ErrorState(
                message: 'No se pudieron leer tus periodos.',
                onRetry: () => retrySubjects(ref),
              ),
            ),
          ],
          _ => const [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 200, height: 18),
                  SizedBox(height: AppSpacing.xs),
                  Skeleton(width: 140),
                ],
              ),
            ),
          ],
        },
      ),
    );
  }
}

AppTone _toneForKind(KeyDateKind kind) => switch (kind) {
  KeyDateKind.classes => AppTone.primary,
  KeyDateKind.review => AppTone.info,
  KeyDateKind.exams => AppTone.danger,
  KeyDateKind.delivery => AppTone.accent,
  KeyDateKind.nonTeaching || KeyDateKind.other => AppTone.neutral,
};

enum _PeriodAction { edit, delete }

class _PeriodCard extends ConsumerWidget {
  const _PeriodCard({required this.period});

  final Period period;

  void _update(WidgetRef ref, Period edited) {
    guardWrite(ref.read(periodsRepositoryProvider).update(period, edited));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar este periodo?'),
        content: Text(
          '«${period.name}» y sus fechas clave irán a la papelera. Las '
          'asignaturas que lo usan se conservan y quedan sin periodo.',
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
    if (confirmed != true) return;

    final repository = ref.read(periodsRepositoryProvider);
    final deleted = period.copyWith(deletedAt: DateTime.now().toUtc());
    guardWrite(repository.update(period, deleted));
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Periodo eliminado'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => guardWrite(repository.update(deleted, period)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = context.text;
    final pending = period.pendingConfirmations;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xxs,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(period.name, style: text.titleMedium)),
              PopupMenuButton<_PeriodAction>(
                tooltip: 'Acciones del periodo',
                icon: const Icon(LucideIcons.ellipsisVertical),
                onSelected: (action) => switch (action) {
                  _PeriodAction.edit => showPeriodForm(
                    context,
                    original: period,
                  ),
                  _PeriodAction.delete => _delete(context, ref),
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _PeriodAction.edit,
                    child: Text('Editar'),
                  ),
                  PopupMenuItem(
                    value: _PeriodAction.delete,
                    child: Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Dates.formatRange(period.startDate, period.endDate),
                  style: text.bodyMedium!.copyWith(color: c.inkSoft),
                ),
                if (pending > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppTag(
                    label: pending == 1
                        ? '1 fecha por confirmar'
                        : '$pending fechas por confirmar',
                    tone: AppTone.warning,
                    icon: LucideIcons.triangleAlert,
                  ),
                ],
                if (!period.datesConfirmed) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    label: 'Confirmar inicio y fin',
                    variant: AppButtonVariant.secondary,
                    icon: LucideIcons.check,
                    onPressed: () =>
                        _update(ref, period.copyWith(datesConfirmed: true)),
                  ),
                ],
              ],
            ),
          ),
          if (period.keyDates.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            for (final date in period.keyDates)
              _KeyDateRow(
                date: date,
                onToggle: () => _update(
                  ref,
                  period.withKeyDateConfirmed(
                    date.id,
                    confirmed: !date.confirmed,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _KeyDateRow extends StatelessWidget {
  const _KeyDateRow({required this.date, required this.onToggle});

  final KeyDate date;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date.title, style: text.bodyLarge),
                Text(
                  Dates.formatRange(date.start, date.end),
                  style: text.bodyMedium!.copyWith(
                    color: c.inkSoft,
                    fontFeatures: AppTypography.tabular,
                  ),
                ),
                if (date.note.isNotEmpty)
                  Text(date.note, style: text.bodySmall),
                const SizedBox(height: AppSpacing.xxs),
                AppTag(label: date.kind.label, tone: _toneForKind(date.kind)),
              ],
            ),
          ),
          Semantics(
            toggled: date.confirmed,
            child: IconButton(
              tooltip: date.confirmed
                  ? 'Confirmada: ${date.title}. Marcar como pendiente'
                  : 'Confirmar: ${date.title}',
              icon: Icon(
                date.confirmed ? LucideIcons.circleCheck : LucideIcons.circle,
                color: date.confirmed ? c.success : c.inkMuted,
              ),
              onPressed: onToggle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Abre la hoja para crear un periodo o editar [original].
Future<void> showPeriodForm(BuildContext context, {Period? original}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _PeriodForm(original: original),
  );
}

class _PeriodForm extends ConsumerStatefulWidget {
  const _PeriodForm({required this.original});

  final Period? original;

  @override
  ConsumerState<_PeriodForm> createState() => _PeriodFormState();
}

class _PeriodFormState extends ConsumerState<_PeriodForm> {
  late final _name = TextEditingController(text: widget.original?.name);
  late DateTime? _start = widget.original?.startDate;
  late DateTime? _end = widget.original?.endDate;
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _submitted = true);
    final start = _start;
    final end = _end;
    if (PeriodRules.name(_name.text) != null ||
        PeriodRules.dates(start, end) != null ||
        start == null ||
        end == null) {
      return;
    }

    final repository = ref.read(periodsRepositoryProvider);
    final original = widget.original;
    if (original == null) {
      guardWrite(
        repository.create(
          Period(
            id: repository.newId(),
            name: _name.text.trim(),
            startDate: start,
            endDate: end,
          ),
        ),
      );
    } else {
      final datesChanged =
          start != original.startDate || end != original.endDate;
      guardWrite(
        repository.update(
          original,
          original.copyWith(
            name: _name.text.trim(),
            startDate: start,
            endDate: end,
            // Fechas escritas a mano se dan por validadas.
            datesConfirmed: datesChanged ? true : null,
          ),
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final nameError = _submitted ? PeriodRules.name(_name.text) : null;
    final datesError = _submitted ? PeriodRules.dates(_start, _end) : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.original == null ? 'Nuevo periodo' : 'Editar periodo',
            style: text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _name,
            autofocus: widget.original == null,
            textCapitalization: TextCapitalization.sentences,
            maxLength: Period.maxNameLength,
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
            decoration: InputDecoration(
              labelText: 'Nombre',
              hintText: '1.er cuatrimestre',
              errorText: nameError,
              counterText: '',
            ),
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
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.original == null
                ? 'Crear periodo'
                : 'Guardar cambios',
            icon: LucideIcons.check,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
