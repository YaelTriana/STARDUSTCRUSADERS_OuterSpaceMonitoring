"""La API sirve los datos de PostgreSQL cuando hay base y cae a los de ejemplo cuando no."""

import pytest
from fastapi.testclient import TestClient

import data
import main
from catalog import Catalog
from rules import Baseline

OVERLAY = {
    "metrics": {"heart_rate": {"base": Baseline(55, 66), "abs_high": 100.0, "series": [60.0, 61.0, 70.0, 71.0, 72.0]}},
    "sans": {"series": [8.0, 22.0], "days": [30, 90]},
}

client = TestClient(main.app)


def catalogo(loader):
    return Catalog(data.METRICS, {"series": data.SANS_SERIES, "days": data.SANS_DAYS}, loader=loader)


@pytest.fixture
def con_base(monkeypatch):
    monkeypatch.setattr(main, "catalog", catalogo(lambda: OVERLAY))


@pytest.fixture
def base_caida(monkeypatch):
    def roto():
        raise ConnectionError("sin servidor")

    monkeypatch.setattr(main, "catalog", catalogo(roto))


def test_health_dice_de_donde_salen_los_datos_por_defecto():
    assert client.get("/health").json()["data_source"] == "ejemplo"


def test_health_con_base(con_base):
    body = client.get("/health").json()
    assert body["ok"] is True
    assert body["data_source"] == "db"


def test_tendencia_usa_la_serie_de_la_base(con_base):
    body = client.get("/trend/heart_rate").json()
    assert body["series"] == [60.0, 61.0, 70.0, 71.0, 72.0]
    assert body["base"] == {"low": 55.0, "high": 66.0}
    assert body["status"] == "atencion"
    assert body["consecutive_above"] == 3
    assert body["sample_data"] is True


def test_catalogo_de_metricas_marca_con_datos_las_que_trae_la_base(con_base):
    por_id = {m["id"]: m for m in client.get("/metrics").json()["metrics"]}
    assert por_id["heart_rate"]["has_data"] is True
    assert por_id["spo2"]["has_data"] is False  # ni la base ni data.py la traen


def test_evaluacion_usa_la_base_personal_de_la_base_de_datos(con_base):
    body = client.post("/evaluate/heart_rate", json={"value": 80}).json()
    assert body["status"] != "sin_dato"
    assert body["base"] == {"low": 55.0, "high": 66.0}


def test_sans_usa_las_lecturas_de_la_base(con_base):
    body = client.get("/trend/sans").json()
    assert body["series"] == [8.0, 22.0]
    assert body["days"] == [30, 90]
    assert body["status"] == "atencion"  # +22 µm supera el primer signo (+20)


def test_si_la_base_esta_caida_la_api_responde_con_datos_de_ejemplo(base_caida):
    health = client.get("/health").json()
    assert health["ok"] is True
    assert health["data_source"] == "ejemplo"
    assert health["db_error"] == "ConnectionError"
    assert client.get("/trend/systolic").json()["series"] == data.SYSTOLIC_14
    # FC ya tiene datos de ejemplo: con la base caída se sirven esos, no "sin dato".
    assert client.get("/trend/heart_rate").json()["series"] == data.METRICS["heart_rate"]["series"]
