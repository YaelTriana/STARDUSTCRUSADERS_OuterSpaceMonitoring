"""DATOS DE EJEMPLO de TIRELUS. Sintéticos, solo para el mockup."""

from __future__ import annotations

from rules import Baseline

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
#   alert_when        → "above", "below" o "both": hacia dónde preocupa la desviación
#                       (igual que indicators.alert_when en db/schema.sql)
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
        # >>> DATOS: línea base prevuelo de FC en reposo, p. ej. Baseline(55, 66).
        "base": None,
        # >>> DATOS: límite terrestre de respaldo (supuesto de diseño), p. ej. 100.0.
        "abs_high": None,
        "abs_low": None,
        # >>> DATOS: 14 lecturas diarias D34–D47 (matriz: escenarios nominal · atención).
        "series": [],
        "alert_when": "both",  # igual que la base: preocupa si sube o si baja
        "rule": "Supuesto de diseño: 3 días consecutivos fuera de la base personal, por arriba o por abajo.",
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
        "alert_when": "both",  # igual que la base: preocupa si sube o si baja
        "rule": "Supuesto de diseño: 3 días consecutivos fuera de la base personal, por arriba o por abajo.",
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
        "alert_when": "both",  # igual que la base: preocupa si sube o si baja
        "rule": "Supuesto de diseño: 3 días consecutivos fuera de la base personal, por arriba o por abajo.",
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
        "alert_when": "both",  # igual que la base: preocupa si sube o si baja
        "rule": "Supuesto de diseño: 3 días consecutivos fuera de la base personal, por arriba o por abajo.",
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
        # >>> DATOS: línea base prevuelo de sueño, p. ej. Baseline(6.5, 8.5).
        "base": None,
        "abs_high": None,
        # >>> DATOS: mínimo de respaldo (supuesto de diseño), p. ej. 5.0.
        "abs_low": None,
        # >>> DATOS: 14 noches D34–D47 (matriz: escenarios nominal · déficit).
        "series": [],
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
        # >>> DATOS: rango habitual del tripulante, p. ej. Baseline(3, 5).
        "base": None,
        "abs_high": None,
        # >>> DATOS: mínimo de respaldo (supuesto de diseño), p. ej. 1.0.
        "abs_low": None,
        # >>> DATOS: 14 autorreportes D34–D47 (matriz: escenarios estable · baja).
        "series": [],
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
        "alert_when": "both",  # igual que la base: preocupa si sube o si baja
        "rule": "Supuesto de diseño: 3 días consecutivos fuera de la base personal, por arriba o por abajo.",
        "source": "Examen periódico de salud (NTRS 20250000330). Umbral: supuesto de diseño.",
    },
}

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

ENVIRONMENTS = {
    "iss": {"label": "ISS", "delay": "tiempo real", "autonomous": False},
    "luna": {"label": "Luna", "delay": "4–12 s", "autonomous": True},
    "marte": {"label": "Marte", "delay": "hasta 20 min", "autonomous": True},
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

TASKS = [
    {"time": "09:30", "title": "Medir presión arterial", "detail": "Guía paso a paso · 6 min", "pending": True},
    {"time": "14:00", "title": "Batería cognitiva", "detail": "10 pruebas · ~16 min", "pending": False},
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
        {"title": "Este protocolo", "state": "Borrador"},
    ],
}
