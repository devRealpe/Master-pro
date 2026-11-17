import 'package:flutter_test/flutter_test.dart';
import 'package:master_pro/features/subjects/domain/period.dart';
import 'package:master_pro/features/subjects/domain/subject.dart';
import 'package:master_pro/features/subjects/presentation/subjects_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/pump_app.dart';

/// Un teléfono alto, para que los formularios quepan sin desplazar.
void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> openSubjectsTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Asignaturas'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openMenu(WidgetTester tester, String option) async {
  await tester.tap(find.byTooltip('Más acciones'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option));
  await tester.pumpAndSettle();
}

final _period = Period(
  id: 'p1',
  name: '1.er cuatrimestre',
  startDate: DateTime(2026, 11, 16),
  endDate: DateTime(2027, 3, 21),
);

const _subject = Subject(
  id: 's1',
  name: 'Asignatura de prueba',
  teacher: 'Docente de prueba',
);

void main() {
  group('Crear', () {
    testWidgets('una asignatura nueva aparece en la lista y queda guardada', (
      tester,
    ) async {
      usePhone(tester);
      final backend = await pumpApp(tester);
      await openSubjectsTab(tester);

      await tester.tap(find.text('Agregar asignatura'));
      await tester.pumpAndSettle();
      expect(find.text('Nueva asignatura'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '  Asignatura 1  ');
      await tester.enterText(find.byType(TextField).at(1), 'Docente de prueba');
      await tester.tap(find.text('Agregar asignatura').hitTestable());
      await tester.pumpAndSettle();

      expect(find.byType(SubjectCard), findsOneWidget);
      expect(find.text('Asignatura 1'), findsOneWidget);
      expect(find.text('Actuales (1)'), findsOneWidget);

      final saved = backend.subjects.items.single;
      expect(saved.name, 'Asignatura 1');
      expect(saved.teacher, 'Docente de prueba');
      expect(saved.status, SubjectStatus.active);
      expect(saved.isDeleted, isFalse);
    });

    testWidgets('sin nombre no se guarda y se explica por qué', (tester) async {
      usePhone(tester);
      final backend = await pumpApp(tester);
      await openSubjectsTab(tester);
      await tester.tap(find.text('Agregar asignatura'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agregar asignatura').hitTestable());
      await tester.pumpAndSettle();

      expect(find.text('Escribe el nombre de la asignatura'), findsOneWidget);
      expect(find.text('Nueva asignatura'), findsOneWidget);
      expect(backend.subjects.items, isEmpty);
    });

    testWidgets('al elegir periodo se proponen sus fechas', (tester) async {
      usePhone(tester);
      final backend = await pumpApp(
        tester,
        backend: TestBackend(periods: [_period]),
      );
      await openSubjectsTab(tester);
      await tester.tap(find.text('Agregar asignatura'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Asignatura 1');
      await tester.tap(find.text('Sin periodo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1.er cuatrimestre').last);
      await tester.pumpAndSettle();

      expect(find.text('16 nov 2026'), findsOneWidget);
      expect(find.text('21 mar 2027'), findsOneWidget);

      await tester.tap(find.text('Agregar asignatura').hitTestable());
      await tester.pumpAndSettle();

      final saved = backend.subjects.items.single;
      expect(saved.periodId, 'p1');
      expect(saved.startDate, DateTime(2026, 11, 16));
      expect(saved.endDate, DateTime(2027, 3, 21));
    });

    testWidgets('cada asignatura nueva propone un color libre', (tester) async {
      usePhone(tester);
      final backend = await pumpApp(
        tester,
        backend: TestBackend(subjects: [_subject]),
      );
      await openSubjectsTab(tester);
      await tester.tap(find.byTooltip('Agregar asignatura'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Asignatura 2');
      await tester.tap(find.text('Agregar asignatura').hitTestable());
      await tester.pumpAndSettle();

      final colors = {for (final s in backend.subjects.items) s.colorIndex};
      expect(colors, hasLength(2));
    });
  });

  group('Detalle', () {
    Future<TestBackend> openDetail(WidgetTester tester) async {
      usePhone(tester);
      final backend = await pumpApp(
        tester,
        backend: TestBackend(subjects: [_subject], periods: [_period]),
      );
      await openSubjectsTab(tester);
      await tester.tap(find.byType(SubjectCard));
      await tester.pumpAndSettle();
      return backend;
    }

    testWidgets('muestra los datos de la asignatura', (tester) async {
      await openDetail(tester);

      expect(find.text('Asignatura de prueba'), findsWidgets);
      expect(find.text('Docente de prueba'), findsWidgets);
      expect(find.text('Sin fechas'), findsOneWidget);
    });

    testWidgets('editar cambia solo lo editado', (tester) async {
      final backend = await openDetail(tester);

      await tester.tap(find.byTooltip('Editar'));
      await tester.pumpAndSettle();
      expect(find.text('Editar asignatura'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Nombre corregido');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('Nombre corregido'), findsWidgets);
      final saved = backend.subjects.items.single;
      expect(saved, _subject.copyWith(name: 'Nombre corregido'));
    });

    testWidgets('finalizar la lleva al historial y se puede reabrir', (
      tester,
    ) async {
      final backend = await openDetail(tester);

      await openMenu(tester, 'Marcar como finalizada');
      expect(backend.subjects.items.single.status, SubjectStatus.finished);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Actuales (0)'), findsOneWidget);
      expect(find.byType(SubjectCard), findsNothing);

      await tester.tap(find.text('Historial (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SubjectCard));
      await tester.pumpAndSettle();

      await openMenu(tester, 'Volver a «En curso»');
      expect(backend.subjects.items.single.status, SubjectStatus.active);
    });

    testWidgets('eliminar pide confirmación y se puede deshacer', (
      tester,
    ) async {
      final backend = await openDetail(tester);

      await openMenu(tester, 'Eliminar');
      expect(find.text('¿Eliminar esta asignatura?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
      await tester.pumpAndSettle();

      // Va a la papelera: sale de la lista, pero no se borra.
      expect(find.byType(SubjectCard), findsNothing);
      expect(find.text('Registra tus asignaturas'), findsOneWidget);
      expect(backend.subjects.items.single.isDeleted, isTrue);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      expect(find.byType(SubjectCard), findsOneWidget);
      expect(backend.subjects.items.single, _subject);
    });

    testWidgets('cancelar la eliminación no cambia nada', (tester) async {
      final backend = await openDetail(tester);

      await openMenu(tester, 'Eliminar');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(backend.subjects.items.single, _subject);
      expect(find.byTooltip('Editar'), findsOneWidget);
    });
  });

  group('Periodos', () {
    Future<TestBackend> openPeriods(
      WidgetTester tester, {
      List<Period> periods = const [],
    }) async {
      usePhone(tester);
      final backend = await pumpApp(
        tester,
        backend: TestBackend(periods: periods),
      );
      await openSubjectsTab(tester);
      await tester.tap(find.byTooltip('Periodos y fechas clave'));
      await tester.pumpAndSettle();
      return backend;
    }

    testWidgets('el calendario UNIR se carga sin confirmar', (tester) async {
      final backend = await openPeriods(tester);

      await tester.tap(find.text('Cargar calendario UNIR'));
      await tester.pumpAndSettle();

      expect(backend.periods.items, hasLength(2));
      expect(find.text('1.er cuatrimestre 2026–2027'), findsOneWidget);
      expect(find.text('16 nov 2026 – 21 mar 2027'), findsOneWidget);
      // Inicio y fin del periodo más sus 4 fechas clave.
      expect(find.text('5 fechas por confirmar'), findsOneWidget);
      expect(find.text('9 – 11 abr 2027'), findsOneWidget);
    });

    testWidgets('confirmar una fecha reduce las pendientes', (tester) async {
      final backend = await openPeriods(tester);
      await tester.tap(find.text('Cargar calendario UNIR'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar inicio y fin').first);
      await tester.pumpAndSettle();
      expect(find.text('4 fechas por confirmar'), findsOneWidget);

      await tester.tap(find.byTooltip('Confirmar: Exámenes').first);
      await tester.pumpAndSettle();
      expect(find.text('3 fechas por confirmar'), findsOneWidget);

      final first = sortPeriods(backend.periods.items).first;
      expect(first.datesConfirmed, isTrue);
      expect(
        first.keyDates.firstWhere((d) => d.title == 'Exámenes').confirmed,
        isTrue,
      );
    });

    testWidgets('crear un periodo a mano valida las fechas', (tester) async {
      final backend = await openPeriods(tester);

      await tester.tap(find.byTooltip('Agregar periodo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Periodo de prueba');
      await tester.tap(find.text('Crear periodo'));
      await tester.pumpAndSettle();

      expect(find.text('Elige las dos fechas'), findsOneWidget);
      expect(backend.periods.items, isEmpty);
    });

    testWidgets('eliminar un periodo conserva las asignaturas y se deshace', (
      tester,
    ) async {
      final backend = await openPeriods(tester, periods: [_period]);

      await tester.tap(find.byTooltip('Acciones del periodo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(backend.periods.items.single.isDeleted, isTrue);
      expect(find.text('Organiza tu año académico'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      expect(backend.periods.items.single, _period);
      expect(find.text('1.er cuatrimestre'), findsOneWidget);
    });
  });
}
