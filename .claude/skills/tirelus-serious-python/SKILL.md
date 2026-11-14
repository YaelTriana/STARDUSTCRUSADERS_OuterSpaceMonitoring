---
name: tirelus-serious-python
description: Cómo integrar la lógica en Python de TIRELUS dentro de la app Flutter con la librería serious_python (Flet). Úsala al escribir o mover código Python a app/python_app/, al empaquetar Python para Windows/Android, al conectar Flutter con el servidor Python local, o al elegir dependencias de Python para el dispositivo.
---

# Python embebido en Flutter con serious_python

Fuente: https://pub.dev/packages/serious_python (v6.1.3, publicador verificado flet.dev).

## Decisión del proyecto
- La lógica (motor de reglas, línea base, tendencias, datos de ejemplo) se escribe UNA vez en Python. **No se porta a Dart.**
- Flutter solo dibuja la interfaz y llama al Python embebido.
- serious_python incrusta el runtime de CPython (3.12, 3.13 o 3.14; por defecto 3.14) en la app y ejecuta el programa en segundo plano sin bloquear la UI.

## Estructura
```
app/                    ← raíz Flutter (pubspec.yaml)
  lib/                  ← UI en Dart
  python_app/           ← código Python que se empaqueta
    main.py             ← punto de entrada (servidor HTTP local)
    rules.py            ← motor de reglas (puro Python, con pruebas pytest)
    requirements.txt
  tests_py/             ← pytest (NO se empaqueta)
```

## Comunicación Dart ↔ Python
- Dart **no** llama funciones de Python directamente. Python expone una API y Flutter la consume: HTTP/REST (opción del proyecto), sockets, SQLite o archivos.
- El programa Python debe quedarse bloqueado para seguir vivo (por ejemplo, sirviendo HTTP).
- Servir solo en `127.0.0.1` y pasar el puerto desde Dart con `environmentVariables` (p. ej. `TIRELUS_PORT`).
- Antes de la primera llamada, Flutter hace *polling* a `GET /health` hasta que responda.

```dart
import 'package:serious_python/serious_python.dart';

SeriousPython.run(
  appFileName: 'main.py',               // por defecto ya es main.py
  environmentVariables: {'TIRELUS_PORT': '8765'},
  sync: false,                          // segundo plano: no bloquea la UI
);
```
(Parámetros según el README de la v6.1.3. Confirma la firma en la versión instalada antes de depender de ella.)

## Empaquetado (desde `app/`)
```powershell
$env:SERIOUS_PYTHON_VERSION = "3.12"
$env:SERIOUS_PYTHON_SITE_PACKAGES = "$PWD\build\site-packages"
$env:SERIOUS_PYTHON_APP = "$PWD\build\python_app"
dart run serious_python:main package python_app -p Windows -r -r -r python_app/requirements.txt --cleanup
flutter run -d windows
```
- `-p`: `Android`, `iOS`, `Darwin`, `Windows`, `Linux`, `Emscripten` (web).
- `SERIOUS_PYTHON_VERSION` debe estar puesto también durante `flutter build`/`flutter run`, para que coincidan el runtime y los paquetes.
- Si cambias la versión de Python: `flutter clean`.
- Desde Windows se puede compilar para Android, Windows y web (Linux vía WSL). iOS y macOS requieren una Mac.

## Reglas de dependencias
- Paquetes **puro Python** funcionan en todas las plataformas.
- Para Android/iOS solo hay binarios de lo que publica https://pypi.flet.dev (incluye numpy, pandas, scipy, scikit-learn, pydantic-core, matplotlib). **statsmodels NO está.**
- Prioridad: el motor de reglas en Python estándar (`statistics`, `dataclasses`). numpy solo si de verdad hace falta.
- Servidor: FastAPI + `uvicorn` sin extras (`uvicorn`, no `uvicorn[standard]`). Validar en Android en la primera hora; si falla, usar Flask (el ejemplo oficial) o `http.server` de la biblioteca estándar.
- `neurokit2` solo para generar datos sintéticos en desarrollo, nunca dentro de la app.

## Restricciones
- El directorio de la app es de solo lectura: escribe datos en el directorio de trabajo (`<application-support>/data`), que es el *cwd* al arrancar.
- Web (Pyodide) no puede abrir un servidor HTTP: la demo con Python embebido se hace en **Windows o Android**.
- Android: `minSdk` 23 o mayor. iOS 15 o mayor.
- Si una lectura necesita una ruta de archivo de un paquete en Android, agrégalo a `SERIOUS_PYTHON_ANDROID_EXTRACT_PACKAGES`.
