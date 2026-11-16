import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design_system/design_system.dart';

/// Plan: las actividades en lista, Kanban y sprints.
class PlanPage extends StatelessWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Plan',
      children: [
        FadeSlideIn(
          child: AppCard(
            child: EmptyState(
              icon: LucideIcons.listTodo,
              title: 'Aún no hay actividades',
              message:
                  'Tus trabajos, test y tareas aparecerán aquí en '
                  'lista, Kanban y sprints.',
              footer: AppTag(label: 'Llega en la entrega 1.3'),
            ),
          ),
        ),
      ],
    );
  }
}
