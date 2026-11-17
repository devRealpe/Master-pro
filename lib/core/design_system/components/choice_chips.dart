import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_layout.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_typography.dart';

class AppChoice<T> {
  const AppChoice({required this.value, required this.label, this.dotColor});

  final T value;
  final String label;

  /// Punto de color delante del texto (por ejemplo, el de una asignatura).
  final Color? dotColor;
}

/// Fila de opciones de las que se elige una. Si no caben, la fila se desplaza
/// (o se parte en varias líneas con [wrap]).
class AppChoiceChips<T> extends StatelessWidget {
  const AppChoiceChips({
    super.key,
    required this.choices,
    required this.selected,
    required this.onChanged,
    this.wrap = false,
  });

  final List<AppChoice<T>> choices;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final choice in choices)
        _Chip(
          choice: choice,
          selected: choice.value == selected,
          onTap: () => onChanged(choice.value),
        ),
    ];

    if (wrap) {
      return Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: chips,
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (index, chip) in chips.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpacing.xs),
            chip,
          ],
        ],
      ),
    );
  }
}

class _Chip<T> extends StatelessWidget {
  const _Chip({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final AppChoice<T> choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dot = choice.dotColor;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppDurations.quick),
        curve: AppCurves.standard,
        decoration: BoxDecoration(
          color: selected ? c.primaryContainer : c.surface,
          borderRadius: AppRadii.pill,
          border: Border.all(color: selected ? c.primary : c.outline),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: AppRadii.pill,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dot != null) ...[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: dot,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 8),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      choice.label,
                      style: context.text.labelLarge!.copyWith(
                        color: selected ? c.onPrimaryContainer : c.inkSoft,
                      ),
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
