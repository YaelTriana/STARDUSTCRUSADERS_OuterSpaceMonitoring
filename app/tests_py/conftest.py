import pytest


@pytest.fixture(autouse=True)
def carpeta_de_datos(tmp_path, monkeypatch):
    """Ninguna prueba escribe el resumen médico fuera de una carpeta temporal."""
    monkeypatch.setenv("TIRELUS_DATA_DIR", str(tmp_path))
    return tmp_path
