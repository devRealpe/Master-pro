import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/design_system/design_system.dart';

/// Estructura principal: el contenido de la pestaña activa y la barra
/// inferior con las cinco pestañas.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const destinations = [
    (label: 'Inicio', icon: LucideIcons.house),
    (label: 'Plan', icon: LucideIcons.squareKanban),
    (label: 'Calendario', icon: LucideIcons.calendarDays),
    (label: 'Asignaturas', icon: LucideIcons.bookOpen),
    (label: 'Mi espacio', icon: LucideIcons.layoutGrid),
  ];

  void _select(int index) {
    // Tocar la pestaña activa vuelve a su pantalla inicial.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle(c),
      child: Scaffold(
        body: _BranchTransition(
          index: navigationShell.currentIndex,
          child: navigationShell,
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.outline)),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _select,
            destinations: [
              for (final d in destinations)
                NavigationDestination(icon: Icon(d.icon), label: d.label),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fundido breve al cambiar de pestaña. No desmonta el contenido, así que
/// cada pestaña conserva su estado.
class _BranchTransition extends StatefulWidget {
  const _BranchTransition({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_BranchTransition> createState() => _BranchTransitionState();
}

class _BranchTransitionState extends State<_BranchTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.quick,
    value: 1,
  );

  @override
  void didUpdateWidget(_BranchTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index && !AppMotion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: AppCurves.enter),
      child: widget.child,
    );
  }
}
