"""Datos de ejemplo de FC, sueño y ánimo para /trend y /metrics (Tendencia)."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python_app"))

from fastapi.testclient import TestClient  # noqa: E402

import data  # noqa: E402
from main import app  # noqa: E402

client = TestClient(app)

NEW_METRICS = ["heart_rate", "sleep_hours", "mood"]

# Última lectura de hoy (D47): debe coincidir con lo que /dashboard ya muestra
# en SYSTEMS para cardio (FC) y mente (sueño, ánimo).
LAST_READING = {"heart_rate": 64, "sleep_hours": 6.17, "mood": 3}


# --- (a) has_data true para las tres, en es y en -----------------------------


def test_metrics_catalogo_marca_has_data_true_en_espanol():
    metrics = {m["id"]: m for m in client.get("/metrics").json()["metrics"]}
    for key in NEW_METRICS:
        assert metrics[key]["has_data"] is True, f"{key} debería tener datos de ejemplo"


def test_metrics_catalogo_marca_has_data_true_en_ingles():
    metrics = {m["id"]: m for m in client.get("/metrics", params={"lang": "en"}).json()["metrics"]}
    for key in NEW_METRICS:
        assert metrics[key]["has_data"] is True, f"{key} debería tener datos de ejemplo también en inglés"


# --- (b) la última lectura coincide con el Panel ------------------------------


def test_ultima_lectura_coincide_con_el_panel():
    dashboard = client.get("/dashboard").json()
    cardio = next(s for s in dashboard["systems"] if s["id"] == "cardio")
    mente = next(s for s in dashboard["systems"] if s["id"] == "mente")
    fc_panel = next(i for i in cardio["indicators"] if i["label"] == "FC en reposo")
    sueno_panel = next(i for i in mente["indicators"] if i["label"] == "Sueño anoche")
    animo_panel = next(i for i in mente["indicators"] if i["label"] == "Ánimo")

    assert fc_panel["value"] == "64"
    assert sueno_panel["value"] == "6:10"
    assert animo_panel["value"] == "3"

    for key in NEW_METRICS:
        body = client.get(f"/trend/{key}").json()
        assert body["series"][-1] == LAST_READING[key], f"última lectura de {key} no coincide con el Panel"
        assert body["first_day"] == data.MISSION_DAY - len(body["series"]) + 1
        assert len(body["series"]) == 14


# --- (c) sleep_hours y mood evalúan "atención" por desviación sostenida (below) ---


def test_sleep_hours_dispara_atencion_por_deficit_sostenido():
    body = client.get("/trend/sleep_hours").json()
    assert body["alert_when"] == "below"
    assert body["status"] == "atencion"
    assert body["consecutive_below"] >= 3


def test_mood_dispara_atencion_por_caida_sostenida():
    body = client.get("/trend/mood").json()
    assert body["alert_when"] == "below"
    assert body["status"] == "atencion"
    assert body["consecutive_below"] >= 3


# --- (d) heart_rate no dispara alerta crítica ---------------------------------


def test_heart_rate_no_es_critico():
    body = client.get("/trend/heart_rate").json()
    assert body["status"] != "critico"
    assert body["alert_when"] == "above"
    # Ninguna lectura cruza la base (66): no debería haber racha sostenida arriba.
    assert body["consecutive_above"] == 0


# --- (e) /evaluate/{metric} responde 200 dentro y fuera de rango -------------


def test_evaluate_heart_rate_dentro_y_fuera_de_rango():
    dentro = client.post("/evaluate/heart_rate", json={"value": 60})
    fuera = client.post("/evaluate/heart_rate", json={"value": 80})
    assert dentro.status_code == 200 and dentro.json()["status"] == "nominal"
    assert fuera.status_code == 200 and fuera.json()["status"] == "atencion"


def test_evaluate_sleep_hours_dentro_y_fuera_de_rango():
    dentro = client.post("/evaluate/sleep_hours", json={"value": 7.5})
    fuera = client.post("/evaluate/sleep_hours", json={"value": 6.0})
    assert dentro.status_code == 200 and dentro.json()["status"] == "nominal"
    assert fuera.status_code == 200 and fuera.json()["status"] == "atencion"


def test_evaluate_mood_dentro_y_fuera_de_rango():
    dentro = client.post("/evaluate/mood", json={"value": 4})
    fuera = client.post("/evaluate/mood", json={"value": 2})
    assert dentro.status_code == 200 and dentro.json()["status"] == "nominal"
    assert fuera.status_code == 200 and fuera.json()["status"] == "atencion"
