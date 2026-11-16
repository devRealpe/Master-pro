import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tokens/app_motion.dart';

/// Aparición progresiva de un elemento. En una lista, [index] escalona la
/// entrada; a partir de [AppDurations.maxStaggered] el resto entra a la vez.
///
/// Con «reducir movimiento» activo, el elemento aparece sin desplazarse.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final Duration _delay =
      AppDurations.stagger * math.min(widget.index, AppDurations.maxStaggered);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _delay + AppDurations.smooth,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _delay.inMilliseconds / _controller.duration!.inMilliseconds,
      1,
      curve: AppCurves.enter,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
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
      opacity: _progress,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_progress),
        child: widget.child,
      ),
    );
  }
}
