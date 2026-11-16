import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:master_pro/core/design_system/catalog/catalog_page.dart';
import 'package:master_pro/core/design_system/design_system.dart';

Future<void> pumpIn(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  bool reduceMotion = false,
  double textScale = 1,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: app!,
      ),
      home: child is Scaffold || child is CatalogPage
          ? child
          : Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('AppButton', () {
    testWidgets('ejecuta la acción al tocarlo', (tester) async {
      var taps = 0;
      await pumpIn(
        tester,
        AppButton(label: 'Guardar', onPressed: () => taps++),
      );

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('mientras carga no responde y lo anuncia', (tester) async {
      var taps = 0;
      await pumpIn(
        tester,
        AppButton(label: 'Guardar', loading: true, onPressed: () => taps++),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump(AppDurations.quick);

      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Guardar, en curso'), findsOneWidget);
    });

    testWidgets('sin acción queda deshabilitado', (tester) async {
      await pumpIn(tester, const AppButton(label: 'Guardar', onPressed: null));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.enabled, isFalse);
    });
  });

  group('Progreso', () {
    testWidgets('el anillo recorta los valores fuera de rango', (tester) async {
      await pumpIn(
        tester,
        const ProgressRing(value: 1.8, semanticLabel: 'Evaluación continua'),
      );
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(find.byType(ProgressRing));
      expect(semantics.label, 'Evaluación continua');
      expect(semantics.value, '100 %');
    });

    testWidgets('la barra llega a su valor al terminar la animación', (
      tester,
    ) async {
      await pumpIn(
        tester,
        const SizedBox(width: 200, child: AppProgressBar(value: 0.5)),
      );
      await tester.pumpAndSettle();

      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.widthFactor, 0.5);
    });

    test('las cifras usan coma decimal', () {
      expect(AnimatedCount.format(4.25, 2), '4,25');
      expect(AnimatedCount.format(3.75, 1), '3,8');
      expect(AnimatedCount.format(5, 0), '5');
    });

    testWidgets('la cifra animada termina en su valor', (tester) async {
      await pumpIn(tester, const AnimatedCount(value: 4.25, fractionDigits: 2));
      await tester.pumpAndSettle();

      expect(find.text('4,25'), findsOneWidget);
    });
  });

  group('Estados', () {
    testWidgets('el estado vacío ofrece su acción', (tester) async {
      var taps = 0;
      await pumpIn(
        tester,
        EmptyState(
          icon: LucideIcons.inbox,
          title: 'Sin actividades',
          message: 'Crea la primera.',
          actionLabel: 'Crear actividad',
          onAction: () => taps++,
        ),
      );

      await tester.tap(find.text('Crear actividad'));
      await tester.pumpAndSettle();

      expect(find.text('Sin actividades'), findsOneWidget);
      expect(taps, 1);
    });

    testWidgets('el error permite reintentar', (tester) async {
      var retries = 0;
      await pumpIn(
        tester,
        ErrorState(message: 'Sin conexión.', onRetry: () => retries++),
      );

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(retries, 1);
    });
  });

  group('AppSegmented', () {
    testWidgets('avisa de la opción elegida y no de la ya activa', (
      tester,
    ) async {
      final changes = <int>[];
      await pumpIn(
        tester,
        SizedBox(
          width: 300,
          child: AppSegmented<int>(
            selected: 1,
            onChanged: changes.add,
            segments: const [
              AppSegment(value: 1, label: 'Lista'),
              AppSegment(value: 2, label: 'Kanban'),
              AppSegment(value: 3, label: 'Sprints'),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Lista'));
      await tester.tap(find.text('Sprints'));
      await tester.pumpAndSettle();

      expect(changes, [3]);
    });

    testWidgets('en 280 dp y con texto x1.5 no se parte ni se desborda', (
      tester,
    ) async {
      await pumpIn(
        tester,
        SizedBox(
          width: 280,
          child: AppSegmented<int>(
            selected: 1,
            onChanged: (_) {},
            segments: const [
              AppSegment(value: 1, label: 'Sistema', icon: LucideIcons.monitor),
              AppSegment(value: 2, label: 'Claro', icon: LucideIcons.sun),
              AppSegment(value: 3, label: 'Oscuro', icon: LucideIcons.moon),
            ],
          ),
        ),
        textScale: 1.5,
      );

      expect(tester.takeException(), isNull);
      // Una sola línea: la etiqueta mide 20 de interlínea × 1,5 de escala.
      expect(tester.getSize(find.text('Sistema')).height, closeTo(30, 0.5));
    });
  });

  group('Movimiento', () {
    testWidgets('FadeSlideIn termina visible y en su sitio', (tester) async {
      await pumpIn(tester, const FadeSlideIn(index: 3, child: Text('Hola')));
      await tester.pump();

      FadeTransition fade() => tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('Hola'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade().opacity.value, lessThan(1));

      await tester.pumpAndSettle();
      expect(fade().opacity.value, 1);
    });

    testWidgets('con reducir movimiento aparece de inmediato', (tester) async {
      await pumpIn(
        tester,
        const FadeSlideIn(index: 3, child: Text('Hola')),
        reduceMotion: true,
      );
      await tester.pump();

      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('Hola'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 1);
    });
  });

  group('Catálogo', () {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets(
          'se dibuja sin desbordes · ${dark ? 'oscuro' : 'claro'} · texto x$scale',
          (tester) async {
            // Un teléfono estrecho: 360 × 800 dp.
            tester.view.physicalSize = const Size(360, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);

            await pumpIn(
              tester,
              const CatalogPage(),
              dark: dark,
              textScale: scale,
            );
            await tester.pump(AppDurations.expressive);

            // Recorre toda la página: un desborde lanzaría una excepción.
            final list = find.byType(Scrollable).first;
            final lastSection = find.text('celebrate · 900 ms');
            for (var i = 0; i < 40 && lastSection.evaluate().isEmpty; i++) {
              await tester.drag(list, const Offset(0, -500));
              await tester.pump(AppDurations.quick);
            }

            expect(tester.takeException(), isNull);
            expect(lastSection, findsOneWidget);
          },
        );
      }
    }
  });
}
