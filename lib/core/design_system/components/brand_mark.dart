import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';

/// Marca de Master Pro: un birrete sobre el degradado de marca, o en blanco
/// translúcido cuando ya está encima del degradado ([onGradient]).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64, this.onGradient = false});

  final double size;
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onGradient ? null : c.brandGradient,
          color: onGradient ? c.onGradient.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: SizedBox.square(
          dimension: size,
          child: Icon(
            LucideIcons.graduationCap,
            size: size * 0.5,
            color: c.onGradient,
          ),
        ),
      ),
    );
  }
}
