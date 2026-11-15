-- TIRELUS · ojos (SANS): grosor macular, RNFL, autoprueba de visión cercana e indicadores secundarios.
-- Correr después de schema.sql y antes de load_datos.sql:
--   psql -U postgres -d tirelus -f db/002_ojos.sql
-- shortcut: sin lateralidad (OD/OS); el dataset trae un valor por paciente. Agregar columna `eye`
-- a measurements y baselines cuando la app capture cada ojo.

BEGIN;

-- retinal_disorders_dataset.csv completo (columnas en el orden del CSV para \copy).
-- OJO: las columnas no cambian entre clases de retinal_disorder → solo población de referencia,
-- nunca para entrenar un clasificador (además la app no diagnostica).
CREATE TABLE IF NOT EXISTS ref.retinal (
    optic_disc_area            numeric,
    optic_cup_area             numeric,
    cup_to_disc_ratio          numeric,
    exudates_count             numeric,
    hemorrhages_count          numeric,
    microaneurysms_count       numeric,
    vessel_tortuosity          numeric,
    bifurcation_angle          numeric,
    faz_area                   numeric,
    macular_thickness          numeric,   -- µm
    rnfl_thickness             numeric,   -- µm, capa de fibras nerviosas
    texture_glcm_contrast      numeric,
    texture_gabor_response     numeric,
    deep_feature_1             numeric,
    deep_feature_2             numeric,
    deep_feature_3             numeric,
    image_quality_score        numeric,   -- 0–1
    patient_id                 bigint PRIMARY KEY,
    age                        numeric,
    gender                     text,
    systolic_bp                numeric,
    diastolic_bp               numeric,
    bmi                        numeric,
    fasting_glucose            numeric,
    hba1c                      numeric,
    diabetes_duration          numeric,
    history_hypertension       text,
    history_cvd                text,
    smoking_status             text,
    family_history_eye_disease text,
    visual_acuity              text,      -- Snellen "20/40"
    intraocular_pressure       numeric,   -- mmHg
    medications                text,
    ethnicity                  text,
    last_eye_exam              date,
    symptom_duration_weeks     numeric,
    retinal_disorder           integer
);

-- Snellen "20/40" → logMAR 0.30 (0 = normal; +0.1 = una línea peor).
CREATE OR REPLACE FUNCTION ref.snellen_to_logmar(snellen text) RETURNS numeric
LANGUAGE sql IMMUTABLE RETURNS NULL ON NULL INPUT AS $$
    SELECT round(log(split_part(snellen, '/', 2)::numeric / split_part(snellen, '/', 1)::numeric), 2)
$$;

-- Rango poblacional de cada indicador de ojos (p05–p95). Supuesto de diseño.
CREATE OR REPLACE VIEW ref.eye_reference AS
SELECT v.indicator_id,
       count(*)                                                      AS n,
       percentile_cont(0.05) WITHIN GROUP (ORDER BY v.value::float8) AS p05,
       percentile_cont(0.50) WITHIN GROUP (ORDER BY v.value::float8) AS p50,
       percentile_cont(0.95) WITHIN GROUP (ORDER BY v.value::float8) AS p95
FROM ref.retinal r
CROSS JOIN LATERAL (VALUES
    ('macular_thickness',    r.macular_thickness),
    ('rnfl_thickness',       r.rnfl_thickness),
    ('near_vision_logmar',   ref.snellen_to_logmar(r.visual_acuity)),
    ('intraocular_pressure', r.intraocular_pressure),
    ('cup_to_disc_ratio',    r.cup_to_disc_ratio)
) AS v(indicator_id, value)
WHERE v.value IS NOT NULL
GROUP BY v.indicator_id;

-- ---------- Catálogo ----------
INSERT INTO indicators (id, name, unit, system, alert_when, valid_min, valid_max, how_to, why_space) VALUES
    ('macular_thickness', 'Grosor macular', 'µm', 'ojos', 'above', 150, 600,
     'Lo mide el OCT a bordo: el CMO opera y TIRELUS guía la posición. Una lectura por ciclo de OCT.',
     'El desplazamiento de líquidos hacia la cabeza puede engrosar la retina (pliegues coroideos, edema).'),
    ('rnfl_thickness', 'Capa de fibras nerviosas (RNFL)', 'µm', 'ojos', 'both', 20, 200,
     'Lo mide el OCT alrededor del nervio óptico, en la misma sesión que el grosor macular.',
     'Si aumenta, puede indicar edema del disco óptico, uno de los signos de SANS.'),
    ('near_vision_logmar', 'Visión cercana (autoprueba)', 'logMAR', 'ojos', 'above', -0.3, 2.0,
     'Cada semana: carta de visión cercana a 40 cm, un ojo a la vez, con buena luz. Anota la última línea que lees completa.',
     'Muchos tripulantes notan visión borrosa de cerca en vuelo largo; suele ser el primer aviso que percibe el astronauta.'),
    ('intraocular_pressure', 'Presión intraocular', 'mmHg', 'ojos', 'both', 0, 60,
     'Tonómetro a bordo, con el CMO. Repite si el valor cambia mucho frente a la anterior.',
     'Indicador secundario: el desplazamiento de líquidos cambia la presión dentro del ojo.'),
    ('cup_to_disc_ratio', 'Relación copa/disco', 'ratio', 'ojos', 'both', 0, 1,
     'Se calcula de la imagen del nervio óptico (fondo de ojo u OCT).',
     'Indicador secundario: con edema del disco la copa se rellena y la relación baja.')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    unit = EXCLUDED.unit,
    system = EXCLUDED.system,
    alert_when = EXCLUDED.alert_when,
    valid_min = EXCLUDED.valid_min,
    valid_max = EXCLUDED.valid_max,
    how_to = EXCLUDED.how_to,
    why_space = EXCLUDED.why_space;

-- Rango clínico terrestre de presión intraocular (10–21 mmHg). Supuesto de diseño para el espacio.
INSERT INTO thresholds (indicator_id, atencion_low, atencion_high, source) VALUES
    ('intraocular_pressure', 10, 21, 'Rango clínico terrestre habitual. Supuesto de diseño, sin umbral publicado en vuelo.')
ON CONFLICT (indicator_id, body_state) WHERE environment IS NULL DO NOTHING;

-- Peligro → indicador → efecto → acción preventiva
INSERT INTO indicator_hazards (indicator_id, hazard, health_effect, preventive_action, source) VALUES
    ('macular_thickness',    'gravedad', 'Engrosamiento retiniano por desplazamiento de líquidos (SANS).',
     'OCT periódico y comparar contra la base prevuelo.', 'NASA HRP · Risk of SANS'),
    ('rnfl_thickness',       'gravedad', 'Edema del disco óptico (SANS).',
     'OCT periódico; reportar visión borrosa en cuanto aparezca.', 'NASA HRP · Risk of SANS'),
    ('near_vision_logmar',   'gravedad', 'Pérdida de visión cercana (hipermetropía adquirida).',
     'Autoprueba semanal; usar lentes de ajuste disponibles a bordo.', 'NASA HRP · Risk of SANS'),
    ('intraocular_pressure', 'gravedad', 'Cambio de presión intraocular por redistribución de líquidos.',
     'Medir junto con el OCT y seguir la tendencia.', 'NASA HRP · Risk of SANS'),
    ('cup_to_disc_ratio',    'gravedad', 'Cambio en el nervio óptico asociado a edema del disco.',
     'Revisar la imagen del nervio óptico en cada ciclo de OCT.', 'NASA HRP · Risk of SANS')
ON CONFLICT (indicator_id, hazard) DO NOTHING;

COMMIT;
