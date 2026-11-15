# TIRELUS · STARDUST CRUSADERS

App de automonitoreo de salud para astronautas — NASA Space Apps Challenge 2026 (Instituto Tecnológico de Tijuana).

- **UI:** Flutter en `app/`
- **Lógica:** Python en `app/python_app/`, embebido con serious_python; sirve una API local en `127.0.0.1:8765`
- **Base de datos:** PostgreSQL (esquema en `db/`). Servidor externo compartido en desarrollo; PostgreSQL interno en la nave en la versión final (ver [Base de datos](#base-de-datos))
- **Pruebas:** `pytest app/tests_py` (92 pruebas: motor de reglas, API, exportación, configuración y lectura de PostgreSQL) · `cd app; flutter test` (64 pruebas: semáforo, selector de entorno, contraste, tendencia, medición y SANS)

> La app no diagnostica. Todos los umbrales, salvo SANS, son supuestos de diseño. Los datos de la demo son sintéticos.

📋 **Plan de acción del hackathon** (fases, calendario, roles y riesgos): [`planning/PLAN.md`](planning/PLAN.md). Las tareas pendientes viven en la [matriz de abajo](#matriz-de-pendientes).

## Correr en desarrollo

```bash
cd app
python python_app/main.py                                   # servidor Python
flutter run -d windows --dart-define=TIRELUS_DEV_SERVER=true  # UI usando ese servidor
```

## Correr con Docker (PostgreSQL + API)

Requiere Docker Desktop abierto. Desde la raíz del repo:

```powershell
.\tirelus.ps1              # levanta PostgreSQL y la API, y verifica que la API lea de la base
.\tirelus.ps1 db -Lan      # solo PostgreSQL, visible en la red local (servidor compartido)
.\tirelus.ps1 verificar    # comprueba /health: data_source debe decir "db"
.\tirelus.ps1 datos        # (opcional) carga los datasets de referencia desde .\datosdb
.\tirelus.ps1 down         # detiene (conserva datos) · reset: detiene y borra los datos
```

Si PowerShell bloquea el script: `powershell -ExecutionPolicy Bypass -File .\tirelus.ps1`.

- La primera vez crea `.env` con una contraseña aleatoria (no se sube al repo; para compartir la base, pásala por un canal privado).
- `docker-compose.yml` corre `db/schema.sql`, `db/002_ojos.sql` y `db/003_demo.sql` al crear la base. `003_demo.sql` solo trae lo que ya está en `data.py` (sistólica D34–D47 y su línea base) para poder probar `data_source: db`.
- La API queda en `http://127.0.0.1:8765` y la base en `127.0.0.1:5432`, solo para este equipo. Con `-Lan` la base se abre a la red local; en ese caso abre el puerto 5432 en el firewall solo para red privada.
- La app Flutter no va en Docker: `cd app; flutter run -d windows --dart-define=TIRELUS_DEV_SERVER=true`.
- Variables nuevas del servidor: `TIRELUS_HOST` (por defecto `127.0.0.1`; la imagen usa `0.0.0.0` y compose publica el puerto solo en localhost).

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
- **Conexión opcional ya escrita** (`app/python_app/db.py` y `catalog.py`, driver `pg8000`): con `TIRELUS_DB_HOST` definido la API lee línea base, límites y series de la base; sin él, o si el servidor no responde, sigue con los datos de `data.py`. `GET /health` dice `data_source` (`db` o `ejemplo`).
- Variables: `TIRELUS_DB_HOST` (obligatoria), `TIRELUS_DB_PORT` (5432), `TIRELUS_DB_NAME` (tirelus), `TIRELUS_DB_USER` (postgres), `TIRELUS_DB_PASSWORD`, `TIRELUS_DB_TIMEOUT` (3 s) y `TIRELUS_ASTRONAUT_ID` (opcional).
- **Aún no se ha probado contra un servidor real** y la base no trae lecturas de la app. Ver [`db/AUDITORIA.md`](db/AUDITORIA.md) y la matriz de pendientes.

## Estado del MVP

| # | Punto | Estado |
|---|---|---|
| 1 | Panel con figura corporal y semáforo por sistema | ✅ Listo |
| 2 | Medición guiada contra la línea base | 🟡 Pantallas listas para todas las métricas; faltan datos de FC, sueño, ánimo y SANS |
| 3 | Tendencia con alerta por desviación sostenida | 🟡 Pantallas listas (alerta hacia arriba o hacia abajo); faltan datos |
| 4 | Resumen exportable para la conferencia médica | ✅ Se exporta en Markdown (portapapeles) |
| 5 | Selector ISS / Luna / Marte y modo autónomo | ✅ Listo |
| — | Extras: consola de base y EVA | ✅ Pantallas hechas |
| — | Datos compartidos en PostgreSQL | 🟡 Esquema y capa de lectura en la API listos (con respaldo); falta el servidor externo, cargar datos de la app y probar |
| — | Entrega (video, presentación, página con fuentes) | 🔴 Sin empezar |

## Matriz de pendientes

Prioridad: **P0** = sin esto no hay demo · **P1** = importante para el MVP · **P2** = pulido si sobra tiempo.

| Prioridad | Qué falta | Cómo hacerlo | Esfuerzo |
|---|---|---|---|
| **P0** | Probar la app empaquetada en Windows | desde `app/`: `dart run serious_python:main package python_app -p Windows -r -r -r python_app/requirements.txt --cleanup` (detalles en la skill `tirelus-serious-python`), luego `flutter build windows`. Verificar que `/health` responda dentro de la app. Falta instalar Visual Studio con "Desarrollo para el escritorio con C++": hoy `flutter build windows` falla sin él (revisar con `flutter doctor`). | 1–2 h |
| **P2** | Android (recortado de la demo; se intenta al final si sobra tiempo) | `-p Android` en el mismo comando y `flutter build apk`. Si uvicorn falla, cambiar a Flask o `http.server` (ver skill `tirelus-serious-python`). Decidir también cómo llega el Python embebido al servidor y si hay caché local. | 2–3 h |
| **P0** | Levantar el servidor externo con PostgreSQL | Montar PostgreSQL en un servidor accesible para todo el equipo, correr `db/schema.sql`, `db/002_ojos.sql` y `db/load_datos.sql`, y compartir las credenciales por un canal privado (no en el repo). Solo datos sintéticos. | 1–2 h |
| **P0** | Probar la capa de PostgreSQL contra un servidor real | Hecho en código: `db.py` y `catalog.py` leen base, límites y series con respaldo a `data.py` (`tests_py/test_db_*.py`, `test_catalog.py`), pero solo se probaron con una conexión falsa. **Falta:** con el servidor arriba, definir `TIRELUS_DB_*`, correr `python python_app/main.py` y comprobar que `/health` dice `data_source: db` (las consultas SQL no se han ejecutado nunca). Además: instalar `pg8000` en el empaquetado de Windows. El servidor y el equipo están en la misma red (Ethernet por switch): usa la IP local del servidor como `TIRELUS_DB_HOST`. | 1–2 h |
| **P1** | Cargar datos de la app en la base | Hoy ningún `.sql` crea tripulante, línea base ni lecturas. Falta un script (p. ej. `db/003_demo.sql`) con los datos de ejemplo de `data.py` y los `>>> DATOS:`, cada uno marcado "Datos de ejemplo". Ver los huecos en [`db/AUDITORIA.md`](db/AUDITORIA.md) (incluye `heart_rate` `both` vs `above`). | 1–2 h |
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
