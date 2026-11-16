import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design_system.dart';

/// Catálogo del Design System. Solo se registra en modo desarrollo: muestra
/// todos los tokens y componentes para revisarlos en ambos temas.
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  double _progress = 0.64;
  String _view = 'Lista';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return Scaffold(
      appBar: AppBar(title: const Text('Design System')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.huge,
        ),
        children: [
          const _Section('Color'),
          _Swatches([
            ('canvas', c.canvas, c.ink),
            ('surface', c.surface, c.ink),
            ('surfaceRaised', c.surfaceRaised, c.ink),
            ('outline', c.outline, c.ink),
            ('ink', c.ink, c.canvas),
            ('inkSoft', c.inkSoft, c.canvas),
            ('inkMuted', c.inkMuted, c.canvas),
            ('primary', c.primary, c.onPrimary),
            ('primaryContainer', c.primaryContainer, c.onPrimaryContainer),
            ('accent', c.accent, c.onAccent),
            ('accentContainer', c.accentContainer, c.onAccentContainer),
            ('success', c.successContainer, c.onSuccessContainer),
            ('warning', c.warningContainer, c.onWarningContainer),
            ('danger', c.danger, c.onDanger),
            ('info', c.infoContainer, c.onInfoContainer),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text('Asignaturas', style: text.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              for (var i = 0; i < AppColors.subjectNames.length; i++)
                SubjectLabel(name: AppColors.subjectNames[i], colorIndex: i),
            ],
          ),

          const _Section('Tipografía'),
          for (final (name, style) in [
            ('Display · 40', text.displaySmall),
            ('Título 1 · 28', text.headlineMedium),
            ('Título 2 · 22', text.headlineSmall),
            ('Título 3 · 18', text.titleMedium),
            ('Cuerpo L · 16', text.bodyLarge),
            ('Cuerpo · 14', text.bodyMedium),
            ('Etiqueta · 14', text.labelLarge),
            ('Detalle · 12', text.bodySmall),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(name, style: style),
            ),
          const Overline('Sobretítulo · 11'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '0123456789 · 3,75 pts · 17:59',
            style: text.titleMedium!.copyWith(
              fontFeatures: AppTypography.tabular,
            ),
          ),

          const _Section('Botones'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(label: 'Principal', onPressed: () {}),
              AppButton(
                label: 'Secundario',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(
                label: 'Texto',
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
              AppButton(
                label: 'Eliminar',
                icon: LucideIcons.trash2,
                variant: AppButtonVariant.destructive,
                onPressed: () {},
              ),
              const AppButton(label: 'Deshabilitado', onPressed: null),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Guardar cambios',
            icon: LucideIcons.check,
            expand: true,
            loading: _loading,
            onPressed: () async {
              setState(() => _loading = true);
              await Future<void>.delayed(const Duration(milliseconds: 1400));
              if (mounted) setState(() => _loading = false);
            },
          ),

          const _Section('Etiquetas'),
          const Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppTag(label: 'Pendiente'),
              AppTag(label: 'En progreso', tone: AppTone.primary),
              AppTag(label: 'Sprint', tone: AppTone.accent),
              AppTag(
                label: 'Entregada',
                tone: AppTone.success,
                icon: LucideIcons.check,
              ),
              AppTag(
                label: 'Vence pronto',
                tone: AppTone.warning,
                icon: LucideIcons.clock,
              ),
              AppTag(
                label: 'Vencida',
                tone: AppTone.danger,
                icon: LucideIcons.triangleAlert,
              ),
              AppTag(label: 'Informativo', tone: AppTone.info),
            ],
          ),

          const _Section('Tarjetas y progreso'),
          AppCard(
            gradient: c.brandGradient,
            borderRadius: AppRadii.xl,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Overline(
                  'Tarjeta principal',
                  color: c.onGradient.withValues(alpha: 0.8),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Solo aquí se usa el degradado de marca',
                  style: text.titleMedium!.copyWith(color: c.onGradient),
                ),
                const SizedBox(height: AppSpacing.md),
                AppProgressBar(
                  value: _progress,
                  color: c.onGradient,
                  trackColor: c.onGradient.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Eval. continua',
                    leading: ProgressRing(value: _progress, size: 44),
                    value: AnimatedCount(
                      value: _progress * 5,
                      fractionDigits: 1,
                    ),
                    caption: 'de 5 pts',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatCard(
                    label: 'Esta semana',
                    value: AnimatedCount(value: _progress * 10, suffix: ' h'),
                    caption: 'meta 10 h',
                    footer: AppProgressBar(value: _progress, color: c.success),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            onTap: () {},
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tarjeta pulsable', style: text.titleMedium),
                      Text('Tócala: onda y escala', style: text.bodySmall),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: c.inkMuted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Slider(
            value: _progress,
            label: 'Progreso de ejemplo',
            onChanged: (v) => setState(() => _progress = v),
          ),

          const _Section('Formulario'),
          AppSegmented<String>(
            selected: _view,
            onChanged: (v) => setState(() => _view = v),
            segments: const [
              AppSegment(value: 'Lista', label: 'Lista'),
              AppSegment(value: 'Kanban', label: 'Kanban'),
              AppSegment(value: 'Sprints', label: 'Sprints'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Título',
              hintText: 'Actividad 1',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Calificación',
              errorText: 'Debe estar entre 0 y 10',
            ),
          ),

          const _Section('Estados'),
          AppCard(
            child: EmptyState(
              icon: LucideIcons.inbox,
              title: 'Estado vacío',
              message:
                  'Dice qué aparecerá aquí y ofrece la acción para '
                  'empezar.',
              actionLabel: 'Acción',
              onAction: () {},
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: ErrorState(
              message: 'Dice qué pasó y cómo seguir.',
              onRetry: () {},
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 120, height: 12),
                SizedBox(height: AppSpacing.sm),
                Skeleton(height: 20),
                SizedBox(height: AppSpacing.xs),
                Skeleton(width: 200),
              ],
            ),
          ),

          const _Section('Movimiento'),
          for (final (i, (name, d)) in const [
            ('instant · 120 ms', 'Pulsación de botón, casilla'),
            ('quick · 220 ms', 'Cambio de estado, aparición'),
            ('smooth · 360 ms', 'Transición de pantalla'),
            ('expressive · 600 ms', 'Gráficos, barras y anillos'),
            ('celebrate · 900 ms', 'Logros'),
          ].indexed)
            FadeSlideIn(
              index: i,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(name),
                subtitle: Text(d),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.sm),
    child: SectionHeader(title: title),
  );
}

class _Swatches extends StatelessWidget {
  const _Swatches(this.items);

  final List<(String, Color, Color)> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final (name, background, foreground) in items)
          DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadii.md,
              border: Border.all(color: c.outline),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                name,
                style: context.text.labelMedium!.copyWith(color: foreground),
              ),
            ),
          ),
      ],
    );
  }
}
