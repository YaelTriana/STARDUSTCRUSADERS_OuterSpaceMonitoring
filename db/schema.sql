-- TIRELUS · esquema PostgreSQL optimizado (compatible PostgreSQL >= 13).
-- Módulo de Base de Datos · NASA Space Apps Challenge 2026.
--
-- Uso (desde la raíz del repo):
--   createdb -U postgres tirelus
--   psql -U postgres -d tirelus -f db/schema.sql        -- estructura, catálogo y tablas optimizadas
--   psql -U postgres -d tirelus -f db/002_ojos.sql      -- funciones auxiliares de oftalmología
--   psql -U postgres -d tirelus -f db/003_demo.sql      -- tripulante de prueba / compatibilidad
--   psql -U postgres -d tirelus -f db/004_populate.sql  -- poblado automático integral desde datosdb/dataset.csv
--   psql -U postgres -d tirelus -f db/load_datos.sql    -- recarga staging y tablas desde CSV con \copy
--
-- Dos esquemas:
--   ref    → dataset bruto y analítica poblacional (población de referencia, sintética).
--   public → datos relacionales normalizados de la app (astronautas, telemetría, biometría, SANS, alertas).
--
-- Principios de optimización de rendimiento:
--   - Normalización de 67 campos del dataset (excluyendo etnicidad) en dominios de alta cohesión.
--   - Eliminación del almacenamiento redundante de valores nulos (ahorro masivo de I/O y memoria caché).
--   - Índices compuestos (astronaut_id, measured_at DESC) para consultas de series temporales en < 1 ms.
--   - Índices parciales para condiciones clínicas críticas y alertas inmediatas.
--   - Vistas analíticas y de resumen en tiempo real para paneles sin costosos escaneos secuenciales.

BEGIN;

-- =====================================================================
-- Tipos enumerados (coincidentes con app/python_app)
-- =====================================================================
CREATE TYPE environment   AS ENUM ('iss', 'luna', 'marte');
CREATE TYPE health_status AS ENUM ('nominal', 'atencion', 'critico');
CREATE TYPE body_system   AS ENUM ('cardio', 'ojos', 'hueso', 'mente', 'inmune');
CREATE TYPE body_state    AS ENUM ('reposo', 'activo');
CREATE TYPE hazard        AS ENUM ('radiacion', 'aislamiento', 'distancia', 'gravedad', 'ambiente_hostil');
CREATE TYPE crew_role     AS ENUM ('astronauta', 'cmo', 'flight_surgeon');
CREATE TYPE escalation    AS ENUM ('astronauta', 'cmo', 'flight_surgeon');
CREATE TYPE task_kind     AS ENUM ('medicion', 'ejercicio', 'sueno', 'cognitiva', 'psicologica');

-- =====================================================================
-- Esquema ref: Staging poblacional y tablas de referencia
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS ref;

-- Tabla de staging para carga masiva directa de datosdb/dataset.csv
-- NOTA: Se incluyen exactamente 67 campos (se excluye etnicidad expresamente).
CREATE TABLE IF NOT EXISTS ref.dataset_raw (
    patient_id                  text NOT NULL,
    timestamp                   timestamp NOT NULL,
    age                         integer NOT NULL,
    gender                      text NOT NULL,
    -- ethnicity excluida por directriz de privacidad y requisitos
    height_m                    numeric(4,2) NOT NULL,
    weight_kg                   numeric(5,2) NOT NULL,
    bmi                         numeric(5,2) NOT NULL,
    fat_percentage              numeric(4,1) NOT NULL,
    smoking_status              text NOT NULL,
    history_hypertension        text NOT NULL,
    history_cvd                 text NOT NULL,
    diabetes_duration_years     integer NOT NULL,
    family_history_eye_disease  text NOT NULL,
    medications                 text NOT NULL,
    risk_category               text NOT NULL,
    workout_frequency_days_week integer NOT NULL,
    physical_activity_level     integer NOT NULL,
    experience_level            integer NOT NULL,
    workout_type                text,
    session_duration_hours      numeric(4,2),
    calories_burned             numeric(6,1),
    avg_bpm                     numeric(5,1),
    max_bpm                     numeric(5,1),
    caffeine_intake_cups_day    numeric(4,2) NOT NULL,
    water_intake_liters         numeric(4,2) NOT NULL,
    sleep_hours                 numeric(4,2) NOT NULL,
    sleep_quality_score         numeric(5,2) NOT NULL,
    daytime_sleepiness          numeric(4,2) NOT NULL,
    stress_level                numeric(4,2) NOT NULL,
    emotion_regulation_score    numeric(5,2) NOT NULL,
    stroop_task_reaction_time_s numeric(5,2),
    n_back_accuracy_pct         numeric(5,2),
    pvt_reaction_time_ms        numeric(6,2),
    heart_rate                  numeric(5,1),
    systolic_bp                 numeric(5,1),
    diastolic_bp                numeric(5,1),
    derived_pulse_pressure      numeric(5,1),
    derived_map                 numeric(5,1),
    fasting_glucose_mg_dl       numeric(5,1),
    hba1c_pct                   numeric(4,2),
    derived_hrv_s               numeric(6,4),
    body_temperature_c          numeric(4,2),
    oxygen_saturation_pct       numeric(4,1),
    respiratory_rate_bpm        numeric(4,1),
    date_of_last_eye_exam       date,
    symptom_duration_weeks      numeric(4,1),
    visual_acuity               text,
    image_quality_score         numeric(5,3),
    optic_disc_area             numeric(6,3),
    optic_cup_area              numeric(6,3),
    cup_to_disc_ratio           numeric(5,3),
    intraocular_pressure_mmhg   numeric(5,2),
    macular_thickness_um        numeric(6,2),
    rnfl_thickness_um           numeric(6,2),
    vessel_tortuosity           numeric(6,4),
    bifurcation_angle_deg       numeric(5,2),
    faz_area_mm2                numeric(6,3),
    texture_glcm_contrast       numeric(6,4),
    texture_gabor_response      numeric(6,4),
    deep_feature_1              numeric(7,4),
    deep_feature_2              numeric(7,4),
    deep_feature_3              numeric(7,4),
    microaneurysms_count        numeric(4,0),
    exudates_count              numeric(4,0),
    hemorrhages_count           numeric(4,0),
    retinal_disorder            integer,
    retinal_disorder_label      text,
    PRIMARY KEY (patient_id, timestamp)
);

CREATE INDEX IF NOT EXISTS idx_dataset_raw_patient ON ref.dataset_raw (patient_id);
CREATE INDEX IF NOT EXISTS idx_dataset_raw_ts      ON ref.dataset_raw (timestamp);

-- Tablas heredadas para retrocompatibilidad
CREATE TABLE IF NOT EXISTS ref.vital_signs_rest (
    patient_id             bigint PRIMARY KEY,
    heart_rate             numeric NOT NULL,
    respiratory_rate       numeric NOT NULL,
    measured_at            timestamp NOT NULL,
    body_temperature       numeric NOT NULL,
    oxygen_saturation      numeric NOT NULL,
    systolic_bp            numeric NOT NULL,
    diastolic_bp           numeric NOT NULL,
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

CREATE TABLE IF NOT EXISTS ref.gym_sessions (
    id                   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    age                  numeric,
    gender               text,
    weight_kg            numeric,
    height_m             numeric,
    max_bpm              numeric NOT NULL,
    avg_bpm              numeric NOT NULL,
    resting_bpm          numeric NOT NULL,
    session_hours        numeric NOT NULL,
    calories_burned      numeric,
    workout_type         text NOT NULL,
    fat_percentage       numeric,
    water_liters         numeric,
    workout_days_week    numeric,
    experience_level     numeric,
    bmi                  numeric
);

CREATE TABLE IF NOT EXISTS ref.sleep_deprivation (
    participant_id         text PRIMARY KEY,
    sleep_hours            numeric NOT NULL,
    sleep_quality_score    numeric,
    daytime_sleepiness     numeric,
    stroop_reaction_s      numeric,
    n_back_accuracy        numeric,
    emotion_regulation     numeric,
    pvt_reaction_ms        numeric,
    age                    numeric,
    gender                 text,
    bmi                    numeric,
    caffeine_intake        numeric,
    physical_activity      numeric,
    stress_level           numeric
);

-- =====================================================================
-- Esquema public: Tablas de la aplicación y telemetría
-- =====================================================================

CREATE TABLE IF NOT EXISTS missions (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        text NOT NULL,
    environment environment NOT NULL,
    starts_at   timestamptz NOT NULL,
    ends_at     timestamptz,
    CHECK (ends_at IS NULL OR ends_at > starts_at)
);

CREATE TABLE IF NOT EXISTS astronauts (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id  text UNIQUE NOT NULL,       -- Mapeo con SC-00001 .. SC-00030
    mission_id  uuid REFERENCES missions(id) ON DELETE SET NULL,
    name        text NOT NULL,
    role        crew_role NOT NULL DEFAULT 'astronauta',
    birth_date  date,
    age         integer,
    gender      text,
    sex         text CHECK (sex IN ('F', 'M', 'X')),
    height_m    numeric(4,2),
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_astronauts_patient ON astronauts (patient_id);

-- Perfil e historial clínico estático (3NF: separado de series temporales)
CREATE TABLE IF NOT EXISTS astronaut_clinical_history (
    astronaut_id                uuid PRIMARY KEY REFERENCES astronauts(id) ON DELETE CASCADE,
    smoking_status              text NOT NULL,
    history_hypertension        boolean NOT NULL,
    history_cvd                 boolean NOT NULL,
    diabetes_duration_years     integer NOT NULL DEFAULT 0,
    family_history_eye_disease  boolean NOT NULL,
    medications                 text NOT NULL,
    risk_category               text NOT NULL,
    workout_frequency_days_week integer NOT NULL,
    physical_activity_level     integer NOT NULL,
    experience_level            integer NOT NULL,
    updated_at                  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_clinical_risk ON astronaut_clinical_history (risk_category);

-- Composición corporal diaria
CREATE TABLE IF NOT EXISTS body_composition (
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    astronaut_id   uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    measured_at    timestamptz NOT NULL,
    mission_day    integer,
    weight_kg      numeric(5,2) NOT NULL,
    bmi            numeric(5,2) NOT NULL,
    fat_percentage numeric(4,1) NOT NULL,
    CONSTRAINT uq_body_comp_time UNIQUE (astronaut_id, measured_at)
);
CREATE INDEX IF NOT EXISTS idx_body_comp_timeline ON body_composition (astronaut_id, measured_at DESC);
CREATE INDEX IF NOT EXISTS idx_body_comp_day      ON body_composition (astronaut_id, mission_day);

-- Signos vitales de alta frecuencia en reposo
CREATE TABLE IF NOT EXISTS vital_signs (
    id                    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    astronaut_id          uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    measured_at           timestamptz NOT NULL,
    mission_day           integer,
    heart_rate            numeric(5,1) NOT NULL, -- lpm
    derived_hrv_s         numeric(6,4) NOT NULL, -- s
    body_temperature_c    numeric(4,2) NOT NULL, -- °C
    oxygen_saturation_pct numeric(4,1) NOT NULL, -- %
    respiratory_rate_bpm  numeric(4,1) NOT NULL, -- rpm
    CONSTRAINT uq_vital_signs_time UNIQUE (astronaut_id, measured_at)
);
CREATE INDEX IF NOT EXISTS idx_vitals_timeline   ON vital_signs (astronaut_id, measured_at DESC);
CREATE INDEX IF NOT EXISTS idx_vitals_day        ON vital_signs (astronaut_id, mission_day);
CREATE INDEX IF NOT EXISTS idx_vitals_spo2_alert ON vital_signs (astronaut_id, oxygen_saturation_pct) WHERE oxygen_saturation_pct < 95.0;
CREATE INDEX IF NOT EXISTS idx_vitals_hr_alert   ON vital_signs (astronaut_id, heart_rate) WHERE heart_rate > 100.0;

-- Hemodinámica y monitorización cardiovascular
CREATE TABLE IF NOT EXISTS hemodynamics (
    id                     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    astronaut_id           uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    measured_at            timestamptz NOT NULL,
    mission_day            integer,
    systolic_bp            numeric(5,1) NOT NULL, -- mmHg
    diastolic_bp           numeric(5,1) NOT NULL, -- mmHg
    derived_pulse_pressure numeric(5,1) NOT NULL, -- mmHg
    derived_map            numeric(5,1) NOT NULL, -- mmHg
    CONSTRAINT uq_hemodynamics_time UNIQUE (astronaut_id, measured_at)
);
CREATE INDEX IF NOT EXISTS idx_hemo_timeline       ON hemodynamics (astronaut_id, measured_at DESC);
CREATE INDEX IF NOT EXISTS idx_hemo_day            ON hemodynamics (astronaut_id, mission_day);
CREATE INDEX IF NOT EXISTS idx_hemo_systolic_alert ON hemodynamics (astronaut_id, systolic_bp) WHERE systolic_bp >= 140.0;

-- Registro de sueño, hábitos y bienestar mental
CREATE TABLE IF NOT EXISTS sleep_mental_logs (
    id                       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    astronaut_id             uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    logged_at                timestamptz NOT NULL,
    mission_day              integer,
    sleep_hours              numeric(4,2) NOT NULL,
    sleep_quality_score      numeric(5,2) NOT NULL,
    daytime_sleepiness       numeric(4,2) NOT NULL,
    stress_level             numeric(4,2) NOT NULL,
    emotion_regulation_score numeric(5,2) NOT NULL,
    caffeine_intake_cups_day numeric(4,2) NOT NULL,
    water_intake_liters      numeric(4,2) NOT NULL,
    CONSTRAINT uq_sleep_mental_time UNIQUE (astronaut_id, logged_at)
);
CREATE INDEX IF NOT EXISTS idx_sleep_mental_timeline ON sleep_mental_logs (astronaut_id, logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_sleep_mental_day      ON sleep_mental_logs (astronaut_id, mission_day);
CREATE INDEX IF NOT EXISTS idx_sleep_deprivation     ON sleep_mental_logs (astronaut_id, sleep_hours) WHERE sleep_hours < 6.0;

-- Sesiones de ejercicio físico (cuerpo activo)
CREATE TABLE IF NOT EXISTS exercise_sessions (
    id                     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id              uuid UNIQUE DEFAULT gen_random_uuid(),
    astronaut_id           uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    workout_type           text NOT NULL,              -- HIIT, Strength, Cardio, Yoga
    started_at             timestamptz NOT NULL,
    mission_day            integer,
    session_duration_hours numeric(4,2) NOT NULL,
    minutes                numeric(5,1) NOT NULL CHECK (minutes > 0),
    calories_burned        numeric(6,1),
    avg_bpm                numeric(5,1),
    max_bpm                numeric(5,1),
    environment            environment NOT NULL DEFAULT 'iss',
    CONSTRAINT uq_exercise_time UNIQUE (astronaut_id, started_at)
);
CREATE INDEX IF NOT EXISTS idx_exercise_sessions_day ON exercise_sessions (astronaut_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_exercise_workout_type ON exercise_sessions (workout_type, started_at DESC);

-- Batería de evaluaciones cognitivas
CREATE TABLE IF NOT EXISTS cognitive_assessments (
    id                          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    astronaut_id                uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    tested_at                   timestamptz NOT NULL,
    mission_day                 integer,
    stroop_task_reaction_time_s numeric(5,2) NOT NULL,
    n_back_accuracy_pct         numeric(5,2) NOT NULL,
    pvt_reaction_time_ms        numeric(6,2) NOT NULL,
    CONSTRAINT uq_cognitive_time UNIQUE (astronaut_id, tested_at)
);
CREATE INDEX IF NOT EXISTS idx_cognitive_timeline  ON cognitive_assessments (astronaut_id, tested_at DESC);
CREATE INDEX IF NOT EXISTS idx_cognitive_day       ON cognitive_assessments (astronaut_id, mission_day);
CREATE INDEX IF NOT EXISTS idx_cognitive_pvt_alert ON cognitive_assessments (astronaut_id, pvt_reaction_time_ms) WHERE pvt_reaction_time_ms > 350.0;

-- Pruebas metabólicas y de laboratorio
CREATE TABLE IF NOT EXISTS metabolic_lab_tests (
    id                    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    astronaut_id          uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    sampled_at            timestamptz NOT NULL,
    mission_day           integer,
    fasting_glucose_mg_dl numeric(5,1),
    hba1c_pct             numeric(4,2),
    CONSTRAINT uq_metabolic_time UNIQUE (astronaut_id, sampled_at)
);
CREATE INDEX IF NOT EXISTS idx_metabolic_timeline ON metabolic_lab_tests (astronaut_id, sampled_at DESC);
CREATE INDEX IF NOT EXISTS idx_metabolic_glucose  ON metabolic_lab_tests (astronaut_id, fasting_glucose_mg_dl) WHERE fasting_glucose_mg_dl IS NOT NULL;

-- Exámenes oftalmológicos avanzados y SANS (23 biomarcadores de retina / OCT)
CREATE TABLE IF NOT EXISTS ophthalmic_exams (
    id                        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    astronaut_id              uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    exam_date                 date NOT NULL,
    mission_day               integer,
    date_of_last_eye_exam     date,
    symptom_duration_weeks    numeric(4,1) NOT NULL DEFAULT 0.0,
    visual_acuity             text NOT NULL,       -- Snellen "20/40"
    near_vision_logmar        numeric(4,2),        -- logMAR conversion
    image_quality_score       numeric(5,3) NOT NULL,
    optic_disc_area           numeric(6,3) NOT NULL,
    optic_cup_area            numeric(6,3) NOT NULL,
    cup_to_disc_ratio         numeric(5,3) NOT NULL,
    intraocular_pressure_mmhg numeric(5,2) NOT NULL,
    macular_thickness_um      numeric(6,2) NOT NULL,
    rnfl_thickness_um         numeric(6,2) NOT NULL,
    vessel_tortuosity         numeric(6,4) NOT NULL,
    bifurcation_angle_deg     numeric(5,2) NOT NULL,
    faz_area_mm2              numeric(6,3) NOT NULL,
    texture_glcm_contrast     numeric(6,4) NOT NULL,
    texture_gabor_response    numeric(6,4) NOT NULL,
    deep_feature_1            numeric(7,4) NOT NULL,
    deep_feature_2            numeric(7,4) NOT NULL,
    deep_feature_3            numeric(7,4) NOT NULL,
    microaneurysms_count      numeric(4,0) NOT NULL DEFAULT 0,
    exudates_count            numeric(4,0) NOT NULL DEFAULT 0,
    hemorrhages_count         numeric(4,0) NOT NULL DEFAULT 0,
    retinal_disorder          integer NOT NULL,
    retinal_disorder_label    text NOT NULL,
    CONSTRAINT uq_ophthalmic_exam UNIQUE (astronaut_id, exam_date)
);
CREATE INDEX IF NOT EXISTS idx_ophthalmic_timeline ON ophthalmic_exams (astronaut_id, exam_date DESC);
CREATE INDEX IF NOT EXISTS idx_ophthalmic_disorder ON ophthalmic_exams (retinal_disorder_label);
CREATE INDEX IF NOT EXISTS idx_ophthalmic_sans     ON ophthalmic_exams (macular_thickness_um, rnfl_thickness_um);

-- Catálogo de indicadores médicos
CREATE TABLE IF NOT EXISTS indicators (
    id          text PRIMARY KEY,
    name        text NOT NULL,
    unit        text NOT NULL,
    system      body_system NOT NULL,
    alert_when  text NOT NULL CHECK (alert_when IN ('above', 'below', 'both')),
    valid_min   numeric NOT NULL,
    valid_max   numeric NOT NULL,
    how_to      text,
    why_space   text,
    CHECK (valid_min < valid_max)
);

-- Límites clínicos por indicador y entorno
CREATE TABLE IF NOT EXISTS thresholds (
    id                serial PRIMARY KEY,
    indicator_id      text NOT NULL REFERENCES indicators(id) ON DELETE CASCADE,
    body_state        body_state NOT NULL DEFAULT 'reposo',
    environment       environment,
    critico_low       numeric,
    atencion_low      numeric,
    atencion_high     numeric,
    critico_high      numeric,
    design_assumption boolean NOT NULL DEFAULT true,
    source            text NOT NULL,
    CHECK (critico_low  IS NULL OR atencion_low IS NULL OR critico_low  <= atencion_low),
    CHECK (atencion_low IS NULL OR atencion_high IS NULL OR atencion_low < atencion_high),
    CHECK (atencion_high IS NULL OR critico_high IS NULL OR atencion_high <= critico_high)
);
CREATE UNIQUE INDEX IF NOT EXISTS thresholds_env     ON thresholds (indicator_id, body_state, environment) WHERE environment IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS thresholds_generic ON thresholds (indicator_id, body_state)              WHERE environment IS NULL;

-- Mapa de peligros de vuelo espacial de la NASA (HRP)
CREATE TABLE IF NOT EXISTS indicator_hazards (
    indicator_id      text NOT NULL REFERENCES indicators(id) ON DELETE CASCADE,
    hazard            hazard NOT NULL,
    health_effect     text NOT NULL,
    preventive_action text NOT NULL,
    source            text,
    PRIMARY KEY (indicator_id, hazard)
);

-- Líneas base individuales prevuelo
CREATE TABLE IF NOT EXISTS baselines (
    astronaut_id uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    indicator_id text NOT NULL REFERENCES indicators(id) ON DELETE CASCADE,
    body_state   body_state NOT NULL DEFAULT 'reposo',
    low          numeric NOT NULL,
    high         numeric NOT NULL,
    computed_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (astronaut_id, indicator_id, body_state),
    CHECK (low <= high)
);

-- Mediciones de telemetría continuas (consumidas directamente por db.py y API)
CREATE TABLE IF NOT EXISTS measurements (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id    uuid NOT NULL UNIQUE,
    astronaut_id uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    indicator_id text NOT NULL REFERENCES indicators(id),
    body_state   body_state NOT NULL DEFAULT 'reposo',
    value        numeric NOT NULL,
    measured_at  timestamptz NOT NULL,
    mission_day  integer,
    environment  environment NOT NULL DEFAULT 'iss',
    status       health_status,
    note         text,
    synced_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS measurements_series ON measurements (astronaut_id, indicator_id, body_state, measured_at DESC);
CREATE INDEX IF NOT EXISTS measurements_day    ON measurements (astronaut_id, indicator_id, mission_day);

-- Alertas clínicas
CREATE TABLE IF NOT EXISTS alerts (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    astronaut_id    uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    measurement_id  bigint REFERENCES measurements(id) ON DELETE SET NULL,
    system          body_system NOT NULL,
    hazard          hazard,
    status          health_status NOT NULL CHECK (status <> 'nominal'),
    message         text NOT NULL,
    recommendation  text NOT NULL,
    escalate_to     escalation NOT NULL DEFAULT 'astronauta',
    in_summary      boolean NOT NULL DEFAULT false,
    created_at      timestamptz NOT NULL DEFAULT now(),
    acknowledged_at timestamptz,
    resolved_at     timestamptz
);
CREATE INDEX IF NOT EXISTS alerts_open ON alerts (astronaut_id, created_at DESC) WHERE resolved_at IS NULL;

-- Tareas de rutina
CREATE TABLE IF NOT EXISTS tasks (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id    uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    astronaut_id uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    kind         task_kind NOT NULL,
    indicator_id text REFERENCES indicators(id),
    title        text NOT NULL,
    detail       text,
    due_at       timestamptz NOT NULL,
    completed_at timestamptz,
    CHECK ((kind = 'medicion') = (indicator_id IS NOT NULL))
);
CREATE INDEX IF NOT EXISTS tasks_due ON tasks (astronaut_id, due_at);

-- Gamificación y eventos de puntos
CREATE TABLE IF NOT EXISTS badges (
    id          text PRIMARY KEY,
    name        text NOT NULL,
    description text NOT NULL
);

CREATE TABLE IF NOT EXISTS astronaut_badges (
    astronaut_id uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    badge_id     text NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    earned_at    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (astronaut_id, badge_id)
);

CREATE TABLE IF NOT EXISTS point_events (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    astronaut_id uuid NOT NULL REFERENCES astronauts(id) ON DELETE CASCADE,
    task_id      bigint REFERENCES tasks(id) ON DELETE SET NULL,
    points       integer NOT NULL,
    reason       text NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS point_events_astronaut ON point_events (astronaut_id, created_at);

-- =====================================================================
-- Funciones Auxiliares
-- =====================================================================
CREATE OR REPLACE FUNCTION ref.snellen_to_logmar(snellen text) RETURNS numeric
LANGUAGE sql IMMUTABLE RETURNS NULL ON NULL INPUT AS $$
    SELECT round(log(split_part(snellen, '/', 2)::numeric / split_part(snellen, '/', 1)::numeric), 2)
$$;

-- =====================================================================
-- Vistas Optimizadas de Alto Rendimiento
-- =====================================================================

-- Último valor por indicador para semáforo del panel
CREATE OR REPLACE VIEW latest_measurements AS
SELECT DISTINCT ON (astronaut_id, indicator_id, body_state) *
FROM measurements
ORDER BY astronaut_id, indicator_id, body_state, measured_at DESC;

-- Vista 360 de resumen del tripulante: un único registro ultra rápido
CREATE OR REPLACE VIEW v_astronaut_summary AS
SELECT
    a.id AS astronaut_id,
    a.patient_id,
    a.name,
    a.role,
    a.age,
    a.gender,
    a.sex,
    a.height_m,
    c.risk_category,
    c.smoking_status,
    c.medications,
    bc.weight_kg AS latest_weight_kg,
    bc.bmi AS latest_bmi,
    bc.fat_percentage AS latest_fat_percentage,
    vs.heart_rate AS latest_heart_rate,
    vs.derived_hrv_s AS latest_hrv_s,
    vs.body_temperature_c AS latest_temp_c,
    vs.oxygen_saturation_pct AS latest_spo2_pct,
    vs.respiratory_rate_bpm AS latest_resp_rate,
    hm.systolic_bp AS latest_systolic_bp,
    hm.diastolic_bp AS latest_diastolic_bp,
    sm.sleep_hours AS latest_sleep_hours,
    sm.stress_level AS latest_stress_level,
    sm.water_intake_liters AS latest_water_liters,
    ex.workout_type AS latest_workout_type,
    oe.retinal_disorder_label AS ophthalmic_status,
    oe.macular_thickness_um AS baseline_macular_thickness,
    oe.rnfl_thickness_um AS baseline_rnfl_thickness,
    oe.intraocular_pressure_mmhg AS baseline_iop
FROM astronauts a
LEFT JOIN astronaut_clinical_history c ON c.astronaut_id = a.id
LEFT JOIN LATERAL (
    SELECT weight_kg, bmi, fat_percentage FROM body_composition
    WHERE astronaut_id = a.id ORDER BY measured_at DESC LIMIT 1
) bc ON true
LEFT JOIN LATERAL (
    SELECT heart_rate, derived_hrv_s, body_temperature_c, oxygen_saturation_pct, respiratory_rate_bpm
    FROM vital_signs WHERE astronaut_id = a.id ORDER BY measured_at DESC LIMIT 1
) vs ON true
LEFT JOIN LATERAL (
    SELECT systolic_bp, diastolic_bp FROM hemodynamics
    WHERE astronaut_id = a.id ORDER BY measured_at DESC LIMIT 1
) hm ON true
LEFT JOIN LATERAL (
    SELECT sleep_hours, stress_level, water_intake_liters FROM sleep_mental_logs
    WHERE astronaut_id = a.id ORDER BY logged_at DESC LIMIT 1
) sm ON true
LEFT JOIN LATERAL (
    SELECT workout_type FROM exercise_sessions
    WHERE astronaut_id = a.id ORDER BY started_at DESC LIMIT 1
) ex ON true
LEFT JOIN LATERAL (
    SELECT retinal_disorder_label, macular_thickness_um, rnfl_thickness_um, intraocular_pressure_mmhg
    FROM ophthalmic_exams WHERE astronaut_id = a.id ORDER BY exam_date DESC LIMIT 1
) oe ON true;

-- Vista de seguimiento diario consolidado
CREATE OR REPLACE VIEW v_daily_health_overview AS
SELECT
    a.id AS astronaut_id,
    a.patient_id,
    bc.mission_day,
    bc.measured_at::date AS record_date,
    bc.weight_kg,
    bc.bmi,
    bc.fat_percentage,
    vs.heart_rate,
    vs.derived_hrv_s,
    vs.body_temperature_c,
    vs.oxygen_saturation_pct,
    vs.respiratory_rate_bpm,
    hm.systolic_bp,
    hm.diastolic_bp,
    hm.derived_pulse_pressure,
    hm.derived_map,
    sm.sleep_hours,
    sm.sleep_quality_score,
    sm.daytime_sleepiness,
    sm.stress_level,
    sm.emotion_regulation_score,
    sm.water_intake_liters,
    sm.caffeine_intake_cups_day,
    ex.workout_type,
    ex.minutes AS exercise_minutes,
    ex.calories_burned,
    cog.pvt_reaction_time_ms,
    cog.n_back_accuracy_pct,
    cog.stroop_task_reaction_time_s,
    lab.fasting_glucose_mg_dl,
    lab.hba1c_pct
FROM body_composition bc
JOIN astronauts a ON a.id = bc.astronaut_id
LEFT JOIN vital_signs vs ON vs.astronaut_id = bc.astronaut_id AND vs.measured_at = bc.measured_at
LEFT JOIN hemodynamics hm ON hm.astronaut_id = bc.astronaut_id AND hm.measured_at = bc.measured_at
LEFT JOIN sleep_mental_logs sm ON sm.astronaut_id = bc.astronaut_id AND sm.logged_at = bc.measured_at
LEFT JOIN exercise_sessions ex ON ex.astronaut_id = bc.astronaut_id AND ex.started_at = bc.measured_at
LEFT JOIN cognitive_assessments cog ON cog.astronaut_id = bc.astronaut_id AND cog.tested_at = bc.measured_at
LEFT JOIN metabolic_lab_tests lab ON lab.astronaut_id = bc.astronaut_id AND lab.sampled_at = bc.measured_at;

-- Vista de progreso clínico de SANS vs línea base
CREATE OR REPLACE VIEW v_sans_monitoring AS
SELECT
    a.id AS astronaut_id,
    a.patient_id,
    oe.exam_date,
    oe.mission_day,
    oe.visual_acuity,
    oe.near_vision_logmar,
    oe.macular_thickness_um,
    oe.rnfl_thickness_um,
    oe.intraocular_pressure_mmhg,
    oe.cup_to_disc_ratio,
    oe.retinal_disorder_label,
    ROUND(oe.macular_thickness_um - COALESCE(b.low, oe.macular_thickness_um), 2) AS macular_delta_um,
    CASE
        WHEN (oe.macular_thickness_um - COALESCE(b.low, oe.macular_thickness_um)) >= 55.0 THEN 'critico'
        WHEN (oe.macular_thickness_um - COALESCE(b.low, oe.macular_thickness_um)) >= 20.0 THEN 'atencion'
        ELSE 'nominal'
    END AS sans_status
FROM ophthalmic_exams oe
JOIN astronauts a ON a.id = oe.astronaut_id
LEFT JOIN baselines b ON b.astronaut_id = a.id AND b.indicator_id = 'macular_thickness';

-- Resumen estadístico poblacional de referencia (p05, mediana, p95)
CREATE OR REPLACE VIEW ref.dataset_summary AS
SELECT
    metric,
    COUNT(*) AS total_samples,
    ROUND(AVG(val)::numeric, 2) AS mean_value,
    ROUND(percentile_cont(0.05) WITHIN GROUP (ORDER BY val)::numeric, 2) AS p05,
    ROUND(percentile_cont(0.50) WITHIN GROUP (ORDER BY val)::numeric, 2) AS p50_median,
    ROUND(percentile_cont(0.95) WITHIN GROUP (ORDER BY val)::numeric, 2) AS p95,
    ROUND(MIN(val)::numeric, 2) AS min_value,
    ROUND(MAX(val)::numeric, 2) AS max_value
FROM ref.dataset_raw r
CROSS JOIN LATERAL (VALUES
    ('heart_rate', r.heart_rate),
    ('systolic_bp', r.systolic_bp),
    ('diastolic_bp', r.diastolic_bp),
    ('oxygen_saturation_pct', r.oxygen_saturation_pct),
    ('body_temperature_c', r.body_temperature_c),
    ('respiratory_rate_bpm', r.respiratory_rate_bpm),
    ('derived_hrv_s', r.derived_hrv_s),
    ('sleep_hours', r.sleep_hours),
    ('stress_level', r.stress_level),
    ('water_intake_liters', r.water_intake_liters),
    ('pvt_reaction_time_ms', r.pvt_reaction_time_ms),
    ('macular_thickness_um', r.macular_thickness_um),
    ('rnfl_thickness_um', r.rnfl_thickness_um),
    ('intraocular_pressure_mmhg', r.intraocular_pressure_mmhg)
) AS m(metric, val)
WHERE val IS NOT NULL
GROUP BY metric;

-- =====================================================================
-- Catálogo de Indicadores de Salud (Completo)
-- =====================================================================
INSERT INTO indicators (id, name, unit, system, alert_when, valid_min, valid_max, how_to, why_space) VALUES
    ('systolic',         'Presión sistólica',              'mmHg',  'cardio', 'above',  50, 260, 'Manguito braquial automático a nivel del corazón.', 'El desplazamiento cefálico de fluidos altera el tono vascular.'),
    ('diastolic',        'Presión diastólica',             'mmHg',  'cardio', 'above',  30, 160, 'Manguito braquial automático.', 'Cambios en la resistencia periférica total en ingravidez.'),
    ('heart_rate',       'Frecuencia cardiaca',            'lpm',   'cardio', 'both',   20, 230, 'Pulsioxímetro o monitor continuo.', 'Modificación autonómica y menor demanda gravitacional.'),
    ('respiratory_rate', 'Frecuencia respiratoria',        'rpm',   'cardio', 'both',    4,  60, 'Sensores acústicos o banda torácica.', 'Sensible a cambios en CO2 y ventilación en hábitat cerrado.'),
    ('spo2',             'SpO₂',                           '%',     'cardio', 'below',  50, 100, 'Pulsioximetría en reposo.', 'Crucial para monitorizar atmósfera y función pulmonar.'),
    ('hrv',              'Variabilidad de FC',             's',     'cardio', 'below',   0,   1, 'Cálculo electrocardiográfico RMSSD.', 'Biomarcador directo de fatiga y balance autonómico simpático/vagal.'),
    ('temperature',      'Temperatura corporal',           '°C',    'inmune', 'both',   30,  44, 'Termómetro timpánico o sensor dérmico.', 'La desregulación térmica y "fiebre espacial" ocurren por menor convección.'),
    ('retinal_delta',    'Grosor retiniano vs. base',      'µm',    'ojos',   'above', -100, 300, 'OCT guiado a bordo comparado contra escaneo prevuelo.', 'Edema de disco óptico y pliegues coroideos en SANS.'),
    ('macular_thickness','Grosor macular',                 'µm',    'ojos',   'above', 150, 600, 'OCT a bordo operado por CMO.', 'Desplazamiento venoso cefálico puede generar edema macular.'),
    ('rnfl_thickness',   'Capa de fibras nerviosas (RNFL)','µm',    'ojos',   'both',   20, 200, 'OCT peripapilar alrededor del nervio óptico.', 'Primer signo objetivo de edema de papila en SANS.'),
    ('intraocular_pressure','Presión intraocular',         'mmHg',  'ojos',   'both',    0,  60, 'Tonómetro de rebote a bordo.', 'Cambios en gradiente translámina cribosa en microgravedad.'),
    ('cup_to_disc_ratio','Relación copa/disco',            'ratio', 'ojos',   'both',    0,   1, 'Fondo de ojo digital o tomografía.', 'Indicador anatómico secundario de neuropatía óptica.'),
    ('near_vision_logmar','Visión cercana (autoprueba)',   'logMAR','ojos',   'above', -0.3, 2.0, 'Carta de visión cercana a 40 cm.', 'Pérdida de acomodación hipermetrópica adquirida en vuelo.'),
    ('body_mass',        'Masa corporal',                  'kg',    'hueso',  'below',  30, 200, 'Dispositivo de medición de masa por oscilación inercial (SLAMMD).', 'Atrofia muscular y balance calórico negativo en microgravedad.'),
    ('sleep_hours',      'Horas de sueño',                 'h',     'mente',  'below',   0,  24, 'Actigrafía continua de muñeca.', 'Alteración del ritmo circadiano (16 amaneceres/día en LEO).'),
    ('pvt_ms',           'Tiempo de reacción (PVT)',       'ms',    'mente',  'above', 100, 2000,'Prueba psicomotora de 3–5 min en tableta.', 'Monitoreo de fatiga cognitiva y lentitud psicomotora.'),
    ('fasting_glucose',  'Glucosa en ayuno',               'mg/dL', 'inmune', 'both',   40, 400, 'Analizador de sangre capilar a bordo.', 'Resistencia a la insulina inducida por microgravedad e inactividad.'),
    ('hba1c',            'HbA1c',                          '%',     'inmune', 'above',   3,  15, 'Cartucho de bioquímica seca a bordo.', 'Control glucémico a mediano plazo en misiones de exploración.'),
    ('stress_level',     'Nivel de estrés',                'pts',   'mente',  'above',   1,  10, 'Autorreporte psicológico diario.', 'Evaluación del impacto de confinamiento y aislamiento extremo.'),
    ('water_intake',     'Consumo de agua',                'L',     'cardio', 'below', 0.5,  10, 'Registro en dispensador de agua potable.', 'Prevención de deshidratación y nefrolitiasis en vuelo.')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    unit = EXCLUDED.unit,
    system = EXCLUDED.system,
    alert_when = EXCLUDED.alert_when,
    how_to = EXCLUDED.how_to,
    why_space = EXCLUDED.why_space;

-- Umbrales Clínicos (Respaldos terrestres y umbral publicado de SANS)
INSERT INTO thresholds (indicator_id, atencion_low, atencion_high, critico_low, critico_high, design_assumption, source) VALUES
    ('systolic',             NULL, 130,  NULL, 160, true,  'Supuesto de diseño con respaldo clínico terrestre.'),
    ('diastolic',            NULL,  85,  NULL, 100, true,  'Supuesto de diseño con respaldo clínico terrestre.'),
    ('heart_rate',             50, 100,    40, 120, true,  'Supuesto de diseño: taquicardia o bradicardia sostenida.'),
    ('spo2',                   95, NULL,   92, NULL, true,  'Límite de hipoxia en cabina.'),
    ('temperature',          NULL, 37.5, 35.0, 38.3, true,  'Fiebre espacial e hipotermia.'),
    ('respiratory_rate',        8,  20,     6,  25, true,  'Taquipnea o bradipnea.'),
    ('sleep_hours',           6.0, NULL,  4.5, NULL, true,  'Déficit crítico de sueño.'),
    ('pvt_ms',               NULL, 350,  NULL, 500, true,  'Lentitud de respuesta psicomotora.'),
    ('retinal_delta',        NULL,  20,  NULL,  55, false, 'Umbrales publicados de SANS (NASA HRP). 20 µm primer signo, 55 µm clínico.'),
    ('intraocular_pressure',   10,  21,     8,  25, true,  'Rango clínico terrestre habitual.'),
    ('fasting_glucose',        70, 100,    55, 126, true,  'Criterios de glucemia en ayuno ADA.'),
    ('hba1c',                NULL, 5.7,  NULL, 6.5, true,  'Límites de prediabetes/diabetes.'),
    ('stress_level',         NULL, 6.5,  NULL, 8.0, true,  'Escala de estrés sostenido.'),
    ('water_intake',          2.0, NULL,  1.5, NULL, true,  'Riesgo de litiasis renal en el espacio.')
ON CONFLICT (indicator_id, body_state) WHERE environment IS NULL DO UPDATE SET
    atencion_low = EXCLUDED.atencion_low,
    atencion_high = EXCLUDED.atencion_high,
    critico_low = EXCLUDED.critico_low,
    critico_high = EXCLUDED.critico_high,
    design_assumption = EXCLUDED.design_assumption,
    source = EXCLUDED.source;

-- Mapa de peligros espaciales para nuevos indicadores
INSERT INTO indicator_hazards (indicator_id, hazard, health_effect, preventive_action, source) VALUES
    ('retinal_delta',    'gravedad', 'Edema del nervio óptico y engrosamiento retiniano (SANS).', 'OCT periódico y comparación con baseline prevuelo.', 'NASA HRP Risk of SANS'),
    ('systolic',         'gravedad', 'Desacondicionamiento cardiovascular y sobrecarga cefálica.', 'Protocolo de ejercicio diario y prendas de compresión.', 'NASA HRP Cardiovascular'),
    ('water_intake',     'ambiente_hostil', 'Mayor riesgo de formación de cálculos renales por resorción ósea.', 'Meta de hidratación diaria estricta (>2.5 L).', 'NASA HRP Renal Stone Risk'),
    ('pvt_ms',           'aislamiento', 'Deterioro de la atención por desajuste circadiano y estrés.', 'Higiene de sueño, espectro de luz regulado y descanso.', 'NASA HRP Sleep and Fatigue')
ON CONFLICT (indicator_id, hazard) DO NOTHING;

COMMIT;
