# Auditoría de `db/*.sql` contra `app/python_app/data.py` (14 nov 2026)

Se compararon `schema.sql`, `002_ojos.sql` y `load_datos.sql` con el catálogo `METRICS` y con lo que sirve la API.
No se probó contra un PostgreSQL real (no hay servidor ni `psql` en esta máquina).

## Coincide

| Tema | Estado |
|---|---|
| Ids `systolic`, `heart_rate`, `sleep_hours`, `mood` | Existen en `indicators` |
| Unidades (mmHg, lpm, h, pts) | Iguales |
| Dirección de alerta de sistólica, sueño y ánimo | `above` / `below` / `below`, igual que `alert_when` |
| Límite de respaldo sistólica (160) | `thresholds.critico_high`, igual que `SYSTOLIC_ABS_HIGH` |
| SANS +20 / 55 µm | `thresholds` de `retinal_delta` con `design_assumption = false`; la referencia NASA sigue "por confirmar" en ambos lados |
| Estados | `health_status` usa los mismos valores que `rules.Status` (sin_dato = NULL) |

## Diferencias o huecos

1. **`heart_rate` es `both` en la base y `above` en la app.** `evaluate_trend` solo acepta `above` o `below` y lanza `ValueError` con otro valor. La capa nueva (`db.py`) no lee `alert_when` de la base: lo toma de `data.py`. Decidir cuál manda antes de tocar este campo.
2. **Etiquetas distintas:** la base dice "Frecuencia cardiaca"; la app, "FC en reposo". La app sigue usando la suya.
3. **No hay datos de la app en ningún `.sql`:** ni tripulante, ni línea base, ni lecturas (`astronauts`, `baselines`, `measurements` quedan vacías tras correr los tres scripts). `load_datos.sql` solo carga la población de referencia (`ref.*`). Sin esas filas, la API sigue con los datos de ejemplo de `data.py`.
4. **Falta el límite de respaldo de FC, sueño y ánimo** en `thresholds` (solo existen sistólica, SANS y presión intraocular). Corresponde a los campos `>>> DATOS:` de `data.py`.
5. **Nada marca "Datos de ejemplo" en la base.** La API siempre responde `sample_data: true`; si algún día entran datos reales, hay que decidirlo en el esquema (columna o esquema aparte).
6. **Solo hay tablas para tareas;** `HABITAT`, `EVA` y `AUTONOMOUS_PROTOCOL` siguen solo en `data.py` (no son del alcance de esta capa).
7. **Privacidad:** el esquema tiene el enum `crew_role` pero ninguna regla de acceso (roles de base o RLS). Mientras el servidor compartido solo tenga datos sintéticos no es un riesgo; para datos reales hay que definirlo.
8. **Orden de ejecución:** `002_ojos.sql` va después de `schema.sql` y antes de `load_datos.sql`, porque crea `ref.retinal` y `load_datos.sql` la carga.

## Lo que sí lee la app hoy

`app/python_app/db.py` toma, solo en reposo y solo para `systolic`, `heart_rate`, `sleep_hours` y `mood`:
línea base (`baselines`), límites de respaldo (`thresholds.critico_low/high` sin entorno) y las últimas 14 lecturas (`measurements`);
y para SANS, las lecturas de `retinal_delta` con `mission_day`.
Configuración por variables de entorno `TIRELUS_DB_*` y `TIRELUS_ASTRONAUT_ID` (ver el encabezado de `db.py`).
