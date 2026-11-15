"""DATOS DE EJEMPLO de TIRELUS. Sintéticos, solo para el mockup."""

from __future__ import annotations

from types import SimpleNamespace

from rules import Baseline

# Idioma de la API: "es" (por defecto) o "en". Cualquier otro valor cae en "es".
LANGS = ("es", "en")

MISSION_DAY = 47

# Presión sistólica de los últimos 14 días (D34–D47).
SYSTOLIC_14 = [118, 120, 117, 121, 119, 122, 124, 126, 125, 128, 130, 129, 131, 132]
SYSTOLIC_BASE = Baseline(110, 126)
SYSTOLIC_ABS_HIGH = 160.0  # límite clínico terrestre de respaldo (supuesto de diseño)

# ---------------------------------------------------------------------------
# Catálogo de métricas para /trend/{metric} y /evaluate/{metric}.
#
# Cada métrica necesita:
#   label, unit       → texto para la UI
#   system            → sistema del panel: cardio, ojos, hueso, mente o inmune
#                       (mismos ids que body_system en db/schema.sql)
#   base              → Baseline(low, high) personal prevuelo, o None si aún no hay dato
#   abs_high/abs_low  → límite clínico terrestre de respaldo (supuesto de diseño) o None
#   series            → últimos 14 días (D34–D47), la última lectura es hoy
#   alert_when        → "above" o "below": hacia dónde preocupa la desviación
#   rule, source      → texto de la regla y de dónde sale el umbral
#
# Si series está vacía o base es None, la API responde status "sin_dato".
# Las series deben seguir "Claude outputs/TIRELUS_matriz_simulacion.xlsx".
# ---------------------------------------------------------------------------

METRICS: dict[str, dict] = {
    "systolic": {
        "label": "Presión sistólica",
        "unit": "mmHg",
        "system": "cardio",
        "valid_range": (50, 260),  # límite de captura (supuesto de diseño); igual a db/schema.sql
        "base": SYSTOLIC_BASE,
        "abs_high": SYSTOLIC_ABS_HIGH,
        "abs_low": None,
        "series": SYSTOLIC_14,
        "alert_when": "above",
        "rule": "Supuesto de diseño: 3 días consecutivos sobre la base personal.",
        "source": "Captura en examen periódico de salud (NTRS 20250000330). Umbral: supuesto de diseño.",
    },
    "diastolic": {
        "label": "Presión diastólica",
        "unit": "mmHg",
        "system": "cardio",
        "valid_range": (30, 160),
        # >>> DATOS: línea base prevuelo de diastólica, p. ej. Baseline(70, 82).
        "base": None,
        # >>> DATOS: límite terrestre de respaldo (supuesto de diseño), p. ej. 100.0.
        "abs_high": None,
        "abs_low": None,
        # >>> DATOS: 14 lecturas diarias D34–D47, junto con la sistólica.
        "series": [],
        "alert_when": "above",
        "rule": "Supuesto de diseño: 3 días consecutivos sobre la base personal.",
        "source": "Examen periódico de salud (NTRS 20250000330). Umbral: supuesto de diseño.",
    },
    "heart_rate": {
        "label": "FC en reposo",
        "unit": "lpm",
        "system": "cardio",
        "valid_range": (20, 230),
        # Línea base prevuelo de FC en reposo. Coincide con la nota "base 60" del Panel.
        "base": Baseline(55, 66),
        # Límite terrestre de respaldo (supuesto de diseño).
        "abs_high": 100.0,
        "abs_low": None,
        # D34–D47: estable, ligera subida al final, nunca cruza la base (66) → nominal.
        # Última lectura (D47) = 64, igual al Panel (/dashboard, sistema "cardio").
        "series": [58, 59, 57, 60, 58, 61, 59, 62, 60, 63, 61, 64, 62, 64],
        "alert_when": "above",
        "rule": "Supuesto de diseño: 3 días consecutivos sobre la base personal.",
        "source": "Examen periódico de salud (NTRS 20250000330). Umbral: supuesto de diseño.",
    },
    "spo2": {
        "label": "SpO₂",
        "unit": "%",
        "system": "cardio",
        "valid_range": (50, 100),
        # >>> DATOS: línea base prevuelo de saturación, p. ej. Baseline(95, 100).
        "base": None,
        "abs_high": None,
        # >>> DATOS: mínimo de respaldo (supuesto de diseño), p. ej. 90.0.
        "abs_low": None,
        # >>> DATOS: 14 lecturas diarias D34–D47.
        "series": [],
        # Aquí preocupa la baja: evaluate_trend recibe direction="below".
        "alert_when": "below",
        "rule": "Supuesto de diseño: saturación por debajo de la base personal.",
        "source": "Examen periódico de salud (NTRS 20250000330). Umbral: supuesto de diseño.",
    },
    "macular_thickness": {
        "label": "Grosor macular",
        "unit": "µm",
        "system": "ojos",
        "valid_range": (150, 600),
        # >>> DATOS: línea base del OCT prevuelo, p. ej. Baseline(270, 300).
        "base": None,
        "abs_high": None,
        "abs_low": None,
        # >>> DATOS: una lectura por ciclo de OCT.
        "series": [],
        "alert_when": "above",
        "rule": "Supuesto de diseño: 3 días consecutivos sobre la base personal.",
        "source": "OCT a bordo (ver db/002_ojos.sql). Umbral: supuesto de diseño.",
    },
    "rnfl_thickness": {
        "label": "Capa de fibras (RNFL)",
        "unit": "µm",
        "system": "ojos",
        "valid_range": (20, 200),
        # >>> DATOS: línea base del OCT prevuelo, p. ej. Baseline(95, 115).
        "base": None,
        "abs_high": None,
        "abs_low": None,
        "series": [],
        "alert_when": "above",  # si engrosa puede ser edema del disco óptico (SANS)
        "rule": "Supuesto de diseño: 3 días consecutivos sobre la base personal.",
        "source": "OCT a bordo (ver db/002_ojos.sql). Umbral: supuesto de diseño.",
    },
    "near_vision_logmar": {
        "label": "Visión cercana",
        "unit": "logMAR",
        "system": "ojos",
        "valid_range": (-0.3, 2.0),
        # >>> DATOS: autoprueba semanal prevuelo, p. ej. Baseline(-0.1, 0.1).
        "base": None,
        "abs_high": None,
        "abs_low": None,
        "series": [],
        "alert_when": "above",  # más logMAR es peor visión
        "rule": "Supuesto de diseño: autoprueba semanal peor que la base personal.",
        "source": "Autoprueba de visión cercana (ver db/002_ojos.sql). Umbral: supuesto de diseño.",
    },
    "intraocular_pressure": {
        "label": "Presión intraocular",
        "unit": "mmHg",
        "system": "ojos",
        "valid_range": (0, 60),
        # >>> DATOS: tonometría prevuelo, p. ej. Baseline(12, 18).
        "base": None,
        "abs_high": None,
        "abs_low": None,
        "series": [],
        "alert_when": "above",
        "rule": "Supuesto de diseño: 3 días consecutivos sobre la base personal.",
        "source": "Tonómetro a bordo (ver db/002_ojos.sql). Umbral: supuesto de diseño.",
    },
    "cup_to_disc_ratio": {
        "label": "Relación copa/disco",
        "unit": "ratio",
        "system": "ojos",
        "valid_range": (0, 1),
        # >>> DATOS: fondo de ojo prevuelo, p. ej. Baseline(0.25, 0.4).
        "base": None,
        "abs_high": None,
        "abs_low": None,
        "series": [],
        "alert_when": "above",
        "rule": "Supuesto de diseño: 3 días consecutivos sobre la base personal.",
        "source": "Imagen del nervio óptico (ver db/002_ojos.sql). Umbral: supuesto de diseño.",
    },
    "body_mass": {
        "label": "Masa corporal",
        "unit": "kg",
        "system": "hueso",
        "valid_range": (30, 200),
        # >>> DATOS: pesaje prevuelo, p. ej. Baseline(72.0, 74.0).
        "base": None,
        "abs_high": None,
        # >>> DATOS: mínimo de respaldo (supuesto de diseño): pérdida que obliga a escalar.
        "abs_low": None,
        "series": [],
        "alert_when": "below",  # sin carga del peso corporal se pierde hueso y músculo
        "rule": "Supuesto de diseño: 3 días consecutivos bajo la base personal.",
        "source": "Pesaje del examen periódico de salud (NTRS 20250000330). Umbral: supuesto de diseño.",
    },
    "sleep_hours": {
        "label": "Horas de sueño",
        "unit": "h",
        "system": "mente",
        "valid_range": (0, 24),
        # Línea base prevuelo de sueño (periodo de 8.5 h de referencia, ver rule/source).
        "base": Baseline(6.5, 8.5),
        "abs_high": None,
        # Mínimo de respaldo (supuesto de diseño).
        "abs_low": 5.0,
        # D34–D47: déficit sostenido los últimos 5 días (< 6.5 h) → atención.
        # Última lectura (D47) = 6.17 h, igual al Panel ("6:10", sistema "mente").
        "series": [7.8, 7.5, 8.0, 7.6, 7.2, 7.0, 6.9, 6.8, 6.6, 6.3, 6.1, 6.0, 6.2, 6.17],
        # Aquí preocupa la baja: evaluate_trend recibe direction="below".
        "alert_when": "below",
        "rule": "Supuesto de diseño: periodo de sueño de 8.5 h; déficit sostenido frente a la base.",
        "source": "Promedio histórico <6.1 h (Basner et al., PMC4691281). Umbral: supuesto de diseño.",
    },
    "mood": {
        "label": "Ánimo (1–5)",
        "unit": "pts",
        "system": "mente",
        "valid_range": (1, 5),
        # Rango habitual del tripulante: autorreporte normal es 4–5. Baseline(4, 5) y no
        # (3, 5): la última lectura de hoy (D47) debe quedar en 3, igual al Panel, y con
        # low=3 un valor de 3 nunca cuenta como "por debajo" (evaluate_trend usa v < low),
        # así que la caída sostenida nunca dispararía "atención" hoy. Con low=4, 3 sí
        # cuenta como desviación y la racha de días por debajo si incluye hoy.
        "base": Baseline(4, 5),
        "abs_high": None,
        # Mínimo de respaldo (supuesto de diseño).
        "abs_low": 1.0,
        # D34–D47: estable en 4–5, caída sostenida a 3 los últimos 6 días → atención.
        # Última lectura (D47) = 3, igual al Panel ("3", sistema "mente").
        "series": [5, 4, 5, 4, 5, 4, 4, 4, 3, 3, 3, 3, 3, 3],
        # Igual que sueño: preocupa la baja.
        "alert_when": "below",
        "rule": "Supuesto de diseño: autorreporte por debajo del rango habitual.",
        "source": "Autorreporte: supuesto de diseño, sin umbral publicado.",
    },
    "pvt_ms": {
        "label": "Tiempo de reacción (PVT)",
        "unit": "ms",
        "system": "mente",
        "valid_range": (100, 2000),
        # >>> DATOS: batería cognitiva prevuelo, p. ej. Baseline(260, 320).
        "base": None,
        "abs_high": None,
        "abs_low": None,
        "series": [],
        "alert_when": "above",  # más lento que tu base
        "rule": "Supuesto de diseño: 3 días consecutivos sobre la base personal.",
        "source": "Batería cognitiva (~16 min) del examen periódico. Umbral: supuesto de diseño.",
    },
    "temperature": {
        "label": "Temperatura corporal",
        "unit": "°C",
        "system": "inmune",
        "valid_range": (30, 44),
        # >>> DATOS: línea base prevuelo, p. ej. Baseline(36.1, 37.2).
        "base": None,
        # >>> DATOS: límite terrestre de respaldo (supuesto de diseño), p. ej. 38.0.
        "abs_high": None,
        "abs_low": None,
        "series": [],
        "alert_when": "above",
        "rule": "Supuesto de diseño: 3 días consecutivos sobre la base personal.",
        "source": "Examen periódico de salud (NTRS 20250000330). Umbral: supuesto de diseño.",
    },
}

# Texto en inglés de cada métrica (label/rule/source). base/abs_high/abs_low/series/
# alert_when son el mismo objeto que en METRICS: ningún valor numérico cambia por idioma.
_METRICS_EN_TEXT: dict[str, dict] = {
    "systolic": {
        "label": "Systolic blood pressure",
        "rule": "Design assumption: 3 consecutive days above personal baseline.",
        "source": "Captured during periodic health exam (NTRS 20250000330). Threshold: design assumption.",
    },
    "heart_rate": {
        "label": "Resting heart rate",
        "rule": "Design assumption: 3 consecutive days above personal baseline.",
        "source": "Periodic health exam (NTRS 20250000330). Threshold: design assumption.",
    },
    "sleep_hours": {
        "label": "Sleep hours",
        "rule": "Design assumption: 8.5 h sleep period; sustained deficit from baseline.",
        "source": "Historical average <6.1 h (Basner et al., PMC4691281). Threshold: design assumption.",
    },
    "mood": {
        "label": "Mood (1-5)",
        "rule": "Design assumption: self-report below the usual range.",
        "source": "Self-report: design assumption, no published threshold.",
    },
}


def _translate(base: dict[str, dict], text_en: dict[str, dict]) -> dict[str, dict]:
    """Copia `base` pero reemplaza solo las claves de texto que trae `text_en`.

    Las claves numéricas/estructurales (base, series, abs_high...) quedan como
    el mismo objeto de `base`: nunca se duplican ni pueden desincronizarse.
    """
    return {key: {**m, **text_en.get(key, {})} for key, m in base.items()}


# Métricas agregadas con el panel calculado: su texto en inglés va en el mismo
# mecanismo, para que ?lang=en no mezcle idiomas en los azulejos.
_METRICS_EN_TEXT.update({
    "diastolic": {
        "label": "Diastolic blood pressure",
        "rule": "Design assumption: 3 consecutive days above personal baseline.",
        "source": "Periodic health exam (NTRS 20250000330). Threshold: design assumption.",
    },
    "spo2": {
        "label": "SpO₂",
        "rule": "Design assumption: saturation below personal baseline.",
        "source": "Periodic health exam (NTRS 20250000330). Threshold: design assumption.",
    },
    "macular_thickness": {
        "label": "Macular thickness",
        "rule": "Design assumption: 3 consecutive readings above personal baseline.",
        "source": "On-board OCT (see db/002_ojos.sql). Threshold: design assumption.",
    },
    "rnfl_thickness": {
        "label": "Nerve fibre layer (RNFL)",
        "rule": "Design assumption: 3 consecutive readings above personal baseline.",
        "source": "On-board OCT (see db/002_ojos.sql). Threshold: design assumption.",
    },
    "near_vision_logmar": {
        "label": "Near vision",
        "rule": "Design assumption: weekly self-test worse than personal baseline.",
        "source": "Near-vision self-test (see db/002_ojos.sql). Threshold: design assumption.",
    },
    "intraocular_pressure": {
        "label": "Intraocular pressure",
        "rule": "Design assumption: 3 consecutive readings above personal baseline.",
        "source": "On-board tonometer (see db/002_ojos.sql). Threshold: design assumption.",
    },
    "cup_to_disc_ratio": {
        "label": "Cup-to-disc ratio",
        "rule": "Design assumption: 3 consecutive readings above personal baseline.",
        "source": "Optic nerve imaging (see db/002_ojos.sql). Threshold: design assumption.",
    },
    "body_mass": {
        "label": "Body mass",
        "rule": "Design assumption: 3 consecutive days below personal baseline.",
        "source": "Weigh-in during periodic health exam (NTRS 20250000330). Threshold: design assumption.",
    },
    "pvt_ms": {
        "label": "Reaction time (PVT)",
        "rule": "Design assumption: 3 consecutive days above personal baseline.",
        "source": "Cognitive battery (~16 min) of the periodic exam. Threshold: design assumption.",
    },
    "temperature": {
        "label": "Body temperature",
        "rule": "Design assumption: 3 consecutive days above personal baseline.",
        "source": "Periodic health exam (NTRS 20250000330). Threshold: design assumption.",
    },
})

METRICS_EN: dict[str, dict] = _translate(METRICS, _METRICS_EN_TEXT)

# ---------------------------------------------------------------------------
# SANS: cambio de grosor retiniano (µm) frente a la base, una lectura por ciclo de OCT.
# Los umbrales (+20 / 55 µm) viven en rules.py porque son cifras publicadas.
# ---------------------------------------------------------------------------

# Límite de captura del cambio de grosor (µm); igual a indicators 'retinal_delta' en db/schema.sql.
SANS_VALID_RANGE = (-100, 300)

# >>> DATOS: deltas en µm por OCT, en orden (matriz: escenarios +8 · +22 · +58 µm).
SANS_SERIES: list[float] = []
# >>> DATOS: día de misión de cada OCT, misma longitud que SANS_SERIES (p. ej. [30, 90]).
SANS_DAYS: list[int] = []
# >>> FUENTE: referencia NASA exacta de los umbrales de SANS (NASA HRP / NTRS) para citarla en la app.
SANS_SOURCE = "Umbrales publicados de SANS: +20 µm primer signo; 55 µm preocupación clínica. Referencia NASA por confirmar."
SANS_SOURCE_EN = "Published SANS thresholds: +20 µm first sign; 55 µm clinical concern. NASA reference to be confirmed."

# Etiqueta de /trend/sans (no vive en METRICS porque SANS no se mide con valor único).
SANS_LABEL = "Grosor retiniano (cambio frente a la base)"
SANS_LABEL_EN = "Retinal thickness (change from baseline)"

ENVIRONMENTS = {
    "iss": {"label": "ISS", "delay": "tiempo real", "autonomous": False},
    "luna": {"label": "Luna", "delay": "4–12 s", "autonomous": True},
    "marte": {"label": "Marte", "delay": "hasta 20 min", "autonomous": True},
}

ENVIRONMENTS_EN = {
    "iss": {"label": "ISS", "delay": "real time", "autonomous": False},
    "luna": {"label": "Moon", "delay": "4–12 s", "autonomous": True},
    "marte": {"label": "Mars", "delay": "up to 20 min", "autonomous": True},
}


SYSTEMS = [
    {
        # Calculado: el estado y los azulejos los arma panel.py desde METRICS
        # (sistólica, diastólica, FC y SpO₂). Aquí solo vive el texto educativo.
        "id": "cardio",
        "name": "Corazón y circulación",
        "why": "En microgravedad los líquidos se desplazan hacia la cabeza y el corazón y los vasos "
        "se adaptan. La presión puede variar en las primeras semanas.",
        "action": "Repite la medición tras 5 min en reposo. Si sigue sobre tu base 3 días, TIRELUS "
        "la agrega al resumen de tu conferencia médica.",
    },
    {
        # Calculado: SANS (umbrales publicados) + los indicadores de ojos de 002_ojos.sql.
        "id": "ojos",
        "name": "Ojos y cerebro (SANS)",
        "why": "El desplazamiento de líquidos hacia la cabeza puede engrosar la retina y el nervio "
        "óptico. Es el principal riesgo de salud que señala NASA.",
        "action": "Haz la autoprueba de visión cercana cada semana y reporta visión borrosa en "
        "cuanto la notes.",
    },
    {
        # Calculado: masa corporal. El ejercicio y la carga en ARED no son indicadores del
        # esquema: viven en exercise_sessions y en la tarjeta de ejercicio del panel.
        "id": "hueso",
        "name": "Huesos y músculo",
        "why": "Sin carga del peso corporal, el hueso se degrada y el músculo se pierde. El "
        "ejercicio diario es la contramedida principal.",
        "action": "Completa los 8 minutos restantes de resistencia antes de las 18:00.",
    },
    {
        # Calculado: sueño, ánimo (autorreporte) y tiempo de reacción (PVT).
        "id": "mente",
        "name": "Sueño y ánimo",
        "why": "Horarios irregulares, ruido y aislamiento alteran el reloj biológico. La falta de "
        "sueño se nota primero en el tiempo de reacción.",
        "action": "Evita tareas críticas entre la 1 y las 7 h de tu ciclo. Opcional: agenda una "
        "conferencia psicológica privada.",
    },
    {
        # Calculado: temperatura. Síntomas y muestras de saliva no son indicadores medidos.
        "id": "inmune",
        "name": "Sistema inmune",
        "why": "El estrés del vuelo puede reactivar virus latentes y causar sarpullidos u otros síntomas.",
        "action": "Registra cualquier sarpullido, llaga o fiebre con foto; TIRELUS lo adjunta a tu expediente.",
    },
]

SYSTEMS_EN = [
    {
        # Computed: panel.py builds status and tiles from METRICS.
        "id": "cardio",
        "name": "Heart and circulation",
        "why": "In microgravity, fluids shift toward the head and the heart and vessels adapt. "
        "Blood pressure can vary during the first weeks.",
        "action": "Repeat the measurement after 5 min of rest. If it stays above your baseline for "
        "3 days, TIRELUS adds it to your medical conference summary.",
    },
    {
        # Computed: SANS (published thresholds) plus the eye indicators.
        "id": "ojos",
        "name": "Eyes and brain (SANS)",
        "why": "Fluid shift toward the head can thicken the retina and optic nerve. It's the main "
        "health risk NASA flags.",
        "action": "Do the near-vision self-test every week and report blurry vision as soon as you "
        "notice it.",
    },
    {
        # Computed: body mass. Exercise and ARED load are not schema indicators.
        "id": "hueso",
        "name": "Bone and muscle",
        "why": "Without body-weight loading, bone degrades and muscle is lost. Daily exercise is "
        "the main countermeasure.",
        "action": "Finish the remaining 8 minutes of resistance training before 18:00.",
    },
    {
        # Computed: sleep, mood (self-report) and reaction time (PVT).
        "id": "mente",
        "name": "Sleep and mood",
        "why": "Irregular schedules, noise and isolation disrupt the body clock. Sleep loss shows "
        "up first in reaction time.",
        "action": "Avoid critical tasks between hour 1 and 7 of your cycle. Optional: schedule a "
        "private psychological conference.",
    },
    {
        # Computed: temperature. Symptoms and saliva samples are not measured indicators.
        "id": "inmune",
        "name": "Immune system",
        "why": "Flight stress can reactivate latent viruses and cause rashes or other symptoms.",
        "action": "Log any rash, sore or fever with a photo; TIRELUS attaches it to your record.",
    },
]

TASKS = [
    {"time": "09:30", "title": "Medir presión arterial", "detail": "Guía paso a paso · 6 min", "pending": True},
    {"time": "14:00", "title": "Batería cognitiva", "detail": "10 pruebas · ~16 min", "pending": False},
]

TASKS_EN = [
    {"time": "09:30", "title": "Measure blood pressure", "detail": "Step-by-step guide · 6 min", "pending": True},
    {"time": "14:00", "title": "Cognitive battery", "detail": "10 tests · ~16 min", "pending": False},
]

EXERCISE = {"done_min": 112, "goal_min": 120}
STREAK_DAYS = 12

# Vista compartida de la base: sin datos clínicos.
HABITAT = {
    "day": 18,
    "gravity": "0.17 g",
    "link": "~4 s",
    "environment": [
        {"label": "CO₂", "value": "2.6", "unit": "mmHg", "status": "nominal"},
        {"label": "O₂", "value": "21.1", "unit": "%", "status": "nominal"},
        {"label": "Presión", "value": "101", "unit": "kPa", "status": "nominal"},
        {"label": "Temperatura", "value": "22.4", "unit": "°C", "status": "nominal"},
        {"label": "Ruido", "value": "52", "unit": "dBA", "status": "nominal"},
        {"label": "Polvo en esclusa", "value": "Alto", "unit": "", "status": "atencion"},
    ],
    "alert": "Clima espacial: posible evento de partículas solares en ~6 h. Revisa la ruta al "
    "refugio y limita las salidas al exterior.",
    "crew": [
        {"name": "Tripulante A · CMO", "location": "HÁBITAT", "detail": "2 tareas de salud pendientes hoy", "progress": 0.6},
        {"name": "Tripulante B", "location": "EVA · ROVER", "detail": "01:42 en el exterior · monitoreo activo", "highlight": True},
        {"name": "Tripulante C", "location": "LABORATORIO", "detail": "Tareas de salud al día", "progress": 1.0},
        {"name": "Tripulante D", "location": "DESCANSO", "detail": "Periodo de sueño · no molestar hasta 16:30"},
    ],
    "agenda": [
        {"time": "08:00", "title": "Vitales y pesaje · todos"},
        {"time": "10:30", "title": "OCT ocular · Tripulante A"},
        {"time": "13:00", "title": "Autorización médica pre-EVA · B"},
        {"time": "15:30", "title": "Muestras de saliva seca · todos"},
        {"time": "18:00", "title": "Conferencia médica privada · C"},
    ],
    "team_challenge": {"title": "Reto de equipo: ejercicio completo", "done": 3, "total": 5},
}

HABITAT_EN = {
    "day": 18,
    "gravity": "0.17 g",
    "link": "~4 s",
    "environment": [
        {"label": "CO₂", "value": "2.6", "unit": "mmHg", "status": "nominal"},
        {"label": "O₂", "value": "21.1", "unit": "%", "status": "nominal"},
        {"label": "Pressure", "value": "101", "unit": "kPa", "status": "nominal"},
        {"label": "Temperature", "value": "22.4", "unit": "°C", "status": "nominal"},
        {"label": "Noise", "value": "52", "unit": "dBA", "status": "nominal"},
        {"label": "Airlock dust", "value": "High", "unit": "", "status": "atencion"},
    ],
    "alert": "Space weather: possible solar particle event in ~6 h. Review the shelter route and "
    "limit outside excursions.",
    "crew": [
        {"name": "Crew Member A · CMO", "location": "HABITAT", "detail": "2 health tasks pending today", "progress": 0.6},
        {"name": "Crew Member B", "location": "EVA · ROVER", "detail": "01:42 outside · active monitoring", "highlight": True},
        {"name": "Crew Member C", "location": "LAB", "detail": "Health tasks up to date", "progress": 1.0},
        {"name": "Crew Member D", "location": "REST", "detail": "Sleep period · do not disturb until 16:30"},
    ],
    "agenda": [
        {"time": "08:00", "title": "Vitals and weigh-in · everyone"},
        {"time": "10:30", "title": "Eye OCT · Crew Member A"},
        {"time": "13:00", "title": "Pre-EVA medical clearance · B"},
        {"time": "15:30", "title": "Dry saliva samples · everyone"},
        {"time": "18:00", "title": "Private medical conference · C"},
    ],
    "team_challenge": {"title": "Team challenge: full exercise", "done": 3, "total": 5},
}

# Telemetría de caminata espacial (visor y variante de mano).
EVA = {
    "elapsed": "02:18",
    "o2_left": "5:42",
    "return_in_min": 48,
    "hr": 128,
    "spo2": 97,
    "temp": 37.6,
    "co2": "nominal",
    "effort": "alto",
    "alert": "Esfuerzo alto 4 min · baja el ritmo",
}

EVA_EN = {
    "elapsed": "02:18",
    "o2_left": "5:42",
    "return_in_min": 48,
    "hr": 128,
    "spo2": 97,
    "temp": 37.6,
    "co2": "nominal",
    "effort": "high",
    "alert": "High effort 4 min · slow down",
}

AUTONOMOUS_PROTOCOL = {
    "title": "Visión borrosa de cerca",
    "steps": [
        {"title": "Autoprueba de visión cercana", "detail": "Ojo derecho peor que tu base", "state": "done"},
        {"title": "OCT con guía en pantalla", "detail": "El CMO opera; TIRELUS indica la posición paso a paso", "state": "current"},
        {"title": "Comparar grosor retiniano con tu base", "detail": "Atención desde +20 µm · preocupación clínica 55 µm", "state": "todo"},
        {"title": "Decisión a bordo", "detail": "Opciones del protocolo + inventario del botiquín", "state": "todo"},
    ],
    "message": "D212 · Visión cercana ↓ OD\nPA 124/80 · FC 62 · sin cefalea\nOCT: pendiente (paso 2/4)\n"
    "Adjuntos: autoprueba, tendencia 30 d",
    "queue": [
        {"title": "Resumen semanal D210", "state": "Recibido"},
        {"title": "Respuesta a consulta de sueño", "state": "Llega en 9 min"},
        # Estos dos valores ("Este protocolo" / "Recibido" arriba) NO se traducen:
        # autonomous_screen.dart los compara literalmente en español (q['title']
        # == 'Este protocolo', q['state'] == 'Recibido') para decidir el check
        # verde y el toggle de envío. Traducirlos rompería eso en inglés.
        {"title": "Este protocolo", "state": "Borrador"},
    ],
}

AUTONOMOUS_PROTOCOL_EN = {
    "title": "Blurry near vision",
    "steps": [
        {"title": "Near-vision self-test", "detail": "Right eye worse than your baseline", "state": "done"},
        {"title": "OCT with on-screen guide", "detail": "The CMO operates; TIRELUS guides the position step by step", "state": "current"},
        {"title": "Compare retinal thickness with your baseline", "detail": "Attention from +20 µm · clinical concern at 55 µm", "state": "todo"},
        {"title": "On-board decision", "detail": "Protocol options + medical kit inventory", "state": "todo"},
    ],
    "message": "D212 · Near vision ↓ OD\nBP 124/80 · HR 62 · no headache\nOCT: pending (step 2/4)\n"
    "Attachments: self-test, 30-day trend",
    "queue": [
        {"title": "Weekly summary D210", "state": "Recibido"},
        {"title": "Reply to sleep inquiry", "state": "Arrives in 9 min"},
        {"title": "Este protocolo", "state": "Borrador"},
    ],
}


def for_lang(lang: str) -> SimpleNamespace:
    """Devuelve las constantes traducibles para `lang` ("es" o "en"; cualquier otro cae en "es").

    Los ids, claves y valores numéricos son los mismos objetos en los dos
    idiomas; solo cambia el texto (label/name/why/action/...).
    """
    if lang == "en":
        return SimpleNamespace(
            SYSTEMS=SYSTEMS_EN,
            TASKS=TASKS_EN,
            ENVIRONMENTS=ENVIRONMENTS_EN,
            METRICS=METRICS_EN,
            HABITAT=HABITAT_EN,
            EVA=EVA_EN,
            AUTONOMOUS_PROTOCOL=AUTONOMOUS_PROTOCOL_EN,
            SANS_SOURCE=SANS_SOURCE_EN,
            SANS_LABEL=SANS_LABEL_EN,
        )
    return SimpleNamespace(
        SYSTEMS=SYSTEMS,
        TASKS=TASKS,
        ENVIRONMENTS=ENVIRONMENTS,
        METRICS=METRICS,
        HABITAT=HABITAT,
        EVA=EVA,
        AUTONOMOUS_PROTOCOL=AUTONOMOUS_PROTOCOL,
        SANS_SOURCE=SANS_SOURCE,
        SANS_LABEL=SANS_LABEL,
    )
