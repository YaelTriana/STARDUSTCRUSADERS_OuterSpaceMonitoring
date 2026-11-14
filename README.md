# TIRELUS · STARDUST CRUSADERS

App de automonitoreo de salud para astronautas — NASA Space Apps Challenge 2026 (Instituto Tecnológico de Tijuana).

- **UI:** Flutter en `app/`
- **Lógica:** Python en `app/python_app/`, embebido con serious_python; sirve una API local en `127.0.0.1:8765`
- **Pruebas:** `pytest app/tests_py` (motor de reglas, API y exportación) · `cd app; flutter test` (45 pruebas: semáforo, selector de entorno y contraste)

> La app no diagnostica. Todos los umbrales, salvo SANS, son supuestos de diseño. Los datos de la demo son sintéticos.

📋 **Plan de acción del hackathon** (fases, calendario, roles y riesgos): [`planning/PLAN.md`](planning/PLAN.md). Las tareas pendientes viven en la [matriz de abajo](#matriz-de-pendientes).

## Correr en desarrollo

```bash
cd app
python python_app/main.py                                   # servidor Python
flutter run -d windows --dart-define=TIRELUS_DEV_SERVER=true  # UI usando ese servidor
```

## Estado del MVP

| # | Punto | Estado |
|---|---|---|
| 1 | Panel con figura corporal y semáforo por sistema | ✅ Listo |
| 2 | Medición guiada contra la línea base | 🟡 Solo presión arterial |
| 3 | Tendencia con alerta por desviación sostenida | 🟡 Solo presión sistólica |
| 4 | Resumen exportable para la conferencia médica | ✅ Se exporta en Markdown (portapapeles) |
| 5 | Selector ISS / Luna / Marte y modo autónomo | ✅ Listo |
| — | Extras: consola de base y EVA | ✅ Pantallas hechas |

## Matriz de pendientes

Prioridad: **P0** = sin esto no hay demo · **P1** = importante para el MVP · **P2** = pulido si sobra tiempo.

| Prioridad | Qué falta | Cómo hacerlo | Esfuerzo |
|---|---|---|---|
| **P0** | Probar la app empaquetada en Windows y Android | desde `app/`: `dart run serious_python:main package python_app -p Windows -r -r -r python_app/requirements.txt --cleanup` (y `-p Android`; detalles en la skill `tirelus-serious-python`), luego `flutter build windows` / `flutter build apk`. Verificar que `/health` responda dentro de la app. Falta instalar Visual Studio con "Desarrollo para el escritorio con C++": hoy `flutter build windows` falla sin él (revisar con `flutter doctor`). Si uvicorn falla en Android, cambiar a Flask o `http.server` (ver skill `tirelus-serious-python`). | 2–4 h |
| ~~P0~~ ✅ | ~~Exportar el resumen médico~~ | Hecho: `GET /summary/export` devuelve Markdown con fecha, día de misión y "Datos de ejemplo" (`tests_py/test_export.py`). Botón "Exportar resumen médico" en la pantalla de tendencia: copia al portapapeles. Compartir con `share_plus` y PDF quedan para después. | — |
| ~~P1~~ ✅ | ~~Guardar el resumen entre reinicios~~ | Hecho: se guarda en `summary.json`. | — |
| ~~P1~~ ✅ | ~~Pasar la carpeta de datos desde Flutter~~ | Hecho: `path_provider` manda `TIRELUS_DATA_DIR` con `getApplicationSupportDirectory()` (`lib/python_env.dart`, probado en `test/python_env_test.dart`). Si falla, Python usa su respaldo. | — |
| **P1** | Medición y tendencia de SANS | La API ya está (`POST /evaluate/sans`, `GET /trend/sans`). Falta: serie de ejemplo en `SANS_SERIES` y `SANS_DAYS` de `data.py`, la referencia NASA exacta en `SANS_SOURCE` y la pantalla en Flutter reutilizando `measurement_screen` / `trend_chart`. | 1–1.5 h |
| **P1** | Generalizar medición y tendencia a más sistemas | La API ya está (`/trend/{metric}`, `/evaluate/{metric}`, `/metrics`). Falta: línea base, límite de respaldo y serie de 14 días de FC, sueño y ánimo en `METRICS` de `data.py` (marcados `>>> DATOS:`), y que las pantallas reciban la métrica como parámetro. | 1.5–2 h |
| ~~P1~~ ✅ | ~~Alertar tendencias a la baja~~ | Hecho: `evaluate_trend` recibe `direction` ("above"/"below") y `absolute_low`; la API usa `alert_when` del catálogo y devuelve `consecutive_below` y `delta_from_low`. Pruebas en `test_rules.py` y `test_p1.py`. | — |
| ~~P2~~ ✅ | ~~Botón "Marte" cortado en pantallas angostas~~ | Hecho: `lib/widgets/env_selector.dart` usa botones segmentados en pantallas anchas y menú desplegable por debajo de 640 px. Probado a 360 px sin desbordes. | — |
| ~~P2~~ ✅ | ~~Pruebas de widgets en Flutter~~ | Hecho: `app/test/` con pruebas del semáforo (color + forma + palabra + lector de pantalla), del selector de entorno con un `TirelusApi` falso y de contraste de la paleta. | — |
| ~~P2~~ ✅ | ~~Revisar accesibilidad~~ | Hecho: todo el texto ≥ 4.5:1 sobre todos los fondos; bordes de controles subidos a ≥ 3:1 (`borderStrong` #5B6F9E); selector de entorno ≥ 44 px (botones y campos ya medían ≥ 44 px). `test/contrast_test.dart` lo verifica en cada corrida. | — |
