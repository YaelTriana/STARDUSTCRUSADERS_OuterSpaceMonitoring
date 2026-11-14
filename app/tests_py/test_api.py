import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python_app"))

from fastapi.testclient import TestClient  # noqa: E402

from main import app  # noqa: E402

client = TestClient(app)


def test_health():
    assert client.get("/health").json()["ok"] is True


def test_dashboard_tiene_cinco_sistemas():
    body = client.get("/dashboard").json()
    assert len(body["systems"]) == 5
    assert body["sample_data"] is True


def test_tendencia_sistolica():
    body = client.get("/trend/systolic").json()
    assert body["status"] == "atencion"
    assert body["first_day"] == 34
    assert body["days_out_of_range"] == 5


def test_evaluar_lectura():
    assert client.post("/evaluate/systolic", json={"value": 118}).json()["status"] == "nominal"
    assert client.post("/evaluate/systolic", json={"value": 132}).json()["status"] == "atencion"


def test_modo_autonomo_usa_el_retraso_del_entorno():
    body = client.get("/autonomous", params={"env": "luna"}).json()
    assert body["env"]["delay"] == "4–12 s"
    assert len(body["steps"]) == 4


def test_habitat_no_expone_datos_clinicos():
    crew = client.get("/habitat").json()["crew"]
    for member in crew:
        assert set(member) <= {"name", "location", "detail", "progress", "highlight"}


def test_resumen_medico():
    client.post("/summary", json={"item": "PA sistólica sobre la base 3 días"})
    items = client.get("/summary").json()["items"]
    assert "PA sistólica sobre la base 3 días" in items
