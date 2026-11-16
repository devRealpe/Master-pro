import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_pro/app/master_pro_app.dart';
import 'package:master_pro/app/shell/app_shell.dart';
import 'package:master_pro/core/design_system/design_system.dart';
import 'package:master_pro/core/settings/theme_mode_controller.dart';
import 'package:master_pro/features/home/presentation/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> pumpApp(
  WidgetTester tester, {
  Map<String, Object> stored = const {},
}) async {
  SharedPreferences.setMockInitialValues(stored);
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const MasterProApp(),
    ),
  );
  await tester.pumpAndSettle();
  return preferences;
}

Brightness brightnessOf(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(AppShell))).brightness;

void main() {
  testWidgets('arranca en Inicio con las cinco pestañas', (tester) async {
    await pumpApp(tester);

    expect(find.text('Tu centro académico'), findsOneWidget);
    for (final destination in AppShell.destinations) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(destination.label),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('cada pestaña muestra su pantalla', (tester) async {
    await pumpApp(tester);

    const expected = {
      'Plan': 'Aún no hay actividades',
      'Calendario': 'Nada en el calendario',
      'Asignaturas': 'Registra tus asignaturas',
      'Mi espacio': 'Apariencia',
      'Inicio': 'Tu centro académico',
    };
    for (final MapEntry(key: tab, value: content) in expected.entries) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(content), findsOneWidget, reason: tab);
    }
  });

  testWidgets('el tema elegido se aplica y se recuerda', (tester) async {
    final preferences = await pumpApp(tester);
    await tester.tap(find.text('Mi espacio'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(brightnessOf(tester), Brightness.dark);
    expect(preferences.getString(ThemeModeController.storageKey), 'dark');

    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();

    expect(brightnessOf(tester), Brightness.light);
    expect(preferences.getString(ThemeModeController.storageKey), 'light');
  });

  testWidgets('arranca con el tema guardado', (tester) async {
    await pumpApp(tester, stored: {ThemeModeController.storageKey: 'dark'});

    expect(brightnessOf(tester), Brightness.dark);
    expect(
      Theme.of(tester.element(find.byType(AppShell))).extension<AppColors>(),
      AppColors.dark,
    );
  });

  testWidgets('un valor guardado inválido vuelve al tema del sistema', (
    tester,
  ) async {
    await pumpApp(tester, stored: {ThemeModeController.storageKey: 'sepia'});

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
  });

  testWidgets('el catálogo se abre desde Mi espacio y permite volver', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Mi espacio'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Design System'));
    // El catálogo tiene animaciones continuas: no se puede esperar a que
    // «termine».
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Tipografía'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Apariencia'), findsOneWidget);
  });

  test('el saludo depende de la hora', () {
    expect(HomePage.greeting(5), 'Buenos días');
    expect(HomePage.greeting(11), 'Buenos días');
    expect(HomePage.greeting(12), 'Buenas tardes');
    expect(HomePage.greeting(18), 'Buenas tardes');
    expect(HomePage.greeting(19), 'Buenas noches');
    expect(HomePage.greeting(2), 'Buenas noches');
  });
}
