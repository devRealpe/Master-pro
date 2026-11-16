import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_layout.dart';
import '../tokens/app_typography.dart';
import 'app_card.dart';

/// Texto pequeño en mayúsculas que nombra una categoría o una cifra.
class Overline extends StatelessWidget {
  const Overline(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: context.text.labelSmall!.copyWith(
      color: color ?? context.colors.inkMuted,
    ),
  );
}

/// Encabezado de sección con una acción opcional a la derecha.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: context.text.titleMedium),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// Tarjeta de estadística: rótulo, cifra protagonista y detalle.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.leading,
    this.footer,
    this.onTap,
  });

  final String label;

  /// La cifra. Suele ser un `Text` o un `AnimatedCount`.
  final Widget value;
  final String? caption;
  final Widget? leading;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Overline(label),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle.merge(
                      style: text.headlineSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      child: value,
                    ),
                    if (caption != null)
                      Text(
                        caption!,
                        style: text.bodySmall!.copyWith(
                          color: context.colors.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.sm),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Estructura común de las pantallas de pestaña: sobretítulo, título grande
/// y contenido desplazable con los márgenes del sistema.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.children,
    this.overline,
    this.trailing,
  });

  final String title;
  final String? overline;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.md,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (overline != null) ...[
                      Overline(overline!),
                      const SizedBox(height: AppSpacing.xxs),
                    ],
                    Semantics(
                      header: true,
                      child: Text(title, style: context.text.headlineMedium),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}
