import 'package:flutter_test/flutter_test.dart';
import 'package:master_pro/core/time/dates.dart';
import 'package:master_pro/core/time/deadline_clock.dart';
import 'package:master_pro/features/activities/domain/activity.dart';
import 'package:master_pro/features/activities/presentation/activity_card.dart';
import 'package:master_pro/features/subjects/domain/subject.dart';
import 'package:master_pro/features/subjects/presentation/subjects_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/pump_app.dart';

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

const _subject = Subject(id: 's1', name: 'Asignatura 1', colorIndex: 2);
const _otherSubject = Subject(id: 's2', name: 'Asignatura 2', colorIndex: 4);

Activity _dueOn(int day, String title, {String? subjectId = 's1'}) => Activity(
  id: 'a$day',
  title: title,
  subjectId: subjectId,
  dueAt: SpainTime.toInstant(DateTime(2026, 11, day)),
);

void main() {
  // Varias actividades de ejemplo se crean al declarar las pruebas, antes
  // de que arranque la app: las zonas horarias deben estar ya cargadas.
  initializeTimeZones();

  group('Crear', () {
    testWidgets('una actividad nueva queda guardada con los valores de UNIR', (
      tester,
    ) async {
      useTallPhone(tester);
      final backend = await pumpApp(
        tester,
        backend: TestBackend(subjects: [_subject]),
      );
      await openTab(tester, 'Plan');
      await tester.tap(find.text('Agregar actividad'));
      await tester.pumpAndSettle();
      expect(find.text('Nueva actividad'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '  Actividad 1 ');
      await tester.tap(find.text('Sin asignatura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Asignatura 1').last);
      await tester.pumpAndSettle();

      // El selector de fecha propone hoy; se acepta tal cual.
      await tester.tap(find.text('Día'));
      await tester.pumpAndSettle();
      final picker = find.byType(DatePickerDialog);
      await tester.tap(
        find.descendant(
          of: picker,
          matching: find.text(
            MaterialLocalizations.of(tester.element(picker)).okButtonLabel,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('En tu hora:'), findsOneWidget);

      await tester.tap(find.text('Agregar actividad').hitTestable());
      await tester.pumpAndSettle();

      final saved = backend.activities.items.single;
      expect(saved.title, 'Actividad 1');
      expect(saved.subjectId, 's1');
      expect(saved.dueZone, DeadlineZone.spain);
      expect(saved.dueAt, SpainTime.toInstant(Dates.today()));
      expect(saved.bufferDays, 1);
      expect(saved.status, ActivityStatus.backlog);
      expect(saved.priority, ActivityPriority.medium);
      expect(find.byType(ActivityCard), findsOneWidget);
    });

    testWidgets('sin fecha también se puede guardar', (tester) async {
      useTallPhone(tester);
      final backend = await pumpApp(tester);
      await openTab(tester, 'Plan');
      await tester.tap(find.text('Agregar actividad'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Lectura del tema 1',
      );
      await tester.tap(find.text('Agregar actividad').hitTestable());
      await tester.pumpAndSettle();

      final saved = backend.activities.items.single;
      expect(saved.dueAt, isNull);
      expect(saved.subjectId, isNull);
      expect(find.text('Sin fecha'.toUpperCase()), findsOneWidget);
    });

    testWidgets('valida el título y el tiempo estimado', (tester) async {
      useTallPhone(tester);
      final backend = await pumpApp(tester);
      await openTab(tester, 'Plan');
      await tester.tap(find.text('Agregar actividad'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Tiempo estimado'),
        'mucho',
      );
      await tester.tap(find.text('Agregar actividad').hitTestable());
      await tester.pumpAndSettle();

      expect(find.text('Escribe el título de la actividad'), findsOneWidget);
      expect(
        find.text('Escribe las horas como número, por ejemplo 1,5'),
        findsOneWidget,
      );
      expect(backend.activities.items, isEmpty);
    });
  });

  group('Lista del Plan', () {
    Future<TestBackend> openPlan(WidgetTester tester) async {
      useTallPhone(tester);
      final backend = await pumpApp(
        tester,
        backend: TestBackend(
          subjects: [_subject, _otherSubject],
          activities: [
            _dueOn(15, 'Vencida'),
            _dueOn(17, 'Meta de hoy'),
            _dueOn(20, 'De esta semana', subjectId: 's2'),
            const Activity(
              id: 'x',
              title: 'Sin fecha',
              type: ActivityType.test,
            ),
            _dueOn(12, 'Ya entregada').submit(DateTime.utc(2026, 11, 11)),
          ],
        ),
      );
      await openTab(tester, 'Plan');
      return backend;
    }

    testWidgets('agrupa por urgencia y muestra lo que falta', (tester) async {
      await openPlan(tester);

      for (final section in [
        'VENCIDAS',
        'PARA HOY',
        'ESTA SEMANA',
        'SIN FECHA',
      ]) {
        expect(find.text(section), findsOneWidget, reason: section);
      }
      expect(find.text('MÁS ADELANTE'), findsNothing);
      expect(find.text('Venció ayer'), findsOneWidget);
      expect(find.text('Vence mañana'), findsOneWidget);
      expect(find.text('Faltan 4 días'), findsOneWidget);
      expect(find.text('Por hacer (4)'), findsOneWidget);
      expect(find.text('Hechas (1)'), findsOneWidget);
      expect(find.text('Ya entregada'), findsNothing);

      // Tu hora y la oficial, en la misma línea.
      expect(find.text('mar 17 nov, 17:59 · 23:59 España'), findsOneWidget);
    });

    testWidgets('las hechas van en su propia pestaña', (tester) async {
      await openPlan(tester);

      await tester.tap(find.text('Hechas (1)'));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityCard), findsOneWidget);
      expect(find.text('Ya entregada'), findsOneWidget);
      expect(find.text('Entregada'), findsOneWidget);
    });

    testWidgets('filtra por asignatura', (tester) async {
      await openPlan(tester);

      // La fila de filtros se desplaza: se trae a la vista antes de tocar.
      final chip = find.text('Asignatura 2').first;
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(find.byType(ActivityCard), findsOneWidget);
      expect(find.text('De esta semana'), findsOneWidget);

      await tester.ensureVisible(find.text('Todas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todas'));
      await tester.pumpAndSettle();
      expect(find.byType(ActivityCard), findsNWidgets(4));
    });

    testWidgets('filtra por tipo desde la hoja de filtros', (tester) async {
      await openPlan(tester);

      await tester.tap(find.byTooltip('Filtrar por tipo y prioridad'));
      await tester.pumpAndSettle();
      // «Test» aparece también en la tarjeta; la hoja está encima.
      await tester.tap(find.text('Test').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver resultados'));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityCard), findsOneWidget);
      expect(find.text('Sin fecha'), findsOneWidget);
      expect(find.byTooltip('Filtros activos: 1'), findsOneWidget);
    });
  });

  group('Detalle', () {
    final activity = _dueOn(19, 'Actividad 1').copyWith(
      subtasks: const [
        Subtask(id: 'p1', title: 'Revisar requisitos'),
        Subtask(id: 'p2', title: 'Elaborar borrador'),
      ],
    );

    Future<TestBackend> openDetail(WidgetTester tester) async {
      useTallPhone(tester);
      final backend = await pumpApp(
        tester,
        backend: TestBackend(subjects: [_subject], activities: [activity]),
      );
      await openTab(tester, 'Plan');
      await tester.tap(find.byType(ActivityCard));
      await tester.pumpAndSettle();
      return backend;
    }

    testWidgets('muestra tu hora, la oficial y tu meta', (tester) async {
      await openDetail(tester);

      expect(find.text('jue 19 nov, 17:59'), findsOneWidget);
      expect(find.text('Hora oficial: 23:59 España'), findsOneWidget);
      expect(find.text('Tu meta: mié 18 nov, 17:59'), findsOneWidget);
      expect(find.text('Faltan 3 días'), findsOneWidget);
    });

    testWidgets('marcar, agregar y quitar pasos', (tester) async {
      final backend = await openDetail(tester);
      Activity saved() => backend.activities.items.single;

      await tester.tap(find.text('Revisar requisitos'));
      await tester.pumpAndSettle();
      expect(saved().subtasksDone, 1);
      expect(find.text('1 de 2'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Agregar un paso'),
        'Revisar resultados',
      );
      await tester.tap(find.byTooltip('Agregar paso'));
      await tester.pumpAndSettle();
      expect(saved().subtasks.map((s) => s.title), [
        'Revisar requisitos',
        'Elaborar borrador',
        'Revisar resultados',
      ]);

      await tester.tap(find.byTooltip('Quitar paso: Elaborar borrador'));
      await tester.pumpAndSettle();
      expect(saved().subtasks, hasLength(2));
      expect(find.text('1 de 2'), findsOneWidget);
    });

    testWidgets('un paso vacío no se agrega', (tester) async {
      final backend = await openDetail(tester);

      await tester.tap(find.byTooltip('Agregar paso'));
      await tester.pumpAndSettle();

      expect(backend.activities.items.single, activity);
    });

    testWidgets('cambiar el estado se guarda', (tester) async {
      final backend = await openDetail(tester);

      await tester.tap(find.text('En revisión'));
      await tester.pumpAndSettle();

      expect(backend.activities.items.single.status, ActivityStatus.inReview);
    });

    testWidgets('entregar registra el momento y se puede deshacer', (
      tester,
    ) async {
      final backend = await openDetail(tester);
      Activity saved() => backend.activities.items.single;

      await tester.tap(find.text('Marcar como entregada'));
      await tester.pumpAndSettle();

      expect(saved().submittedAt, testNow);
      expect(saved().status, ActivityStatus.done);
      expect(find.text('Entregada: lun 16 nov, 12:00'), findsOneWidget);

      await tester.tap(find.text('Deshacer la entrega'));
      await tester.pumpAndSettle();

      expect(saved().isSubmitted, isFalse);
      expect(saved().status, ActivityStatus.inProgress);
    });

    testWidgets('editar conserva la fecha en hora de España', (tester) async {
      final backend = await openDetail(tester);

      await tester.tap(find.byTooltip('Editar'));
      await tester.pumpAndSettle();
      expect(find.text('19 nov 2026'), findsOneWidget);
      expect(find.text('23:59'), findsOneWidget);
      expect(find.text('En tu hora: jue 19 nov, 17:59'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).first,
        'Actividad corregida',
      );
      await tester.tap(find.text('3 días'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(
        backend.activities.items.single,
        activity.copyWith(title: 'Actividad corregida', bufferDays: 3),
      );
      expect(find.text('Tu meta: lun 16 nov, 17:59'), findsOneWidget);
    });

    testWidgets('eliminar pide confirmación y se puede deshacer', (
      tester,
    ) async {
      final backend = await openDetail(tester);

      await tester.tap(find.byTooltip('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(backend.activities.items.single.isDeleted, isTrue);
      expect(find.byType(ActivityCard), findsNothing);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      expect(backend.activities.items.single, activity);
      expect(find.byType(ActivityCard), findsOneWidget);
    });
  });

  group('Desde la asignatura', () {
    testWidgets('lista sus actividades y propone la asignatura al agregar', (
      tester,
    ) async {
      useTallPhone(tester);
      final backend = await pumpApp(
        tester,
        backend: TestBackend(
          subjects: [_subject, _otherSubject],
          activities: [
            _dueOn(19, 'De la asignatura 1'),
            _dueOn(20, 'De la asignatura 2', subjectId: 's2'),
          ],
        ),
      );
      await openTab(tester, 'Asignaturas');
      await tester.tap(find.byType(SubjectCard).first);
      await tester.pumpAndSettle();

      expect(find.text('De la asignatura 1'), findsOneWidget);
      expect(find.text('De la asignatura 2'), findsNothing);

      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Test del tema 1');
      await tester.tap(find.text('Agregar actividad'));
      await tester.pumpAndSettle();

      final created = backend.activities.items.last;
      expect(created.title, 'Test del tema 1');
      expect(created.subjectId, 's1');
      expect(find.text('Test del tema 1'), findsOneWidget);
    });
  });
}
