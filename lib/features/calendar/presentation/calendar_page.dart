import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design_system/design_system.dart';

/// Calendario: una vista de todo lo que tiene fecha.
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Calendario',
      children: [
        FadeSlideIn(
          child: AppCard(
            child: EmptyState(
              icon: LucideIcons.calendarDays,
              title: 'Nada en el calendario',
              message:
                  'Las entregas, clases y exámenes se mostrarán aquí '
                  'sin que tengas que crearlos dos veces.',
              footer: AppTag(label: 'Llega en la entrega 1.5'),
            ),
          ),
        ),
      ],
    );
  }
}
