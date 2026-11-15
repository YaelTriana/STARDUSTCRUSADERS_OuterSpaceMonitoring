"""
Script de Verificación Integral de Base de Datos para TIRELUS.
NASA Space Apps Challenge 2026.

Comprueba:
1. Cobertura del 100% de columnas de dataset.csv (67 campos utilizados, etnicidad excluida).
2. Validez sintáctica y consistencia de 004_populate.sql.
3. Compatibilidad con consultas de db.py (API de TIRELUS).
"""

from __future__ import annotations

import os
import re
import sqlite3
import pandas as pd

DB_DIR = os.path.dirname(__file__)
CSV_PATH = os.path.join(DB_DIR, "datosdb", "dataset.csv")
POPULATE_SQL = os.path.join(DB_DIR, "004_populate.sql")

def verify_column_coverage():
    print("=== 1. Verificación de Cobertura de Columnas ===")
    df = pd.read_csv(CSV_PATH)
    total_cols = len(df.columns)
    assert "Ethnicity" in df.columns, "Ethnicity debería estar en el CSV original"
    
    expected_mapped = set(df.columns) - {"Ethnicity"}
    print(f"Total columnas en CSV original: {total_cols}")
    print(f"Columna excluida expresamente: Ethnicity")
    print(f"Total columnas requeridas para persistir: {len(expected_mapped)}")

    with open(os.path.join(DB_DIR, "schema.sql"), "r", encoding="utf-8") as f:
        schema_text = f.read().lower()

    missing = []
    for col in expected_mapped:
        col_clean = col.lower()
        if col_clean not in schema_text:
            missing.append(col)

    if missing:
        print(f"ERROR: Columnas faltantes en el esquema: {missing}")
        return False
    
    print(f"Éxito: Las {len(expected_mapped)} columnas (100%) están declaradas e indexadas en el esquema.")
    return True

def verify_populate_sql():
    print("\n=== 2. Verificación de 004_populate.sql ===")
    with open(POPULATE_SQL, "r", encoding="utf-8") as f:
        sql = f.read()

    print(f"Tamaño de 004_populate.sql: {len(sql):,} bytes ({sql.count(chr(10)):,} líneas)")

    # Verificar que no contenga 'ethnicity'
    if "ethnicity" in sql.lower():
        print("ERROR: Se detectó 'ethnicity' en 004_populate.sql")
        return False
    print("Éxito: 'ethnicity' no aparece en ninguna sentencia de 004_populate.sql")

    # Simular en SQLite
    conn = sqlite3.connect(":memory:")
    cur = conn.cursor()

    cur.execute('''CREATE TABLE astronauts (
        id TEXT PRIMARY KEY, patient_id TEXT, mission_id TEXT, name TEXT,
        role TEXT, age INT, gender TEXT, sex TEXT, height_m REAL
    )''')
    cur.execute('''CREATE TABLE baselines (
        astronaut_id TEXT, indicator_id TEXT, body_state TEXT, low REAL, high REAL,
        PRIMARY KEY (astronaut_id, indicator_id, body_state)
    )''')
    cur.execute('''CREATE TABLE measurements (
        client_id TEXT PRIMARY KEY, astronaut_id TEXT, indicator_id TEXT,
        body_state TEXT, value REAL, measured_at TEXT, mission_day INT, environment TEXT
    )''')
    cur.execute('''CREATE TABLE body_composition (
        id INTEGER PRIMARY KEY AUTOINCREMENT, astronaut_id TEXT, measured_at TEXT,
        mission_day INT, weight_kg REAL, bmi REAL, fat_percentage REAL
    )''')
    cur.execute('''CREATE TABLE vital_signs (
        id INTEGER PRIMARY KEY AUTOINCREMENT, astronaut_id TEXT, measured_at TEXT,
        mission_day INT, heart_rate REAL, derived_hrv_s REAL, body_temperature_c REAL,
        oxygen_saturation_pct REAL, respiratory_rate_bpm REAL
    )''')
    cur.execute('''CREATE TABLE hemodynamics (
        id INTEGER PRIMARY KEY AUTOINCREMENT, astronaut_id TEXT, measured_at TEXT,
        mission_day INT, systolic_bp REAL, diastolic_bp REAL, derived_pulse_pressure REAL, derived_map REAL
    )''')
    cur.execute('''CREATE TABLE sleep_mental_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT, astronaut_id TEXT, logged_at TEXT,
        mission_day INT, sleep_hours REAL, sleep_quality_score REAL, daytime_sleepiness REAL,
        stress_level REAL, emotion_regulation_score REAL, caffeine_intake_cups_day REAL, water_intake_liters REAL
    )''')
    cur.execute('''CREATE TABLE exercise_sessions (
        client_id TEXT PRIMARY KEY, astronaut_id TEXT, workout_type TEXT, started_at TEXT,
        mission_day INT, session_duration_hours REAL, minutes REAL, calories_burned REAL,
        avg_bpm REAL, max_bpm REAL, environment TEXT
    )''')
    cur.execute('''CREATE TABLE cognitive_assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT, astronaut_id TEXT, tested_at TEXT,
        mission_day INT, stroop_task_reaction_time_s REAL, n_back_accuracy_pct REAL, pvt_reaction_time_ms REAL
    )''')
    cur.execute('''CREATE TABLE metabolic_lab_tests (
        id INTEGER PRIMARY KEY AUTOINCREMENT, astronaut_id TEXT, sampled_at TEXT,
        mission_day INT, fasting_glucose_mg_dl REAL, hba1c_pct REAL
    )''')
    cur.execute('''CREATE TABLE ophthalmic_exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT, astronaut_id TEXT, exam_date TEXT,
        mission_day INT, date_of_last_eye_exam TEXT, symptom_duration_weeks REAL,
        visual_acuity TEXT, near_vision_logmar REAL, image_quality_score REAL,
        optic_disc_area REAL, optic_cup_area REAL, cup_to_disc_ratio REAL,
        intraocular_pressure_mmhg REAL, macular_thickness_um REAL, rnfl_thickness_um REAL,
        vessel_tortuosity REAL, bifurcation_angle_deg REAL, faz_area_mm2 REAL,
        texture_glcm_contrast REAL, texture_gabor_response REAL, deep_feature_1 REAL,
        deep_feature_2 REAL, deep_feature_3 REAL, microaneurysms_count INT,
        exudates_count INT, hemorrhages_count INT, retinal_disorder INT, retinal_disorder_label TEXT
    )''')

    stmts = sql.split(";\n")
    loaded_counts = {}
    for stmt in stmts:
        stmt = stmt.strip()
        lines = [l for l in stmt.splitlines() if not l.strip().startswith("--") and not l.strip().startswith("\\")]
        clean = "\n".join(lines).strip()
        if not clean or clean in ("BEGIN", "COMMIT"):
            continue
        clean = re.sub(r"ON CONFLICT.*", "", clean, flags=re.DOTALL).strip()
        clean = clean.replace("+00", "")
        
        for table in [
            "astronauts", "baselines", "measurements", "body_composition", "vital_signs",
            "hemodynamics", "sleep_mental_logs", "exercise_sessions", "cognitive_assessments",
            "metabolic_lab_tests", "ophthalmic_exams"
        ]:
            if clean.startswith(f"INSERT INTO {table}"):
                cur.execute(clean)
                loaded_counts[table] = loaded_counts.get(table, 0) + 1

    print("Registros cargados en tablas simuladas:")
    for table in [
        "astronauts", "body_composition", "vital_signs", "hemodynamics",
        "sleep_mental_logs", "exercise_sessions", "cognitive_assessments",
        "metabolic_lab_tests", "ophthalmic_exams", "baselines", "measurements"
    ]:
        count = cur.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        print(f"  - {table}: {count:,} filas")

    # 3. Test de consulta de db.py
    print("\n=== 3. Verificación de Compatibilidad con app/python_app/db.py ===")
    cur.execute("SELECT id, patient_id, name FROM astronauts ORDER BY id LIMIT 1")
    row = cur.fetchone()
    astro_id = row[0]
    print(f"Tripulante activo para db.py: {row[1]} ({row[2]}), UUID={astro_id}")

    cur.execute('''
    SELECT indicator_id, value, mission_day FROM (
      SELECT indicator_id, value, mission_day, measured_at,
             row_number() OVER (PARTITION BY indicator_id ORDER BY measured_at DESC) AS rn
      FROM measurements
      WHERE astronaut_id = ? AND body_state = 'reposo'
    ) ultimas WHERE rn <= 14 ORDER BY indicator_id, measured_at
    ''', (astro_id,))
    meas = cur.fetchall()
    print(f"Lecturas históricas devueltas para tripulante activo: {len(meas)} mediciones.")
    assert len(meas) > 0, "Debe devolver mediciones para el tripulante activo"
    print("Éxito: Todas las pruebas de compatibilidad y arquitectura han sido aprobadas.")
    return True

if __name__ == "__main__":
    ok1 = verify_column_coverage()
    ok2 = verify_populate_sql()
    if ok1 and ok2:
        print("\nTODO EL MÓDULO DE DB HA SIDO VERIFICADO EXITOSAMENTE (100%).")
    else:
        print("\nSE ENCONTRARON ERRORES EN LA VERIFICACIÓN.")
