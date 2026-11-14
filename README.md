# TIRELUS · STARDUST CRUSADERS

App de automonitoreo de salud para astronautas — NASA Space Apps Challenge 2026 (Instituto Tecnológico de Tijuana).

- **UI:** Flutter en `app/`
- **Lógica:** Python en `app/python_app/`, embebido con serious_python; sirve una API local en `127.0.0.1:8765`
- **Pruebas:** `pytest app/tests_py` (41 pruebas: motor de reglas, API, resumen persistente, métricas y SANS) · `cd app; flutter test` (45 pruebas: semáforo, selector de entorno y contraste)

> La app no diagnostica. Todos los umbrales, salvo SANS, son supuestos de diseño. Los datos de la demo son sintéticos.

📋 **Plan de acción del hackathon** (fases, calendario, roles y riesgos): [`planning/PLAN.md`](planning/PLAN.md). Las tareas pendientes viven en la [matriz de abajo](#matriz-de-pendientes).

## Correr en desarrollo

```bash
cd app
python python_app/main.py                                   # servidor Python
flutter run -d windows --dart-define=TIRELUS_DEV_SERVER=true  # UI usando ese servidor
```

## API local

| Ruta | Qué hace |
|---|---|
| `GET /metrics` | Catálogo de métricas y si ya tienen datos de ejemplo |
| `GET /trend/{metric}` · `POST /evaluate/{metric}` | Tendencia y lectura aislada de `systolic`, `heart_rate`, `sleep_hours`, `mood`. Sin datos → `sin_dato` |
| `GET /trend/sans` · `POST /evaluate/sans` | Cambio de grosor retiniano en µm (+20 atención, 55 crítico) con su fuente |
| `GET /summary` · `POST /summary` | Resumen para la conferencia médica, guardado en `summary.json` (`TIRELUS_DATA_DIR`, respaldo `~/.tirelus`) |
| `GET /dashboard`, `/environments`, `/autonomous`, `/habitat`, `/eva`, `/health` | Panel, entornos, modo autónomo, consola de base, EVA |

Los datos de ejemplo viven en `app/python_app/data.py`. Los lugares donde faltan series están marcados con `>>> DATOS:` y deben seguir la matriz de simulación.

## Estado del MVP

| # | Punto | Estado |
|---|---|---|
| 1 | Panel con figura corporal y semáforo por sistema | ✅ Listo |
| 2 | Medición guiada contra la línea base | 🟡 Pantalla solo de presión arterial; la API ya evalúa cualquier métrica y SANS |
| 3 | Tendencia con alerta por desviación sostenida | 🟡 Solo presión sistólica con datos; las demás métricas esperan sus series |
| 4 | Resumen exportable para la conferencia médica | 🟠 La lista se guarda entre reinicios; falta exportar |
| 5 | Selector ISS / Luna / Marte y modo autónomo | ✅ Listo |
| — | Extras: consola de base y EVA | ✅ Pantallas hechas |

## Matriz de pendientes

Prioridad: **P0** = sin esto no hay demo · **P1** = importante para el MVP · **P2** = pulido si sobra tiempo.

| Prioridad | Qué falta | Cómo hacerlo | Esfuerzo |
|---|---|---|---|
| **P0** | Probar la app empaquetada en Windows y Android | desde `app/`: `dart run serious_python:main package python_app -p Windows -r -r -r python_app/requirements.txt --cleanup` (y `-p Android`; detalles en la skill `tirelus-serious-python`), luego `flutter build windows` / `flutter build apk`. Verificar que `/health` responda dentro de la app. Requiere Visual Studio con "Desarrollo para el escritorio con C++" (hoy `flutter build windows` falla sin él; revisar con `flutter doctor`). Si uvicorn falla en Android, cambiar a Flask o `http.server` (ver skill `tirelus-serious-python`). | 2–4 h |
| **P0** | Exportar el resumen médico | Endpoint `GET /summary/export` en Python que devuelva texto/Markdown con fecha, día de misión y la etiqueta "Datos de ejemplo". En Flutter, botón "Exportar" en la pantalla de tendencia: copiar al portapapeles y compartir (`share_plus`). PDF solo si sobra tiempo. Prueba pytest del formato. | 1–2 h |
| ~~P1~~ ✅ | ~~Guardar el resumen entre reinicios~~ | Hecho: `summary.json` con escritura atómica en `TIRELUS_DATA_DIR` (respaldo `~/.tirelus`); un archivo dañado no tumba la API. | — |
| **P1** | Pasar la carpeta de datos desde Flutter | Agregar `path_provider` y enviar `TIRELUS_DATA_DIR = getApplicationSupportDirectory()` en `lib/python_starter_io.dart` (hay un TODO). Sin esto el resumen queda en `~/.tirelus`. | 20 min |
| 🟡 P1 | Medición y tendencia de SANS | Hecho en la API: `POST /evaluate/sans` y `GET /trend/sans`, con pruebas. **Falta:** serie de ejemplo (`SANS_SERIES`, `SANS_DAYS` en `data.py`), la referencia NASA exacta en `SANS_SOURCE` y la pantalla de medición en Flutter reutilizando `measurement_screen` / `trend_chart`. | 1–1.5 h |
| 🟡 P1 | Generalizar medición y tendencia a más sistemas | Hecho en la API: `/trend/{metric}`, `/evaluate/{metric}`, `/metrics` y catálogo `METRICS`; cliente Dart con `trend()` y `evaluate()`. **Falta:** línea base, límite de respaldo y serie de 14 días de FC, sueño y ánimo (marcados `>>> DATOS:`), y que las pantallas reciban la métrica como parámetro. | 1.5–2 h |
| **P1** | Alertar tendencias a la baja | Sueño y ánimo preocupan cuando bajan, pero `evaluate_trend` solo cuenta días sobre la base. Agregar un parámetro de dirección en `rules.py` con sus pruebas y usar `alert_when` del catálogo. | 45 min |
| ~~P2~~ ✅ | ~~Botón "Marte" cortado en pantallas angostas~~ | Hecho: `lib/widgets/env_selector.dart` usa botones segmentados en pantallas anchas y menú desplegable por debajo de 640 px. Probado a 360 px sin desbordes. | — |
| ~~P2~~ ✅ | ~~Pruebas de widgets en Flutter~~ | Hecho: `app/test/` con pruebas del semáforo (color + forma + palabra + lector de pantalla), del selector de entorno con un `TirelusApi` falso y de contraste de la paleta. | — |
| ~~P2~~ ✅ | ~~Revisar accesibilidad~~ | Hecho: todo el texto ≥ 4.5:1 sobre todos los fondos; bordes de controles subidos a ≥ 3:1 (`borderStrong` #5B6F9E); selector de entorno ≥ 44 px (botones y campos ya medían ≥ 44 px). `test/contrast_test.dart` lo verifica en cada corrida. | — |
