# TIRELUS · STARDUST CRUSADERS

App de automonitoreo de salud para astronautas — NASA Space Apps Challenge 2026 (Instituto Tecnológico de Tijuana).

- **UI:** Flutter en `app/`
- **Lógica:** Python en `app/python_app/`, embebido con serious_python; sirve una API local en `127.0.0.1:8765`
- **Base de datos:** PostgreSQL (esquema en `db/`). Servidor externo compartido en desarrollo; PostgreSQL interno en la nave en la versión final (ver [Base de datos](#base-de-datos))
- **Pruebas:** `pytest app/tests_py` (127 pruebas: motor de reglas, API, rangos válidos, exportación, configuración, TLS y lectura de PostgreSQL) · `cd app; flutter test` (68 pruebas: cliente de la API, semáforo, selector de entorno, contraste, tendencia, medición y SANS)

> La app no diagnostica. Todos los umbrales, salvo SANS, son supuestos de diseño. Los datos de la demo son sintéticos.

📋 **Plan de acción del hackathon** (fases, calendario, roles y riesgos): [`planning/PLAN.md`](planning/PLAN.md). Las tareas pendientes viven en la [matriz de abajo](#matriz-de-pendientes).

## Correr en desarrollo

```bash
cd app
python python_app/main.py                                   # servidor Python
flutter run -d windows --dart-define=TIRELUS_DEV_SERVER=true  # UI usando ese servidor
```

## Correr con Docker (PostgreSQL + API)

> ⚠️ **Descartado (14 nov):** Docker no se usa en la demo. `docker/Dockerfile.api`, `docker-compose.yml` y `tirelus.ps1` quedan en el repo **sin haberse ejecutado nunca**; si algún día se retoman, hay que probarlos primero. La demo corre en modo desarrollo (ver arriba).

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
- Variables: `TIRELUS_DB_HOST` (obligatoria), `TIRELUS_DB_PORT` (5432), `TIRELUS_DB_NAME` (tirelus), `TIRELUS_DB_USER` (postgres), `TIRELUS_DB_PASSWORD`, `TIRELUS_DB_TIMEOUT` (3 s), `TIRELUS_DB_SSL` (`off` por defecto; `require` cifra sin verificar el certificado; `verify` cifra y verifica, con `TIRELUS_DB_SSL_CA` opcional) y `TIRELUS_ASTRONAUT_ID` (opcional).
- **Probado el 14 nov contra el servidor del equipo** (PostgreSQL 18.7, red local 192.168.10.0/24, usuario sin permisos de DDL): `/health` dice `data_source: db` y la sistólica sale de la base. Las credenciales no están en el repo. La base solo trae la sistólica de ejemplo (`db/003_demo.sql`); faltan FC, sueño, ánimo y SANS. Ver [`db/AUDITORIA.md`](db/AUDITORIA.md) y la matriz de pendientes.

### Conectar tu app al servidor del equipo

Estar en la red del router (192.168.10.0/24). Comprueba con `Test-NetConnection 192.168.10.2 -Port 5432` (debe decir `True`). Las variables solo se definen en tu terminal; la contraseña te la pasa el equipo por un canal privado:

```powershell
cd app
$env:TIRELUS_DB_HOST = "192.168.10.2"
$env:TIRELUS_DB_USER = "tirelus_equipo"
$env:TIRELUS_DB_PASSWORD = "<contraseña del equipo>"
$env:TIRELUS_ASTRONAUT_ID = "00000000-0000-4000-8000-000000000001"   # tripulante de ejemplo
python python_app/main.py
# en otra terminal: curl http://127.0.0.1:8765/health   -> data_source: "db"
```

### Estructura de `db/` y `docker/`

| Archivo | Qué es |
|---|---|
| `db/schema.sql`, `db/002_ojos.sql` | Esquema (requieren administrador) |
| `db/003_demo.sql` | Solo INSERT, repetible: tripulante "Tripulante A (Datos de ejemplo)", línea base y 14 lecturas de sistólica |
| `db/load_datos.sql` | Datasets de referencia; lee de `datosdb/` |
| `db/AUDITORIA.md` | Comparación del esquema contra `data.py` y huecos conocidos |
| `docker/Dockerfile.api`, `docker-compose.yml`, `.env.example` | Imagen de la API y PostgreSQL local (sin probar) |

`datosdb/` (~117 MB) **no está en el repo**: pídela al equipo si necesitas `load_datos.sql` o `.\tirelus.ps1 datos`.

### Prueba de estabilidad (14 nov, servidor del equipo)

Hecha con un tripulante de prueba que se borró al terminar (la base quedó con 1 tripulante, 1 línea base y 14 lecturas):

| Prueba | Resultado |
|---|---|
| Permisos | Usuario sin superusuario, sin CREATE ni TRUNCATE; `ref` solo lectura |
| Latencia | Conectar p50 63 ms · lectura completa de `db.py` p50 9 ms |
| Escrituras | 1000 INSERT en 1.6 s; el mismo `client_id` dos veces deja 1 fila |
| Integridad | 11 de 11 casos (duplicados, claves foráneas, enum, NOT NULL, CHECK, permisos) rechazados con el código esperado |
| Inyección SQL | 3 entradas maliciosas tratadas como datos; ninguna tabla afectada |
| Concurrencia | 8 hilos, 800 INSERT y 160 lecturas en 0.6 s, sin errores |
| API | Con caché de 30 s p50 3.4 ms; sin caché p50 101 ms; 0 respuestas incorrectas |
| Servidor caído | La API cae a `ejemplo` en 0.1–2 s con la sistólica completa |

**Hallazgos:** la base **acepta valores fuera de rango** (una sistólica de 9999 mmHg entró aunque `valid_max` es 260); **ya se valida en la API** (422) y el catálogo descarta esas lecturas de la base. El tráfico a PostgreSQL **va sin cifrar**: el cliente ya soporta TLS (`TIRELUS_DB_SSL`), pero el servidor tiene `ssl = off` (aceptable solo con datos sintéticos en la LAN privada). Con el servidor inalcanzable una petición espera el timeout (2–3 s) cada 30 s.

### Seguridad

- Credenciales solo en variables de entorno o en `.env` (ignorado por git). Nunca en el repo ni en el chat; si la contraseña se compartió por un medio inseguro, rotarla después de la demo.
- El servidor compartido guarda solo datos sintéticos. Los datos médicos reales solo los ven el tripulante, el CMO y el flight surgeon (regla de `CLAUDE.md`); la base aún no tiene roles ni RLS.
- Sistema de usuarios: **pendiente de decidir** (selección de perfil con rol para la demo o login real).

## Estado del MVP

| # | Punto | Estado |
|---|---|---|
| 1 | Panel con figura corporal y semáforo por sistema | ✅ Listo |
| 2 | Medición guiada contra la línea base | 🟡 Pantallas listas para todas las métricas; faltan datos de FC, sueño, ánimo y SANS |
| 3 | Tendencia con alerta por desviación sostenida | 🟡 Pantallas listas (alerta hacia arriba o hacia abajo); faltan datos |
| 4 | Resumen exportable para la conferencia médica | ✅ Se exporta en Markdown (portapapeles) |
| 5 | Selector ISS / Luna / Marte y modo autónomo | ✅ Listo |
| — | Extras: consola de base y EVA | ✅ Pantallas hechas |
| — | Datos compartidos en PostgreSQL | 🟡 Servidor del equipo funcionando y API leyendo de él (probado). El poblado completo ya está en `db/004_populate.sql` (30 tripulantes, 21 indicadores); falta confirmar que se cargó en el servidor |
| — | Entrega (video, presentación, página con fuentes) | 🔴 Sin empezar |

## Matriz de pendientes

Prioridad: **P0** = sin esto no hay demo · **P1** = importante para el MVP · **P2** = pulido si sobra tiempo. Primero lo que falta; lo hecho y lo descartado está más abajo.

### Falta

#### Base de datos

##### Servidor · Francisco (db)

| Prioridad | Qué falta | Detalle / cómo hacerlo | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P2** | Activar TLS en el servidor PostgreSQL | El cliente ya soporta `TIRELUS_DB_SSL=require\|verify` (`tests_py/test_db_tls.py`), pero **el servidor responde `ssl = off`** y rechaza el cifrado ("Server refuses SSL"). Lo hace quien administra el servidor: certificado, `ssl = on` y regla `hostssl` en `pg_hba.conf`. Solo importa si algún día hay datos reales. | Administrador del servidor | 30 min |
| **P2** | Rotar la contraseña del servidor después de la demo | La contraseña del usuario `tirelus_equipo` se compartió por chat. Cambiarla al terminar y avisar al equipo por un canal privado. | Administrador del servidor | 5 min |
| **P2** | PostgreSQL interno de la nave (concepto) | Para la versión final: documentar el despliegue local (sin Internet) y mostrarlo en la presentación. No hace falta implementarlo para la demo. | — | 1 h |

##### Datos · Prina y Angel

Fuente única de los datos sintéticos: el repo [`SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring`](https://github.com/MerelyMeredith/SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring) (genera `dataset.csv`, 68 columnas; Angel elabora el dataset). El CSV no se versiona aquí: va en `db/datosdb/`.

| Prioridad | Qué falta | Detalle / cómo hacerlo | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Cargar el poblado completo en el servidor y verificarlo | 🟡 A medias. El SQL ya existe en `main`: `db/004_populate.sql` (30 903 mediciones, 30 tripulantes, 21 indicadores; `mood` derivado del estrés, SANS como cambio de RNFL), generado por `db/generate_populate_sql.py`. **Falta:** confirmar que se cargó en el servidor del equipo (`schema.sql` → `002_ojos.sql` → `004_populate.sql`), que `/health` diga `data_source: db`, que las pantallas dejen de decir "Sin dato" y que se vea "Datos de ejemplo". Ver [`db/AUDITORIA.md`](db/AUDITORIA.md). | Dataset de Angel | 30 min |
| **P1** | Citar el repo de datos y anotar cómo se generó el dataset | TIRELUS no cita el repo de datos en ningún archivo y `data.py` aún nombra `Claude outputs/TIRELUS_matriz_simulacion.xlsx` como origen. El repo documenta 30 × 60 = 1800 filas y el poblado usa 3000 (30 × 100): anotar commit y parámetros. | Dataset de Angel | 15 min |
| **P2** | Umbrales de respaldo que faltan | `body_mass`, `hrv`, `macular_thickness`, `rnfl_thickness`, `cup_to_disc_ratio` y `near_vision_logmar` no tienen umbral. No se inventan: son supuestos de diseño que decide la persona de ciencia (`db/AUDITORIA.md` §5.1). | Criterio de la persona de ciencia | 30 min |

#### Decisiones

| Prioridad | Qué decidir | Detalle / contexto | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Decidir sistema de usuarios | Hoy no hay usuarios: la API lee un tripulante fijo (`TIRELUS_ASTRONAUT_ID` o el primero de la base). Opciones: selección de perfil con rol (astronauta, CMO, flight surgeon) para la demo, o login real. Recomendado para la demo: selección de perfil. La base tampoco tiene roles ni RLS. | Decisión del equipo | 1–2 h |
| **P1** | Decidir `heart_rate`: `above` o `both` | En la base `heart_rate` alerta en ambos sentidos (`both`); en la app solo hacia arriba (`evaluate_trend` acepta `above` o `below`). Lo mismo pasa con `respiratory_rate`, `temperature`, `intraocular_pressure`, `rnfl_thickness` y `cup_to_disc_ratio`. Hoy no falla porque `db.py` no lee `alert_when` de la base. Hay que elegir una fuente de verdad para los umbrales (base o `data.py`). Ver `db/AUDITORIA.md` §5.2. | Criterio de la persona de ciencia | 30 min |
| **P1** | Decidir qué hacer con `Claude outputs/` | Carpeta sin versionar con `TIRELUS_matriz_simulacion.xlsx`, que `data.py` cita como origen de las series. Como la fuente de datos ya es el repo de datos sintéticos, lo recomendado es cambiar la referencia y no subir la carpeta. | — | 5 min |

#### Backend · Angel

| Prioridad | Qué falta | Detalle / cómo hacerlo | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Generalizar medición y tendencia a FC, sueño y ánimo | Las pantallas ya tienen selector de métrica y muestran "Sin dato" mientras falten datos. Con la base cargada los datos llegan por `db.py`. **Falta solo** el respaldo sin base, en `METRICS` de `data.py`: línea base, límite de respaldo (supuesto de diseño) y serie de 14 días por métrica, tomados del dataset. | Dataset de Angel | 20–30 min |
| **P1** | Medición y tendencia de SANS | Pestaña "Ojos" (`lib/screens/sans_screen.dart`) ya evalúa el cambio de grosor con Python y muestra los umbrales +20/55 µm. **Falta solo:** serie de ejemplo en `SANS_SERIES` y `SANS_DAYS` de `data.py` (del dataset, como cambio de RNFL) y la referencia NASA exacta de los umbrales en `SANS_SOURCE` (hoy dice "por confirmar"). | Datos y referencia NASA | 15 min |
| **P2** | Android (recortado de la demo; se intenta al final) | `-p Android` en el comando de empaquetado y `flutter build apk`. Si uvicorn falla, cambiar a Flask o `http.server` (ver skill `tirelus-serious-python`). Decidir también cómo llega el Python embebido al servidor y si hay caché local. Va después de resolver el empaquetado, que está descartado para la demo. | Empaquetado | 2–3 h |

#### Front · Jenny

Sin pendientes: `frontend/jen-trabajo` se fusionó en `main` el 15 nov (ver Hecho).

#### Ramas

| Prioridad | Qué falta | Detalle / cómo hacerlo | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P2** | Cerrar `AngelPrueba` y borrar ramas ya fusionadas | `AngelPrueba` (`fc979d5`) es otra capa de PostgreSQL, anterior a la que entró a `main`; choca en `db.py`, `main.py` y `db/003_demo.sql`. Ya fusionadas: `feat/p0-export`, `feat/p1-*`, `feat/p2-pulido`, `feat/docker`, `feat/db-acceso`, `feat/db-postgres`, `docs/planning`, `feat/flutter-mockup`, `chore/claude-setup`. | Confirmación de Angel | 10 min |

#### Entrega

| Prioridad | Qué falta | Detalle / cómo hacerlo | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Entrega: video, presentación y página del proyecto | Guion del video, presentación, texto del formulario y página con las fuentes citadas (NASA HRP, NTRS, CSA, ESA). El hackathon va del 14 al 15 de nov. Ya hay un prompt listo para producirlo en otra cuenta de Claude; falta revisar los requisitos de entrega vigentes de Space Apps 2026 (duración del video, límites de texto) y preparar capturas de la app. | Capturas de la app, nombres del equipo | 3–4 h |

### Hecho

| Prioridad | Qué | Resultado |
|---|---|---|
| ~~P1~~ ✅ | ~~Fusionar `frontend/jen-trabajo` en `main`~~ | Fusionado el 15 nov (`707c4c6`), sin conflictos: ES/EN con `flutter_localizations`, navegación adaptable, teclado numérico propio, tendencia con puntos tocables, aviso al CMO con deshacer, modo Autónomo con protocolo guiado, SANS localizado, texto mínimo de 13 px y áreas táctiles de 44 px, avisos cuando el motor no responde. `flutter test`: 88 pruebas pasan. |
| ~~P1~~ ✅ | ~~Validar rangos en la API~~ | `POST /evaluate/{metric}` y `/evaluate/sans` responden 422 fuera de `valid_range` (o con NaN/inf), y el catálogo descarta lecturas de la base fuera de rango. Pruebas en `tests_py/test_ranges.py` y `test/api_range_test.dart` (la app muestra "Sin dato" en vez de lanzar). |
| ~~P0~~ ✅ | ~~Levantar el servidor externo con PostgreSQL~~ | PostgreSQL 18.7 en la red local con un usuario de equipo sin permisos de DDL. Host y contraseña se comparten por un canal privado (no en el repo). Solo datos sintéticos. |
| ~~P0~~ ✅ | ~~Probar la capa de PostgreSQL contra un servidor real~~ | El 14 nov las consultas de `db.py` se ejecutaron contra el servidor y `/health` dijo `data_source: db`. Prueba de estabilidad, inyección y concurrencia en [Base de datos](#prueba-de-estabilidad-14-nov-servidor-del-equipo). |
| ~~P0~~ ✅ | ~~Exportar el resumen médico~~ | `GET /summary/export` devuelve Markdown con fecha, día de misión y "Datos de ejemplo" (`tests_py/test_export.py`). Botón "Exportar resumen médico" en la pantalla de tendencia: copia al portapapeles. Compartir con `share_plus` y PDF quedan para después. |
| ~~P1~~ ✅ | ~~Guardar el resumen entre reinicios~~ | Se guarda en `summary.json`. |
| ~~P1~~ ✅ | ~~Pasar la carpeta de datos desde Flutter~~ | `path_provider` manda `TIRELUS_DATA_DIR` con `getApplicationSupportDirectory()` (`lib/python_env.dart`, probado en `test/python_env_test.dart`). Si falla, Python usa su respaldo. |
| ~~P1~~ ✅ | ~~Alertar tendencias a la baja~~ | `evaluate_trend` recibe `direction` ("above"/"below") y `absolute_low`; la API usa `alert_when` del catálogo y devuelve `consecutive_below` y `delta_from_low`. Pruebas en `test_rules.py` y `test_p1.py`. |
| ~~P2~~ ✅ | ~~Botón "Marte" cortado en pantallas angostas~~ | `lib/widgets/env_selector.dart` usa botones segmentados en pantallas anchas y menú desplegable por debajo de 640 px. Probado a 360 px sin desbordes. |
| ~~P2~~ ✅ | ~~Pruebas de widgets en Flutter~~ | `app/test/` con pruebas del semáforo (color + forma + palabra + lector de pantalla), del selector de entorno con un `TirelusApi` falso y de contraste de la paleta. |
| ~~P2~~ ✅ | ~~Revisar accesibilidad~~ | Todo el texto ≥ 4.5:1 sobre todos los fondos; bordes de controles ≥ 3:1 (`borderStrong` #5B6F9E); selector de entorno ≥ 44 px. `test/contrast_test.dart` lo verifica en cada corrida. |

### Descartado

| Qué | Motivo |
|---|---|
| ~~Probar la app empaquetada en Windows~~ | Descartado el 14 nov. La demo corre en modo desarrollo: `python python_app/main.py` y `flutter run -d windows --dart-define=TIRELUS_DEV_SERVER=true`. Si se retoma: `dart run serious_python:main package python_app -p Windows -r -r -r python_app/requirements.txt --cleanup`, Visual Studio con C++ y `pg8000` en el empaquetado. |
| ~~Probar Docker (`tirelus.ps1`, imagen y compose)~~ | Descartado el 14 nov. Los archivos siguen en el repo, nunca se ejecutaron. |
