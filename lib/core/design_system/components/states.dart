import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_layout.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_typography.dart';
import 'app_button.dart';

/// Estado vacío: una invitación, no una disculpa. Dice qué aparecerá aquí y,
/// si existe, ofrece la acción para empezar.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _StateLayout(
      icon: icon,
      iconColor: c.primary,
      iconBackground: c.primaryContainer,
      title: title,
      message: message,
      action: actionLabel == null
          ? null
          : AppButton(label: actionLabel!, onPressed: onAction),
      footer: footer,
    );
  }
}

/// Error en el lugar donde ocurrió: qué pasó y cómo reintentar.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.title = 'No se pudo cargar',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _StateLayout(
      icon: LucideIcons.triangleAlert,
      iconColor: c.onDangerContainer,
      iconBackground: c.dangerContainer,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : AppButton(
              label: 'Reintentar',
              icon: LucideIcons.refreshCw,
              variant: AppButtonVariant.secondary,
              onPressed: onRetry,
            ),
    );
  }
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    this.action,
    this.footer,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String message;
  final Widget? action;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 64,
              child: Icon(icon, size: 28, color: iconColor),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: text.bodyMedium!.copyWith(color: context.colors.inkSoft),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Bloque de carga con la forma del contenido que va a llegar.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppRadii.sm,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.celebrate,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceRaised,
            borderRadius: widget.borderRadius,
          ),
          child: SizedBox(width: widget.width, height: widget.height),
        ),
      ),
    );
  }
}
