"""Configuración de PostgreSQL por variables de entorno (nunca en el código)."""

import pytest

from db import DbConfig, config_from_env


def test_sin_host_la_base_queda_desactivada():
    assert config_from_env({}) is None
    assert config_from_env({"TIRELUS_DB_HOST": "  "}) is None


def test_valores_por_defecto():
    cfg = config_from_env({"TIRELUS_DB_HOST": "db.ejemplo.test"})
    assert cfg == DbConfig(host="db.ejemplo.test", port=5432, name="tirelus", user="postgres",
                           password="", timeout=3.0, astronaut_id=None)


def test_lee_todas_las_variables():
    cfg = config_from_env({
        "TIRELUS_DB_HOST": "10.0.0.5",
        "TIRELUS_DB_PORT": "6543",
        "TIRELUS_DB_NAME": "tirelus_dev",
        "TIRELUS_DB_USER": "equipo",
        "TIRELUS_DB_PASSWORD": "secreto",
        "TIRELUS_DB_TIMEOUT": "1.5",
        "TIRELUS_ASTRONAUT_ID": "11111111-2222-3333-4444-555555555555",
    })
    assert cfg.host == "10.0.0.5"
    assert cfg.port == 6543
    assert cfg.name == "tirelus_dev"
    assert cfg.user == "equipo"
    assert cfg.password == "secreto"
    assert cfg.timeout == 1.5
    assert cfg.astronaut_id == "11111111-2222-3333-4444-555555555555"


def test_la_contrasena_no_aparece_en_repr_ni_str():
    cfg = config_from_env({"TIRELUS_DB_HOST": "h", "TIRELUS_DB_PASSWORD": "secreto"})
    assert "secreto" not in repr(cfg)
    assert "secreto" not in str(cfg)


def test_puerto_invalido_falla_sin_filtrar_la_contrasena():
    with pytest.raises(ValueError) as err:
        config_from_env({"TIRELUS_DB_HOST": "h", "TIRELUS_DB_PORT": "abc", "TIRELUS_DB_PASSWORD": "secreto"})
    assert "TIRELUS_DB_PORT" in str(err.value)
    assert "secreto" not in str(err.value)
