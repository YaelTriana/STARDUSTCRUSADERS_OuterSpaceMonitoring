# Base de datos · TIRELUS

Detalle de la capa de PostgreSQL: cómo conectarse, qué hay en `db/`, la prueba de estabilidad y la seguridad. El resumen está en el [README](../README.md#base-de-datos); la auditoría del esquema, en [`AUDITORIA.md`](AUDITORIA.md).

## Resumen

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
- **Probado el 14 nov contra el servidor del equipo** (PostgreSQL 18.7, red local 192.168.10.0/24, usuario sin permisos de DDL): `/health` dice `data_source: db` y la sistólica sale de la base. Las credenciales no están en el repo. La base solo trae la sistólica de ejemplo (`db/003_demo.sql`); faltan FC, sueño, ánimo y SANS. Ver [`AUDITORIA.md`](AUDITORIA.md) y [`pendientes.md`](../pendientes.md).

## Conectar tu app al servidor del equipo

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

## Estructura de `db/` y `docker/`

| Archivo | Qué es |
|---|---|
| `db/schema.sql`, `db/002_ojos.sql` | Esquema (requieren administrador) |
| `db/003_demo.sql` | Solo INSERT, repetible: tripulante "Tripulante A (Datos de ejemplo)", línea base y 14 lecturas de sistólica |
| `db/load_datos.sql` | Datasets de referencia; lee de `datosdb/` |
| `db/AUDITORIA.md` | Comparación del esquema contra `data.py` y huecos conocidos |
| `docker/Dockerfile.api`, `docker-compose.yml`, `.env.example` | Imagen de la API y PostgreSQL local (sin probar) |

`datosdb/` (~117 MB) **no está en el repo**: pídela al equipo si necesitas `load_datos.sql` o `.\tirelus.ps1 datos`.

## Prueba de estabilidad (14 nov, servidor del equipo)

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

## Seguridad

- Credenciales solo en variables de entorno o en `.env` (ignorado por git). Nunca en el repo ni en el chat; si la contraseña se compartió por un medio inseguro, rotarla después de la demo.
- El servidor compartido guarda solo datos sintéticos. Los datos médicos reales solo los ven el tripulante, el CMO y el flight surgeon (regla de `CLAUDE.md`); la base aún no tiene roles ni RLS.
- Sistema de usuarios: para la demo la API usa un tripulante fijo (decidido el 15 nov). Roles y control de acceso quedan como deuda técnica en [`planning/FUTURO.md`](../planning/FUTURO.md).

## Docker (PostgreSQL + API) · descartado

> ⚠️ **Descartado (14 nov):** Docker no se usa en la demo. `docker/Dockerfile.api`, `docker-compose.yml` y `tirelus.ps1` quedan en el repo **sin haberse ejecutado nunca**; si algún día se retoman, hay que probarlos primero. La demo corre en modo desarrollo (ver el [README](../README.md#inicio-rápido)).

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
