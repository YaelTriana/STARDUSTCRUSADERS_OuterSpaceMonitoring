# TIRELUS · STARDUST CRUSADERS

App de automonitoreo de salud para astronautas — NASA Space Apps Challenge 2026 (Instituto Tecnológico de Tijuana).

- **UI:** Flutter en `app/`
- **Lógica:** Python en `app/python_app/`, embebido con serious_python; sirve una API local en `127.0.0.1:8765`
- **Base de datos:** PostgreSQL (esquema en `db/`). Servidor externo compartido en desarrollo; PostgreSQL interno en la nave en la versión final (ver [Base de datos](#base-de-datos))
- **Pruebas:** `pytest app/tests_py` (56 pruebas: motor de reglas, API y exportación) · `cd app; flutter test` (64 pruebas: semáforo, selector de entorno, contraste, tendencia, medición y SANS)

> La app no diagnostica. Todos los umbrales, salvo SANS, son supuestos de diseño. Los datos de la demo son sintéticos.

📋 **Plan de acción del hackathon** (fases, calendario, roles y riesgos): [`planning/PLAN.md`](planning/PLAN.md). Las tareas pendientes viven en la [matriz de abajo](#matriz-de-pendientes).

## Correr en desarrollo

```bash
cd app
python python_app/main.py                                   # servidor Python
flutter run -d windows --dart-define=TIRELUS_DEV_SERVER=true  # UI usando ese servidor
```

## Base de datos

PostgreSQL. Los scripts viven en `db/`: `schema.sql` (esquema), `002_ojos.sql` (ojos/SANS) y `load_datos.sql` (carga de datos de ejemplo).

| Etapa | Dónde corre | Para qué |
|---|---|---|
| Desarrollo y hackathon | Servidor externo compartido | Que todo el equipo use los mismos datos |
| Versión final (concepto) | PostgreSQL interno en la nave | Funcionar sin Internet ni retraso de comunicación con la Tierra |

- La conexión se configura con variables de entorno (host, puerto, base, usuario y contraseña). Nunca se suben al repo.
- El mismo código debe servir para ambos servidores cambiando solo la configuración.
- Flutter no habla con la base: solo con la API local; la lógica sigue en el Python embebido.
- El servidor compartido solo guarda datos sintéticos ("Datos de ejemplo"). La privacidad médica aplica también en la base.
- **Aún no está conectada:** hoy la API local sirve los datos de `data.py`. Ver la matriz de pendientes.

## Estado del MVP

| # | Punto | Estado |
|---|---|---|
| 1 | Panel con figura corporal y semáforo por sistema | ✅ Listo |
| 2 | Medición guiada contra la línea base | 🟡 Pantallas listas para todas las métricas; faltan datos de FC, sueño, ánimo y SANS |
| 3 | Tendencia con alerta por desviación sostenida | 🟡 Pantallas listas (alerta hacia arriba o hacia abajo); faltan datos |
| 4 | Resumen exportable para la conferencia médica | ✅ Se exporta en Markdown (portapapeles) |
| 5 | Selector ISS / Luna / Marte y modo autónomo | ✅ Listo |
| — | Extras: consola de base y EVA | ✅ Pantallas hechas |
| — | Datos compartidos en PostgreSQL | 🔴 Esquema listo; falta el servidor externo y conectar la API |
| — | Entrega (video, presentación, página con fuentes) | 🔴 Sin empezar |

## Matriz de pendientes

Prioridad: **P0** = sin esto no hay demo · **P1** = importante para el MVP · **P2** = pulido si sobra tiempo.

| Prioridad | Qué falta | Cómo hacerlo | Esfuerzo |
|---|---|---|---|
| **P0** | Probar la app empaquetada en Windows y Android | desde `app/`: `dart run serious_python:main package python_app -p Windows -r -r -r python_app/requirements.txt --cleanup` (y `-p Android`; detalles en la skill `tirelus-serious-python`), luego `flutter build windows` / `flutter build apk`. Verificar que `/health` responda dentro de la app. Falta instalar Visual Studio con "Desarrollo para el escritorio con C++": hoy `flutter build windows` falla sin él (revisar con `flutter doctor`). Si uvicorn falla en Android, cambiar a Flask o `http.server` (ver skill `tirelus-serious-python`). | 2–4 h |
| **P0** | Levantar el servidor externo con PostgreSQL | Montar PostgreSQL en un servidor accesible para todo el equipo, correr `db/schema.sql`, `db/002_ojos.sql` y `db/load_datos.sql`, y compartir las credenciales por un canal privado (no en el repo). Solo datos sintéticos. | 1–2 h |
| **P0** | Conectar la API local con PostgreSQL | Leer la conexión de variables de entorno en Python, consultar métricas, series y resumen desde la base en lugar de `data.py`, con pruebas pytest. Decidir antes: cómo llega el Python embebido en Android al servidor y si hay caché local sin conexión. Si el servidor no responde, la app debe seguir con datos de ejemplo. | 3–5 h |
| **P1** | Datos de la base alineados con la app | Revisar que `load_datos.sql` y `002_ojos.sql` cubran FC, sueño, ánimo y SANS con las mismas unidades y rangos que `METRICS`, y que cada dato diga "Datos de ejemplo". | 1 h |
| **P1** | Entrega: video, presentación y página del proyecto | Guion del video, presentación y página con las fuentes citadas (NASA HRP, NTRS, CSA, ESA). Hoy es el 14 de nov: el hackathon va de hoy al 15. | 3–4 h |
| **P2** | PostgreSQL interno de la nave (concepto) | Para la versión final: documentar el despliegue local (sin Internet) y mostrarlo en la presentación. No hace falta implementarlo para la demo. | 1 h |
| ~~P0~~ ✅ | ~~Exportar el resumen médico~~ | Hecho: `GET /summary/export` devuelve Markdown con fecha, día de misión y "Datos de ejemplo" (`tests_py/test_export.py`). Botón "Exportar resumen médico" en la pantalla de tendencia: copia al portapapeles. Compartir con `share_plus` y PDF quedan para después. | — |
| ~~P1~~ ✅ | ~~Guardar el resumen entre reinicios~~ | Hecho: se guarda en `summary.json`. | — |
| ~~P1~~ ✅ | ~~Pasar la carpeta de datos desde Flutter~~ | Hecho: `path_provider` manda `TIRELUS_DATA_DIR` con `getApplicationSupportDirectory()` (`lib/python_env.dart`, probado en `test/python_env_test.dart`). Si falla, Python usa su respaldo. | — |
| **P1** | Medición y tendencia de SANS | Pantalla lista: pestaña "Ojos" (`lib/screens/sans_screen.dart`) evalúa el cambio de grosor con Python y muestra los umbrales +20/55 µm. **Falta solo:** serie de ejemplo en `SANS_SERIES` y `SANS_DAYS` de `data.py` y la referencia NASA exacta en `SANS_SOURCE`. | 15 min |
| **P1** | Generalizar medición y tendencia a más sistemas | Pantallas listas: medición y tendencia tienen selector de métrica y muestran "Sin dato" mientras falten datos. **Falta solo:** línea base, límite de respaldo y serie de 14 días de FC, sueño y ánimo en `METRICS` de `data.py` (marcados `>>> DATOS:`). Aparecen solas en la app. | 20–30 min |
| ~~P1~~ ✅ | ~~Alertar tendencias a la baja~~ | Hecho: `evaluate_trend` recibe `direction` ("above"/"below") y `absolute_low`; la API usa `alert_when` del catálogo y devuelve `consecutive_below` y `delta_from_low`. Pruebas en `test_rules.py` y `test_p1.py`. | — |
| ~~P2~~ ✅ | ~~Botón "Marte" cortado en pantallas angostas~~ | Hecho: `lib/widgets/env_selector.dart` usa botones segmentados en pantallas anchas y menú desplegable por debajo de 640 px. Probado a 360 px sin desbordes. | — |
| ~~P2~~ ✅ | ~~Pruebas de widgets en Flutter~~ | Hecho: `app/test/` con pruebas del semáforo (color + forma + palabra + lector de pantalla), del selector de entorno con un `TirelusApi` falso y de contraste de la paleta. | — |
| ~~P2~~ ✅ | ~~Revisar accesibilidad~~ | Hecho: todo el texto ≥ 4.5:1 sobre todos los fondos; bordes de controles subidos a ≥ 3:1 (`borderStrong` #5B6F9E); selector de entorno ≥ 44 px (botones y campos ya medían ≥ 44 px). `test/contrast_test.dart` lo verifica en cada corrida. | — |
