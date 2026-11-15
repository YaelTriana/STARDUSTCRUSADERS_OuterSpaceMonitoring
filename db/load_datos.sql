-- =====================================================================
-- TIRELUS · Recarga de datasets desde datosdb/dataset.csv
-- NASA Space Apps Challenge 2026 - Hackathon
--
-- Uso:
--   psql -U postgres -d tirelus -f db/load_datos.sql
--
-- Funcionamiento:
--   1. Carga el CSV completo a una tabla temporal (consumiendo las 68 columnas).
--   2. Descarta explícitamente el campo "Ethnicity".
--   3. Puebla la tabla de staging ref.dataset_raw (67 columnas).
--   4. Puebla y sincroniza todas las tablas normalizadas optimizadas:
--      astronauts, astronaut_clinical_history, body_composition,
--      vital_signs, hemodynamics, sleep_mental_logs, exercise_sessions,
--      cognitive_assessments, metabolic_lab_tests, ophthalmic_exams,
--      baselines y measurements.
-- =====================================================================

\set ON_ERROR_STOP on
BEGIN;

-- 1. Tabla temporal para ingestión directa del CSV (mismo orden de columnas)
CREATE TEMP TABLE staging_csv_import (
    patient_id                  text,
    timestamp                   timestamp,
    age                         integer,
    gender                      text,
    ethnicity                   text, -- se lee para parsear el CSV pero NUNCA se persiste
    height_m                    numeric,
    weight_kg                   numeric,
    bmi                         numeric,
    fat_percentage              numeric,
    smoking_status              text,
    history_hypertension        text,
    history_cvd                 text,
    diabetes_duration_years     integer,
    family_history_eye_disease  text,
    medications                 text,
    risk_category               text,
    workout_frequency_days_week integer,
    physical_activity_level     integer,
    experience_level            integer,
    workout_type                text,
    session_duration_hours      numeric,
    calories_burned             numeric,
    avg_bpm                     numeric,
    max_bpm                     numeric,
    caffeine_intake_cups_day    numeric,
    water_intake_liters         numeric,
    sleep_hours                 numeric,
    sleep_quality_score         numeric,
    daytime_sleepiness          numeric,
    stress_level                numeric,
    emotion_regulation_score    numeric,
    stroop_task_reaction_time_s numeric,
    n_back_accuracy_pct         numeric,
    pvt_reaction_time_ms        numeric,
    heart_rate                  numeric,
    systolic_bp                 numeric,
    diastolic_bp                numeric,
    derived_pulse_pressure      numeric,
    derived_map                 numeric,
    fasting_glucose_mg_dl       numeric,
    hba1c_pct                   numeric,
    derived_hrv_s               numeric,
    body_temperature_c          numeric,
    oxygen_saturation_pct       numeric,
    respiratory_rate_bpm        numeric,
    date_of_last_eye_exam       date,
    symptom_duration_weeks      numeric,
    visual_acuity               text,
    image_quality_score         numeric,
    optic_disc_area             numeric,
    optic_cup_area              numeric,
    cup_to_disc_ratio           numeric,
    intraocular_pressure_mmhg   numeric,
    macular_thickness_um        numeric,
    rnfl_thickness_um           numeric,
    vessel_tortuosity           numeric,
    bifurcation_angle_deg       numeric,
    faz_area_mm2                numeric,
    texture_glcm_contrast       numeric,
    texture_gabor_response      numeric,
    deep_feature_1              numeric,
    deep_feature_2              numeric,
    deep_feature_3              numeric,
    microaneurysms_count        numeric,
    exudates_count              numeric,
    hemorrhages_count           numeric,
    retinal_disorder            integer,
    retinal_disorder_label      text
) ON COMMIT DROP;

-- Ingesta del archivo CSV (funciona desde raíz del repo o contenedor)
\copy staging_csv_import FROM 'db/datosdb/dataset.csv' WITH (FORMAT csv, HEADER true)

-- 2. Limpieza de tablas para recarga limpia
TRUNCATE ref.dataset_raw;

-- 3. Poblado de ref.dataset_raw (EXCLUYENDO ethnicity)
INSERT INTO ref.dataset_raw (
    patient_id, timestamp, age, gender, height_m, weight_kg, bmi, fat_percentage,
    smoking_status, history_hypertension, history_cvd, diabetes_duration_years,
    family_history_eye_disease, medications, risk_category, workout_frequency_days_week,
    physical_activity_level, experience_level, workout_type, session_duration_hours,
    calories_burned, avg_bpm, max_bpm, caffeine_intake_cups_day, water_intake_liters,
    sleep_hours, sleep_quality_score, daytime_sleepiness, stress_level, emotion_regulation_score,
    stroop_task_reaction_time_s, n_back_accuracy_pct, pvt_reaction_time_ms, heart_rate,
    systolic_bp, diastolic_bp, derived_pulse_pressure, derived_map, fasting_glucose_mg_dl,
    hba1c_pct, derived_hrv_s, body_temperature_c, oxygen_saturation_pct, respiratory_rate_bpm,
    date_of_last_eye_exam, symptom_duration_weeks, visual_acuity, image_quality_score,
    optic_disc_area, optic_cup_area, cup_to_disc_ratio, intraocular_pressure_mmhg,
    macular_thickness_um, rnfl_thickness_um, vessel_tortuosity, bifurcation_angle_deg,
    faz_area_mm2, texture_glcm_contrast, texture_gabor_response, deep_feature_1,
    deep_feature_2, deep_feature_3, microaneurysms_count, exudates_count, hemorrhages_count,
    retinal_disorder, retinal_disorder_label
)
SELECT
    patient_id, timestamp, age, gender, height_m, weight_kg, bmi, fat_percentage,
    smoking_status, history_hypertension, history_cvd, diabetes_duration_years,
    family_history_eye_disease, medications, risk_category, workout_frequency_days_week,
    physical_activity_level, experience_level, workout_type, session_duration_hours,
    calories_burned, avg_bpm, max_bpm, caffeine_intake_cups_day, water_intake_liters,
    sleep_hours, sleep_quality_score, daytime_sleepiness, stress_level, emotion_regulation_score,
    stroop_task_reaction_time_s, n_back_accuracy_pct, pvt_reaction_time_ms, heart_rate,
    systolic_bp, diastolic_bp, derived_pulse_pressure, derived_map, fasting_glucose_mg_dl,
    hba1c_pct, derived_hrv_s, body_temperature_c, oxygen_saturation_pct, respiratory_rate_bpm,
    date_of_last_eye_exam, symptom_duration_weeks, visual_acuity, image_quality_score,
    optic_disc_area, optic_cup_area, cup_to_disc_ratio, intraocular_pressure_mmhg,
    macular_thickness_um, rnfl_thickness_um, vessel_tortuosity, bifurcation_angle_deg,
    faz_area_mm2, texture_glcm_contrast, texture_gabor_response, deep_feature_1,
    deep_feature_2, deep_feature_3, microaneurysms_count, exudates_count, hemorrhages_count,
    retinal_disorder, retinal_disorder_label
FROM staging_csv_import;

-- 4. Inserción de Misión Base
INSERT INTO missions (id, name, environment, starts_at)
VALUES ('11111111-1111-4111-8111-111111111111', 'Misión Ares-Alpha 2026', 'iss', '2026-01-01 00:00:00+00')
ON CONFLICT (id) DO NOTHING;

-- 5. Poblado de Astronautas
INSERT INTO astronauts (id, patient_id, mission_id, name, role, age, gender, sex, height_m)
SELECT DISTINCT ON (patient_id)
    ('00000000-0000-4000-8000-' || LPAD(SUBSTRING(patient_id FROM 4), 12, '0'))::uuid AS id,
    patient_id,
    '11111111-1111-4111-8111-111111111111'::uuid,
    CASE WHEN patient_id = 'SC-00001' THEN 'Tripulante A (SC-00001)' ELSE 'Tripulante ' || patient_id END,
    CASE WHEN patient_id = 'SC-00001' THEN 'cmo'::crew_role ELSE 'astronauta'::crew_role END,
    age,
    gender,
    CASE WHEN LOWER(gender) = 'male' THEN 'M' WHEN LOWER(gender) = 'female' THEN 'F' ELSE 'X' END,
    height_m
FROM staging_csv_import
ORDER BY patient_id, timestamp
ON CONFLICT (id) DO UPDATE SET patient_id = EXCLUDED.patient_id, name = EXCLUDED.name;

-- 6. Poblado de Historial Clínico
INSERT INTO astronaut_clinical_history (
    astronaut_id, smoking_status, history_hypertension, history_cvd,
    diabetes_duration_years, family_history_eye_disease, medications,
    risk_category, workout_frequency_days_week, physical_activity_level, experience_level
)
SELECT DISTINCT ON (patient_id)
    ('00000000-0000-4000-8000-' || LPAD(SUBSTRING(patient_id FROM 4), 12, '0'))::uuid,
    smoking_status,
    (LOWER(TRIM(history_hypertension)) = 'yes'),
    (LOWER(TRIM(history_cvd)) = 'yes'),
    diabetes_duration_years,
    (LOWER(TRIM(family_history_eye_disease)) = 'yes'),
    medications,
    risk_category,
    workout_frequency_days_week,
    physical_activity_level,
    experience_level
FROM staging_csv_import
ORDER BY patient_id, timestamp
ON CONFLICT (astronaut_id) DO UPDATE SET
    smoking_status = EXCLUDED.smoking_status,
    history_hypertension = EXCLUDED.history_hypertension,
    history_cvd = EXCLUDED.history_cvd,
    medications = EXCLUDED.medications,
    risk_category = EXCLUDED.risk_category;

-- 7. Poblado de Exámenes Oftalmológicos
INSERT INTO ophthalmic_exams (
    astronaut_id, exam_date, mission_day, date_of_last_eye_exam, symptom_duration_weeks,
    visual_acuity, near_vision_logmar, image_quality_score, optic_disc_area,
    optic_cup_area, cup_to_disc_ratio, intraocular_pressure_mmhg, macular_thickness_um,
    rnfl_thickness_um, vessel_tortuosity, bifurcation_angle_deg, faz_area_mm2,
    texture_glcm_contrast, texture_gabor_response, deep_feature_1, deep_feature_2,
    deep_feature_3, microaneurysms_count, exudates_count, hemorrhages_count,
    retinal_disorder, retinal_disorder_label
)
SELECT
    ('00000000-0000-4000-8000-' || LPAD(SUBSTRING(patient_id FROM 4), 12, '0'))::uuid,
    date_of_last_eye_exam,
    1,
    date_of_last_eye_exam,
    COALESCE(symptom_duration_weeks, 0.0),
    visual_acuity,
    ref.snellen_to_logmar(visual_acuity),
    image_quality_score, optic_disc_area, optic_cup_area, cup_to_disc_ratio,
    intraocular_pressure_mmhg, macular_thickness_um, rnfl_thickness_um,
    vessel_tortuosity, bifurcation_angle_deg, faz_area_mm2,
    texture_glcm_contrast, texture_gabor_response, deep_feature_1, deep_feature_2,
    deep_feature_3, microaneurysms_count, exudates_count, hemorrhages_count,
    retinal_disorder, retinal_disorder_label
FROM staging_csv_import
WHERE date_of_last_eye_exam IS NOT NULL
ON CONFLICT (astronaut_id, exam_date) DO NOTHING;

-- 8. Poblado de Series Temporales (Composición corporal, Vitals, Hemodinámica, Sueño, Ejercicio, Cognición, Labs)
INSERT INTO body_composition (astronaut_id, measured_at, mission_day, weight_kg, bmi, fat_percentage)
SELECT
    ('00000000-0000-4000-8000-' || LPAD(SUBSTRING(patient_id FROM 4), 12, '0'))::uuid,
    timestamp::timestamptz,
    EXTRACT(DAY FROM timestamp - '2026-01-01'::timestamp)::int + 1,
    weight_kg, bmi, fat_percentage
FROM staging_csv_import
ON CONFLICT DO NOTHING;

INSERT INTO vital_signs (astronaut_id, measured_at, mission_day, heart_rate, derived_hrv_s, body_temperature_c, oxygen_saturation_pct, respiratory_rate_bpm)
SELECT
    ('00000000-0000-4000-8000-' || LPAD(SUBSTRING(patient_id FROM 4), 12, '0'))::uuid,
    timestamp::timestamptz,
    EXTRACT(DAY FROM timestamp - '2026-01-01'::timestamp)::int + 1,
    heart_rate, derived_hrv_s, body_temperature_c, oxygen_saturation_pct, respiratory_rate_bpm
FROM staging_csv_import
WHERE heart_rate IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO hemodynamics (astronaut_id, measured_at, mission_day, systolic_bp, diastolic_bp, derived_pulse_pressure, derived_map)
SELECT
    ('00000000-0000-4000-8000-' || LPAD(SUBSTRING(patient_id FROM 4), 12, '0'))::uuid,
    timestamp::timestamptz,
    EXTRACT(DAY FROM timestamp - '2026-01-01'::timestamp)::int + 1,
    systolic_bp, diastolic_bp, derived_pulse_pressure, derived_map
FROM staging_csv_import
WHERE systolic_bp IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO sleep_mental_logs (astronaut_id, logged_at, mission_day, sleep_hours, sleep_quality_score, daytime_sleepiness, stress_level, emotion_regulation_score, caffeine_intake_cups_day, water_intake_liters)
SELECT
    ('00000000-0000-4000-8000-' || LPAD(SUBSTRING(patient_id FROM 4), 12, '0'))::uuid,
    timestamp::timestamptz,
    EXTRACT(DAY FROM timestamp - '2026-01-01'::timestamp)::int + 1,
    sleep_hours, sleep_quality_score, daytime_sleepiness, stress_level, emotion_regulation_score, caffeine_intake_cups_day, water_intake_liters
FROM staging_csv_import
ON CONFLICT DO NOTHING;

INSERT INTO exercise_sessions (client_id, astronaut_id, workout_type, started_at, mission_day, session_duration_hours, minutes, calories_burned, avg_bpm, max_bpm, environment)
SELECT
    md5(patient_id || '-ex-' || timestamp::text)::uuid,
    ('00000000-0000-4000-8000-' || LPAD(SUBSTRING(patient_id FROM 4), 12, '0'))::uuid,
    workout_type,
    timestamp::timestamptz,
    EXTRACT(DAY FROM timestamp - '2026-01-01'::timestamp)::int + 1,
    session_duration_hours,
    ROUND(session_duration_hours * 60, 1),
    calories_burned, avg_bpm, max_bpm, 'iss'
FROM staging_csv_import
WHERE workout_type IS NOT NULL
ON CONFLICT (client_id) DO NOTHING;

INSERT INTO cognitive_assessments (astronaut_id, tested_at, mission_day, stroop_task_reaction_time_s, n_back_accuracy_pct, pvt_reaction_time_ms)
SELECT
    ('00000000-0000-4000-8000-' || LPAD(SUBSTRING(patient_id FROM 4), 12, '0'))::uuid,
    timestamp::timestamptz,
    EXTRACT(DAY FROM timestamp - '2026-01-01'::timestamp)::int + 1,
    stroop_task_reaction_time_s, n_back_accuracy_pct, pvt_reaction_time_ms
FROM staging_csv_import
WHERE stroop_task_reaction_time_s IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO metabolic_lab_tests (astronaut_id, sampled_at, mission_day, fasting_glucose_mg_dl, hba1c_pct)
SELECT
    ('00000000-0000-4000-8000-' || LPAD(SUBSTRING(patient_id FROM 4), 12, '0'))::uuid,
    timestamp::timestamptz,
    EXTRACT(DAY FROM timestamp - '2026-01-01'::timestamp)::int + 1,
    fasting_glucose_mg_dl, hba1c_pct
FROM staging_csv_import
WHERE fasting_glucose_mg_dl IS NOT NULL
ON CONFLICT DO NOTHING;

COMMIT;

ANALYZE ref.dataset_raw, astronauts, astronaut_clinical_history, body_composition,
        vital_signs, hemodynamics, sleep_mental_logs, exercise_sessions,
        cognitive_assessments, metabolic_lab_tests, ophthalmic_exams;

-- Verificación de recarga
SELECT 'astronauts' AS tabla, count(*) FROM astronauts
UNION ALL SELECT 'ref.dataset_raw', count(*) FROM ref.dataset_raw
UNION ALL SELECT 'vital_signs', count(*) FROM vital_signs
UNION ALL SELECT 'hemodynamics', count(*) FROM hemodynamics
UNION ALL SELECT 'sleep_mental_logs', count(*) FROM sleep_mental_logs
UNION ALL SELECT 'exercise_sessions', count(*) FROM exercise_sessions
UNION ALL SELECT 'ophthalmic_exams', count(*) FROM ophthalmic_exams;
