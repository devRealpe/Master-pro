import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design_system/design_system.dart';

/// Inicio: el centro académico. Por ahora solo saluda; el dashboard llega
/// cuando existan asignaturas y actividades que resumir.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.now});

  /// Momento actual. Se inyecta en las pruebas.
  final DateTime? now;

  static String greeting(int hour) => switch (hour) {
    >= 5 && < 12 => 'Buenos días',
    >= 12 && < 19 => 'Buenas tardes',
    _ => 'Buenas noches',
  };

  @override
  Widget build(BuildContext context) {
    final moment = now ?? DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat('EEEE d MMM', locale).format(moment);

    return AppPage(
      overline: date,
      title: greeting(moment.hour),
      children: const [
        FadeSlideIn(
          child: AppCard(
            child: EmptyState(
              icon: LucideIcons.graduationCap,
              title: 'Tu centro académico',
              message:
                  'Aquí verás tus entregas próximas, tus puntos de '
                  'evaluación continua y lo que toca hoy.',
              footer: AppTag(label: 'Se activa al registrar tus asignaturas'),
            ),
          ),
        ),
      ],
    );
  }
}
