import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design_system/design_system.dart';

/// Asignaturas: el eje de la información académica.
class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Asignaturas',
      children: [
        FadeSlideIn(
          child: AppCard(
            child: EmptyState(
              icon: LucideIcons.bookOpen,
              title: 'Registra tus asignaturas',
              message:
                  'Cada una reunirá sus actividades, calificaciones, '
                  'clases y material.',
              footer: AppTag(label: 'Llega en la entrega 1.2'),
            ),
          ),
        ),
      ],
    );
  }
}
