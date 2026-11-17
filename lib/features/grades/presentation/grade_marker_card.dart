import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_router.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/format/decimals.dart';
import '../../../core/sync/write_guard.dart';
import '../../subjects/domain/subject.dart';
import '../../subjects/presentation/subjects_providers.dart';
import '../domain/grade_calculator.dart';
import '../domain/grading_scheme.dart';
import 'grades_providers.dart';

/// Frase que resume qué falta para la meta.
String gradeOutlook(GradeSummary summary) {
  final scheme = summary.scheme;
  if (summary.goalReached) {
    return 'Meta alcanzada. Sigue con las actividades: suelen repetirse en '
        'el examen.';
  }
  final remaining = Decimals.format(summary.remainingToGoal);
  if (!summary.goalReachable) {
    return 'Con lo que queda llegarías como máximo a '
        '${Decimals.format(summary.maxReachable)} puntos.';
  }
  final average = summary.requiredAverage;
  if (average == null) {
    return 'Te faltan $remaining puntos. Puedes reunirlos con test y '
        'asistencia.';
  }
  if (average > scheme.scaleMax) {
    return 'Te faltan $remaining puntos. Las actividades solas no alcanzan: '
        'suma también test y asistencia.';
  }
  return 'Te faltan $remaining puntos: una media de '
      '${Decimals.format(average, maxDecimals: 1)} en las actividades que '
      'quedan.';
}

/// Marcador de evaluación continua de una asignatura.
class GradeMarkerCard extends ConsumerWidget {
  const GradeMarkerCard({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = context.text;
    final summary = watchGradeSummary(ref, subject);
    final scheme = subject.grading;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProgressRing(
                value: summary.progress,
                size: 76,
                strokeWidth: 7,
                color: summary.goalReached ? c.success : null,
                semanticLabel: 'Avance hacia la meta de puntos',
                child: AnimatedCount(
                  value: summary.earned,
                  fractionDigits: 1,
                  style: text.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Overline('Evaluación continua'),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${Decimals.format(summary.earned)} de '
                      '${Decimals.format(summary.goal)} puntos',
                      style: text.titleMedium!.copyWith(
                        fontFeatures: AppTypography.tabular,
                      ),
                    ),
                    if (summary.goalReached)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.xxs),
                        child: AppTag(
                          label: 'Meta alcanzada',
                          tone: AppTone.success,
                          icon: LucideIcons.check,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            gradeOutlook(summary),
            style: text.bodyMedium!.copyWith(color: c.inkSoft),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              for (final source in GradeSource.values)
                AppTag(
                  label:
                      '${source.label} '
                      '${Decimals.format(summary.earnedFrom(source))}',
                ),
              if (summary.awaiting > 0)
                AppTag(
                  label:
                      'Por calificar: hasta '
                      '${Decimals.format(summary.awaiting)}',
                  tone: AppTone.info,
                ),
              if (summary.pending > 0)
                AppTag(
                  label:
                      'Aún puedes sumar '
                      '${Decimals.format(summary.pending)}',
                  tone: AppTone.primary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${Decimals.format(scheme.continuousWeight)} % evaluación '
            'continua · ${Decimals.format(scheme.examWeight)} % examen',
            style: text.bodySmall,
          ),
          if (!scheme.confirmed)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxs),
              child: AppTag(
                label: 'Reglas sin confirmar con la guía docente',
                tone: AppTone.warning,
                icon: LucideIcons.triangleAlert,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Simular',
                  icon: LucideIcons.flaskConical,
                  variant: AppButtonVariant.secondary,
                  expand: true,
                  onPressed: () =>
                      context.push(AppRoutes.simulator(subject.id)),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppButton(
                label: 'Reglas',
                variant: AppButtonVariant.ghost,
                onPressed: () => showGradingSchemeSheet(context, subject),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hoja para ajustar las reglas de evaluación de [subject].
Future<void> showGradingSchemeSheet(BuildContext context, Subject subject) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _SchemeForm(subject: subject),
  );
}

class _SchemeForm extends ConsumerStatefulWidget {
  const _SchemeForm({required this.subject});

  final Subject subject;

  @override
  ConsumerState<_SchemeForm> createState() => _SchemeFormState();
}

class _SchemeFormState extends ConsumerState<_SchemeForm> {
  late final GradingScheme _original = widget.subject.grading;
  late final _scale = _field(_original.scaleMax);
  late final _goal = _field(_original.pointsGoal);
  late final _attendance = _field(_original.attendancePoints);
  late final _test = _field(_original.testPoints);
  late final _continuous = _field(_original.continuousWeight);
  late final _exam = _field(_original.examWeight);
  late bool _confirmed = _original.confirmed;
  bool _submitted = false;

  TextEditingController _field(double value) =>
      TextEditingController(text: Decimals.format(value));

  @override
  void dispose() {
    for (final c in [_scale, _goal, _attendance, _test, _continuous, _exam]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    setState(() => _submitted = true);
    final scale = Decimals.parse(_scale.text);
    final goal = Decimals.parse(_goal.text);
    final attendance = Decimals.parse(_attendance.text);
    final test = Decimals.parse(_test.text);
    final continuous = Decimals.parse(_continuous.text);
    final exam = Decimals.parse(_exam.text);
    if (GradingRules.scale(scale) != null ||
        GradingRules.points(goal) != null ||
        GradingRules.points(attendance) != null ||
        GradingRules.points(test) != null ||
        GradingRules.weights(continuous, exam) != null) {
      return;
    }

    final subject = widget.subject;
    guardWrite(
      ref
          .read(subjectsRepositoryProvider)
          .update(
            subject,
            subject.copyWith(
              grading: GradingScheme(
                scaleMax: scale!,
                pointsGoal: goal!,
                attendancePoints: attendance!,
                testPoints: test!,
                continuousWeight: continuous!,
                examWeight: exam!,
                confirmed: _confirmed,
              ),
            ),
          ),
    );
    Navigator.of(context).pop();
  }

  Widget _number(
    TextEditingController controller,
    String label,
    String? error, {
    String? suffix,
  }) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: (_) {
      if (_submitted) setState(() {});
    },
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      errorText: _submitted ? error : null,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final weightsError = GradingRules.weights(
      Decimals.parse(_continuous.text),
      Decimals.parse(_exam.text),
    );

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
          Text('Reglas de evaluación', style: text.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Vienen con los valores de UNIR. Cámbialos si la guía docente de '
            'esta asignatura dice otra cosa.',
            style: text.bodyMedium!.copyWith(color: c.inkSoft),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _number(
                  _scale,
                  'Nota máxima',
                  GradingRules.scale(Decimals.parse(_scale.text)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _number(
                  _goal,
                  'Meta de puntos',
                  GradingRules.points(Decimals.parse(_goal.text)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _number(
                  _attendance,
                  'Puntos por clase',
                  GradingRules.points(Decimals.parse(_attendance.text)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _number(
                  _test,
                  'Puntos por test',
                  GradingRules.points(Decimals.parse(_test.text)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _number(_continuous, 'Ev. continua', null, suffix: '%'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _number(_exam, 'Examen', null, suffix: '%')),
            ],
          ),
          if (_submitted && weightsError != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              weightsError,
              style: text.bodySmall!.copyWith(color: c.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Confirmé estas reglas con la guía docente'),
            value: _confirmed,
            onChanged: (value) => setState(() => _confirmed = value),
          ),
          Text(
            'La app calcula puntos de evaluación continua. No calcula la nota '
            'final de 0 a 10, porque falta confirmar cómo se combinan esos '
            'puntos con el examen.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Guardar reglas',
            icon: LucideIcons.check,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
