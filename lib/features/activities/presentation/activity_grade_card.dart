import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/format/decimals.dart';
import '../../../core/sync/write_guard.dart';
import '../../grades/domain/grade_calculator.dart';
import '../../grades/domain/grading_scheme.dart';
import '../domain/activity.dart';
import 'activities_providers.dart';

/// Valor y nota de la actividad, con lo que aporta a la evaluación continua.
class ActivityGradeCard extends ConsumerWidget {
  const ActivityGradeCard({
    super.key,
    required this.activity,
    required this.scheme,
  });

  final Activity activity;
  final GradingScheme scheme;

  Future<void> _editScore(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_ScoreResult>(
      context: context,
      builder: (context) => _ScoreDialog(activity: activity, scheme: scheme),
    );
    if (result == null) return;

    final score = result.score;
    final edited = score == null
        ? activity.copyWith(score: null)
        // Una actividad con nota ya está hecha.
        : activity.copyWith(score: score, status: ActivityStatus.done);
    guardWrite(ref.read(activitiesRepositoryProvider).update(activity, edited));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = context.text;
    final value = activity.value ?? 0;
    final score = activity.score;
    final isTest = activity.type == ActivityType.test;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Overline('Calificación'),
          const SizedBox(height: AppSpacing.xs),
          if (isTest)
            Text(
              activity.isDone
                  ? 'Sumó ${Decimals.format(value)} puntos'
                  : 'Suma ${Decimals.format(value)} puntos al hacerlo',
              style: text.titleMedium,
            )
          else if (score == null) ...[
            Text(
              'Vale hasta ${Decimals.format(value)} puntos',
              style: text.titleMedium,
            ),
            Text(
              activity.isDone ? 'Entregada, sin nota todavía' : 'Sin nota',
              style: text.bodyMedium!.copyWith(color: c.inkSoft),
            ),
          ] else ...[
            Text(
              'Nota ${Decimals.format(score)}',
              style: text.headlineSmall!.copyWith(
                fontFeatures: AppTypography.tabular,
              ),
            ),
            Text(
              _contribution(value, score),
              style: text.bodyMedium!.copyWith(color: c.inkSoft),
            ),
          ],
          if (!isTest) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: score == null ? 'Registrar nota' : 'Cambiar nota',
              variant: AppButtonVariant.secondary,
              icon: LucideIcons.pencil,
              expand: true,
              onPressed: () => _editScore(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  String _contribution(double value, double score) {
    final points = GradeCalculator.pointsFor(
      value: value,
      score: score,
      scheme: scheme,
    );
    return 'Aporta ${Decimals.format(points)} de '
        '${Decimals.format(value)} puntos';
  }
}

/// Resultado del diálogo de nota: una nota nueva o, con `null`, quitarla.
class _ScoreResult {
  const _ScoreResult(this.score);

  final double? score;
}

class _ScoreDialog extends StatefulWidget {
  const _ScoreDialog({required this.activity, required this.scheme});

  final Activity activity;
  final GradingScheme scheme;

  @override
  State<_ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends State<_ScoreDialog> {
  late final _controller = TextEditingController(
    text: switch (widget.activity.score) {
      final score? => Decimals.format(score),
      null => '',
    },
  );
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final score = Decimals.parse(_controller.text);
    if (GradingRules.score(score, widget.scheme) != null) {
      setState(() => _submitted = true);
      return;
    }
    Navigator.of(context).pop(_ScoreResult(score));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final score = Decimals.parse(_controller.text);
    final error = GradingRules.score(score, scheme);
    final value = widget.activity.value ?? 0;
    final preview = error == null && score != null
        ? 'Aporta '
              '${Decimals.format(GradeCalculator.pointsFor(value: value, score: score, scheme: scheme))}'
              ' de ${Decimals.format(value)} puntos'
        : null;

    return AlertDialog(
      title: const Text('Nota obtenida'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: 'Nota de 0 a ${Decimals.format(scheme.scaleMax)}',
          errorText: _submitted ? error : null,
          helperText: preview,
        ),
      ),
      actions: [
        if (widget.activity.isGraded)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const _ScoreResult(null)),
            child: const Text('Quitar nota'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
