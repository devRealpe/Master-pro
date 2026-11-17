import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/format/decimals.dart';
import '../../subjects/domain/subject.dart';
import '../../subjects/presentation/subjects_providers.dart';
import '../domain/grade_calculator.dart';
import 'grade_marker_card.dart';
import 'grades_providers.dart';

/// Simulador de calificaciones: «si saco esto, ¿llego a la meta?».
///
/// Las hipótesis viven solo en esta pantalla. No se guardan ni tocan las
/// notas reales.
class SimulatorPage extends ConsumerWidget {
  const SimulatorPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(subjectProvider(subjectId))) {
      AsyncData(:final value?) => _Simulator(subject: value),
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

class _Simulator extends ConsumerStatefulWidget {
  const _Simulator({required this.subject});

  final Subject subject;

  @override
  ConsumerState<_Simulator> createState() => _SimulatorState();
}

class _SimulatorState extends ConsumerState<_Simulator> {
  final Map<String, double> _scores = {};
  final Set<String> _assumeDone = {};

  bool get _empty => _scores.isEmpty && _assumeDone.isEmpty;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final subject = widget.subject;
    final scheme = subject.grading;
    final inputs = ref.watch(gradeInputsProvider(subject.id));

    final real = GradeCalculator.summarize(
      scheme: scheme,
      activities: inputs.activities,
      classSessions: inputs.classes,
    );
    final simulated = GradeCalculator.summarize(
      scheme: scheme,
      activities: inputs.activities,
      classSessions: inputs.classes,
      hypotheticalScores: _scores,
      assumeDone: _assumeDone,
    );

    final scorable = [
      for (final item in real.open)
        if (item.needsScore) item,
    ];
    final others = [
      for (final item in real.open)
        if (!item.needsScore) item,
    ];
    final divisions = (scheme.scaleMax * 2).round().clamp(1, 200);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador'),
        actions: [
          if (!_empty)
            TextButton(
              onPressed: () => setState(() {
                _scores.clear();
                _assumeDone.clear();
              }),
              child: const Text('Restablecer'),
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
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProgressRing(
                      value: simulated.progress,
                      size: 76,
                      strokeWidth: 7,
                      color: simulated.goalReached ? c.success : null,
                      semanticLabel: 'Avance simulado hacia la meta',
                      child: AnimatedCount(
                        value: simulated.earned,
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
                          Overline(_empty ? 'Tu situación real' : 'Simulación'),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${Decimals.format(simulated.earned)} de '
                            '${Decimals.format(simulated.goal)} puntos',
                            style: text.titleMedium!.copyWith(
                              fontFeatures: AppTypography.tabular,
                            ),
                          ),
                          if (!_empty)
                            Text(
                              'Hoy tienes ${Decimals.format(real.earned)}',
                              style: text.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  gradeOutlook(simulated),
                  style: text.bodyMedium!.copyWith(color: c.inkSoft),
                ),
                const SizedBox(height: AppSpacing.xs),
                const AppTag(
                  label: 'Nada de esto se guarda',
                  icon: LucideIcons.flaskConical,
                ),
              ],
            ),
          ),
          if (real.open.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const AppCard(
              child: EmptyState(
                icon: LucideIcons.flaskConical,
                title: 'Nada que simular',
                message:
                    'Agrega actividades con su valor en puntos, o clases, y '
                    'aquí podrás probar distintas notas.',
              ),
            ),
          ],
          if (scorable.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Actividades sin nota'),
            for (final item in scorable)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ScoreSlider(
                  item: item,
                  score: _scores[item.id],
                  scaleMax: scheme.scaleMax,
                  divisions: divisions,
                  needed: real.requiredScoreFor(item.id),
                  points: (score) => GradeCalculator.pointsFor(
                    value: item.maxPoints,
                    score: score,
                    scheme: scheme,
                  ),
                  onChanged: (score) =>
                      setState(() => _scores[item.id] = score),
                  onClear: () => setState(() => _scores.remove(item.id)),
                ),
              ),
          ],
          if (others.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Test y clases pendientes'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  for (final item in others)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.source == GradeSource.test ? 'Hacerlo' : 'Asistir'}'
                        ' suma ${Decimals.format(item.maxPoints)}',
                      ),
                      value: _assumeDone.contains(item.id),
                      onChanged: (on) => setState(
                        () => on
                            ? _assumeDone.add(item.id)
                            : _assumeDone.remove(item.id),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreSlider extends StatelessWidget {
  const _ScoreSlider({
    required this.item,
    required this.score,
    required this.scaleMax,
    required this.divisions,
    required this.needed,
    required this.points,
    required this.onChanged,
    required this.onClear,
  });

  final GradeItem item;
  final double? score;
  final double scaleMax;
  final int divisions;

  /// Nota que haría falta en esta actividad para llegar sola a la meta.
  final double? needed;
  final double Function(double score) points;
  final ValueChanged<double> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final score = this.score;
    final needed = this.needed;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.title, style: text.titleMedium)),
              if (score != null)
                IconButton(
                  tooltip: 'Quitar hipótesis: ${item.title}',
                  icon: Icon(LucideIcons.x, size: 18, color: c.inkMuted),
                  onPressed: onClear,
                ),
            ],
          ),
          Text(
            [
              'Vale hasta ${Decimals.format(item.maxPoints)}',
              if (item.state == GradeState.awaitingGrade) 'entregada',
            ].join(' · '),
            style: text.bodySmall,
          ),
          if (needed != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                needed > scaleMax
                    ? 'Sola no alcanza para la meta'
                    : 'Con un ${Decimals.format(needed, maxDecimals: 1)} '
                          'aquí llegas a la meta',
                style: text.bodySmall!.copyWith(color: c.inkSoft),
              ),
            ),
          Slider(
            value: score ?? 0,
            max: scaleMax,
            divisions: divisions,
            label: Decimals.format(score ?? 0, maxDecimals: 1),
            semanticFormatterCallback: (value) =>
                'Nota ${Decimals.format(value, maxDecimals: 1)}',
            onChanged: onChanged,
          ),
          Text(
            score == null
                ? 'Mueve el control para probar una nota'
                : 'Con un ${Decimals.format(score, maxDecimals: 1)} sumas '
                      '${Decimals.format(points(score))}',
            style: text.bodyMedium!.copyWith(
              color: score == null ? c.inkMuted : c.ink,
              fontFeatures: AppTypography.tabular,
            ),
          ),
        ],
      ),
    );
  }
}
