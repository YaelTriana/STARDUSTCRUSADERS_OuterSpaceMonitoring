"""
Generador de SQL de poblado automático para TIRELUS · NASA Space Apps 2026.
Lee db/datosdb/dataset.csv (68 columnas, excluyendo Ethnicity) y genera db/004_populate.sql.
"""

from __future__ import annotations

import math
import os
import uuid
import pandas as pd
import numpy as np

CSV_PATH = os.path.join(os.path.dirname(__file__), "datosdb", "dataset.csv")
OUTPUT_SQL = os.path.join(os.path.dirname(__file__), "004_populate.sql")

MISSION_UUID = "11111111-1111-4111-8111-111111111111"
MISSION_START = "2026-01-01 00:00:00+00"

def get_astronaut_uuid(patient_id: str) -> str:
    """Mapea SC-00001 a 00000000-0000-4000-8000-000000000001, etc."""
    num_str = patient_id.split("-")[-1]
    num = int(num_str)
    return f"00000000-0000-4000-8000-{num:012d}"

def sql_quote(val) -> str:
    if val is None or (isinstance(val, float) and math.isnan(val)) or pd.isna(val):
        return "NULL"
    if isinstance(val, (int, np.integer)):
        return str(val)
    if isinstance(val, (float, np.floating)):
        return str(round(val, 4))
    if isinstance(val, bool):
        return "TRUE" if val else "FALSE"
    # string
    s = str(val).replace("'", "''")
    return f"'{s}'"

def mood_from_stress(stress: float) -> float:
    """Ánimo 1-5 derivado del estrés percibido 0-10, invertido.

    SUPUESTO DE DISEÑO: el dataset no trae autorreporte de ánimo, pero sí estrés
    percibido (que correlaciona con sueño y regulación emocional). La app muestra
    el ánimo en 1-5 (indicators.mood), así que se deriva aquí y queda documentado.
    Misma fórmula que tools/sim_sinteticos.py, para no tener dos verdades.
    """
    proporcion = min(1.0, max(0.0, float(stress) / 10.0))
    return round(5.0 - proporcion * 4.0, 2)


def snellen_to_logmar(snellen: str) -> float | None:
    try:
        parts = snellen.split("/")
        top, bottom = float(parts[0]), float(parts[1])
        return round(math.log10(bottom / top), 2)
    except Exception:
        return None

def main():
    print(f"Leyendo dataset desde {CSV_PATH}...")
    df = pd.read_csv(CSV_PATH)
    print(f"Total registros en dataset: {len(df)}, columnas: {len(df.columns)}")

    # Validar que Ethnicity no se use en tablas públicas ni de ref
    # df.drop(columns=['Ethnicity']) cuando mapeemos
    
    # Preparamos las sentencias SQL
    lines = []
    lines.append("-- =====================================================================")
    lines.append("-- TIRELUS · Poblado automático de base de datos desde datosdb/dataset.csv")
    lines.append("-- NASA Space Apps Challenge 2026 - Hackathon")
    lines.append("-- Generado automáticamente por db/generate_populate_sql.py")
    lines.append("-- =====================================================================")
    lines.append("\n\\set ON_ERROR_STOP on\nBEGIN;\n")

    # 1. Misión
    lines.append("-- 1. Misión de Referencia")
    lines.append(f"""INSERT INTO missions (id, name, environment, starts_at)
VALUES ('{MISSION_UUID}', 'Misión Ares-Alpha 2026', 'iss', '{MISSION_START}')
ON CONFLICT (id) DO NOTHING;\n""")

    # 2. Astronautas y Perfil Clínico Estático
    lines.append("-- 2. Tripulantes (Astronautas) y Perfil Clínico")
    patients = df.drop_duplicates(subset=["Patient_ID"]).sort_values("Patient_ID")
    
    astro_rows = []
    hist_rows = []
    for _, r in patients.iterrows():
        p_id = r["Patient_ID"]
        a_uuid = get_astronaut_uuid(p_id)
        name = f"Tripulante A ({p_id})" if p_id == "SC-00001" else f"Tripulante {p_id}"
        role = "cmo" if p_id == "SC-00001" else "astronauta"
        gender = r["Gender"]
        sex = "M" if gender.lower() == "male" else ("F" if gender.lower() == "female" else "X")
        age = int(r["Age"])
        height = float(r["Height_m"])

        astro_rows.append(
            f"('{a_uuid}', '{p_id}', '{MISSION_UUID}', '{name}', '{role}', {age}, '{gender}', '{sex}', {height})"
        )

        smoking = r["Smoking_Status"]
        htn = "TRUE" if str(r["History_Hypertension"]).strip().lower() == "yes" else "FALSE"
        cvd = "TRUE" if str(r["History_CVD"]).strip().lower() == "yes" else "FALSE"
        diab_dur = int(r["Diabetes_Duration_years"])
        fam_eye = "TRUE" if str(r["Family_History_Eye_Disease"]).strip().lower() == "yes" else "FALSE"
        meds = str(r["Medications"]).replace("'", "''")
        risk = r["Risk_Category"]
        wf = int(r["Workout_Frequency_days_week"])
        pal = int(r["Physical_Activity_Level"])
        exp = int(r["Experience_Level"])

        hist_rows.append(
            f"('{a_uuid}', '{smoking}', {htn}, {cvd}, {diab_dur}, {fam_eye}, '{meds}', '{risk}', {wf}, {pal}, {exp})"
        )

    lines.append("INSERT INTO astronauts (id, patient_id, mission_id, name, role, age, gender, sex, height_m) VALUES\n  " +
                 ",\n  ".join(astro_rows) +
                 "\nON CONFLICT (id) DO UPDATE SET patient_id = EXCLUDED.patient_id, name = EXCLUDED.name;\n")

    lines.append("INSERT INTO astronaut_clinical_history (astronaut_id, smoking_status, history_hypertension, history_cvd, diabetes_duration_years, family_history_eye_disease, medications, risk_category, workout_frequency_days_week, physical_activity_level, experience_level) VALUES\n  " +
                 ",\n  ".join(hist_rows) +
                 "\nON CONFLICT (astronaut_id) DO NOTHING;\n")

    # 3. Exámenes Oftalmológicos / SANS (30 filas)
    lines.append("-- 3. Exámenes Oftalmológicos y Biomarcadores Retinianos / OCT (SANS)")
    eye_df = df[df["Date_of_Last_Eye_Exam"].notna()].sort_values("Patient_ID")
    eye_rows = []
    for _, r in eye_df.iterrows():
        a_uuid = get_astronaut_uuid(r["Patient_ID"])
        exam_date = r["Date_of_Last_Eye_Exam"]
        symp_w = float(r["Symptom_Duration_weeks"]) if pd.notna(r["Symptom_Duration_weeks"]) else 0.0
        va = str(r["Visual_Acuity"])
        logmar = snellen_to_logmar(va)
        logmar_str = str(logmar) if logmar is not None else "NULL"
        iqs = float(r["Image_Quality_Score"])
        disc_a = float(r["Optic_Disc_Area"])
        cup_a = float(r["Optic_Cup_Area"])
        cdr = float(r["Cup_to_Disc_Ratio"])
        iop = float(r["Intraocular_Pressure_mmhg"])
        mac_th = float(r["Macular_Thickness_um"])
        rnfl_th = float(r["RNFL_Thickness_um"])
        tort = float(r["Vessel_Tortuosity"])
        bif = float(r["Bifurcation_Angle_deg"])
        faz = float(r["FAZ_Area_mm2"])
        glcm = float(r["Texture_GLCM_Contrast"])
        gabor = float(r["Texture_Gabor_Response"])
        df1 = float(r["Deep_Feature_1"])
        df2 = float(r["Deep_Feature_2"])
        df3 = float(r["Deep_Feature_3"])
        micro = int(r["Microaneurysms_Count"])
        exud = int(r["Exudates_Count"])
        hem = int(r["Hemorrhages_Count"])
        disorder_code = int(r["Retinal_Disorder"])
        disorder_lbl = str(r["Retinal_Disorder_Label"]).replace("'", "''")

        eye_rows.append(
            f"('{a_uuid}', '{exam_date}', 1, '{exam_date}', {symp_w}, '{va}', {logmar_str}, {iqs}, {disc_a}, {cup_a}, {cdr}, {iop}, {mac_th}, {rnfl_th}, {tort}, {bif}, {faz}, {glcm}, {gabor}, {df1}, {df2}, {df3}, {micro}, {exud}, {hem}, {disorder_code}, '{disorder_lbl}')"
        )

    lines.append("INSERT INTO ophthalmic_exams (astronaut_id, exam_date, mission_day, date_of_last_eye_exam, symptom_duration_weeks, visual_acuity, near_vision_logmar, image_quality_score, optic_disc_area, optic_cup_area, cup_to_disc_ratio, intraocular_pressure_mmhg, macular_thickness_um, rnfl_thickness_um, vessel_tortuosity, bifurcation_angle_deg, faz_area_mm2, texture_glcm_contrast, texture_gabor_response, deep_feature_1, deep_feature_2, deep_feature_3, microaneurysms_count, exudates_count, hemorrhages_count, retinal_disorder, retinal_disorder_label) VALUES\n  " +
                 ",\n  ".join(eye_rows) +
                 "\nON CONFLICT (astronaut_id, exam_date) DO NOTHING;\n")

    # Helper para chunks
    def chunked_inserts(table_name, col_names, rows, chunk_size=500):
        res = []
        for i in range(0, len(rows), chunk_size):
            chunk = rows[i:i + chunk_size]
            res.append(f"INSERT INTO {table_name} ({', '.join(col_names)}) VALUES\n  " +
                       ",\n  ".join(chunk) +
                       "\nON CONFLICT DO NOTHING;\n")
        return "".join(res)

    # 4. Composición Corporal (1800 filas)
    lines.append("-- 4. Composición Corporal Diaria (Peso, IMC, Grasa)")
    body_rows = []
    base_ts = pd.Timestamp("2026-01-01")
    for _, r in df.iterrows():
        a_uuid = get_astronaut_uuid(r["Patient_ID"])
        ts = r["Timestamp"]
        m_day = (pd.Timestamp(ts) - base_ts).days + 1
        w = float(r["Weight_kg"])
        bmi = float(r["BMI"])
        fat = float(r["Fat_Percentage"])
        body_rows.append(f"('{a_uuid}', '{ts}+00', {m_day}, {w}, {bmi}, {fat})")
    lines.append(chunked_inserts("body_composition", ["astronaut_id", "measured_at", "mission_day", "weight_kg", "bmi", "fat_percentage"], body_rows))

    # 5. Signos Vitales en Reposo (1721 filas)
    lines.append("-- 5. Signos Vitales en Reposo")
    vitals_df = df[df["Heart_Rate"].notna()]
    vitals_rows = []
    for _, r in vitals_df.iterrows():
        a_uuid = get_astronaut_uuid(r["Patient_ID"])
        ts = r["Timestamp"]
        m_day = (pd.Timestamp(ts) - base_ts).days + 1
        hr = float(r["Heart_Rate"])
        hrv = float(r["Derived_HRV_s"])
        temp = float(r["Body_Temperature_c"])
        spo2 = float(r["Oxygen_Saturation_pct"])
        rr = float(r["Respiratory_Rate_bpm"])
        vitals_rows.append(f"('{a_uuid}', '{ts}+00', {m_day}, {hr}, {hrv}, {temp}, {spo2}, {rr})")
    lines.append(chunked_inserts("vital_signs", ["astronaut_id", "measured_at", "mission_day", "heart_rate", "derived_hrv_s", "body_temperature_c", "oxygen_saturation_pct", "respiratory_rate_bpm"], vitals_rows))

    # 6. Hemodinámica / Presión Arterial (281 filas)
    lines.append("-- 6. Hemodinámica y Presión Arterial")
    hemo_df = df[df["Systolic_BP"].notna()]
    hemo_rows = []
    for _, r in hemo_df.iterrows():
        a_uuid = get_astronaut_uuid(r["Patient_ID"])
        ts = r["Timestamp"]
        m_day = (pd.Timestamp(ts) - base_ts).days + 1
        sys = float(r["Systolic_BP"])
        dia = float(r["Diastolic_BP"])
        pp = float(r["Derived_Pulse_Pressure"])
        map_val = float(r["Derived_MAP"])
        hemo_rows.append(f"('{a_uuid}', '{ts}+00', {m_day}, {sys}, {dia}, {pp}, {map_val})")
    lines.append(chunked_inserts("hemodynamics", ["astronaut_id", "measured_at", "mission_day", "systolic_bp", "diastolic_bp", "derived_pulse_pressure", "derived_map"], hemo_rows))

    # 7. Sueño, Estado Mental y Hábitos (1800 filas)
    lines.append("-- 7. Sueño, Estado Mental y Hábitos Diarios")
    sleep_rows = []
    for _, r in df.iterrows():
        a_uuid = get_astronaut_uuid(r["Patient_ID"])
        ts = r["Timestamp"]
        m_day = (pd.Timestamp(ts) - base_ts).days + 1
        sh = float(r["Sleep_Hours"])
        sqs = float(r["Sleep_Quality_Score"])
        ds = float(r["Daytime_Sleepiness"])
        stress = float(r["Stress_Level"])
        emo = float(r["Emotion_Regulation_Score"])
        caff = float(r["Caffeine_Intake_cups_day"])
        water = float(r["Water_Intake_liters"])
        sleep_rows.append(f"('{a_uuid}', '{ts}+00', {m_day}, {sh}, {sqs}, {ds}, {stress}, {emo}, {caff}, {water})")
    lines.append(chunked_inserts("sleep_mental_logs", ["astronaut_id", "logged_at", "mission_day", "sleep_hours", "sleep_quality_score", "daytime_sleepiness", "stress_level", "emotion_regulation_score", "caffeine_intake_cups_day", "water_intake_liters"], sleep_rows))

    # 8. Sesiones de Ejercicio (764 filas)
    lines.append("-- 8. Sesiones de Ejercicio Físico en Misión")
    ex_df = df[df["Workout_Type"].notna()]
    ex_rows = []
    for _, r in ex_df.iterrows():
        a_uuid = get_astronaut_uuid(r["Patient_ID"])
        ts = r["Timestamp"]
        m_day = (pd.Timestamp(ts) - base_ts).days + 1
        w_type = r["Workout_Type"]
        dur = float(r["Session_Duration_hours"])
        mins = round(dur * 60, 1)
        cals = float(r["Calories_Burned"])
        avg_bpm = float(r["Avg_BPM"])
        max_bpm = float(r["Max_BPM"])
        cid = str(uuid.uuid5(uuid.NAMESPACE_DNS, f"{r['Patient_ID']}-exercise-{ts}"))
        ex_rows.append(f"('{cid}', '{a_uuid}', '{w_type}', '{ts}+00', {m_day}, {dur}, {mins}, {cals}, {avg_bpm}, {max_bpm}, 'iss')")
    lines.append(chunked_inserts("exercise_sessions", ["client_id", "astronaut_id", "workout_type", "started_at", "mission_day", "session_duration_hours", "minutes", "calories_burned", "avg_bpm", "max_bpm", "environment"], ex_rows))

    # 9. Evaluaciones Cognitivas (152 filas)
    lines.append("-- 9. Batería de Evaluaciones Cognitivas")
    cog_df = df[df["Stroop_Task_Reaction_Time_s"].notna()]
    cog_rows = []
    for _, r in cog_df.iterrows():
        a_uuid = get_astronaut_uuid(r["Patient_ID"])
        ts = r["Timestamp"]
        m_day = (pd.Timestamp(ts) - base_ts).days + 1
        stroop = float(r["Stroop_Task_Reaction_Time_s"])
        nback = float(r["N_Back_Accuracy_pct"])
        pvt = float(r["PVT_Reaction_Time_ms"])
        cog_rows.append(f"('{a_uuid}', '{ts}+00', {m_day}, {stroop}, {nback}, {pvt})")
    lines.append(chunked_inserts("cognitive_assessments", ["astronaut_id", "tested_at", "mission_day", "stroop_task_reaction_time_s", "n_back_accuracy_pct", "pvt_reaction_time_ms"], cog_rows))

    # 10. Pruebas Metabólicas de Laboratorio (131 filas)
    lines.append("-- 10. Pruebas Metabólicas de Laboratorio")
    lab_df = df[df["Fasting_Glucose_mg_dl"].notna()]
    lab_rows = []
    for _, r in lab_df.iterrows():
        a_uuid = get_astronaut_uuid(r["Patient_ID"])
        ts = r["Timestamp"]
        m_day = (pd.Timestamp(ts) - base_ts).days + 1
        gluc = float(r["Fasting_Glucose_mg_dl"])
        hba1c_str = str(round(float(r["HbA1c_pct"]), 2)) if pd.notna(r["HbA1c_pct"]) else "NULL"
        lab_rows.append(f"('{a_uuid}', '{ts}+00', {m_day}, {gluc}, {hba1c_str})")
    lines.append(chunked_inserts("metabolic_lab_tests", ["astronaut_id", "sampled_at", "mission_day", "fasting_glucose_mg_dl", "hba1c_pct"], lab_rows))

    # 11. Poblado de Líneas Base (baselines) para cada tripulante
    lines.append("-- 11. Líneas Base Personales Prevuelo (baselines)")
    baseline_rows = []
    for p_id in df["Patient_ID"].unique():
        a_uuid = get_astronaut_uuid(p_id)
        sub = df[df["Patient_ID"] == p_id]
        
        # Systolic baseline
        sys_s = sub["Systolic_BP"].dropna()
        if len(sys_s) > 0:
            low_sys, high_sys = round(float(sys_s.quantile(0.1)), 1), round(float(sys_s.quantile(0.9)), 1)
            baseline_rows.append(f"('{a_uuid}', 'systolic', 'reposo', {low_sys}, {high_sys})")
        
        # Diastolic baseline
        dia_s = sub["Diastolic_BP"].dropna()
        if len(dia_s) > 0:
            low_dia, high_dia = round(float(dia_s.quantile(0.1)), 1), round(float(dia_s.quantile(0.9)), 1)
            baseline_rows.append(f"('{a_uuid}', 'diastolic', 'reposo', {low_dia}, {high_dia})")

        # Heart rate baseline
        hr_s = sub["Heart_Rate"].dropna()
        if len(hr_s) > 0:
            low_hr, high_hr = round(float(hr_s.quantile(0.1)), 1), round(float(hr_s.quantile(0.9)), 1)
            baseline_rows.append(f"('{a_uuid}', 'heart_rate', 'reposo', {low_hr}, {high_hr})")

        # Sleep hours baseline
        sh_s = sub["Sleep_Hours"].dropna()
        if len(sh_s) > 0:
            low_sh, high_sh = round(float(sh_s.quantile(0.1)), 2), round(float(sh_s.quantile(0.9)), 2)
            baseline_rows.append(f"('{a_uuid}', 'sleep_hours', 'reposo', {low_sh}, {high_sh})")

        # SpO2 baseline
        spo2_s = sub["Oxygen_Saturation_pct"].dropna()
        if len(spo2_s) > 0:
            low_sp, high_sp = round(float(spo2_s.quantile(0.05)), 1), round(float(spo2_s.quantile(0.95)), 1)
            baseline_rows.append(f"('{a_uuid}', 'spo2', 'reposo', {low_sp}, {high_sp})")

        # Temperature baseline
        temp_s = sub["Body_Temperature_c"].dropna()
        if len(temp_s) > 0:
            low_t, high_t = round(float(temp_s.quantile(0.05)), 2), round(float(temp_s.quantile(0.95)), 2)
            baseline_rows.append(f"('{a_uuid}', 'temperature', 'reposo', {low_t}, {high_t})")

        # Respiratory rate baseline
        rr_s = sub["Respiratory_Rate_bpm"].dropna()
        if len(rr_s) > 0:
            low_rr, high_rr = round(float(rr_s.quantile(0.05)), 1), round(float(rr_s.quantile(0.95)), 1)
            baseline_rows.append(f"('{a_uuid}', 'respiratory_rate', 'reposo', {low_rr}, {high_rr})")

        # HRV baseline
        hrv_s = sub["Derived_HRV_s"].dropna()
        if len(hrv_s) > 0:
            low_hrv, high_hrv = round(float(hrv_s.quantile(0.05)), 4), round(float(hrv_s.quantile(0.95)), 4)
            baseline_rows.append(f"('{a_uuid}', 'hrv', 'reposo', {low_hrv}, {high_hrv})")

        # Body mass baseline
        bm_s = sub["Weight_kg"].dropna()
        if len(bm_s) > 0:
            low_bm, high_bm = round(float(bm_s.quantile(0.05)), 1), round(float(bm_s.quantile(0.95)), 1)
            baseline_rows.append(f"('{a_uuid}', 'body_mass', 'reposo', {low_bm}, {high_bm})")

        # Retinal delta baseline (0 +/- 5)
        baseline_rows.append(f"('{a_uuid}', 'retinal_delta', 'reposo', -5.0, 5.0)")

        # Estrés y ánimo: diarios, misma convención de percentiles
        stress_s = sub["Stress_Level"].dropna()
        if len(stress_s) > 0:
            low_st, high_st = round(float(stress_s.quantile(0.05)), 2), round(float(stress_s.quantile(0.95)), 2)
            baseline_rows.append(f"('{a_uuid}', 'stress_level', 'reposo', {low_st}, {high_st})")
            mood_s = stress_s.map(mood_from_stress)
            low_mo, high_mo = round(float(mood_s.quantile(0.05)), 2), round(float(mood_s.quantile(0.95)), 2)
            baseline_rows.append(f"('{a_uuid}', 'mood', 'reposo', {low_mo}, {high_mo})")

        water_s = sub["Water_Intake_liters"].dropna()
        if len(water_s) > 0:
            low_w, high_w = round(float(water_s.quantile(0.05)), 2), round(float(water_s.quantile(0.95)), 2)
            baseline_rows.append(f"('{a_uuid}', 'water_intake', 'reposo', {low_w}, {high_w})")

        # PVT reaction time baseline
        pvt_s = sub["PVT_Reaction_Time_ms"].dropna()
        if len(pvt_s) > 0:
            low_pvt, high_pvt = round(float(pvt_s.quantile(0.1)), 1), round(float(pvt_s.quantile(0.9)), 1)
            baseline_rows.append(f"('{a_uuid}', 'pvt_ms', 'reposo', {low_pvt}, {high_pvt})")

    lines.append(chunked_inserts("baselines", ["astronaut_id", "indicator_id", "body_state", "low", "high"], baseline_rows))

    # 12. Poblado de Mediciones de la App (measurements)
    lines.append("-- 12. Mediciones de Telemetría para API (measurements)")
    meas_rows = []
    
    # Base del RNFL para el delta de SANS. Los umbrales publicados (+20 / 55 um) son
    # de grosor retiniano PERIPAPILAR, no macular: ver el encabezado de
    # SANS_ATTENTION_UM en app/python_app/rules.py.
    rnfl_bases = {}
    for _, r in eye_df.iterrows():
        if pd.notna(r["RNFL_Thickness_um"]):
            rnfl_bases[r["Patient_ID"]] = float(r["RNFL_Thickness_um"])

    for _, r in df.iterrows():
        p_id = r["Patient_ID"]
        a_uuid = get_astronaut_uuid(p_id)
        ts = r["Timestamp"]
        m_day = (pd.Timestamp(ts) - base_ts).days + 1

        def add_meas(ind_id, val, state='reposo'):
            if pd.notna(val):
                cid = str(uuid.uuid5(uuid.NAMESPACE_DNS, f"{p_id}-{ind_id}-{ts}"))
                meas_rows.append(f"('{cid}', '{a_uuid}', '{ind_id}', '{state}', {round(float(val), 4)}, '{ts}+00', {m_day}, 'iss')")

        add_meas("heart_rate", r["Heart_Rate"])
        add_meas("systolic", r["Systolic_BP"])
        add_meas("diastolic", r["Diastolic_BP"])
        add_meas("spo2", r["Oxygen_Saturation_pct"])
        add_meas("temperature", r["Body_Temperature_c"])
        add_meas("respiratory_rate", r["Respiratory_Rate_bpm"])
        add_meas("hrv", r["Derived_HRV_s"])
        add_meas("sleep_hours", r["Sleep_Hours"])
        add_meas("pvt_ms", r["PVT_Reaction_Time_ms"])
        add_meas("body_mass", r["Weight_kg"])
        add_meas("macular_thickness", r["Macular_Thickness_um"])
        add_meas("rnfl_thickness", r["RNFL_Thickness_um"])
        add_meas("intraocular_pressure", r["Intraocular_Pressure_mmhg"])

        # Columnas que llegaban a las tablas de dominio pero no a la API
        add_meas("stress_level", r["Stress_Level"])
        if pd.notna(r["Stress_Level"]):
            add_meas("mood", mood_from_stress(r["Stress_Level"]))
        add_meas("fasting_glucose", r["Fasting_Glucose_mg_dl"])
        add_meas("hba1c", r["HbA1c_pct"])
        add_meas("water_intake", r["Water_Intake_liters"])
        add_meas("cup_to_disc_ratio", r["Cup_to_Disc_Ratio"])
        add_meas("near_vision_logmar", snellen_to_logmar(r["Visual_Acuity"]))

        # SANS: retinal_delta = cambio del RNFL frente a la primera lectura
        if pd.notna(r["RNFL_Thickness_um"]) and p_id in rnfl_bases:
            add_meas("retinal_delta", float(r["RNFL_Thickness_um"]) - rnfl_bases[p_id])

    lines.append(chunked_inserts("measurements", ["client_id", "astronaut_id", "indicator_id", "body_state", "value", "measured_at", "mission_day", "environment"], meas_rows, chunk_size=500))

    # 13. ref.dataset_raw (Copia íntegra de las 67 columnas sin Ethnicity)
    lines.append("-- 13. Staging Poblacional Completo (ref.dataset_raw)")
    cols_67 = [
        "Patient_ID", "Timestamp", "Age", "Gender", "Height_m", "Weight_kg", "BMI", "Fat_Percentage",
        "Smoking_Status", "History_Hypertension", "History_CVD", "Diabetes_Duration_years",
        "Family_History_Eye_Disease", "Medications", "Risk_Category", "Workout_Frequency_days_week",
        "Physical_Activity_Level", "Experience_Level", "Workout_Type", "Session_Duration_hours",
        "Calories_Burned", "Avg_BPM", "Max_BPM", "Caffeine_Intake_cups_day", "Water_Intake_liters",
        "Sleep_Hours", "Sleep_Quality_Score", "Daytime_Sleepiness", "Stress_Level", "Emotion_Regulation_Score",
        "Stroop_Task_Reaction_Time_s", "N_Back_Accuracy_pct", "PVT_Reaction_Time_ms", "Heart_Rate",
        "Systolic_BP", "Diastolic_BP", "Derived_Pulse_Pressure", "Derived_MAP", "Fasting_Glucose_mg_dl",
        "HbA1c_pct", "Derived_HRV_s", "Body_Temperature_c", "Oxygen_Saturation_pct", "Respiratory_Rate_bpm",
        "Date_of_Last_Eye_Exam", "Symptom_Duration_weeks", "Visual_Acuity", "Image_Quality_Score",
        "Optic_Disc_Area", "Optic_Cup_Area", "Cup_to_Disc_Ratio", "Intraocular_Pressure_mmhg",
        "Macular_Thickness_um", "RNFL_Thickness_um", "Vessel_Tortuosity", "Bifurcation_Angle_deg",
        "FAZ_Area_mm2", "Texture_GLCM_Contrast", "Texture_Gabor_Response", "Deep_Feature_1",
        "Deep_Feature_2", "Deep_Feature_3", "Microaneurysms_Count", "Exudates_Count", "Hemorrhages_Count",
        "Retinal_Disorder", "Retinal_Disorder_Label"
    ]
    db_cols_67 = [c.lower() for c in cols_67]
    raw_rows = []
    for _, r in df.iterrows():
        vals = [sql_quote(r[c]) for c in cols_67]
        raw_rows.append("(" + ", ".join(vals) + ")")

    lines.append(chunked_inserts("ref.dataset_raw", db_cols_67, raw_rows, chunk_size=300))

    lines.append("COMMIT;\n")
    lines.append("-- Fin de poblado automático exitoso.")

    with open(OUTPUT_SQL, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"Archivo generado exitosamente: {OUTPUT_SQL} ({os.path.getsize(OUTPUT_SQL)} bytes)")

if __name__ == "__main__":
    main()
