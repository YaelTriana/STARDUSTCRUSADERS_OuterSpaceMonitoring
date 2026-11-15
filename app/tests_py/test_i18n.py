"""API bilingüe: ?lang=es|en en los endpoints con texto para el usuario.

Con lang=en ninguna cadena clave debe salir en español; con lang=es o sin
lang, la respuesta debe quedar igual que antes de agregar el idioma.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python_app"))

from fastapi.testclient import TestClient  # noqa: E402

import data  # noqa: E402
from main import app, build_summary_export  # noqa: E402

client = TestClient(app)

# Palabras que no deben aparecer en una respuesta en inglés.
SPANISH_MARKERS = [
    "Presión",
    "Corazón",
    "Sueño",
    "Hueso",
    "músculo",
    "Ánimo",
    "sistólica",
    "tripulante",
    "Tripulante",
    "Resumen",
    "hallazgos",
    "diagnostica",
]


def _no_spanish(text: str) -> None:
    for word in SPANISH_MARKERS:
        assert word not in text, f"'{word}' no debería aparecer en la respuesta en inglés:\n{text}"


# --- /dashboard --------------------------------------------------------------


def test_dashboard_es_default_queda_igual_que_antes():
    body = client.get("/dashboard").json()
    assert body["systems"][0]["name"] == "Corazón y circulación"
    assert body["systems"][0]["why"].startswith("En microgravedad")
    assert body["tasks"][0]["title"] == "Medir presión arterial"


def test_dashboard_es_explicito_queda_igual():
    body = client.get("/dashboard", params={"lang": "es"}).json()
    assert body["systems"][0]["name"] == "Corazón y circulación"


def test_dashboard_en_sin_espanol():
    body = client.get("/dashboard", params={"lang": "en"}).json()
    assert body["systems"][0]["name"] == "Heart and circulation"
    _no_spanish(str(body))
    # Mismos ids, mismo orden, mismos valores numéricos que en español.
    es = client.get("/dashboard").json()
    for s_es, s_en in zip(es["systems"], body["systems"]):
        assert s_es["id"] == s_en["id"]
        assert s_es["status"] == s_en["status"]
        for i_es, i_en in zip(s_es["indicators"], s_en["indicators"]):
            # "value" puede ser texto traducible (p. ej. "sin cambio" / "no change");
            # unit y status son los que deben quedar idénticos entre idiomas.
            assert i_es["unit"] == i_en["unit"]
            assert i_es["status"] == i_en["status"]
    assert body["mission_day"] == es["mission_day"]
    assert body["streak_days"] == es["streak_days"]
    assert body["exercise"] == es["exercise"]


def test_lang_invalido_cae_en_espanol():
    body = client.get("/dashboard", params={"lang": "fr"}).json()
    assert body["systems"][0]["name"] == "Corazón y circulación"


# --- /metrics ------------------------------------------------------------


def test_metrics_en_traduce_etiquetas_sin_cambiar_ids():
    es = client.get("/metrics").json()["metrics"]
    en = client.get("/metrics", params={"lang": "en"}).json()["metrics"]
    assert [m["id"] for m in es] == [m["id"] for m in en]
    assert [m["unit"] for m in es] == [m["unit"] for m in en]
    assert [m["has_data"] for m in es] == [m["has_data"] for m in en]
    systolic_en = next(m for m in en if m["id"] == "systolic")
    assert systolic_en["label"] == "Systolic blood pressure"
    _no_spanish(str(en))


# --- /environments --------------------------------------------------------


def test_environments_en():
    body = client.get("/environments", params={"lang": "en"}).json()
    assert body["iss"]["label"] == "ISS"
    assert body["luna"]["label"] == "Moon"
    assert body["marte"]["label"] == "Mars"
    # El retraso en segundos/minutos no cambia, solo el texto que lo rodea.
    assert body["luna"]["delay"] == "4–12 s"
    assert body["iss"]["autonomous"] is False
    assert body["marte"]["autonomous"] is True


def test_environments_es_default():
    body = client.get("/environments").json()
    assert body["luna"]["label"] == "Luna"
    assert body["marte"]["label"] == "Marte"


# --- /trend/{metric} y /evaluate/{metric} ---------------------------------


def test_trend_systolic_en_mismos_numeros():
    es = client.get("/trend/systolic").json()
    en = client.get("/trend/systolic", params={"lang": "en"}).json()
    assert en["label"] == "Systolic blood pressure"
    assert en["series"] == es["series"]
    assert en["base"] == es["base"]
    assert en["status"] == es["status"]
    assert en["days_out_of_range"] == es["days_out_of_range"]
    _no_spanish(en["rule"] + en["source"])


def test_metrica_desconocida_en_ingles():
    res = client.get("/trend/no-existe", params={"lang": "en"})
    assert res.status_code == 404
    assert "desconocida" not in res.json()["detail"]


def test_evaluate_acepta_lang_sin_romper():
    body = client.post("/evaluate/systolic", params={"lang": "en"}, json={"value": 118}).json()
    assert body["status"] == "nominal"


# --- /trend/sans y /evaluate/sans -----------------------------------------


def test_trend_sans_en():
    body = client.get("/trend/sans", params={"lang": "en"}).json()
    assert body["label"] == "Retinal thickness (change from baseline)"
    _no_spanish(body["source"])


def test_evaluate_sans_en():
    body = client.post("/evaluate/sans", params={"lang": "en"}, json={"value": 25}).json()
    assert body["status"] == "atencion"
    _no_spanish(body["source"])


# --- /autonomous -----------------------------------------------------------


def test_autonomous_en_traduce_pero_mantiene_estados():
    es = client.get("/autonomous", params={"env": "luna"}).json()
    en = client.get("/autonomous", params={"env": "luna", "lang": "en"}).json()
    assert en["env"]["label"] == "Moon"
    assert en["title"] == "Blurry near vision"
    assert [s["state"] for s in en["steps"]] == [s["state"] for s in es["steps"]]
    assert len(en["steps"]) == len(es["steps"]) == 4
    _no_spanish(en["title"] + en["message"] + "".join(s["title"] + s["detail"] for s in en["steps"]))
    # Excepción documentada: estos dos valores no se traducen porque el Dart
    # de autonomous_screen.dart los compara literalmente para decidir el ok
    # ("recibido") y el toggle de "Este protocolo" (isThis). Traducirlos
    # rompería ese comportamiento en inglés.
    assert en["queue"][2]["title"] == "Este protocolo"
    assert en["queue"][0]["state"] == "Recibido"
    # El resto de la cola sí se traduce.
    assert en["queue"][1]["title"] != es["queue"][1]["title"]


# --- /habitat y /eva ---------------------------------------------------------


def test_habitat_en_sin_datos_clinicos_y_sin_espanol():
    body = client.get("/habitat", params={"lang": "en"}).json()
    crew = body["crew"]
    for member in crew:
        assert set(member) <= {"name", "location", "detail", "progress", "highlight"}
    _no_spanish(str(body))
    assert body["day"] == data.HABITAT["day"]
    assert body["gravity"] == data.HABITAT["gravity"]


def test_eva_en():
    body = client.get("/eva", params={"lang": "en"}).json()
    assert body["effort"] == "high"
    assert body["hr"] == data.EVA["hr"]
    assert body["spo2"] == data.EVA["spo2"]
    _no_spanish(body["alert"])


# --- /summary/export ---------------------------------------------------------


def test_build_summary_export_en():
    texto = build_summary_export(["Finding one"], data.MISSION_DAY, __import__("datetime").date.today(), lang="en")
    assert texto.startswith("# Summary for the private medical conference")
    assert "- Finding one" in texto
    assert "does not diagnose" in texto
    assert "CMO" in texto and "flight surgeon" in texto
    assert f"Mission day: {data.MISSION_DAY}" in texto


def test_build_summary_export_es_default_queda_igual():
    texto = build_summary_export([], data.MISSION_DAY, __import__("datetime").date.today())
    assert texto.startswith("# Resumen para la conferencia médica privada")
    assert "Sin hallazgos registrados" in texto


def test_summary_export_endpoint_en():
    body = client.get("/summary/export", params={"lang": "en"}).json()
    assert body["text"].startswith("# Summary for the private medical conference")
    assert body["mission_day"] == data.MISSION_DAY
