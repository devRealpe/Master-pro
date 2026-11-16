import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_layout.dart';
import '../tokens/app_motion.dart';
import 'pressable.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

/// Botón de Master Pro. Con [loading] conserva su tamaño, muestra un
/// indicador y deja de responder al toque.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (background, foreground) = switch (variant) {
      AppButtonVariant.primary => (c.primary, c.onPrimary),
      AppButtonVariant.secondary => (c.primaryContainer, c.onPrimaryContainer),
      AppButtonVariant.ghost => (Colors.transparent, c.primary),
      AppButtonVariant.destructive => (c.danger, c.onDanger),
    };
    final enabled = onPressed != null && !loading;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    final button = FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        // Mientras carga, el botón no se ve deshabilitado: sigue siendo la
        // misma acción, solo que en curso.
        disabledBackgroundColor: loading ? background : null,
        disabledForegroundColor: loading ? foreground : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: loading ? 0 : 1,
            duration: AppMotion.duration(context, AppDurations.instant),
            child: content,
          ),
          if (loading)
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
    );

    return Semantics(
      label: loading ? '$label, en curso' : null,
      child: PressScale(
        enabled: enabled,
        child: expand
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}
