"""TLS opcional hacia PostgreSQL. Por defecto apagado (la demo corre en una LAN privada)."""

import ssl

import pg8000.dbapi
import pytest

import db
from db import DbConfig, config_from_env, connect, ssl_context_for


def test_por_defecto_sin_tls():
    cfg = config_from_env({"TIRELUS_DB_HOST": "h"})
    assert cfg.ssl_mode == "off"
    assert cfg.ssl_ca is None
    assert ssl_context_for(cfg) is None


@pytest.mark.parametrize("valor", ["off", "require", "verify"])
def test_lee_el_modo_tls(valor):
    assert config_from_env({"TIRELUS_DB_HOST": "h", "TIRELUS_DB_SSL": valor}).ssl_mode == valor


def test_el_modo_tls_no_distingue_mayusculas_ni_espacios():
    assert config_from_env({"TIRELUS_DB_HOST": "h", "TIRELUS_DB_SSL": " Require "}).ssl_mode == "require"


def test_modo_tls_invalido_nombra_la_variable_y_no_el_valor():
    with pytest.raises(ValueError) as err:
        config_from_env({"TIRELUS_DB_HOST": "h", "TIRELUS_DB_SSL": "quizas"})
    assert "TIRELUS_DB_SSL" in str(err.value)
    assert "quizas" not in str(err.value)


def test_lee_la_ruta_del_certificado_de_la_autoridad():
    cfg = config_from_env({"TIRELUS_DB_HOST": "h", "TIRELUS_DB_SSL": "verify", "TIRELUS_DB_SSL_CA": "C:/ca.pem"})
    assert cfg.ssl_ca == "C:/ca.pem"


def test_require_cifra_sin_verificar_el_certificado():
    ctx = ssl_context_for(DbConfig(host="h", ssl_mode="require"))
    assert isinstance(ctx, ssl.SSLContext)
    assert ctx.verify_mode == ssl.CERT_NONE
    assert ctx.check_hostname is False


def test_verify_exige_certificado_y_nombre_de_host():
    ctx = ssl_context_for(DbConfig(host="h", ssl_mode="verify"))
    assert ctx.verify_mode == ssl.CERT_REQUIRED
    assert ctx.check_hostname is True


def test_verify_usa_el_certificado_indicado(monkeypatch):
    usado = {}
    original = ssl.create_default_context

    def falso(cafile=None, **kwargs):
        usado["cafile"] = cafile
        return original()

    monkeypatch.setattr(db.ssl, "create_default_context", falso)
    ssl_context_for(DbConfig(host="h", ssl_mode="verify", ssl_ca="C:/ca.pem"))
    assert usado["cafile"] == "C:/ca.pem"


def test_connect_pasa_el_contexto_tls_a_pg8000(monkeypatch):
    recibido = {}
    monkeypatch.setattr(pg8000.dbapi, "connect", lambda **kw: recibido.update(kw) or object())
    connect(DbConfig(host="h", ssl_mode="require"))
    assert isinstance(recibido["ssl_context"], ssl.SSLContext)


def test_connect_sin_tls_no_pide_cifrado(monkeypatch):
    recibido = {}
    monkeypatch.setattr(pg8000.dbapi, "connect", lambda **kw: recibido.update(kw) or object())
    connect(DbConfig(host="h"))
    assert recibido.get("ssl_context") is None


def test_la_contrasena_sigue_fuera_del_repr_con_tls():
    assert "secreto" not in repr(DbConfig(host="h", password="secreto", ssl_mode="require"))
