"""Pruebas de las tareas P1: resumen persistente, métricas genéricas y SANS."""

import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python_app"))

from fastapi.testclient import TestClient  # noqa: E402

import data  # noqa: E402
from main import app  # noqa: E402

client = TestClient(app)


# La fixture carpeta_de_datos vive en conftest.py.

# --- 1. Resumen persistente -------------------------------------------------


class TestResumenPersistente:
    def test_empieza_vacio(self):
        assert client.get("/summary").json()["items"] == []

    def test_se_guarda_en_json(self, carpeta_de_datos):
        client.post("/summary", json={"item": "PA sobre la base 3 días"})
        guardado = json.loads((carpeta_de_datos / "summary.json").read_text(encoding="utf-8"))
        assert guardado == ["PA sobre la base 3 días"]

    def test_sobrevive_a_un_reinicio(self, carpeta_de_datos):
        # Simula una sesión anterior que dejó el archivo escrito.
        (carpeta_de_datos / "summary.json").write_text(json.dumps(["Sueño < 6 h"]), encoding="utf-8")
        assert client.get("/summary").json()["items"] == ["Sueño < 6 h"]

    def test_no_duplica(self):
        client.post("/summary", json={"item": "X"})
        client.post("/summary", json={"item": "X"})
        assert client.get("/summary").json()["items"] == ["X"]

    def test_archivo_corrupto_no_tumba_la_api(self, carpeta_de_datos):
        (carpeta_de_datos / "summary.json").write_text("{no es json", encoding="utf-8")
        assert client.get("/summary").json()["items"] == []


# --- 2. Métricas genéricas ---------------------------------------------------


class TestMetricasGenericas:
    def test_catalogo_lista_las_metricas(self):
        body = client.get("/metrics").json()
        ids = {m["id"] for m in body["metrics"]}
        assert {"systolic", "heart_rate", "sleep_hours", "mood"} <= ids

    def test_tendencia_generica_igual_a_la_sistolica(self):
        assert client.get("/trend/systolic").json()["status"] == "atencion"
        body = client.get("/trend/systolic").json()
        assert body["metric"] == "systolic"
        assert body["unit"] == "mmHg"
        assert body["first_day"] == 34

    def test_evaluacion_generica(self):
        assert client.post("/evaluate/systolic", json={"value": 118}).json()["status"] == "nominal"
        assert client.post("/evaluate/systolic", json={"value": 165}).json()["status"] == "critico"

    def test_metrica_desconocida_da_404(self):
        assert client.get("/trend/colesterol").status_code == 404
        assert client.post("/evaluate/colesterol", json={"value": 1}).status_code == 404

    @pytest.mark.parametrize("metric", ["heart_rate", "sleep_hours", "mood"])
    def test_metrica_sin_datos_responde_sin_dato(self, metric, monkeypatch):
        monkeypatch.setitem(data.METRICS, metric, {**data.METRICS[metric], "series": [], "base": None})
        assert client.get(f"/trend/{metric}").json()["status"] == "sin_dato"
        # Un valor dentro del rango válido de cada métrica (FC 20–230, sueño 0–24, ánimo 1–5).
        valido = {"heart_rate": 60, "sleep_hours": 7, "mood": 3}[metric]
        assert client.post(f"/evaluate/{metric}", json={"value": valido}).json()["status"] == "sin_dato"

    def test_todas_las_metricas_dicen_que_son_datos_de_ejemplo(self):
        for m in client.get("/metrics").json()["metrics"]:
            assert client.get(f"/trend/{m['id']}").json()["sample_data"] is True


# --- 3. SANS -------------------------------------------------------------------


class TestSans:
    @pytest.mark.parametrize(
        ("delta", "esperado"),
        [(8, "nominal"), (19.9, "nominal"), (20, "atencion"), (22, "atencion"), (55, "critico"), (58, "critico")],
    )
    def test_evaluar_cambio_de_grosor(self, delta, esperado):
        body = client.post("/evaluate/sans", json={"value": delta}).json()
        assert body["status"] == esperado
        assert body["thresholds"] == {"attention_um": 20.0, "critical_um": 55.0}

    def test_la_respuesta_trae_la_fuente(self):
        body = client.post("/evaluate/sans", json={"value": 8}).json()
        assert body["source"]

    def test_tendencia_sans_sin_serie_es_sin_dato(self, monkeypatch):
        monkeypatch.setattr(data, "SANS_SERIES", [])
        assert client.get("/trend/sans").json()["status"] == "sin_dato"


# --- 4. Tendencias a la baja (sueño y ánimo) ----------------------------------


class TestTendenciaALaBajaEnLaApi:
    def test_sueno_bajo_la_base_alerta(self, monkeypatch):
        from rules import Baseline

        monkeypatch.setitem(
            data.METRICS,
            "sleep_hours",
            {**data.METRICS["sleep_hours"], "base": Baseline(6.5, 8.5), "abs_low": 5.0,
             "series": [7.8, 7.5, 7.0, 6.2, 6.0, 5.8]},
        )
        body = client.get("/trend/sleep_hours").json()
        assert body["alert_when"] == "below"
        assert body["status"] == "atencion"
        assert body["consecutive_below"] == 3
        assert body["delta_from_low"] == pytest.approx(-0.7)

    def test_sistolica_sigue_alertando_hacia_arriba(self):
        body = client.get("/trend/systolic").json()
        assert body["status"] == "atencion"
        assert body["consecutive_below"] == 0
