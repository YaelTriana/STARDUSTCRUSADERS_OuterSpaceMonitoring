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
        "base": SYSTOLIC_BASE,
        "abs_high": SYSTOLIC_ABS_HIGH,
        "abs_low": None,
        "series": SYSTOLIC_14,
        "alert_when": "above",
        "rule": "Supuesto de diseño: 3 días consecutivos sobre la base personal.",
        "source": "Captura en examen periódico de salud (NTRS 20250000330). Umbral: supuesto de diseño.",
    },
    "heart_rate": {
        "label": "FC en reposo",
        "unit": "lpm",
        # >>> DATOS: línea base prevuelo de FC en reposo, p. ej. Baseline(55, 66).
        "base": None,
        # >>> DATOS: límite terrestre de respaldo (supuesto de diseño), p. ej. 100.0.
        "abs_high": None,
        "abs_low": None,
        # >>> DATOS: 14 lecturas diarias D34–D47 (matriz: escenarios nominal · atención).
        "series": [],
        "alert_when": "above",
        "rule": "Supuesto de diseño: 3 días consecutivos sobre la base personal.",
        "source": "Examen periódico de salud (NTRS 20250000330). Umbral: supuesto de diseño.",
    },
    "sleep_hours": {
        "label": "Horas de sueño",
        "unit": "h",
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
}

# ---------------------------------------------------------------------------
# SANS: cambio de grosor retiniano (µm) frente a la base, una lectura por ciclo de OCT.
# Los umbrales (+20 / 55 µm) viven en rules.py porque son cifras publicadas.
# ---------------------------------------------------------------------------

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


def _ind(label, value, unit, note, status="nominal"):
    return {"label": label, "value": value, "unit": unit, "note": note, "status": status}


SYSTEMS = [
    {
        "id": "cardio",
        "name": "Corazón y circulación",
        "status": "atencion",
        "indicators": [
            _ind("Presión arterial", "132/84", "mmHg", "▲ base 118/76", "atencion"),
            _ind("FC en reposo", "64", "lpm", "base 60"),
            _ind("SpO₂", "98", "%", "en rango"),
        ],
        "why": "En microgravedad los líquidos se desplazan hacia la cabeza y el corazón y los vasos "
        "se adaptan. La presión puede variar en las primeras semanas.",
        "action": "Repite la medición tras 5 min en reposo. Si sigue sobre tu base 3 días, TIRELUS "
        "la agrega al resumen de tu conferencia médica.",
    },
    {
        "id": "ojos",
        "name": "Ojos y cerebro (SANS)",
        "status": "nominal",
        "indicators": [
            _ind("Grosor retiniano", "+8", "µm", "atención desde +20"),
            _ind("Visión cercana", "sin cambio", "", "autoprueba semanal"),
            _ind("Próximo OCT", "D90", "", "en 43 días"),
        ],
        "why": "El desplazamiento de líquidos hacia la cabeza puede engrosar la retina y el nervio "
        "óptico. Es el principal riesgo de salud que señala NASA.",
        "action": "Haz la autoprueba de visión cercana cada semana y reporta visión borrosa en "
        "cuanto la notes.",
    },
    {
        "id": "hueso",
        "name": "Huesos y músculo",
        "status": "nominal",
        "indicators": [
            _ind("Ejercicio hoy", "1:52", "h", "meta ~2 h"),
            _ind("Masa corporal", "72.4", "kg", "base 73.0"),
            _ind("Carga en ARED", "estable", "", "últimos 7 días"),
        ],
        "why": "Sin carga del peso corporal, el hueso se degrada y el músculo se pierde. El "
        "ejercicio diario es la contramedida principal.",
        "action": "Completa los 8 minutos restantes de resistencia antes de las 18:00.",
    },
    {
        "id": "mente",
        "name": "Sueño y ánimo",
        "status": "atencion",
        "indicators": [
            _ind("Sueño anoche", "6:10", "h", "▼ periodo 8.5 h", "atencion"),
            _ind("Ánimo", "3", "/5", "autorreporte"),
            _ind("Reacción (PVT)", "+9", "%", "más lento que tu base", "atencion"),
        ],
        "why": "Horarios irregulares, ruido y aislamiento alteran el reloj biológico. La falta de "
        "sueño se nota primero en el tiempo de reacción.",
        "action": "Evita tareas críticas entre la 1 y las 7 h de tu ciclo. Opcional: agenda una "
        "conferencia psicológica privada.",
    },
    {
        "id": "inmune",
        "name": "Sistema inmune",
        "status": "nominal",
        "indicators": [
            _ind("Temperatura", "36.7", "°C", "en rango"),
            _ind("Síntomas", "ninguno", "", "registro de hoy"),
            _ind("Muestra de saliva", "D60", "", "en 13 días"),
        ],
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
