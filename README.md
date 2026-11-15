# TIRELUS · STARDUST CRUSADERS

App de automonitoreo de salud para astronautas — NASA Space Apps Challenge 2026 (Instituto Tecnológico de Tijuana).

- **UI:** Flutter en `app/`
- **Lógica:** Python en `app/python_app/`, embebido con serious_python; sirve una API local en `127.0.0.1:8765`
- **Base de datos:** PostgreSQL (esquema en `db/`). Servidor externo compartido en desarrollo; PostgreSQL interno en la nave en la versión final (ver [Base de datos](#base-de-datos))
- **Pruebas:** `pytest app/tests_py` (168 pruebas: motor de reglas, panel calculado (los cinco sistemas), API, rangos válidos, exportación, configuración, TLS, lectura de PostgreSQL y carga de datos sintéticos) · `cd app; flutter test` (78 pruebas: cliente de la API, puerto, panel con refresco, semáforo, selector de entorno, contraste, tendencia, medición y SANS)

> La app no diagnostica. Todos los umbrales, salvo SANS, son supuestos de diseño. Los datos de la demo son sintéticos.

📋 **Plan de acción del hackathon** (fases, calendario, roles y riesgos): [`planning/PLAN.md`](planning/PLAN.md). Las tareas pendientes viven en la [matriz de abajo](#matriz-de-pendientes).

🔍 **Auditoría del MVP frente al reto** (14 nov: qué mejorar, en qué orden y qué recortar): [`planning/AUDITORIA.md`](planning/AUDITORIA.md).

🧪 **Simulación de datos en vivo** (qué del frontend cambia cuando cambia PostgreSQL, medido): [`planning/SIMULACION-TIEMPO-REAL.md`](planning/SIMULACION-TIEMPO-REAL.md) · herramienta: `tools/sim_tiempo_real.py`.

## Correr en desarrollo

```bash
cd app
python python_app/main.py                                   # servidor Python
flutter run -d windows --dart-define=TIRELUS_DEV_SERVER=true  # UI usando ese servidor
```

Banderas de compilación de la app (todas opcionales):

| Bandera | Para qué |
|---|---|
| `--dart-define=TIRELUS_DEV_SERVER=true` | la app no arranca el Python embebido: usa el servidor que ya corre |
| `--dart-define=TIRELUS_PORT=8766` | puerto de la API local (por defecto 8765), cuando el 8765 está ocupado |
| `--dart-define=TIRELUS_REFRESH_SECONDS=2` | cada cuánto el panel vuelve a preguntar por los datos (por defecto 5 s) |

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
- Variables: `TIRELUS_DB_HOST` (obligatoria), `TIRELUS_DB_PORT` (5432), `TIRELUS_DB_NAME` (tirelus), `TIRELUS_DB_USER` (postgres), `TIRELUS_DB_PASSWORD`, `TIRELUS_DB_TIMEOUT` (3 s), `TIRELUS_DB_TTL` (30 s: cada cuánto se relee la base; 2 s para ver los cambios en vivo en la demo), `TIRELUS_DB_SSL` (`off` por defecto; `require` cifra sin verificar el certificado; `verify` cifra y verifica, con `TIRELUS_DB_SSL_CA` opcional) y `TIRELUS_ASTRONAUT_ID` (opcional).
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

## Simulación de datos en tiempo real

Los signos vitales de la demo salen del generador del equipo
([SyntheticData_STARDUSTCRUSADERS](https://github.com/MerelyMeredith/SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring)),
que produce un CSV por tripulante con 68 variables y cascada causal. En el repo del generador:

```bash
python app/main.py generate --patients 4 --days 90     # 4 tripulantes, 360 filas
```

> Antes de generar, pon `blood_pressure_interval_days_min/max` en **1** dentro de
> `config/synthetic_data_config.json`: por defecto la presión llega cada 3–14 días ("cuff de clínica") y la
> regla de desviación sostenida necesita lecturas diarias. El examen retiniano sigue limitado a 1–2 por
> corrida (está escrito a mano en `generate.py`), así que la serie de SANS queda corta.

Y en este repo, `tools/sim_sinteticos.py` los traduce a los indicadores de `db/schema.sql` y los escribe en PostgreSQL:

```bash
export TIRELUS_DB_HOST=192.168.10.2 TIRELUS_DB_USER=tirelus_equipo TIRELUS_DB_PASSWORD=... TIRELUS_DB_TTL=2
app/.venv/bin/python tools/sim_sinteticos.py cargar --csv ~/Desktop/SyntheticData_*/output/patients
app/.venv/bin/python tools/sim_sinteticos.py vivo   --csv ... --cada 15   # un día de misión cada 15 s
app/.venv/bin/python tools/sim_sinteticos.py limpiar
```

- `cargar` crea la tripulación (el primero como CMO), calcula la **línea base personal con los primeros 14 días**
  (ventana prevuelo, media ± 2 desviaciones; `--desviaciones 1` la estrecha y hace aparecer más alertas) y
  escribe el historial. Imprime el `TIRELUS_ASTRONAUT_ID` de cada tripulante.
- `vivo` mete un día de misión cada N segundos: el panel avanza solo mientras se mira la app.
- Cada lectura lleva un `client_id` determinista (recargar no duplica) y la marca
  `note = 'Datos de ejemplo (sintéticos)'`; `limpiar` borra exactamente eso.
- **Supuestos de diseño del mapeo:** el ánimo (1–5) se deriva del estrés percibido invertido, porque el
  generador no trae autorreporte de ánimo; SANS es el **cambio** de `RNFL_Thickness_um` frente a la primera
  lectura, que es la definición de la app.

`tools/sim_tiempo_real.py` es la otra mitad: escenarios escritos a mano para empujar un sistema de nominal a
atención a crítico (`ciclo`, `vivo`, `panel`, `limpiar`), útil para grabar el video sin esperar a que los datos
sintéticos se desvíen. Lo medido en ambos casos está en
[`planning/SIMULACION-TIEMPO-REAL.md`](planning/SIMULACION-TIEMPO-REAL.md): con el TTL por defecto el panel
refleja un cambio de la base en ~30 s; con `TIRELUS_DB_TTL=2` y `TIRELUS_REFRESH_SECONDS=2`, en menos de 1 s.

## Estado del MVP

| # | Punto | Estado |
|---|---|---|
| 1 | Panel con figura corporal y semáforo por sistema | ✅ **Los cinco sistemas calculados** desde el catálogo y el motor de reglas (`python_app/panel.py`), con refresco automático. Ya no queda ninguna cifra escrita a mano en el panel |
| 2 | Medición guiada contra la línea base | 🟡 Pantallas listas; con los datos sintéticos cargados hay 6 métricas con línea base personal (sistólica, diastólica, FC, SpO₂, sueño y ánimo). Sin base de datos, `data.py` sigue con FC, sueño y ánimo vacíos |
| 3 | Tendencia con alerta por desviación sostenida | 🟡 Pantallas y regla listas (arriba o abajo); series de 14 días llegando de PostgreSQL. El eje de días todavía se calcula con `MISSION_DAY` fijo en `data.py` |
| 4 | Resumen exportable para la conferencia médica | ✅ Se exporta en Markdown (portapapeles) |
| 5 | Selector ISS / Luna / Marte y modo autónomo | ✅ Listo |
| — | Extras: consola de base y EVA | ✅ Pantallas hechas |
| — | Datos compartidos en PostgreSQL | ✅ Servidor del equipo funcionando, API leyendo de él y cargador de datos sintéticos probado (4 tripulantes, ~590 lecturas cada uno) |
| — | Simulación en tiempo real | ✅ `tools/sim_sinteticos.py` y `tools/sim_tiempo_real.py`; panel refrescándose solo |
| — | Entrega (video, presentación, página con fuentes) | 🔴 Sin empezar |

## Matriz de pendientes

Prioridad: **P0** = sin esto no hay demo · **P1** = importante para el MVP · **P2** = pulido si sobra tiempo. Primero lo que falta; lo hecho y lo descartado está más abajo.

### Falta

| Prioridad | Qué falta | Detalle / cómo hacerlo | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Guardar lo que captura el astronauta | No hay endpoint de escritura de lecturas: lo que se mide se evalúa y se tira, así que la alerta por desviación sostenida no puede nacer durante la demo. `measurements` ya está diseñada para esto (`client_id` idempotente). Ver A2 en [`planning/AUDITORIA.md`](planning/AUDITORIA.md). | — | 1–2 h |
| **P1** | Cerrar CORS por defecto | `main.py` monta `allow_origins=["*"]`: cualquier página abierta en ese equipo puede leer `/summary` y `/trend/*`. Montarlo solo con `TIRELUS_DEV_CORS`. Ver C en la auditoría. | — | 10 min |
| **P1** | Día de misión real | `/trend/{metric}` calcula el eje con `MISSION_DAY = 47` fijo y `lib/main.dart:194` imprime "DÍA DE MISIÓN 047" como texto literal: con datos de la base el día que muestra el gráfico no coincide. Ver A6 en la auditoría. | — | 30 min |
| **P2** | Examen retiniano periódico en el generador | `generate.py` programa el OCT con `{0}` y un segundo examen solo `if days >= 90` (80 y 90 escritos a mano, ignorando `retinal_exam_interval_days_*` del config). Sin eso, la serie de SANS se queda en 1–2 puntos. | Repo del generador | 30 min |
| **P1** | Entrega: video, presentación y página del proyecto | Guion del video, presentación, texto del formulario y página con las fuentes citadas (NASA HRP, NTRS, CSA, ESA). El hackathon va del 14 al 15 de nov. Ya hay un prompt listo para producirlo en otra cuenta de Claude; falta revisar los requisitos de entrega vigentes de Space Apps 2026 (duración del video, límites de texto) y preparar capturas de la app. | Capturas de la app, nombres del equipo | 3–4 h |
| **P1** | Cargar la tripulación sintética en el servidor del equipo | Ya probado contra un PostgreSQL local: `tools/sim_sinteticos.py cargar` mete tripulación, línea base y lecturas (sistólica, diastólica, FC, SpO₂, temperatura, respiratoria, HRV, sueño, masa corporal, ánimo). Falta correrlo contra `192.168.10.2` para que todo el equipo vea los mismos datos. **SANS sigue corto** por el límite del generador. | Generar los CSV y la contraseña del equipo | 20 min |
| **P2** | Valores de ejemplo en `data.py` (camino sin base de datos) | Con PostgreSQL cargado las pantallas ya muestran las 6 métricas. **Sin** base, `data.py` sigue con FC, sueño, ánimo, diastólica y SpO₂ vacíos (`>>> DATOS:`), así que la demo de respaldo diría "Sin dato". Se pueden copiar del CSV de un tripulante. | Un CSV del generador | 20 min |
| **P1** | Medición y tendencia de SANS | Pestaña "Ojos" (`lib/screens/sans_screen.dart`) ya evalúa el cambio de grosor con Python y muestra los umbrales +20/55 µm. **Falta solo:** serie de ejemplo en `SANS_SERIES` y `SANS_DAYS` de `data.py` y la referencia NASA exacta de los umbrales en `SANS_SOURCE` (hoy dice "por confirmar"). | Datos y referencia NASA | 15 min |
| **P1** | Decidir sistema de usuarios | Hoy no hay usuarios: la API lee un tripulante fijo (`TIRELUS_ASTRONAUT_ID` o el primero de la base). Opciones: selección de perfil con rol (astronauta, CMO, flight surgeon) para la demo, o login real. Recomendado para la demo: selección de perfil. La base tampoco tiene roles ni RLS. | Decisión del equipo | 1–2 h |
| **P1** | Decidir `heart_rate`: `above` o `both` | En la base `heart_rate` alerta en ambos sentidos (`both`); en la app solo hacia arriba (`evaluate_trend` acepta `above` o `below`). Hay que elegir una fuente de verdad para los umbrales (base o `data.py`). Ver `db/AUDITORIA.md`. | Criterio de la persona de ciencia | 30 min |
| **P1** | Decidir qué hacer con `Claude outputs/` | Carpeta sin versionar con `TIRELUS_matriz_simulacion.xlsx`, que `data.py` cita como origen de las series. O se sube al repo o se cambia la referencia. | — | 5 min |
| **P2** | Activar TLS en el servidor PostgreSQL | El cliente ya soporta `TIRELUS_DB_SSL=require\|verify` (`tests_py/test_db_tls.py`), pero **el servidor responde `ssl = off`** y rechaza el cifrado ("Server refuses SSL"). Lo hace quien administra el servidor: certificado, `ssl = on` y regla `hostssl` en `pg_hba.conf`. Solo importa si algún día hay datos reales. | Administrador del servidor | 30 min |
| **P2** | Rotar la contraseña del servidor después de la demo | La contraseña del usuario `tirelus_equipo` se compartió por chat. Cambiarla al terminar y avisar al equipo por un canal privado. | Administrador del servidor | 5 min |
| **P2** | Android (recortado de la demo; se intenta al final) | `-p Android` en el comando de empaquetado y `flutter build apk`. Si uvicorn falla, cambiar a Flask o `http.server` (ver skill `tirelus-serious-python`). Decidir también cómo llega el Python embebido al servidor y si hay caché local. Va después de resolver el empaquetado, que está descartado para la demo. | Empaquetado | 2–3 h |
| **P2** | PostgreSQL interno de la nave (concepto) | Para la versión final: documentar el despliegue local (sin Internet) y mostrarlo en la presentación. No hace falta implementarlo para la demo. | — | 1 h |

### Hecho

| Prioridad | Qué | Resultado |
|---|---|---|
| ~~P1~~ ✅ | ~~Panel calculado por el motor de reglas (los cinco sistemas)~~ | **Ojos** lleva el azulejo de SANS con los umbrales publicados (+20 / 55 µm, regla propia `evaluate_sans`) más los cinco indicadores de `002_ojos.sql`; **hueso** la masa corporal; **mente** sueño, ánimo y PVT; **inmune** la temperatura. `data.SYSTEMS` se quedó solo con el texto educativo y `_ind` desapareció. |
| ~~P1~~ ✅ | ~~Módulo cardio del panel~~ | `python_app/panel.py` arma cada bloque desde `catalog.snapshot()` con `evaluate_trend`: estado del sistema, valor, variación frente a la línea base y conteo de días ("1 de 3 días", "4 días seguidos"). `data.py` perdió las cifras de cardio; las métricas ganaron `system` y se agregaron diastólica y SpO₂ con los rangos de `db/schema.sql`. Pruebas en `tests_py/test_panel.py` y `test/dashboard_screen_test.dart`. |
| ~~P1~~ ✅ | ~~El panel se refresca solo~~ | `DashboardScreen` vuelve a preguntar cada `TIRELUS_REFRESH_SECONDS` (5 s por defecto), conserva el último dato bueno si el refresco falla ("Sin conexión · último dato HH:MM:SS") y muestra "Actualizado HH:MM:SS". |
| ~~P1~~ ✅ | ~~Cada cuánto se relee la base~~ | `TIRELUS_DB_TTL` (30 s por defecto, 2 s para la demo); un valor inválido no desactiva la base. |
| ~~P2~~ ✅ | ~~Puerto de la API configurable~~ | `--dart-define=TIRELUS_PORT`, como ya pedía `CLAUDE.md`; antes estaba escrito a mano en Dart. |
| ~~P1~~ ✅ | ~~Datos vitales de la tripulación~~ | `tools/sim_sinteticos.py` carga los CSV del generador del equipo a PostgreSQL: tripulación, línea base personal prevuelo y lecturas, con mapeo probado contra los indicadores reales del esquema. Verificado con 4 tripulantes × 90 días. |
| ~~P2~~ ✅ | ~~`--records` exacto en el generador~~ | En el repo del generador: `--records` ahora es el número exacto de filas (decide cuántos pacientes, nunca su duración) y `--patients` manda sobre él; antes `--records 100` producía 6000 filas. 13 pruebas nuevas. |
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
