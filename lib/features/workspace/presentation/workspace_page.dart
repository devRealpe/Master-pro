import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/settings/theme_mode_controller.dart';

/// Mi espacio: herramientas y ajustes. Las herramientas se agregan a medida
/// que se construyen; no se listan las que todavía no funcionan.
class WorkspacePage extends ConsumerWidget {
  const WorkspacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final text = context.text;
    final c = context.colors;

    return AppPage(
      title: 'Mi espacio',
      children: [
        FadeSlideIn(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.palette, size: 20, color: c.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Apariencia', style: text.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Elige el tema o deja que siga al del teléfono.',
                  style: text.bodyMedium!.copyWith(color: c.inkSoft),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSegmented<ThemeMode>(
                  selected: mode,
                  onChanged: ref.read(themeModeProvider.notifier).select,
                  segments: const [
                    AppSegment(
                      value: ThemeMode.system,
                      label: 'Sistema',
                      icon: LucideIcons.monitor,
                    ),
                    AppSegment(
                      value: ThemeMode.light,
                      label: 'Claro',
                      icon: LucideIcons.sun,
                    ),
                    AppSegment(
                      value: ThemeMode.dark,
                      label: 'Oscuro',
                      icon: LucideIcons.moon,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: AppSpacing.sm),
          FadeSlideIn(
            index: 1,
            child: AppCard(
              onTap: () => context.push(AppRoutes.catalog),
              child: Row(
                children: [
                  Icon(LucideIcons.sparkles, size: 20, color: c.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Design System', style: text.titleMedium),
                        Text(
                          'Catálogo de componentes · solo en desarrollo',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: c.inkMuted),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
