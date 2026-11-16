import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_layout.dart';
import '../tokens/app_motion.dart';

/// Anillo de progreso animado. Sin [color] usa el degradado de marca.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 64,
    this.strokeWidth = 6,
    this.color,
    this.child,
    this.semanticLabel,
  });

  /// Progreso entre 0 y 1. Los valores fuera de rango se recortan.
  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Widget? child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final target = value.clamp(0.0, 1.0);

    return Semantics(
      label: semanticLabel,
      value: '${(target * 100).round()} %',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: AppMotion.duration(context, AppDurations.expressive),
        curve: AppCurves.enter,
        builder: (context, animated, child) => CustomPaint(
          painter: _RingPainter(
            value: animated,
            strokeWidth: strokeWidth,
            track: c.surfaceRaised,
            start: color ?? c.primary,
            end: color ?? c.accent,
          ),
          child: SizedBox.square(
            dimension: size,
            child: Center(child: child),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.track,
    required this.start,
    required this.end,
  });

  final double value;
  final double strokeWidth;
  final Color track;
  final Color start;
  final Color end;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, base..color = track);
    if (value <= 0) return;

    final arc = base
      ..shader = SweepGradient(
        colors: [start, end, start],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.track != track ||
      old.start != start ||
      old.end != end ||
      old.strokeWidth != strokeWidth;
}

/// Barra de progreso animada.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.trackColor,
    this.height = 6,
    this.semanticLabel,
  });

  /// Progreso entre 0 y 1. Los valores fuera de rango se recortan.
  final double value;
  final Color? color;
  final Color? trackColor;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final target = value.clamp(0.0, 1.0);

    return Semantics(
      label: semanticLabel,
      value: '${(target * 100).round()} %',
      child: ClipRRect(
        borderRadius: AppRadii.pill,
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: trackColor ?? c.surfaceRaised,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target),
              duration: AppMotion.duration(context, AppDurations.expressive),
              curve: AppCurves.enter,
              builder: (context, animated, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: animated,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color ?? c.primary,
                    borderRadius: AppRadii.pill,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cifra que cambia contando en vez de saltar.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.fractionDigits = 0,
    this.style,
    this.suffix = '',
  });

  final double value;
  final int fractionDigits;
  final TextStyle? style;
  final String suffix;

  /// Formato es-CO: coma decimal.
  static String format(double value, int fractionDigits) =>
      value.toStringAsFixed(fractionDigits).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: AppMotion.duration(context, AppDurations.expressive),
      curve: AppCurves.enter,
      builder: (context, animated, _) => Text(
        '${format(animated, fractionDigits)}$suffix',
        style: (style ?? DefaultTextStyle.of(context).style).copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        semanticsLabel: '${format(value, fractionDigits)}$suffix',
      ),
    );
  }
}
