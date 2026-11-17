# Master Pro — Propuesta de arquitectura, datos, diseño y fases

Versión 2 · 16 nov 2026 · Para revisión antes de escribir código

> **Cambios de la versión 2.** (1) Todo el proyecto queda en el plan gratuito de Firebase, sin tarjeta: los archivos se guardan en el teléfono y no en Firebase Storage. (2) Reglas de puntos confirmadas por ti: notas de 0 a 10, `valor × nota / 10`, 0,4 por clase, 0,1 por test y meta de 5 puntos. (3) El respaldo con restauración pasa a la Fase 1, porque es la única copia de los archivos.

Este documento sigue el orden que pediste en la sección 30 de tu propuesta. Cada afirmación sobre UNIR indica de dónde sale. Lo que no está confirmado en tus materiales aparece marcado como **por confirmar** y la aplicación lo deja configurable en vez de darlo por hecho.

## Contenido

1. [Resumen y decisiones que necesito de ti](#1-resumen-y-decisiones-que-necesito-de-ti)
2. [Lo que ya sé de tu maestría](#2-lo-que-ya-sé-de-tu-maestría)
3. [Necesidades adicionales y mejoras propuestas](#3-necesidades-adicionales-y-mejoras-propuestas)
4. [Viabilidad de las funcionalidades](#4-viabilidad-de-las-funcionalidades)
5. [Arquitectura técnica](#5-arquitectura-técnica)
6. [Modelo de datos](#6-modelo-de-datos)
7. [Design System](#7-design-system)
8. [Navegación](#8-navegación)
9. [Módulos y relaciones](#9-módulos-y-relaciones)
10. [Plan por fases](#10-plan-por-fases)
11. [Riesgos, dependencias y costos](#11-riesgos-dependencias-y-costos)
12. [Estado actual del proyecto](#12-estado-actual-del-proyecto)

---

## 1. Resumen y decisiones que necesito de ti

**Qué propongo construir.** Una aplicación Flutter para Android (preparada para iOS) con Firebase, organizada por funcionalidades en tres capas, con Riverpod para el estado y la caché sin conexión de Firestore como único almacén local. La asignatura es la entidad central: actividades, clases, exámenes, documentos y apuntes cuelgan de ella. El calendario, el Kanban, «Mi día» y las estadísticas no guardan datos propios: son vistas calculadas sobre esas entidades, así nada se duplica.

**Tres ideas que cambian tu propuesta original:**

1. **El sistema de calificaciones se modela con «valor × calificación», que es como puntúa UNIR**, además del promedio ponderado clásico. El indicador principal de cada asignatura será el marcador de puntos de evaluación continua frente a tu meta.
2. **Las fechas límite se guardan en hora de España y se muestran en tu hora local**, con un «colchón» personal (por defecto un día antes). Es el error más caro que puedes cometer en UNIR y la app lo evita por diseño.
3. **Los recordatorios básicos de entregas y clases pasan a la Fase 1.** El campus no envía notificaciones al celular; sin ellas la primera versión no cumple «usarla en mi día a día».

**Decisiones que son tuyas** (mi recomendación va primero):

| # | Decisión | Recomendación | Alternativa |
|---|---|---|---|
| D1 | Plan de Firebase | **Resuelta: plan gratuito Spark, sin tarjeta.** Los archivos se guardan en el teléfono y se protegen con el respaldo (§5.5) | — |
| D2 | Pestañas principales | Inicio · Plan · Calendario · Asignaturas · Mi espacio (§8) | Tu propuesta: Inicio · Actividades · Calendario · Biblioteca · Mi espacio |
| D3 | Escala de notas | **Resuelta: 0 a 10**, con decimales (8,5) | — |
| D4 | Inicio de sesión | **Google**, con el registro de cuentas nuevas desactivado después de crear la tuya | Correo y contraseña |
| D5 | Versión de Flutter | Actualizar a la estable actual antes de empezar (tienes 3.38.2, de nov 2025) | Quedarse en 3.38.2 |
| D6 | Fechas clave de UNIR | Precargarlas marcadas «por confirmar» para que las valides contra el PDF oficial | Las ingresas tú a mano |
| D7 | Paleta e identidad | La de §7 | Ajustes que pidas al verla |

---

## 2. Lo que ya sé de tu maestría

Fuentes: `Maestría IA/CLAUDE.md`, la guía `00-bienvenida` (sesión con la mentora, 73 min) y el informe del seminario de metodologías ágiles y design thinking (Antonio Giménez Rico, 16 nov 2026).

### 2.1 Datos que la app aprovecha

| Dato | Fuente | Cómo lo usa Master Pro |
|---|---|---|
| Máster Universitario en Inteligencia Artificial, grupo PER 18408 | CLAUDE.md | Perfil académico inicial |
| 1.er cuatrimestre: 16 nov 2026 – 21 mar 2027, cinco asignaturas en paralelo, más o menos una clase en vivo al día | Bienvenida | Periodos académicos; el dashboard se diseña para 5 asignaturas simultáneas |
| Repaso 21 dic – 10 ene y 22 mar – 4 abr; exámenes 9–11 abr 2027; 2.º cuatrimestre desde 19 abr 2027; exámenes 10–12 sep; extraordinarios 8–10 oct; TFM 22 sep (ordinaria) y 20 oct (extraordinaria) | Bienvenida, tomado de la imagen del calendario oficial | Fechas clave precargadas como «por confirmar» (D6). La propia guía advierte que una diapositiva tenía fechas cruzadas |
| Nota final = 40 % evaluación continua + 60 % examen | Bienvenida | Plantilla de esquema de evaluación «UNIR» |
| Cada actividad tiene un **valor**; sumas `valor × calificación / 10`. Test: 0,1 cada uno. Asistencia: por ejemplo 0,4 por clase. Máximo 15 puntos. Meta práctica: 5 puntos | Bienvenida | Motor de calificaciones en modo «por puntos» y marcador de evaluación continua |
| Test y asistencia solo suman, nunca restan | Bienvenida | Las clases y los test sin hacer no penalizan en el cálculo |
| Entregas a las 23:59 de España: 17:59 en Colombia hasta el 27 mar 2027 y 16:59 desde el 28 mar | Bienvenida | Fechas con zona horaria y cambio de horario automático |
| «La fecha del campus es la máxima, no el día para entregar» | Bienvenida | Colchón de entrega configurable |
| El campus no notifica al celular; hay que anotar las clases cada semana | Bienvenida | Recordatorios de clases en la Fase 1 y alta rápida de las clases de la semana |
| Llamadas de seguimiento con la mentora cerca de cada entrega | Bienvenida | Tipo de evento «seguimiento» en el calendario |
| Cursos extra (AWS, Azure, Python), abiertos hasta sep–oct 2027, con certificado unos 3 meses después | Bienvenida | Módulo de certificaciones con fecha de cierre de la plataforma |
| Exámenes presenciales de viernes a domingo; en línea hay 6 días; existe convocatoria extraordinaria | Bienvenida | Campo «convocatoria» y ventana de fechas en cada examen |
| TFM en unos 4 meses, con 3 o 4 iteraciones con el director | Seminario (consejo de un profesor de otro máster) | Plantilla opcional de TFM por iteraciones, en la Fase 3 |
| Tus guías de estudio por clase, con repaso espaciado a 1, 3, 7, 14 y 30 días | CLAUDE.md | Enlace a la guía en cada clase; los mismos intervalos para repasar temas de examen |

### 2.2 Lo que no sé y no voy a inventar

- **Confirmado por ti (v2):** las notas van de 0 a 10, con decimales. Una actividad aporta `valor × nota / 10`: con valor 5, un 8 son 4 puntos y un 8,5 son 4,25. Cada clase asistida da 0,4 puntos y cada test 0,1. La meta son 5 puntos, que aseguran el 40 %; el 60 % restante es el examen de fin de cuatrimestre.
- **Sigue abierto:** cómo se convierte eso en la nota final de 0 a 10 (por ejemplo, si pasar de 5 puntos la sube, o si el examen exige una nota mínima). No afecta al marcador de puntos, solo a la «nota final estimada», que se muestra como provisional hasta que lo confirmes en la guía docente.
- Los nombres de tus cinco asignaturas, sus docentes y el valor de cada actividad. Los registras tú; están en «Actividades y test» del campus.
- Si tienes prácticas inscritas.

### 2.3 Cómo adapto lo ágil

Del seminario tomo las prácticas que sirven a una sola persona y dejo fuera las de equipo (roles, reunión diaria, velocidad).

| Concepto del seminario | En Master Pro |
|---|---|
| Sprint: ciclo corto que termina con algo que funciona | Mini sprint de horas a semanas, con **un objetivo verificable** («borrador de la actividad 1 completo»), no solo una lista de tareas |
| Ciclo planificar → revisar | Al crear el sprint eliges actividades y subtareas; al cerrarlo, lo no terminado vuelve al tablero y registras la retrospectiva |
| Kaizen, reflexión y mejora continua (principio 12) | Retrospectiva de tres preguntas por sprint y revisión semanal |
| Entregas incrementales (principio 3) | Subtareas como hitos de un trabajo grande; el progreso de la actividad sale de ellas |
| Kanban: ver el estado de un vistazo | Tablero con tus cinco columnas |
| Ritmo sostenible (principio 8) | Meta semanal de horas y aviso suave si tienes demasiadas tarjetas «En progreso» |
| Eliminar lo innecesario (principio 10) | Criterio de diseño: cada pantalla responde una pregunta; lo secundario queda un nivel más abajo |
| Jidoka, «IA con toque humano» | Las funciones de IA de la Fase 4 ayudan a repasar y planificar; no redactan entregas |

---

## 3. Necesidades adicionales y mejoras propuestas

Solo incluyo lo que resuelve un problema concreto de tu contexto.

| Propuesta | Problema que resuelve | Fase |
|---|---|---|
| **Fecha límite en hora de España + colchón** | Entregar tarde por confundir la hora. Cada actividad muestra «Vence: 25 ene, 17:59 (23:59 España)» y tu fecha objetivo un día antes | 1 |
| **Marcador de evaluación continua** | Saber de un vistazo cuántos puntos llevas, cuántos puedes sumar todavía y qué nota necesitas en la siguiente entrega para llegar a la meta | 1 |
| **Recordatorios básicos en la Fase 1** | El campus no avisa al celular | 1 |
| **Periodos y fechas clave** | Cuenta regresiva a exámenes y contexto de cada cuatrimestre sin crear eventos a mano | 1 |
| **Estados de actividad separados de «entregada» y «calificada»** | Evita combinaciones incoherentes (§6.3) | 1 |
| **Captura rápida y «Compartir con Master Pro»** | Guardar un PDF recién descargado del campus sin abrir la app y navegar hasta la asignatura | 1 (botón) · 2 (compartir desde Android) |
| **Respaldo y restauración desde la Fase 1** | La sincronización no es un respaldo: si borras algo, se borra en todos lados. Además, los archivos viven solo en el teléfono y el respaldo es su única copia | 1 |
| **Papelera de 30 días** | Eliminaciones accidentales | 1 |
| **Enlace a la guía de estudio de cada clase** | Tus guías ya existen; la app las deja a un toque desde la clase | 2 |
| **Repaso espaciado de temas de examen** | Distribuir repasos con los intervalos que ya usas (1, 3, 7, 14, 30 días) | 2 |
| **Revisión semanal** | Cierra la semana con datos reales y propone prioridades | 2 (simple) · 3 (completa) |
| **Lista de dudas por asignatura** | Preguntas para el foro, el profesor o la llamada con la mentora. Es un tipo de apunte, no un módulo nuevo | 2 |
| **Plantilla de TFM** | Cuando llegue: iteraciones con el director y entregas parciales | 3 |
| **Widget de pantalla de inicio de Android** | Ver la próxima entrega sin abrir la app | 3, opcional |

**Lo que recomiendo no hacer o aplazar:**

- **Cloud Functions y FCM.** Todos los recordatorios de tu lista dependen de fechas que el teléfono ya conoce, así que las notificaciones locales programadas los cubren, gratis y sin conexión. FCM solo aporta cuando un servidor debe decidir el aviso, y ese servidor (Cloud Functions) exige el plan de pago.
- **Rive.** Las animaciones nativas de Flutter cubren todas las de tu lista. Lottie queda para una o dos celebraciones (completar un sprint, alcanzar una meta). Rive exige diseñar las animaciones en su editor y no aporta nada que justifique ese trabajo.
- **Una segunda base de datos local** (Drift, Isar, Hive). Firestore ya trae caché persistente y cola de escrituras sin conexión; mantener dos almacenes sincronizados es la fuente clásica de errores.
- **Un servicio de búsqueda externo.** Con el volumen de una persona, buscar en memoria sobre los datos ya cacheados es instantáneo y gratuito.

---

## 4. Viabilidad de las funcionalidades

| Funcionalidad | Viabilidad | Nota técnica |
|---|---|---|
| Dashboard, asignaturas, actividades, subtareas | Alta | Lectura y escritura directas con caché sin conexión |
| Calificaciones y simulador | Alta | Lógica pura en Dart, la parte más probada del proyecto. El simulador es la misma función con valores hipotéticos, por eso su versión básica entra en la Fase 1 |
| Calendario día, semana y mes | Alta | Proyección sobre varias colecciones; la vista de día y semana con bloques lleva trabajo de interfaz |
| Biblioteca PDF con visor | Alta | Los archivos se guardan en el almacenamiento privado de la app y los metadatos en Firestore. No se recuperan solos al cambiar de teléfono: se restauran desde el respaldo |
| Sin conexión | Alta | Los datos funcionan con la caché de Firestore; los archivos están siempre en el teléfono |
| Kanban con arrastrar y soltar | Media | En móvil el arrastre entre columnas necesita desplazamiento automático en los bordes. Incluye siempre la alternativa «Mover a…» |
| Mini sprints con retrospectiva | Alta | |
| Notificaciones locales | Alta, con límites del sistema | Android 13+ pide permiso; las alarmas exactas tienen su propio permiso; algunos fabricantes retrasan avisos por ahorro de batería; iOS admite 64 pendientes, así que se programa una ventana móvil |
| Temporizador en segundo plano | Alta con el enfoque correcto | No se mantiene un contador vivo: se guarda la hora de fin, se programa el aviso y al volver se recalcula. Una notificación con cronómetro muestra la cuenta atrás sin servicio en primer plano |
| Apuntes con listas, casillas, enlaces e imágenes | Media | Depende del editor de texto enriquecido; se decide con una prueba corta al iniciar la Fase 2 |
| Estadísticas y resumen semanal | Alta | Cálculo local; no hacen falta agregados en servidor |
| Buscador global | Alta | Índice en memoria sin acentos. La búsqueda dentro de los PDF queda para la Fase 3 o 4, extrayendo el texto en el teléfono |
| Reparto automático de sesiones de repaso | Media | Regla simple (repaso espaciado dentro de tu disponibilidad) en la Fase 2; planificador completo en la Fase 4 |
| Orden personalizado del dashboard | Alta | Fase 3 |
| Asistente con IA y búsqueda semántica | Viable, con costo por uso | Fase 4; se presupuesta antes de empezar |

---

## 5. Arquitectura técnica

### 5.1 Capas

Arquitectura por funcionalidades con tres capas. Es una arquitectura limpia aplicada con criterio: sin casos de uso de una línea ni interfaces que solo tienen una implementación y ninguna prueba.

```
lib/
├─ main.dart
├─ app/                    arranque, router, tema, proveedores globales
├─ core/
│  ├─ design_system/       tokens, tema, componentes, animaciones
│  ├─ firebase/            inicialización, referencias tipadas, conversores
│  ├─ sync/                estado de sincronización
│  ├─ files/               archivos locales, respaldo y restauración
│  ├─ time/                zonas horarias, reloj inyectable, formatos es-CO
│  ├─ notifications/       programador de avisos locales
│  └─ utils/               resultados, errores, validadores
└─ features/
   └─ <módulo>/            subjects, activities, grades, calendar, library, ...
      ├─ domain/           entidades inmutables y lógica pura (sin Flutter ni Firebase)
      ├─ data/             repositorios de Firestore, mapeo de documentos
      └─ presentation/     pantallas, widgets y controladores (Riverpod)
```

Reglas de dependencia: `presentation → domain ← data`. El dominio no importa Flutter ni Firebase, así que la lógica de notas, prioridades y fechas se prueba sin emuladores. Los repositorios son clases abstractas con una implementación de Firestore y otra en memoria para las pruebas; eso también deja abierta la puerta a cambiar de proveedor.

La lógica con reglas reales vive en servicios de dominio puros:

- `GradeCalculator`: puntos, promedios, nota necesaria, máximo alcanzable, simulaciones.
- `DeadlineClock`: conversión España ↔ local con cambio de horario y cálculo del colchón.
- `DayPlanner`: orden de «Mi día» por urgencia, importancia y fecha.
- `ReminderPlanner`: qué avisos deben existir para el estado actual de los datos.
- `CalendarProjector`: convierte actividades, exámenes, clases, bloques y sprints en entradas de calendario.

### 5.2 Gestión de estado: Riverpod

**Elijo Riverpod** (rama 3.x; la última versión que encontré es `flutter_riverpod` 3.4.1, de julio de 2026).

| Criterio | Riverpod | Bloc |
|---|---|---|
| Flujos de Firestore | `StreamProvider` expone el flujo con carga y error ya resueltos | Hay que escribir eventos y estados para cada flujo |
| Datos derivados (nota actual = esquema + actividades + clases + exámenes) | Un proveedor que observa otros y se recalcula solo | Combinar varios blocs requiere suscripciones manuales |
| Inyección de dependencias y pruebas | Incluida: se sustituye cualquier proveedor en la prueba | Necesita `get_it` o `RepositoryProvider` |
| Código repetitivo para una sola persona | Bajo | Alto: tres archivos por funcionalidad |
| Trazabilidad estricta de eventos | Menor | Mayor; es su ventaja en equipos grandes |

Master Pro es sobre todo estado derivado de flujos, y ahí Riverpod es más directo. Bloc sería mejor elección con un equipo grande que necesite auditar cada transición, que no es el caso.

Uso Riverpod **sin generador de código** (`Notifier`, `AsyncNotifier`, `StreamProvider`), para no depender de `build_runner` en cada cambio de interfaz.

**Modelos escritos a mano (decisión de la entrega 1.2).** La propuesta original usaba `freezed` y `json_serializable`. Las entidades se escriben a mano: clases inmutables con `copyWith` (con centinela para poder dejar un campo vacío), igualdad y un mapeador aparte en la capa de datos. Ventajas: el dominio no conoce el formato de Firestore y no hay paso de generación. Costo: más código por entidad, cubierto con pruebas de ida y vuelta.

Nota de honestidad: al tomar la decisión, la instalación de `freezed` se quedó colgada y lo atribuí a la resolución de dependencias. Después comprobé que la causa era otra (un `flutter run` abierto en la terminal bloqueaba la herramienta), así que `freezed` probablemente sí se instala. La decisión se mantiene por las ventajas de arriba y porque ya hay tres entidades hechas así; se puede revisar si el número de entidades lo justifica.

### 5.3 Dependencias

Las versiones se fijan al instalar, con `flutter pub add`, comprobando la compatibilidad con el SDK.

| Para qué | Paquete | Por qué este |
|---|---|---|
| Firebase | `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in` | Oficiales; todos dentro del plan gratuito |
| Estado | `flutter_riverpod` | §5.2 |
| Navegación | `go_router` | Mantenido por el equipo de Flutter; pestañas con estado propio y enlaces profundos desde notificaciones |
| Modelos | Ninguna: clases y mapeadores escritos a mano (§5.2) | Sin paso de generación |
| Fechas | `intl`, `timezone`, `flutter_timezone` | Formato es-CO y base de zonas horarias con cambios de horario |
| Avisos | `flutter_local_notifications` | Estándar para notificaciones programadas |
| Archivos | `file_picker`, `path_provider`, `share_plus`, `archive` | Selección, almacenamiento privado, respaldo en ZIP y exportación |
| PDF | `pdfrx` | Motor PDFium, gratuito, con extracción de texto para la búsqueda futura. Syncfusion es comparable pero con licencia comercial |
| Gráficos | `fl_chart` | Líneas, barras y circulares animados, totalmente tematizables |
| Calendario | `table_calendar` para la cuadrícula de mes; día y semana propios | La línea de tiempo con bloques necesita control total del diseño |
| Preferencias del dispositivo | `shared_preferences` | Estado del temporizador, fecha del último respaldo |
| Iconos | `lucide_icons_flutter` | Una sola familia, de trazo fino |
| Fase 2 | `lottie`, editor de texto enriquecido (por decidir), recepción de archivos compartidos | |
| Pruebas | `flutter_test`, `integration_test`, `mocktail` | |

Son unas 20 dependencias directas en la Fase 1. No entran: `get_it`, `dio`, Hive/Isar/Drift, paquetes de componentes prefabricados ni `google_fonts` (Inter va empaquetada en la app, §7.1).

### 5.4 Firebase

- **Plan gratuito Spark.** No pide tarjeta ni cuenta de facturación, así que no puede generar cobros: si un día se superara una cuota, el servicio se pausa hasta el día siguiente.
- **Un solo proyecto** de Firebase. Para desarrollo y pruebas se usa el **Emulator Suite** local (Auth y Firestore); ya tienes Firebase CLI 15.4, FlutterFire CLI, Node y Java. Un segundo proyecto «de pruebas» sería complejidad sin beneficio para una app personal.
- **Authentication:** Google (D4). Después de crear tu cuenta se desactiva el registro de usuarios nuevos en la consola, así nadie más puede crear una aunque tenga la app.
- **Firestore:** todo cuelga de `users/{uid}` (§6). Caché persistente activada.
- **Sin Firebase Storage:** exige el plan de pago. Los archivos viven en el teléfono (§5.5).
- **Sin Cloud Functions:** también exigen el plan de pago. FCM es gratuito, pero no hace falta.
- **App Check** (Play Integrity) en la Fase 3, para que solo tu app firmada pueda hablar con el backend.

### 5.5 Sin conexión, sincronización y conflictos

- **Datos.** Las pantallas escuchan Firestore y reciben primero la caché; las escrituras se aplican al instante y se encolan. No hay un «modo sin conexión» aparte.
- **Indicador honesto.** Firestore informa cuándo un documento tiene escrituras pendientes. La app muestra un estado global («Todo respaldado», «3 cambios por subir», «Sin conexión») y una marca en cada documento afectado.
- **Conflictos.** Con un solo usuario, el conflicto real es editar lo mismo en dos dispositivos sin conexión. Se resuelve así: las escrituras actualizan **solo los campos cambiados**, nunca el documento completo, de modo que cambiar el estado en un teléfono y la nota en otro no se pisa; cada documento lleva `updatedAt` del servidor; los apuntes guardan las últimas versiones para recuperar texto si dos ediciones largas chocan.
- **Archivos.** Al adjuntar, el archivo se copia al almacenamiento privado de la app y sus metadatos (nombre, asignatura, vínculos, huella) se guardan en Firestore. El binario no sube a la nube. Están siempre disponibles sin conexión.
- **Otro teléfono o reinstalación.** Los metadatos reaparecen, pero cada documento muestra «Archivo no disponible en este dispositivo» hasta que restauras el respaldo o lo vuelves a adjuntar. La huella del archivo permite reconocerlo y reconectarlo sin crear duplicados.
- **Puerta abierta.** El acceso a los archivos pasa por una interfaz (`FileStore`). Si más adelante quieres copia automática en la nube sin pagar, se puede añadir una implementación sobre tu propio Google Drive (15 GB gratuitos) sin tocar el resto de la app. No entra en el plan actual.
- **Riesgo conocido.** Desinstalar la app borra la caché, incluidos los cambios todavía no subidos, y todos los archivos de la biblioteca. Por eso el indicador está siempre visible y la app se firma con una clave propia para que actualizar nunca exija desinstalar (§11.1).

### 5.6 Sincronización y respaldo no son lo mismo

| | Sincronización (Firestore) | Respaldo (ZIP) |
|---|---|---|
| Cubre | Los datos: asignaturas, actividades, notas, apuntes | Los datos **y los archivos** |
| Protege de | Perder o cambiar el teléfono (solo datos) | Borrados o cambios erróneos, pérdida de la cuenta, pérdida del teléfono |
| Si borras algo | Se borra en todos lados | La copia lo conserva |
| En Master Pro | Automática | «Crear respaldo»: un ZIP con los datos en JSON y los archivos, que guardas donde elijas (tu computador, tu Drive, una memoria). «Restaurar» lo vuelve a cargar |

Como el respaldo es la única copia de los archivos, la app lo trata como algo de primer nivel: muestra cuántos archivos hay sin respaldar, recuerda hacerlo con la frecuencia que elijas (propongo semanal) y permite respaldar solo lo nuevo. El respaldo y la restauración entran en la Fase 1.

Además: papelera de 30 días para todo lo eliminable y confirmación en los borrados definitivos.

### 5.7 Notificaciones

`ReminderPlanner` calcula, a partir de los datos y de tus preferencias, la lista de avisos que deberían existir; el programador la compara con los avisos pendientes en el sistema y añade o cancela. Se ejecuta al abrir la app y cada vez que cambia un dato relevante. Consecuencias:

- Editar o completar una actividad cancela sus avisos sin código adicional.
- «Actividad sin avances» es un aviso programado para N días después del último cambio, que se reprograma solo cuando avanzas.
- Se programa una ventana móvil (próximos 14 días) para respetar los límites del sistema.
- Limitación asumida: un recordatorio creado en un teléfono se programa en el otro cuando abres la app allí.

El centro de notificaciones de la app muestra el historial de avisos emitidos y los marca como leídos.

### 5.8 Seguridad

- Reglas de Firestore: solo `request.auth.uid == uid` lee o escribe bajo `users/{uid}`; se validan tipos y tamaños en los campos críticos.
- Archivos: se guardan en el directorio privado de la app, al que otras aplicaciones no tienen acceso. La app valida el tamaño máximo (propongo 50 MB) y los tipos permitidos (PDF, imágenes, Office, texto, ZIP).
- Las reglas se prueban con el emulador como parte de la suite.
- En el repositorio no entran claves privadas: ni cuentas de servicio ni el almacén de firma. Los archivos de configuración de Firebase del cliente (`google-services.json`, `firebase_options.dart`) son identificadores, no secretos; la protección real son las reglas y App Check.
- Bloqueo opcional con huella al abrir la app, en la Fase 3.

### 5.9 Calidad y pruebas

| Tipo | Qué cubre |
|---|---|
| Unitarias | Todo el dominio. `GradeCalculator` con casos tabulados (incluidos los ejercicios de tu guía de bienvenida, que tienen resultado conocido); `DeadlineClock` en las fechas de cambio de horario; `DayPlanner`; `ReminderPlanner` |
| Repositorios y reglas | Contra el emulador: lecturas, escrituras y accesos denegados |
| Widgets | Componentes del Design System en ambos temas y con texto ampliado; imágenes de referencia para los principales |
| Contraste | Una prueba recorre los pares de color del tema y falla si alguno baja de AA |
| Integración | Flujos críticos: entrar → asignatura → actividad → calificar → ver marcador; adjuntar PDF sin conexión → sincronizar; crear recordatorio → aviso programado |

`flutter analyze` sin advertencias y pruebas en verde son condición para cerrar cada entrega.

Rendimiento: listas con construcción perezosa, proveedores con `select` para reconstruir solo lo necesario, consultas acotadas a lo activo (el historial se pagina), miniaturas para imágenes, PDF cargados por página y animaciones que solo tocan opacidad y transformaciones.

---

## 6. Modelo de datos

### 6.1 Principios

1. **Una sola fuente por dato.** Una fecha de entrega vive en la actividad; el calendario la proyecta. Una nota vive en la actividad, la clase o el examen; el motor la lee de ahí.
2. **Colecciones planas bajo el usuario.** Las actividades no se anidan dentro de la asignatura: así «todo lo que vence esta semana» es una consulta simple. Cada documento lleva `subjectId`.
3. **Sin copias desnormalizadas.** El nombre y el color de la asignatura no se copian a las actividades: las asignaturas son pocas, están siempre en memoria y se cruzan en el cliente.
4. **Embebido lo que siempre se lee junto.** Las subtareas van dentro de la actividad; el esquema de evaluación, dentro de la asignatura.
5. **Vínculos en un solo lado.** Un documento o un apunte guarda a qué está asociado; el otro lado lo consulta. No hay dos listas que mantener iguales.

### 6.2 Estructura en Firestore

```
users/{uid}                        perfil y preferencias
├─ periods/{id}                    cuatrimestres y fechas clave
├─ subjects/{id}                   asignatura + esquema de evaluación embebido
├─ activities/{id}                 trabajos, test, lecturas, tareas personales (+ subtareas)
├─ classSessions/{id}              clases en vivo
├─ exams/{id}                      exámenes (+ temas)
├─ sprints/{id}                    mini sprints (+ elementos y retrospectiva)
├─ studyBlocks/{id}                bloques de estudio planificados
├─ studySessions/{id}              sesiones de estudio realizadas
├─ documents/{id}                  metadatos de archivos (el binario queda en el teléfono)
├─ notes/{id}                      apuntes
├─ certifications/{id}             certificaciones (+ módulos)
├─ events/{id}                     eventos que no son otra entidad
├─ goals/{id}                      objetivos académicos y de estudio
├─ days/{yyyy-MM-dd}               objetivos del día y cierre de jornada
├─ weeklyReviews/{yyyy-Www}        revisión semanal
└─ inbox/{id}                      centro de notificaciones
```

Campos comunes: `createdAt`, `updatedAt` (hora del servidor), `deletedAt` (papelera), `schemaVersion` (migraciones futuras).

### 6.3 Entidades principales

**subjects**: `name`, `description`, `teacher`, `periodId`, `startDate`, `endDate`, `status` (planned · active · finished), `color`, `targetGrade`, `grading` (esquema, §6.4).
El progreso y el promedio no se guardan: se calculan.

**activities**

| Campo | Notas |
|---|---|
| `title`, `description`, `notes` | |
| `subjectId` | Nulo en actividades personales |
| `type` | work · test · quiz · project · reading · research · delivery · personal |
| `status` | backlog (Pendiente) · next (Próximamente) · inProgress · inReview · done (Finalizada) |
| `dueAt`, `dueTz` | Instante UTC y zona en la que se definió (`Europe/Madrid` para UNIR) |
| `targetAt` | Fecha objetivo personal (colchón) |
| `submittedAt` | Fecha real de entrega: es lo que significa «entregada» |
| `gradeComponentId`, `value`, `maxScore`, `score`, `gradedAt` | Vínculo con el esquema. `value` es el valor o peso; `score` nulo = sin calificar |
| `attempts` | Solo en test |
| `priority` | low · medium · high · urgent |
| `estimateMin` | El tiempo real no se guarda: es la suma de sus sesiones de estudio |
| `subtasks[]` | `{id, title, done, estimateMin, order}` |
| `sprintId`, `boardOrder` | Sprint activo y posición en la columna del Kanban |
| `reminders[]` | Avisos propios; si está vacío se aplican los predeterminados |

**Por qué «entregada» y «calificada» no son estados.** Tu lista (pendiente, en progreso, en revisión, completada, entregada) mezcla el flujo de trabajo con dos hechos que ocurren después. Si fueran estados, una actividad entregada y calificada no cabría en ninguno, y el Kanban tendría columnas distintas de los estados. Solución: `status` describe el flujo y coincide con las cinco columnas del Kanban; «Entregada» (`submittedAt`) y «Calificada» (`score`) son marcas que la tarjeta muestra como insignias. «Vencida» tampoco se guarda: se deduce de `dueAt` y `submittedAt`.

**Los test son actividades** de tipo `test` con intentos y resultado. Tienen fecha, estado y nota como cualquier otra, y así no hay dos lógicas de calificación.

**classSessions**: `subjectId`, `topic`, `startsAt`, `durationMin`, `attended` (nulo = aún no ocurre), `points`, `gradeComponentId`, `guideUrl`, `notes`.

**exams**: `subjectId`, `name`, `startsAt`, `windowEndsAt` (para exámenes en línea con varios días), `call` (ordinary · extraordinary), `targetScore`, `score`, `gradeComponentId`, `prepStatus`, `topics[]` (`{id, title, state: pending · studying · mastered, lastReviewedAt, nextReviewAt}`), `notes`.

**sprints**: `name`, `goal`, `startsAt`, `endsAt`, `status` (planned · active · finished · cancelled), `priority`, `items[]`, `retro` (`{achieved, blockers, improve}`).
Cada elemento es de uno de tres tipos: una actividad completa, una subtarea de una actividad o una tarea suelta del sprint. Los dos primeros son referencias: su estado se lee y se escribe en la actividad, así completar algo en el sprint lo completa en todas partes.

**studyBlocks** (planificado): `startsAt`, `endsAt`, `subjectId`, `ref` (actividad o examen), `title`.
**studySessions** (realizado): `startedAt`, `endedAt`, `focusMin`, `mode` (pomodoro · free), `subjectId`, `ref`, `blockId`, `sprintId`.
Las horas estudiadas, el tiempo por asignatura y el tiempo real de cada actividad salen de esta única colección.

**documents**: `name`, `mime`, `sizeBytes`, `sha256`, `category`, `subjectId`, `links[]` (por ejemplo `activity:abc`, `exam:xyz`), `favorite`, `lastOpenedAt`, `lastBackupAt`. La ruta local no se sincroniza: cada dispositivo comprueba si tiene el archivo.

**notes**: `title`, `content`, `plainText` (para buscar), `subjectId`, `tags[]`, `kind` (note · question), `pinned`, `links[]`, `revisions[]`. Las imágenes se guardan como documentos de la biblioteca; el apunte solo guarda la referencia.

**certifications**: `name`, `institution`, `description`, `url`, `startDate`, `targetDate`, `platformClosesAt`, `status` (pending · inProgress · paused · completed), `modules[]` (`{id, title, done}`), `completedAt`. El certificado final es un documento vinculado.

**events**: solo lo que no es otra entidad: eventos personales, llamadas de seguimiento, fechas clave sueltas.

**goals**: `type` (dailyStudy · weeklyStudy · subjectGrade · custom), `target`, `subjectId`, `from`, `to`.
**days**: `objectives[]` (`{title, done, ref}`), `closingNote`.

### 6.4 Esquema de evaluación

Vive en cada asignatura y es una lista de componentes. No hay nada fijo para todas.

```
grading:
  scaleMax: 10            escala de calificación
  passMark: 5             nota de aprobación
  confirmed: false        ¿lo validaste con la guía docente?
  components:
    - id, name
      mode: points | weighted
      weightPct           peso en la nota final
      pointsGoal          meta de puntos (5 en UNIR)
      attendancePoints    puntos por clase asistida (0,4 en UNIR)
      testPoints          puntos por test (0,1 en UNIR)
      pointsCap           tope de puntos que cuentan (opcional)
      minToPass           mínimo obligatorio en este componente (opcional)
      requiresMinOf       componente cuyo mínimo condiciona a este (opcional)
```

Dos modos de cálculo por componente:

- **Por puntos** (`points`): cada elemento aporta `value × score / maxScore` y el componente suma, con tope opcional. Es el mecanismo de la evaluación continua de UNIR: una actividad de valor 5 con 7,5 aporta 3,75.
- **Por promedio ponderado** (`weighted`): cada elemento pesa un porcentaje dentro del componente.

**Plantilla «UNIR»** que la app aplica al crear una asignatura, con las reglas que confirmaste: escala de 0 a 10 con decimales; «Evaluación continua» por puntos (40 %) con meta de 5 puntos; 0,4 puntos por clase asistida y 0,1 por test, ya rellenados y editables por si una asignatura usa otros valores; «Examen final» (60 %). Al registrar una clase como asistida o un test como hecho, sus puntos se suman solos. La conversión a nota final sigue provisional (§2.2).

Ejemplo con la plantilla: una actividad de valor 5 con 8,5 (4,25 puntos), dos clases (0,8) y tres test (0,3) dan 5,35 puntos: meta alcanzada.

**Qué calcula `GradeCalculator`**, siempre separando tres situaciones (calificado, entregado sin calificar, aún no realizado):

- Puntos acumulados y aporte de cada elemento.
- Puntos pendientes: lo que todavía puedes sumar.
- Nota máxima alcanzable y nota mínima asegurada.
- Promedio actual por componente y nota final estimada.
- Nota necesaria en un elemento, o repartida entre los pendientes, para alcanzar un objetivo; y si el objetivo sigue siendo posible.
- Cumplimiento de mínimos obligatorios.

**El simulador** llama a la misma función con una lista de notas hipotéticas que solo existe en memoria. No hay forma de que modifique las notas reales, porque nunca se escribe.

**Lo construido en la entrega 1.4.** El esquema implementado tiene dos partes fijas, evaluación continua por puntos y examen, con todos sus parámetros editables por asignatura (escala, meta, puntos por clase y por test, pesos). Cada actividad lleva su propio valor, así que trabajos, test, participación u otras actividades entran como elementos que suman puntos. No se construyó todavía el modo «promedio ponderado» ni componentes definidos por el usuario: ninguna de tus asignaturas los necesita y quedan para el simulador avanzado de la Fase 3. La app muestra puntos y no una nota final, porque la conversión sigue sin confirmar.

### 6.5 Calendario sin duplicados

`CalendarProjector` une estas fuentes en una lista de entradas, cada una con un enlace a su origen:

| Origen | Aparece como |
|---|---|
| `activities.dueAt` / `targetAt` | Entrega y fecha objetivo |
| `exams` | Examen, de un día o como ventana |
| `classSessions` | Clase |
| `studyBlocks` | Bloque de estudio |
| `sprints` | Franja con inicio y fin |
| `certifications.targetDate` | Fecha objetivo |
| `periods` | Fechas clave y franjas de fondo (repaso, no lectivo) |
| `events` | Evento |

Tocar una entrada abre la entidad original. Crear «algo» desde el calendario crea la entidad que corresponde.

### 6.6 Consultas, índices y costo

- Suscripciones permanentes: asignaturas activas, actividades no archivadas, exámenes y clases del periodo actual, y lo que cae en la ventana visible del calendario. El historial se pagina a demanda.
- Índices compuestos previstos: `activities (status, dueAt)`, `activities (subjectId, dueAt)`, `studySessions (subjectId, startedAt)`, `documents (subjectId, lastOpenedAt)`, y `links array-contains` en documentos y apuntes.
- Estadísticas y búsqueda se calculan sobre los datos ya cacheados: cero lecturas extra.
- Tamaño: un documento admite 1 MiB. Las subtareas y los temas embebidos están muy por debajo; los apuntes largos se controlan, y sus imágenes viven como archivos.
- Estimación de uso: unas decenas o pocos cientos de lecturas por sesión gracias a la caché, frente a una cuota gratuita de 50 000 lecturas y 20 000 escrituras al día.

---

## 7. Design System

Se construye antes que cualquier pantalla y vive en `core/design_system`. Ninguna pantalla define colores, tamaños ni duraciones propias: todo sale de los tokens. Una pantalla de catálogo, visible solo en modo desarrollo, muestra todos los componentes en ambos temas; es la forma de revisar el sistema sin navegar la app.

### 7.1 Tipografía: Inter

- Inter se **empaqueta en la app** como fuente variable (licencia OFL, libre). No se descarga en tiempo de ejecución: funciona sin conexión y se ve idéntica en Android e iOS.
- Cifras tabulares en estadísticas, temporizadores y notas, para que los números no «bailen» al animarse.
- Interletrado negativo en títulos grandes, como recomienda la propia Inter.

| Rol | Tamaño / interlínea | Peso | Uso |
|---|---|---|---|
| Display | 40 / 44 | 700 | Cifra protagonista (cuenta regresiva, nota) |
| Título 1 | 28 / 34 | 700 | Título de pantalla |
| Título 2 | 22 / 28 | 600 | Sección |
| Título 3 | 18 / 24 | 600 | Título de tarjeta |
| Cuerpo L | 16 / 24 | 400 | Lectura, apuntes |
| Cuerpo | 14 / 20 | 400 | Texto general |
| Etiqueta | 14 / 20 | 600 | Botones, pestañas |
| Detalle | 12 / 16 | 500 | Metadatos, fechas |
| Sobretítulo | 11 / 14 | 600 | Categorías, con interletrado amplio |

### 7.2 Color

Azul profundo como color principal, violeta como acento y neutros fríos. Los dos temas se diseñan por separado: el oscuro no es el claro invertido, usa superficies azul noche escalonadas y colores principales más luminosos.

| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| `canvas` | `#F6F7FB` | `#0B0E1A` | Fondo de la app |
| `surface` | `#FFFFFF` | `#131829` | Tarjetas |
| `surfaceRaised` | `#EEF0F7` | `#1A2036` | Campos, tarjetas anidadas |
| `outline` | `#E1E4EE` | `#262D47` | Bordes y divisores |
| `ink` | `#0F1429` | `#ECEEF8` | Texto principal |
| `inkSoft` | `#4A5170` | `#A9B0CC` | Texto secundario |
| `inkMuted` | `#626A8A` | `#858DAE` | Metadatos |
| `primary` | `#3347D6` | `#8C9BFF` | Acciones, progreso, selección |
| `primaryContainer` | `#E3E7FF` | `#232C66` | Fondos de énfasis |
| `accent` | `#7A4FE0` | `#B79CFF` | Acento violeta: logros, sprints |
| `accentContainer` | `#EEE6FF` | `#33265F` | |
| `success` | `#1E9E6A` | `#4CD3A0` | Completado, a tiempo |
| `warning` | `#C97A06` | `#F2B44C` | Próximo a vencer |
| `danger` | `#D9364F` | `#FF7088` | Vencido, error, eliminar |
| `info` | `#1B8FD6` | `#5CBBF5` | Informativo |

- **Degradado de marca** (`primary → accent`): solo en tres lugares, la tarjeta principal del dashboard, los anillos de progreso y la pantalla de acceso. En el resto, superficies planas.
- **Colores de asignatura:** ocho tonos elegidos para funcionar en ambos temas (índigo, violeta, cian, esmeralda, ámbar, coral, rosa, pizarra). Con cinco asignaturas en paralelo, el color es la forma más rápida de reconocerlas en calendario, Kanban y gráficos.
- **El color nunca es la única señal.** Prioridad y estado llevan siempre icono o texto.
- Todos los pares texto/fondo se verifican en AA con una prueba automática (§5.9). Los valores de esta tabla son el punto de partida y se ajustan si la prueba lo exige.

### 7.3 Espaciado, radios y elevación

- **Espaciado** en retícula de 4: 4, 8, 12, 16, 20, 24, 32, 40, 56. Margen lateral de pantalla 20; relleno de tarjeta 16 o 20.
- **Radios:** 8 (etiquetas), 12 (botones y campos), 16 (tarjetas), 24 (hojas inferiores y tarjeta principal), completo (píldoras).
- **Elevación en claro:** dos sombras suaves teñidas de azul (reposo y elevada), nunca negras puras.
- **Elevación en oscuro:** sin sombras; la profundidad se expresa con el escalón de superficie y un borde de 1 px.

### 7.4 Movimiento

Las duraciones y curvas son tokens, igual que los colores.

| Token | Duración | Uso |
|---|---|---|
| `instant` | 120 ms | Pulsación de botón, casilla |
| `quick` | 220 ms | Cambio de estado, aparición de elementos |
| `smooth` | 360 ms | Transición de pantalla, expandir y contraer |
| `expressive` | 600 ms | Trazado de gráficos, barras y anillos de progreso |
| `celebrate` | 900 ms | Completar un sprint, alcanzar un objetivo |

- Curvas: desaceleración suave para entradas, aceleración para salidas y muelle para arrastres y gestos.
- Las tarjetas de una lista aparecen escalonadas (40 ms entre cada una, máximo seis; el resto entra junto).
- Las cifras cambian contando, no saltando.
- **Reducir movimiento:** si el sistema lo pide, las transiciones pasan a fundidos cortos, sin desplazamientos ni celebraciones. Como todo pasa por los tokens, es un solo punto de control.
- Solo se animan opacidad y transformaciones, para sostener 60 fps en gama media.

### 7.5 Componentes

| Grupo | Componentes |
|---|---|
| Acciones | Botón (principal, secundario, texto, destructivo; con estado de carga), botón de icono, botón flotante de captura rápida |
| Contenedores | Tarjeta, tarjeta de estadística, tarjeta principal, hoja inferior, diálogo de confirmación |
| Datos | Anillo y barra de progreso, cuenta regresiva, etiqueta de prioridad, estado y asignatura, fila de lista, encabezado de sección |
| Formularios | Campo de texto, selector de fecha y hora con zona horaria, selector segmentado, interruptor, casilla, selector de asignatura |
| Navegación | Barra inferior, barra superior, pestañas |
| Estados | Esqueleto de carga, estado vacío, error con reintento, aviso breve, indicador de sincronización |

- **Carga:** esqueletos con la forma del contenido, no ruedas giratorias. Con la caché de Firestore se verán muy poco.
- **Vacío:** ilustración de línea sencilla, una frase y una acción («Registra tu primera asignatura»).
- **Error:** qué pasó y qué puedes hacer, junto al lugar donde ocurrió.
- **Iconos:** una sola familia de trazo (Lucide), 20 o 24 px.

### 7.6 Accesibilidad

Contraste AA; áreas táctiles de al menos 48 dp; la interfaz soporta el tamaño de texto del sistema sin recortes; etiquetas para lector de pantalla; alternativa sin arrastre para todo gesto (Kanban, reordenar); respeto de «reducir movimiento».

---

## 8. Navegación

### 8.1 Propuesta

Cinco pestañas, ordenadas por la pregunta que responden:

| Pestaña | Pregunta | Contiene |
|---|---|---|
| **Inicio** | ¿Cómo voy y qué hago hoy? | Dashboard, Mi día, resumen semanal |
| **Plan** | ¿Qué trabajo tengo? | Actividades en tres vistas: Lista, Kanban y Sprints |
| **Calendario** | ¿Cuándo? | Mes, semana y día; bloques de estudio |
| **Asignaturas** | ¿Cómo voy en cada materia? | Cada asignatura con su resumen, actividades, calificaciones y simulador, clases, exámenes, material y apuntes; historial de finalizadas |
| **Mi espacio** | Mis herramientas | Enfoque (Pomodoro), Biblioteca, Apuntes, Exámenes, Certificaciones, Estadísticas, Objetivos, Ajustes |

Siempre disponibles en la barra superior: **buscador global**, **centro de notificaciones** e **indicador de sincronización**. Un **botón de captura rápida** crea una actividad, un apunte, un documento o inicia una sesión de enfoque desde cualquier pestaña.

### 8.2 Por qué difiere de tu propuesta

Tu estructura tenía Biblioteca como pestaña y no tenía Asignaturas. La cambio por tres razones:

1. La asignatura es el eje de todo y las calificaciones no tenían un lugar propio. Con cinco materias en paralelo, «¿cómo voy en esta?» es una pregunta diaria.
2. La Biblioteca sigue a un toque desde tres sitios: la pestaña Material de cada asignatura (donde normalmente buscarás un PDF), Mi espacio y el buscador. Los documentos recientes aparecen también en Inicio.
3. Kanban y Sprints son formas de ver las mismas actividades, por eso viven juntas en Plan y no en menús separados.

Si en el uso real abres la Biblioteca más que las Asignaturas, intercambiarlas es un cambio de configuración del router, no de arquitectura (D2).

### 8.3 Reglas

- Cada pestaña conserva su posición y su historial al cambiar a otra.
- Crear y editar se hace en hojas inferiores o pantallas completas con cierre claro, sin perder el contexto.
- Las notificaciones abren directamente el elemento al que se refieren.
- Máximo tres niveles de profundidad desde una pestaña.

---

## 9. Módulos y relaciones

| Módulo | Datos propios | Lee de | Reglas clave |
|---|---|---|---|
| Asignaturas | `subjects`, `periods` | — | El progreso y el promedio se calculan |
| Actividades | `activities` | Asignaturas | Estado del flujo separado de entregada y calificada; el progreso sale de las subtareas |
| Calificaciones | Esquema en `subjects` | Actividades, clases, exámenes | Motor puro; el simulador nunca escribe |
| Clases y test | `classSessions` (los test son actividades) | Asignaturas | Solo cuentan para la nota si están vinculados a un componente |
| Calendario | `studyBlocks`, `events` | Todo lo que tiene fecha | Es una proyección |
| Biblioteca | `documents` + archivos en el teléfono | Todo, por vínculos | Respaldo y restauración; papelera |
| Dashboard y Mi día | `days` | Todo | No guarda datos académicos; ordena con `DayPlanner` |
| Kanban | — | Actividades | Mover una tarjeta cambia `status` y `boardOrder` |
| Sprints | `sprints` | Actividades | Los elementos referencian actividades y subtareas |
| Enfoque | `studySessions` | Asignaturas, actividades, exámenes | El temporizador se basa en la hora de fin |
| Exámenes | `exams` | Asignaturas, documentos, sesiones | Cuenta regresiva; temas con repaso espaciado |
| Apuntes | `notes` | Asignaturas, por vínculos | Autoguardado; versiones |
| Certificaciones | `certifications` | Documentos | |
| Notificaciones | `inbox`, preferencias | Todo lo que tiene fecha | `ReminderPlanner` |
| Estadísticas | `weeklyReviews` | Todo | Calculadas en el cliente |
| Buscador | — | Todo | Índice en memoria |
| Ajustes | `users/{uid}` | — | Tema, avisos, metas, horarios, vista inicial |

**Criterio de «módulo terminado».** Un módulo no está hecho porque exista su pantalla. Lo está cuando tiene: persistencia real con funcionamiento sin conexión; validaciones; estados de carga, vacío y error; edición y eliminación con papelera; pruebas de su lógica; y revisión visual en ambos temas contra el Design System.

---

## 10. Plan por fases

Cada fase se divide en entregas cortas que terminan en algo que puedes usar en tu teléfono, con el mismo principio que los sprints del seminario.

### Fase 1 — Fundamentos y primera versión útil

| Entrega | Contenido | Al terminar puedes |
|---|---|---|
| 1.0 Cimientos | Repositorio propio, proyecto de Firebase y emuladores, estructura de capas, autenticación, firma de la app, análisis y pruebas en marcha | Entrar a la app con tu cuenta |
| 1.1 Design System | Tokens, temas claro y oscuro, Inter, componentes base, catálogo, navegación con las cinco pestañas | Ver y aprobar la identidad visual completa |
| 1.2 Asignaturas | Periodos, asignaturas, detalle, historial | Registrar tu cuatrimestre |
| 1.3 Actividades | Alta y edición, subtareas, estados, entrega en hora de España con colchón, vista de lista con filtros | Llevar todas tus entregas |
| 1.4 Calificaciones | Esquema por asignatura, plantilla UNIR, registro de clases y test que puntúan, marcador, simulador básico | Saber cuántos puntos llevas y cuánto necesitas |
| 1.5 Calendario | Proyección en mes, semana y día; bloques de estudio; fechas clave | Ver todo lo que viene |
| 1.6 Biblioteca | Archivos en el teléfono, visor de PDF, categorías, favoritos, recientes, papelera, respaldo y restauración en ZIP | Tener tus PDF en la app y una copia fuera de ella |
| 1.7 Dashboard y cierre | Dashboard real, Mi día básico, recordatorios de entregas, clases y exámenes, indicador de sincronización y de respaldo | Usarla como tu herramienta diaria |

**Cambios respecto a tu Fase 1**, todos para que «usable en mi día a día» sea verdad: entran los recordatorios básicos, el registro mínimo de clases (sin él no se pueden contar los puntos de asistencia), el simulador básico (no cuesta nada adicional: es la misma función) y el respaldo con restauración.

### Fase 2 — Organización y productividad

Kanban → mini sprints con retrospectiva → notificaciones completas con centro y configuración individual → enfoque y Pomodoro con historial → exámenes con temas y repaso espaciado → apuntes → certificaciones → Mi día completo con cierre de jornada → estadísticas base → compartir archivos desde Android.

Dos pruebas técnicas cortas al empezar: arrastre del Kanban en móvil y elección del editor de apuntes.

### Fase 3 — Experiencia avanzada

Simulador avanzado (escenarios guardados y comparación) · estadísticas detalladas y revisión semanal completa · personalización (orden del dashboard, vista inicial, horarios) · búsqueda dentro de los PDF · App Check y bloqueo con huella · plantilla de TFM · widget de Android (opcional) · pasada de rendimiento y de animaciones · primera compilación para iOS si tienes un Mac disponible.

### Fase 4 — Evolución inteligente

Solo cuando las fases anteriores estén estables. Cada función se presenta antes con su costo estimado y qué datos saldrían del teléfono: planificador inteligente, preguntas de repaso generadas desde tus apuntes, resumen de documentos, búsqueda semántica y análisis de hábitos. Varias de estas funciones dependen de servicios de pago (una API de IA, Cloud Functions). Como no quieres pagar por ningún servicio, en esta fase solo se construye lo que tenga una vía gratuita, por ejemplo el planificador y el análisis de hábitos, que son cálculo local; el resto se descarta o espera a que tú decidas otra cosa.

**Regla entre fases:** no se abre una fase con pruebas en rojo ni con errores conocidos de pérdida de datos o de cálculo de notas en la anterior.

---

## 11. Riesgos, dependencias y costos

### 11.1 Riesgos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Alcance grande para un proyecto personal (más de 15 módulos) | Módulos a medias | Entregas verticales con criterio de terminado; no se abre un módulo sin cerrar el anterior |
| Esquema de evaluación de UNIR sin confirmar | Nota final estimada incorrecta | Plantilla marcada como provisional; los puntos sí son fiables; se confirma con la guía docente |
| Pérdida de datos no sincronizados al desinstalar | Alta | Indicador permanente; firma con clave propia para actualizar sin desinstalar; exportación |
| Pérdida de la clave de firma | Habría que reinstalar | Copia de la clave fuera del repositorio |
| Los archivos viven solo en el teléfono | Perder el teléfono o desinstalar la app los borra | Respaldo en ZIP con recordatorio e indicador de archivos sin respaldar; restauración desde la Fase 1; los originales siguen en el campus |
| Avisos retrasados por el ahorro de batería del fabricante | Recordatorios tardíos | Alarmas exactas para lo crítico; guía para excluir la app; el dashboard siempre muestra lo urgente |
| Arrastre del Kanban en móvil | Experiencia torpe | Prueba técnica previa; alternativa «Mover a…» siempre presente |
| Cambios incompatibles en el editor de apuntes | Retrabajo | Prueba técnica; el contenido se guarda también como texto plano |
| Flutter 3.38.2 tiene un año | Paquetes recientes pueden exigir un SDK más nuevo | Actualizar antes de empezar (D5) |
| Dos SDK de Dart en el PATH | Errores confusos | Usar siempre `flutter pub` y `flutter test`, que traen su propio Dart |
| Dependencia de Firebase | Difícil de migrar | Repositorios abstractos; exportación en formato abierto |
| Superar la cuota gratuita de Firestore | Muy bajo: la sincronización se pausa hasta el día siguiente, sin cobro | El uso previsto queda muy por debajo; la app sigue funcionando con la caché local |

### 11.2 Dependencias previas a la entrega 1.0

- Aceptar las licencias de Android: `flutter doctor --android-licenses`.
- Un teléfono Android con depuración USB o un emulador.
- Crear el proyecto de Firebase con tu cuenta de Google y vincularlo (lo hacemos juntos; el inicio de sesión en la consola es tuyo).
- No hace falta tarjeta ni cuenta de facturación.
- iOS, más adelante: un Mac y la cuenta de desarrollador de Apple.

### 11.3 Costos

**Costo total: 0.** Todo el proyecto usa el plan gratuito Spark, que no pide tarjeta y por tanto no puede generar cobros. Cuotas consultadas en noviembre de 2026 en la documentación pública de Firebase.

| Concepto | Costo esperado | Detalle |
|---|---|---|
| Authentication | 0 | Gratis para inicio con Google |
| Firestore | 0 | Cuota gratuita: 1 GiB, 50 000 lecturas, 20 000 escrituras y 20 000 borrados al día. Tu uso estará muy por debajo |
| Archivos | 0 | Se guardan en el teléfono. Firebase Storage queda descartado porque exige el plan de pago desde el 3 de febrero de 2026 |
| Notificaciones locales | 0 | |
| Cloud Functions | No se usan | Exigen el plan de pago |
| Publicación | 0 | La app se instala directamente en tu teléfono; no hace falta Google Play (25 USD, pago único, solo si un día la publicas) |
| iOS | 99 USD al año | Solo si la llevas a un iPhone de forma permanente |
| IA (Fase 4) | 0 | Solo se construye lo que tenga vía gratuita |

Fuentes: [cambios de Cloud Storage para Firebase](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024) · [precios de Firebase](https://firebase.google.com/pricing) · [precios de Cloud Storage](https://cloud.google.com/storage/pricing) · [flutter_riverpod en pub.dev](https://pub.dev/packages/flutter_riverpod/changelog) · [archivo de versiones de Flutter](https://docs.flutter.dev/install/archive)

---

## 12. Estado actual del proyecto

Lo que encontré en `app maestria` el 16 nov 2026:

- Un esqueleto de Flutter llamado `master_pro` (Android, iOS y web) con `lib/app`, un tema generado a partir de un color semilla y una pantalla de inicio de muestra. Sirve como punto de partida; el tema se sustituye por el Design System.
- Idioma `es-CO` ya configurado.
- Identificador de Android `com.masterpro.master_pro`. Conviene decidir el definitivo antes de vincular Firebase, porque cambiarlo después obliga a registrar la app de nuevo.
- Flutter 3.38.2 con Dart 3.10; Firebase CLI 15.4 y FlutterFire CLI instalados; licencias de Android sin aceptar; sin Visual Studio (solo afecta a la versión de escritorio de Windows, que no es un objetivo).
- **Actualización tras la entrega 1.1:** Flutter quedó en 3.50.0 (Dart 3.14). Esa versión separa Material en el paquete `material_ui`, y el proyecto ya lo usa. Las versiones instaladas son `flutter_riverpod` 3.5 y `go_router` 18.1.
- **La carpeta no tiene repositorio propio:** está dentro de un repositorio Git cuya raíz es tu carpeta de usuario (`C:\Users\johan`). El primer paso de la entrega 1.0 es darle su propio repositorio.
- La web se mantiene solo como vista previa rápida de la interfaz durante el desarrollo. No es un objetivo de producto: ahí no funcionan igual los avisos locales ni los archivos.

**Siguiente paso.** D1 y D3 ya están resueltas. Con tu visto bueno a D2 y D4–D7 arranco la entrega 1.0 (cimientos) y la 1.1 (Design System con catálogo), que es la primera que podrás ver y corregir en pantalla.
