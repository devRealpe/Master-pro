# Master Pro

Aplicación móvil personal para gestionar la maestría: asignaturas, entregas, calificaciones, calendario, documentos y estudio. Flutter + Firebase (solo plan gratuito).

La propuesta completa de arquitectura, datos, diseño y fases está en [docs/propuesta-master-pro.md](docs/propuesta-master-pro.md). Léela antes de cambiar algo estructural.

## Estado

| Entrega | Estado |
|---|---|
| 1.0 Cimientos | Repositorio, estructura de capas, análisis, pruebas, proyecto de Firebase, reglas de seguridad e inicio de sesión con Google. **Pendiente:** desactivar el registro de cuentas nuevas en la consola, probar el acceso en un teléfono y firmar la app |
| 1.1 Design System | Tokens, temas claro y oscuro, Inter, componentes base, catálogo y navegación con cinco pestañas |
| 1.2 Asignaturas | Asignaturas (alta, edición, detalle, finalizar, papelera con deshacer), historial, periodos con fechas clave y calendario UNIR 2026–2027 «por confirmar». Probado con datos en memoria; **pendiente** verlo funcionando contra Firestore real |
| 1.3 en adelante | Sin empezar |

## Ejecutar

```bash
flutter pub get
```

```bash
flutter run
```

Vista previa rápida de la interfaz en el navegador (no es un objetivo de producto):

```bash
flutter run -d chrome
```

## Verificar

```bash
flutter analyze
```

```bash
flutter test
```

Ambos deben quedar en verde antes de cerrar una entrega.

Las reglas de seguridad de Firestore se prueban contra el emulador local (necesita Node y Java; no toca datos reales):

```bash
cd rules-test && npm install && npm test
```

## Firebase

- Proyecto `master-pro-l6nu9`, plan gratuito Spark, sin cuenta de facturación.
- Firestore en modo nativo, región `nam5`. Todo cuelga de `users/{uid}` y solo su dueño puede leerlo o escribirlo ([firestore.rules](firestore.rules)).
- Inicio de sesión con Google. La app habla con la sesión a través de `AuthRepository`; Firebase queda detrás, en `features/auth/data`.
- `lib/firebase_options.dart` y `android/app/google-services.json` los genera `flutterfire configure`. Son identificadores, no secretos. Si cambias algo en la consola (por ejemplo, activar un proveedor), vuelve a generarlos:

```bash
flutterfire configure --project=master-pro-l6nu9 --platforms=android,web --android-package-name=com.masterpro.master_pro --yes
```

- Publicar las reglas después de cambiarlas:

```bash
firebase deploy --only firestore:rules
```

## Estructura

```
lib/
├─ main.dart
├─ app/                    arranque, router y estructura de pestañas
├─ core/
│  ├─ design_system/       tokens, tema, componentes y catálogo
│  └─ settings/            preferencias del dispositivo
└─ features/<módulo>/      domain · data · presentation   (auth es el primero completo)

rules-test/                pruebas de firestore.rules con el emulador
test/support/              sesión y arranque en memoria para las pruebas
```

Reglas:

- Las pantallas importan `core/design_system/design_system.dart` y no definen colores, tamaños ni duraciones propias.
- El dominio no importa Flutter ni Firebase.
- Los datos se leen y escriben a través de `EntityRepository`. Las escrituras no se esperan en la interfaz (`guardWrite`): sin conexión quedan en cola y el cambio ya se ve en pantalla.
- Las fechas sin hora se guardan como `aaaa-mm-dd` (`core/time/dates.dart`); nunca se convierten entre zonas horarias.
- Material se importa desde `package:material_ui/material_ui.dart`. Desde Flutter 3.50, `package:flutter/material.dart` está obsoleto.

## Design System

El catálogo muestra todos los tokens y componentes en ambos temas. Solo existe en modo desarrollo: **Mi espacio → Design System**.

La tipografía es Inter, empaquetada en `assets/fonts` (licencia OFL, incluida junto a la fuente).

## Entorno de esta máquina

- Flutter 3.50.0 (Dart 3.14). Hay otro Dart más antiguo en el PATH del sistema: usa siempre `flutter pub`, `flutter test` y `flutter analyze`, que traen el suyo.
- Las apps de escritorio para Windows no están incluidas (falta Visual Studio con C++). No son un objetivo.
