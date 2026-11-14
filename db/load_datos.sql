-- Recarga los datasets de datosdb/ en el esquema ref. Re-ejecutable: vacía y vuelve a cargar.
-- No toca las tablas de la app (public).
-- Correr desde la raíz del repo (las rutas de \copy son relativas a donde corre psql):
--   psql -U postgres -d tirelus -f db/load_datos.sql
-- Si cambian las columnas de un CSV, ajusta su tabla en db/schema.sql y la lista de abajo.

\set ON_ERROR_STOP on
BEGIN;

TRUNCATE ref.vital_signs_rest, ref.sleep_deprivation, ref.retinal;
TRUNCATE ref.gym_sessions RESTART IDENTITY;

\copy ref.vital_signs_rest FROM 'datosdb/human_vital_signs_dataset_2024.csv' WITH (FORMAT csv, HEADER true)

\copy ref.gym_sessions (age, gender, weight_kg, height_m, max_bpm, avg_bpm, resting_bpm, session_hours, calories_burned, workout_type, fat_percentage, water_liters, workout_days_week, experience_level, bmi) FROM 'datosdb/gym_members_exercise_tracking.csv' WITH (FORMAT csv, HEADER true)

\copy ref.sleep_deprivation FROM 'datosdb/sleep_deprivation_dataset_detailed.csv' WITH (FORMAT csv, HEADER true)

\copy ref.retinal FROM 'datosdb/retinal_disorders_dataset.csv' WITH (FORMAT csv, HEADER true)

COMMIT;
ANALYZE ref.vital_signs_rest, ref.gym_sessions, ref.sleep_deprivation, ref.retinal;

-- Verificación rápida
SELECT 'vital_signs_rest' AS tabla, count(*) FROM ref.vital_signs_rest
UNION ALL SELECT 'gym_sessions', count(*) FROM ref.gym_sessions
UNION ALL SELECT 'sleep_deprivation', count(*) FROM ref.sleep_deprivation
UNION ALL SELECT 'retinal', count(*) FROM ref.retinal;
SELECT * FROM ref.simulate_sleep(5.5);
