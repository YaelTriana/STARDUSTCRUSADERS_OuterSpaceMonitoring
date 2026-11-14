"""Pruebas del resumen exportable para la conferencia médica privada (P0)."""

import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python_app"))

from fastapi.testclient import TestClient  # noqa: E402

import data  # noqa: E402
from main import app  # noqa: E402

client = TestClient(app)


def _export() -> dict:
    res = client.get("/summary/export")
    assert res.status_code == 200
    return res.json()


def test_exporta_markdown_con_los_hallazgos():
    client.post("/summary", json={"item": "PA 132/84 mmHg · atención frente a tu base"})
    client.post("/summary", json={"item": "Sistólica 3 días sobre la base (hoy 132 mmHg)"})
    texto = _export()["text"]
    assert texto.startswith("# Resumen para la conferencia médica privada")
    assert "- PA 132/84 mmHg · atención frente a tu base" in texto
    assert "- Sistólica 3 días sobre la base (hoy 132 mmHg)" in texto


def test_incluye_fecha_dia_de_mision_y_etiqueta_de_ejemplo():
    body = _export()
    texto = body["text"]
    assert date.today().isoformat() in texto
    assert f"Día de misión: {data.MISSION_DAY}" in texto
    assert "Datos de ejemplo" in texto
    assert body["sample_data"] is True
    assert body["mission_day"] == data.MISSION_DAY


def test_recuerda_que_no_diagnostica_y_quien_puede_verlo():
    texto = _export()["text"]
    assert "no diagnostica" in texto
    assert "CMO" in texto and "flight surgeon" in texto


def test_resumen_vacio_lo_dice_explicitamente():
    body = _export()
    assert body["items"] == []
    assert "Sin hallazgos registrados" in body["text"]


def test_nombre_de_archivo_sugerido():
    nombre = _export()["filename"]
    assert nombre == f"tirelus_resumen_D{data.MISSION_DAY}_{date.today().isoformat()}.md"
