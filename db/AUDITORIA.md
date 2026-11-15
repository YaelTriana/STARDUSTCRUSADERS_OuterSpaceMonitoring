# Auditoría del módulo de base de datos (15 nov 2026)

Revisión completa de `db/` sobre `main` en `03933e2`, con el dataset real en `db/datosdb/dataset.csv`
(**30 tripulantes × 100 días = 3000 filas, 68 columnas**). Reemplaza la auditoría del 14 nov, que comparaba
un esquema de 13 tablas contra `data.py`.

## Qué es el módulo hoy

| Pieza | Estado |
|---|---|
| `schema.sql` | **25 tablas**: 4 de referencia (`ref.dataset_raw`, `ref.vital_signs_rest`, `ref.gym_sessions`, `ref.sleep_deprivation`) y 21 del dominio, 306 columnas · **33 índices** · **5 vistas** |
| `002_ojos.sql` | indicadores de ojos (macular, RNFL, visión cercana, presión intraocular, copa/disco) y `ref.retinal` |
| `004_populate.sql` | poblado automático generado por `generate_populate_sql.py` desde el CSV: **7.2 MB, 45 555 líneas** |
| `generate_populate_sql.py` | el generador del poblado (lee el CSV, excluye `Ethnicity`) |
| `verify_db.py` · `test_db_sim.py` | verificación de cobertura, del SQL y de compatibilidad con `app/python_app/db.py` |

Normalización por familia de medición: `vital_signs`, `hemodynamics`, `body_composition`,
`sleep_mental_logs`, `exercise_sessions`, `cognitive_assessments`, `metabolic_lab_tests`,
`ophthalmic_exams`, más el catálogo (`indicators`, `thresholds`, `indicator_hazards`), la línea base
(`baselines`), la telemetría que lee la app (`measurements`) y la capa de juego (`badges`, `point_events`).

## 1. Cobertura de columnas: 67 de 67

De las 68 columnas del CSV, **`Ethnicity` queda fuera por decisión del equipo** y las otras 67 se persisten.
Lo confirma el propio `verify_db.py`: *"Las 67 columnas (100%) están declaradas e indexadas"* y
*"'ethnicity' no aparece en ninguna sentencia de 004_populate.sql"*.

Pero "persistida" no era lo mismo que "disponible para la app". Seis indicadores existían en el catálogo con
**cero lecturas** y uno no existía en absoluto, aunque sus columnas sí llegaban a las tablas de dominio:

| Indicador | Columna del CSV | Antes | Ahora |
|---|---|---|---|
| `mood` | derivado de `Stress_Level` | **no existía en el catálogo**, y la app lo pide | 3000 lecturas + 30 líneas base + umbral |
| `stress_level` | `Stress_Level` | 0 lecturas | 3000 |
| `water_intake` | `Water_Intake_liters` | 0 | 3000 |
| `fasting_glucose` | `Fasting_Glucose_mg_dl` | 0 | 196 |
| `hba1c` | `HbA1c_pct` | 0 | 60 |
| `cup_to_disc_ratio` | `Cup_to_Disc_Ratio` | 0 | 60 |
| `near_vision_logmar` | `Visual_Acuity` ("20/40") | 0 | 60 (con `snellen_to_logmar`) |

Los 21 indicadores del catálogo tienen lecturas; **30 903 mediciones** para los 30 tripulantes, todos con
línea base.

**Supuesto de diseño documentado:** el dataset no trae autorreporte de ánimo. `mood` se deriva del estrés
percibido invertido (`5 − 4·estrés/10`, estrés 0–10 → ánimo 5–1), con la misma fórmula que
`tools/sim_sinteticos.py` para no tener dos verdades.

## 2. SANS salía del grosor equivocado

El poblado calculaba `retinal_delta` como el cambio de **`Macular_Thickness_um`**. Los umbrales publicados
del proyecto (+20 µm primer signo, 55 µm preocupación clínica) son de grosor retiniano **peripapilar** — así
está escrito en `app/python_app/rules.py:26` y en `CLAUDE.md`. Con el grosor macular, la única cifra
publicada del proyecto se estaría aplicando a otra medida.

Corregido: `retinal_delta` ahora es el cambio de **`RNFL_Thickness_um`** frente a la primera lectura del
tripulante, que es la definición que usa la app.

## 3. El poblado estaba desfasado

`004_populate.sql` venía generado de un CSV de 1800 filas, mientras el dataset ya tenía 3000. Regenerado:
30 903 mediciones en vez de 13 039. **Hay que regenerarlo cada vez que cambie el dataset**:

```bash
python db/generate_populate_sql.py      # lee db/datosdb/dataset.csv → db/004_populate.sql
python db/verify_db.py                  # cobertura + SQL + compatibilidad con db.py
```

Orden de carga: `schema.sql` → `002_ojos.sql` → `004_populate.sql`. Los tres son idempotentes y se
pueden recargar sin duplicar: verificado cargando los tres **dos veces seguidas** sobre la misma base
(30 903 mediciones en ambas vueltas).

`schema.sql` no lo era: sus ocho `CREATE TYPE` fallaban en la segunda carga ("type already exists"), aunque
todas sus tablas ya usaban `IF NOT EXISTS`. PostgreSQL no tiene `CREATE TYPE IF NOT EXISTS`, así que ahora
van envueltos en un `DO $$ ... EXCEPTION WHEN duplicate_object THEN NULL; END $$;`.

## 4. Rendimiento: medido, no supuesto

Se midió con `EXPLAIN (ANALYZE)` sobre la base poblada. La consulta caliente es la de la app: las últimas 14
lecturas por indicador de un tripulante.

| Consulta | Plan | Tiempo |
|---|---|---|
| Ventana de 14 lecturas (13 039 filas) | Index Scan `measurements_series` | **0.108 ms** |
| La misma con 30 903 filas | Index Scan `measurements_series` | **0.134 ms** |
| Línea base del tripulante | Index Scan | 0.048 ms |
| Umbrales | Index Scan | 0.039 ms |
| `latest_measurements` | Index Scan | 0.396 ms |
| `v_daily_health_overview` | Index Scan | 0.331 ms |
| `v_sans_monitoring` | Seq Scan sobre tablas de 30–60 filas | 0.060 ms |
| `v_astronaut_summary` | Seq Scan sobre `astronauts` (30 filas) | 0.612 ms |

**Conclusión: no hay ninguna tabla ni índice nuevo que justificar.** El índice que importa ya existe —
`measurements_series (astronaut_id, indicator_id, body_state, measured_at DESC)` — y es el prefijo correcto
para la consulta de la app, así que escala: duplicar los datos no movió el tiempo. Los dos `Seq Scan` que
quedan son sobre tablas de 30 y 60 filas, donde escanear es más rápido que un índice, y el planificador lo
elige bien. Agregar vistas materializadas aquí sería ceremonia: a 0.1 ms la app no está esperando a la base,
está esperando los 30 s del TTL del catálogo (`TIRELUS_DB_TTL`).

Si algún día el volumen crece de verdad (50 tripulantes × 1000 días × 20 indicadores ≈ 1 M de filas), el
mismo índice sigue sirviendo; lo primero a revisar entonces sería particionar `measurements` por
`astronaut_id` y materializar `v_daily_health_overview`, no antes.

## 5. Lo que queda abierto

1. **Faltan umbrales de respaldo** para `body_mass`, `hrv`, `macular_thickness`, `rnfl_thickness`,
   `cup_to_disc_ratio` y `near_vision_logmar`. **No los inventé**: la regla del proyecto es que todo umbral
   sea un supuesto de diseño declarado, y para estos no hay cifra defendible todavía. Los decide la persona
   de ciencia.
2. **`heart_rate` alerta `both` en la base** y el motor de la app solo acepta `above` o `below`
   (`evaluate_trend` lanza `ValueError`). Hoy no truena porque `db.py` no lee `alert_when` de la base, pero
   hay que elegir una fuente de verdad. Lo mismo para `respiratory_rate`, `temperature`,
   `intraocular_pressure`, `rnfl_thickness` y `cup_to_disc_ratio`, todos `both`.
3. **Privacidad**: el esquema tiene `crew_role` pero ninguna regla de acceso (sin roles de base ni RLS).
   Mientras solo haya datos sintéticos no es un riesgo; para datos reales es obligatorio, porque la regla del
   proyecto es que los datos médicos de cada tripulante solo los vean él, el CMO y el flight surgeon.
4. **`ref.vital_signs_rest`, `ref.gym_sessions`, `ref.sleep_deprivation` y `ref.retinal` siguen vacías**:
   las llena `load_datos.sql` desde los CSV originales de Kaggle, que no están en `db/datosdb/`.
   El poblado de la app no las necesita.
5. **`alerts`, `tasks`, `badges`, `astronaut_badges` y `point_events` están vacías**: son de la capa de
   juego y de escalamiento, que la app todavía no escribe.
