import 'package:material_ui/material_ui.dart';

import '../tokens/app_layout.dart';
import '../tokens/app_motion.dart';

/// Reduce ligeramente su hijo mientras se mantiene pulsado. Es la
/// microinteracción común de botones y tarjetas.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && _down && !AppMotion.reduced(context);
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: active ? 0.97 : 1,
        duration: AppDurations.instant,
        curve: AppCurves.standard,
        child: widget.child,
      ),
    );
  }
}

/// Superficie decorada que responde al toque con onda y escala.
class Pressable extends StatelessWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    required this.decoration,
    this.borderRadius = AppRadii.lg,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BoxDecoration decoration;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      enabled: onTap != null,
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: child),
        ),
      ),
    );
  }
}
