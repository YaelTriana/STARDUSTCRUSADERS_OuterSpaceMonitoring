-- TIRELUS · esquema PostgreSQL (probado para PG 18; requiere >= 13).
-- Uso (desde la raíz del repo):
--   createdb -U postgres tirelus
--   psql -U postgres -d tirelus -f db/schema.sql        -- una sola vez
--   psql -U postgres -d tirelus -f db/002_ojos.sql      -- una sola vez
--   psql -U postgres -d tirelus -f db/load_datos.sql    -- cada vez que actualices datosdb/
--
-- Dos esquemas:
--   ref    → datasets de datosdb/ tal cual (población de referencia, sintéticos). Se recargan.
--   public → datos de la app (tripulación, mediciones, alertas...). Nunca se truncan al recargar.
--
-- Reglas de dominio (CLAUDE.md): la app no diagnostica; todo umbral salvo SANS es supuesto
-- de diseño; los estados usan los mismos valores que rules.Status (sin_dato = NULL).

BEGIN;

-- =====================================================================
-- Tipos (mismos ids que app/python_app)
-- =====================================================================
CREATE TYPE environment   AS ENUM ('iss', 'luna', 'marte');
CREATE TYPE health_status AS ENUM ('nominal', 'atencion', 'critico');
CREATE TYPE body_system   AS ENUM ('cardio', 'ojos', 'hueso', 'mente', 'inmune');
CREATE TYPE body_state    AS ENUM ('reposo', 'activo');   -- signos vitales = reposo · gym = activo
CREATE TYPE hazard        AS ENUM ('radiacion', 'aislamiento', 'distancia', 'gravedad', 'ambiente_hostil'); -- NASA HRP
CREATE TYPE crew_role     AS ENUM ('astronauta', 'cmo', 'flight_surgeon');
CREATE TYPE escalation    AS ENUM ('astronauta', 'cmo', 'flight_surgeon');
CREATE TYPE task_kind     AS ENUM ('medicion', 'ejercicio', 'sueno', 'cognitiva', 'psicologica');

-- =====================================================================
-- ref: datasets de datosdb/ (columnas en el mismo orden que el CSV para \copy)
-- numeric en lugar de integer para que "60.0" no rompa la carga si cambia el CSV.
-- =====================================================================
CREATE SCHEMA ref;

-- human_vital_signs_dataset_2024.csv → cuerpo en REPOSO
CREATE TABLE ref.vital_signs_rest (
    patient_id             bigint PRIMARY KEY,
    heart_rate             numeric NOT NULL,   -- lpm
    respiratory_rate       numeric NOT NULL,   -- rpm
    measured_at            timestamp NOT NULL,
    body_temperature       numeric NOT NULL,   -- °C
    oxygen_saturation      numeric NOT NULL,   -- %
    systolic_bp            numeric NOT NULL,   -- mmHg
    diastolic_bp           numeric NOT NULL,   -- mmHg
    age                    numeric,
    gender                 text,
    weight_kg              numeric,
    height_m               numeric,
    derived_hrv            numeric,
    derived_pulse_pressure numeric,
    derived_bmi            numeric,
    derived_map            numeric,
    risk_category          text
);

-- gym_members_exercise_tracking.csv → cuerpo ACTIVO (una fila = una sesión)
CREATE TABLE ref.gym_sessions (
    id                   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- el CSV no trae id
    age                  numeric,
    gender               text,
    weight_kg            numeric,
    height_m             numeric,
    max_bpm              numeric NOT NULL,
    avg_bpm              numeric NOT NULL,
    resting_bpm          numeric NOT NULL,
    session_hours        numeric NOT NULL,
    calories_burned      numeric,
    workout_type         text NOT NULL,       -- Strength, Cardio, Yoga, HIIT
    fat_percentage       numeric,
    water_liters         numeric,
    workout_days_week    numeric,
    experience_level     numeric,
    bmi                  numeric
);

-- sleep_deprivation_dataset_detailed.csv → simulación de sueño y su impacto
CREATE TABLE ref.sleep_deprivation (
    participant_id         text PRIMARY KEY,
    sleep_hours            numeric NOT NULL,
    sleep_quality_score    numeric,           -- PSQI: más alto = peor
    daytime_sleepiness     numeric,           -- Epworth: más alto = más somnolencia
    stroop_reaction_s      numeric,
    n_back_accuracy        numeric,           -- %
    emotion_regulation     numeric,
    pvt_reaction_ms        numeric,           -- Psychomotor Vigilance Task
    age                    numeric,
    gender                 text,
    bmi                    numeric,
    caffeine_intake        numeric,
    physical_activity      numeric,
    stress_level           numeric
);

-- Rango poblacional por indicador en reposo (p05–p95). Sirve de base provisional
-- cuando el tripulante aún no tiene línea base propia. Supuesto de diseño.
CREATE VIEW ref.rest_reference AS
SELECT v.indicator_id,
       count(*)                                                   AS n,
       percentile_cont(0.05) WITHIN GROUP (ORDER BY v.value::float8) AS p05,
       percentile_cont(0.50) WITHIN GROUP (ORDER BY v.value::float8) AS p50,
       percentile_cont(0.95) WITHIN GROUP (ORDER BY v.value::float8) AS p95
FROM ref.vital_signs_rest r
CROSS JOIN LATERAL (VALUES
    ('heart_rate',       r.heart_rate),
    ('respiratory_rate', r.respiratory_rate),
    ('temperature',      r.body_temperature),
    ('spo2',             r.oxygen_saturation),
    ('systolic',         r.systolic_bp),
    ('diastolic',        r.diastolic_bp),
    ('hrv',              r.derived_hrv)
) AS v(indicator_id, value)
GROUP BY v.indicator_id;

-- Cuerpo activo por tipo de entrenamiento: FC media/máx y duración típicas.
CREATE VIEW ref.active_reference AS
SELECT workout_type,
       count(*)                       AS n,
       round(avg(avg_bpm), 1)         AS avg_bpm,
       round(avg(max_bpm), 1)         AS max_bpm,
       round(avg(resting_bpm), 1)     AS resting_bpm,
       round(avg(session_hours) * 60) AS avg_minutes,
       round(avg(calories_burned / NULLIF(session_hours * 60, 0)), 2) AS kcal_per_min
FROM ref.gym_sessions
GROUP BY workout_type;

-- Recta de cada resultado contra horas de sueño (mínimos cuadrados).
-- OJO: r2 es bajo (dataset sintético, n≈60); úsalo para simular la tendencia, no como evidencia.
CREATE VIEW ref.sleep_impact AS
SELECT o.outcome,
       count(*)                                         AS n,
       regr_slope(o.value::float8, s.sleep_hours::float8)     AS per_hour,
       regr_intercept(o.value::float8, s.sleep_hours::float8) AS intercept,
       regr_r2(o.value::float8, s.sleep_hours::float8)        AS r2
FROM ref.sleep_deprivation s
CROSS JOIN LATERAL (VALUES
    ('pvt_ms',             s.pvt_reaction_ms),
    ('stroop_s',           s.stroop_reaction_s),
    ('n_back_pct',         s.n_back_accuracy),
    ('emotion_regulation', s.emotion_regulation),
    ('daytime_sleepiness', s.daytime_sleepiness),
    ('sleep_quality',      s.sleep_quality_score)
) AS o(outcome, value)
WHERE o.value IS NOT NULL
GROUP BY o.outcome;

-- Simulador: qué pasa con la cognición si el tripulante duerme `hours` horas.
--   SELECT * FROM ref.simulate_sleep(5.5);
CREATE FUNCTION ref.simulate_sleep(hours numeric)
RETURNS TABLE (outcome text, predicted float8, vs_8_5h float8)
LANGUAGE sql STABLE AS $$
    SELECT outcome,
           intercept + per_hour * hours,
           per_hour * (hours - 8.5)          -- diferencia contra el periodo de sueño de 8.5 h
    FROM ref.sleep_impact
$$;

-- =====================================================================
-- public: datos de la app
-- =====================================================================
CREATE TABLE missions (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        text NOT NULL,
    environment environment NOT NULL,
    starts_at   timestamptz NOT NULL,
    ends_at     timestamptz,
    CHECK (ends_at IS NULL OR ends_at > starts_at)
);

CREATE TABLE astronauts (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    mission_id  uuid REFERENCES missions(id) ON DELETE SET NULL,
    name        text NOT NULL,              -- "Tripulante A"
    role        crew_role NOT NULL DEFAULT 'astronauta',
    birth_date  date,
    sex         text CHECK (sex IN ('F', 'M', 'X')),
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- Catálogo de indicadores. Los ids coinciden con data.METRICS.
CREATE TABLE indicators (
    id          text PRIMARY KEY,
    name        text NOT NULL,
    unit        text NOT NULL,
    system      body_system NOT NULL,
    alert_when  text NOT NULL CHECK (alert_when IN ('above', 'below', 'both')),
    valid_min   numeric NOT NULL,           -- fuera de esto es error de captura, no un estado
    valid_max   numeric NOT NULL,
    how_to      text,                       -- contenido educativo: cómo medir
    why_space   text,                       -- por qué cambia en el espacio
    CHECK (valid_min < valid_max)
);

-- Límites por indicador, estado del cuerpo y entorno (environment NULL = todos).
-- atencion_* solo se usa sin línea base personal (o en SANS); critico_* = respaldo clínico.
CREATE TABLE thresholds (
    id              serial PRIMARY KEY,
    indicator_id    text NOT NULL REFERENCES indicators(id) ON DELETE CASCADE,
    body_state      body_state NOT NULL DEFAULT 'reposo',
    environment     environment,
    critico_low     numeric,
    atencion_low    numeric,
    atencion_high   numeric,
    critico_high    numeric,
    design_assumption boolean NOT NULL DEFAULT true,  -- false solo con cifra publicada (SANS)
    source          text NOT NULL,
    CHECK (critico_low  IS NULL OR atencion_low IS NULL OR critico_low  <= atencion_low),
    CHECK (atencion_low IS NULL OR atencion_high IS NULL OR atencion_low < atencion_high),
    CHECK (atencion_high IS NULL OR critico_high IS NULL OR atencion_high <= critico_high)
);
-- Un límite por (indicador, estado, entorno). Dos índices: un enum no puede ir en COALESCE de índice.
CREATE UNIQUE INDEX thresholds_env     ON thresholds (indicator_id, body_state, environment) WHERE environment IS NOT NULL;
CREATE UNIQUE INDEX thresholds_generic ON thresholds (indicator_id, body_state)              WHERE environment IS NULL;

-- Mapa peligro → indicador → efecto → acción preventiva
CREATE TABLE indicator_hazards (
    indicator_id      text NOT NULL REFERENCES indicators(id) ON DELETE CASCADE,
    hazard            hazard NOT NULL,
    health_effect     text NOT NULL,
    preventive_action text NOT NULL,
    source            text,
    PRIMARY KEY (indicator_id, hazard)
);

-- Línea base personal prevuelo = rules.Baseline(low, high), por estado del cuerpo.
CREATE TABLE baselines (
    astronaut_id uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    indicator_id text NOT NULL REFERENCES indicators(id) ON DELETE CASCADE,
    body_state   body_state NOT NULL DEFAULT 'reposo',
    low          numeric NOT NULL,
    high         numeric NOT NULL,
    computed_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (astronaut_id, indicator_id, body_state),
    CHECK (low <= high)
);

-- Lecturas puntuales (serie de tiempo).
CREATE TABLE measurements (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id    uuid NOT NULL UNIQUE,       -- lo genera el dispositivo: sync offline idempotente
    astronaut_id uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    indicator_id text NOT NULL REFERENCES indicators(id),
    body_state   body_state NOT NULL DEFAULT 'reposo',
    value        numeric NOT NULL,
    measured_at  timestamptz NOT NULL,
    mission_day  integer,                    -- D47, etc.
    environment  environment NOT NULL,
    status       health_status,              -- lo escribe el motor; NULL = sin_dato
    note         text,
    synced_at    timestamptz NOT NULL DEFAULT now() -- llegada a Tierra (simula retraso)
);
CREATE INDEX measurements_series ON measurements (astronaut_id, indicator_id, body_state, measured_at DESC);

-- Sesiones de ejercicio (cuerpo activo; mismas columnas útiles que ref.gym_sessions).
CREATE TABLE exercise_sessions (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id    uuid NOT NULL UNIQUE,
    astronaut_id uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    workout_type text NOT NULL,              -- ARED (fuerza), CEVIS (bici), T2 (caminadora)...
    started_at   timestamptz NOT NULL,
    minutes      numeric NOT NULL CHECK (minutes > 0),
    avg_bpm      numeric,
    max_bpm      numeric,
    calories     numeric,
    environment  environment NOT NULL
);
CREATE INDEX exercise_sessions_day ON exercise_sessions (astronaut_id, started_at DESC);

-- Alertas = estado + mensaje + recomendación + a quién escalar.
CREATE TABLE alerts (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    astronaut_id    uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    measurement_id  bigint REFERENCES measurements(id) ON DELETE SET NULL, -- NULL si viene de una tendencia
    system          body_system NOT NULL,
    hazard          hazard,
    status          health_status NOT NULL CHECK (status <> 'nominal'),
    message         text NOT NULL,
    recommendation  text NOT NULL,
    escalate_to     escalation NOT NULL DEFAULT 'astronauta',
    in_summary      boolean NOT NULL DEFAULT false, -- va al resumen de la conferencia médica
    created_at      timestamptz NOT NULL DEFAULT now(),
    acknowledged_at timestamptz,
    resolved_at     timestamptz
);
CREATE INDEX alerts_open ON alerts (astronaut_id, created_at DESC) WHERE resolved_at IS NULL;

-- Rutina de misión
CREATE TABLE tasks (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id    uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    astronaut_id uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    kind         task_kind NOT NULL,
    indicator_id text REFERENCES indicators(id),  -- solo si kind = 'medicion'
    title        text NOT NULL,
    detail       text,
    due_at       timestamptz NOT NULL,
    completed_at timestamptz,
    CHECK ((kind = 'medicion') = (indicator_id IS NOT NULL))
);
CREATE INDEX tasks_due ON tasks (astronaut_id, due_at);

-- Gamificación: puntos = SUM(points); racha = días seguidos con eventos.
CREATE TABLE badges (
    id          text PRIMARY KEY,
    name        text NOT NULL,
    description text NOT NULL
);

CREATE TABLE astronaut_badges (
    astronaut_id uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    badge_id     text NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    earned_at    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (astronaut_id, badge_id)
);

CREATE TABLE point_events (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    astronaut_id uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    task_id      bigint REFERENCES tasks(id) ON DELETE SET NULL,
    points       integer NOT NULL,
    reason       text NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX point_events_astronaut ON point_events (astronaut_id, created_at);

-- Último valor de cada indicador por tripulante y estado (semáforo del panel).
CREATE VIEW latest_measurements AS
SELECT DISTINCT ON (astronaut_id, indicator_id, body_state) *
FROM measurements
ORDER BY astronaut_id, indicator_id, body_state, measured_at DESC;

-- =====================================================================
-- Catálogo inicial
-- =====================================================================
INSERT INTO indicators (id, name, unit, system, alert_when, valid_min, valid_max) VALUES
    ('systolic',         'Presión sistólica',              'mmHg',  'cardio', 'above',  50, 260),
    ('diastolic',        'Presión diastólica',             'mmHg',  'cardio', 'above',  30, 160),
    ('heart_rate',       'Frecuencia cardiaca',            'lpm',   'cardio', 'both',   20, 230),
    ('respiratory_rate', 'Frecuencia respiratoria',        'rpm',   'cardio', 'both',    4,  60),
    ('spo2',             'SpO₂',                           '%',     'cardio', 'below',  50, 100),
    ('hrv',              'Variabilidad de FC',             's',     'cardio', 'below',   0,   1),
    ('temperature',      'Temperatura corporal',           '°C',    'inmune', 'both',   30,  44),
    ('retinal_delta',    'Grosor retiniano vs. base',      'µm',    'ojos',   'above', -100, 300),
    ('body_mass',        'Masa corporal',                  'kg',    'hueso',  'below',  30, 200),
    ('sleep_hours',      'Horas de sueño',                 'h',     'mente',  'below',   0,  24),
    ('mood',             'Ánimo (1–5)',                    'pts',   'mente',  'below',   1,   5),
    ('pvt_ms',           'Tiempo de reacción (PVT)',       'ms',    'mente',  'above', 100, 2000);

-- Única cifra publicada (CLAUDE.md): SANS +20 µm primer signo, 55 µm preocupación clínica.
INSERT INTO thresholds (indicator_id, atencion_high, critico_high, design_assumption, source) VALUES
    ('retinal_delta', 20, 55, false, 'Umbrales publicados de SANS. Referencia NASA por confirmar.');

-- Respaldos clínicos terrestres ya usados en data.py (supuesto de diseño).
INSERT INTO thresholds (indicator_id, critico_high, source) VALUES
    ('systolic', 160, 'Límite clínico terrestre de respaldo. Supuesto de diseño.');

COMMIT;
