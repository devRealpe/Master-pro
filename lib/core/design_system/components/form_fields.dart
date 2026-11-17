import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../time/dates.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_layout.dart';
import '../tokens/app_typography.dart';

/// Campo de fecha sin hora. Abre el selector del sistema y permite borrar.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final today = Dates.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? today,
      firstDate: firstDate ?? DateTime(today.year - 5),
      lastDate: lastDate ?? DateTime(today.year + 10),
      helpText: label,
    );
    if (picked != null) onChanged(Dates.dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final value = this.value;
    return InkWell(
      borderRadius: AppRadii.md,
      onTap: () => _pick(context),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: value == null
              ? Icon(LucideIcons.calendar, size: 20, color: c.inkMuted)
              : IconButton(
                  tooltip: 'Quitar fecha',
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: value == null
            ? null
            // En campos estrechos la fecha se reduce en vez de partirse en
            // dos líneas.
            : FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Dates.format(value),
                  style: context.text.bodyLarge,
                  maxLines: 1,
                ),
              ),
      ),
    );
  }
}

/// Selector de color de asignatura. Cada opción lleva su nombre para el
/// lector de pantalla y una marca cuando está elegida.
class SubjectColorPicker extends StatelessWidget {
  const SubjectColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: [
        for (var i = 0; i < c.subjects.length; i++)
          Semantics(
            button: true,
            selected: i == selected,
            label: 'Color ${AppColors.subjectNames[i]}',
            child: InkResponse(
              radius: 24,
              onTap: () => onChanged(i),
              child: SizedBox.square(
                dimension: AppSpacing.touchTarget,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.subjects[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: i == selected ? c.ink : Colors.transparent,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    child: i == selected
                        ? Icon(LucideIcons.check, size: 18, color: c.surface)
                        : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
