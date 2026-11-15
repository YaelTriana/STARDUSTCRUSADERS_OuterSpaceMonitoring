"""Rangos válidos: un valor fuera de rango es error de captura, no un estado de salud.

Los rangos son los mismos de `indicators.valid_min/valid_max` en db/schema.sql y son un
supuesto de diseño (límites de captura, no umbrales clínicos). La base no los valida
(se probó: aceptó 9999 mmHg), así que la API y el catálogo los aplican.
"""

import pytest
from fastapi.testclient import TestClient

import data
import main
from catalog import Catalog
from rules import Baseline, within_valid_range

client = TestClient(main.app)

SCHEMA_RANGES = {
    "systolic": (50, 260),
    "heart_rate": (20, 230),
    "sleep_hours": (0, 24),
    "mood": (1, 5),
}


def test_within_valid_range_incluye_los_extremos():
    assert within_valid_range(50, (50, 260))
    assert within_valid_range(260, (50, 260))
    assert not within_valid_range(49.9, (50, 260))
    assert not within_valid_range(260.1, (50, 260))


@pytest.mark.parametrize("raro", [float("nan"), float("inf"), float("-inf")])
def test_within_valid_range_rechaza_no_finitos(raro):
    assert not within_valid_range(raro, (-1e9, 1e9))


def test_cada_metrica_declara_el_rango_del_esquema():
    for metric, expected in SCHEMA_RANGES.items():
        assert data.METRICS[metric]["valid_range"] == expected
    assert data.SANS_VALID_RANGE == (-100, 300)


def test_las_series_de_ejemplo_estan_dentro_de_su_rango():
    for entry in data.METRICS.values():
        assert all(within_valid_range(v, entry["valid_range"]) for v in entry["series"])


@pytest.mark.parametrize("metric,value", [("systolic", 9999), ("systolic", 49), ("heart_rate", 231),
                                           ("sleep_hours", 25), ("sleep_hours", -1), ("mood", 6), ("mood", 0)])
def test_evaluate_rechaza_valores_fuera_de_rango(metric, value):
    r = client.post(f"/evaluate/{metric}", json={"value": value})
    assert r.status_code == 422
    assert r.json()["detail"]["valid_range"] == list(SCHEMA_RANGES[metric])


@pytest.mark.parametrize("metric", list(SCHEMA_RANGES))
def test_evaluate_acepta_los_extremos_del_rango(metric):
    lo, hi = SCHEMA_RANGES[metric]
    assert client.post(f"/evaluate/{metric}", json={"value": lo}).status_code == 200
    assert client.post(f"/evaluate/{metric}", json={"value": hi}).status_code == 200


def test_evaluate_rechaza_nan():
    r = client.post("/evaluate/systolic", content=b'{"value": NaN}', headers={"content-type": "application/json"})
    assert r.status_code == 422


def test_evaluate_sans_valida_su_rango():
    assert client.post("/evaluate/sans", json={"value": 500}).status_code == 422
    assert client.post("/evaluate/sans", json={"value": -101}).status_code == 422
    assert client.post("/evaluate/sans", json={"value": 300}).status_code == 200
    assert client.post("/evaluate/sans", json={"value": -100}).status_code == 200


def test_el_rango_se_valida_aunque_la_metrica_no_tenga_base():
    # heart_rate no tiene base de ejemplo: aun así 9999 es un error de captura.
    assert client.post("/evaluate/heart_rate", json={"value": 9999}).status_code == 422


def catalogo(overlay):
    return Catalog(data.METRICS, {"series": data.SANS_SERIES, "days": data.SANS_DAYS}, loader=lambda: overlay)


def test_el_catalogo_descarta_lecturas_de_la_base_fuera_de_rango():
    overlay = {
        "metrics": {"systolic": {"base": Baseline(110, 126), "series": [118.0, 9999.0, 121.0, -5.0, 130.0]}},
        "sans": {"series": [], "days": []},
    }
    snap = catalogo(overlay).snapshot()
    assert snap.metrics["systolic"]["series"] == [118.0, 121.0, 130.0]


def test_el_catalogo_descarta_sans_fuera_de_rango_y_mantiene_los_dias_alineados():
    overlay = {"metrics": {}, "sans": {"series": [8.0, 9999.0, 22.0], "days": [30, 60, 90]}}
    snap = catalogo(overlay).snapshot()
    assert snap.sans_series == [8.0, 22.0]
    assert snap.sans_days == [30, 90]
