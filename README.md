# TIRELUS · STARDUST CRUSADERS

App de automonitoreo de salud para astronautas — NASA Space Apps Challenge 2026 (Instituto Tecnológico de Tijuana).

- **UI:** Flutter en `app/`
- **Lógica:** Python en `app/python_app/`, embebido con serious_python; sirve una API local en `127.0.0.1:8765`
- **Pruebas:** `pytest app/tests_py` (20 pruebas, motor de reglas y API) · `cd app; flutter test` (45 pruebas: semáforo, selector de entorno y contraste)

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
| 4 | Resumen exportable para la conferencia médica | 🟠 Se arma la lista, no se exporta |
| 5 | Selector ISS / Luna / Marte y modo autónomo | ✅ Listo |
| — | Extras: consola de base y EVA | ✅ Pantallas hechas |

## Matriz de pendientes

Prioridad: **P0** = sin esto no hay demo · **P1** = importante para el MVP · **P2** = pulido si sobra tiempo.

| Prioridad | Qué falta | Cómo hacerlo | Esfuerzo |
|---|---|---|---|
| **P0** | Probar la app empaquetada en Windows y Android | desde `app/`: `dart run serious_python:main package python_app -p Windows -r -r -r python_app/requirements.txt --cleanup` (y `-p Android`; detalles en la skill `tirelus-serious-python`), luego `flutter build windows` / `flutter build apk`. Verificar que `/health` responda dentro de la app. Si uvicorn falla en Android, cambiar a Flask o `http.server` (ver skill `tirelus-serious-python`). | 2–4 h |
| **P0** | Exportar el resumen médico | Endpoint `GET /summary/export` en Python que devuelva texto/Markdown con fecha, día de misión y la etiqueta "Datos de ejemplo". En Flutter, botón "Exportar" en la pantalla de tendencia: copiar al portapapeles y compartir (`share_plus`). PDF solo si sobra tiempo. Prueba pytest del formato. | 1–2 h |
| **P1** | Guardar el resumen entre reinicios | Hoy vive en la variable `_summary` y se pierde al cerrar. Guardarlo en un JSON en la carpeta de datos de la app (ruta vía variable de entorno desde Flutter). Sin diseñar base de datos todavía. | 45 min |
| **P1** | Medición y tendencia de SANS | La regla ya existe (`evaluate_sans`, +20 µm atención / 55 µm crítico, con pruebas). Falta `POST /evaluate/sans`, serie de ejemplo en `data.py` y reutilizar `measurement_screen` / `trend_chart` con el indicador de grosor retiniano. Es la única cifra publicada por NASA: citar la fuente. | 2 h |
| **P1** | Generalizar medición y tendencia a más sistemas | Cambiar `/trend/systolic` y `/evaluate/systolic` por `/trend/{metric}` y `/evaluate/{metric}` con un catálogo de métricas en `data.py` (frecuencia cardiaca, horas de sueño, ánimo). Pruebas por métrica. | 2–3 h |
| ~~P2~~ ✅ | ~~Botón "Marte" cortado en pantallas angostas~~ | Hecho: `lib/widgets/env_selector.dart` usa botones segmentados en pantallas anchas y menú desplegable por debajo de 640 px. Probado a 360 px sin desbordes. | — |
| ~~P2~~ ✅ | ~~Pruebas de widgets en Flutter~~ | Hecho: `app/test/` con pruebas del semáforo (color + forma + palabra + lector de pantalla), del selector de entorno con un `TirelusApi` falso y de contraste de la paleta. | — |
| ~~P2~~ ✅ | ~~Revisar accesibilidad~~ | Hecho: todo el texto ≥ 4.5:1 sobre todos los fondos; bordes de controles subidos a ≥ 3:1 (`borderStrong` #5B6F9E); selector de entorno ≥ 44 px (botones y campos ya medían ≥ 44 px). `test/contrast_test.dart` lo verifica en cada corrida. | — |
