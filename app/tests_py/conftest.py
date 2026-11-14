import sys
from pathlib import Path

import pytest

# Las pruebas importan rules, data, db y catalog directamente desde python_app.
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python_app"))


@pytest.fixture(autouse=True)
def carpeta_de_datos(tmp_path, monkeypatch):
    """Ninguna prueba escribe el resumen médico fuera de una carpeta temporal."""
    monkeypatch.setenv("TIRELUS_DATA_DIR", str(tmp_path))
    return tmp_path
