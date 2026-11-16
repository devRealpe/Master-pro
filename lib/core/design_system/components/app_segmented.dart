import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_layout.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_typography.dart';

class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Selector de una opción entre pocas. Los segmentos se reparten el ancho por
/// igual y el indicador se desliza hasta la opción elegida.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  }) : assert(segments.length >= 2, 'Un selector necesita al menos 2 opciones');

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = segments.length;
    final index = segments
        .indexWhere((s) => s.value == selected)
        .clamp(0, count - 1);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: AppRadii.md,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: SizedBox(
          height: AppSpacing.touchTarget - AppSpacing.xxs * 2,
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: Alignment(-1 + 2 * index / (count - 1), 0),
                duration: AppMotion.duration(context, AppDurations.quick),
                curve: AppCurves.standard,
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: AppRadii.sm,
                      border: c.isDark ? Border.all(color: c.outline) : null,
                      boxShadow: AppShadows.rest(context),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      child: _SegmentButton(
                        segment: segment,
                        selected: segment.value == selected,
                        onTap: () => onChanged(segment.value),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  final AppSegment<T> segment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.primary : c.inkSoft;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppRadii.sm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selected ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Center(
              // Si el texto ampliado no cabe, se reduce en vez de partirse.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (segment.icon != null) ...[
                      Icon(segment.icon, size: 16, color: color),
                      const SizedBox(width: 6),
                    ],
                    AnimatedDefaultTextStyle(
                      duration: AppMotion.duration(context, AppDurations.quick),
                      style: context.text.labelLarge!.copyWith(color: color),
                      child: Text(segment.label, maxLines: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
