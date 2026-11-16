import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_layout.dart';
import 'pressable.dart';

/// Tarjeta base. Con [gradient] se convierte en la tarjeta principal de marca.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.gradient,
    this.borderRadius = AppRadii.lg,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final decoration = BoxDecoration(
      color: gradient == null ? (color ?? c.surface) : null,
      gradient: gradient,
      borderRadius: borderRadius,
      border: gradient == null ? Border.all(color: c.outline) : null,
      boxShadow: gradient == null
          ? AppShadows.rest(context)
          : AppShadows.raised(context),
    );
    final content = Padding(padding: padding, child: child);

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    return Pressable(
      onTap: onTap,
      decoration: decoration,
      borderRadius: borderRadius,
      child: content,
    );
  }
}
