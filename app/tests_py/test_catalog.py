"""Catálogo: datos de ejemplo + capa opcional de PostgreSQL, con respaldo si la base falla."""

from decimal import Decimal

import data
from catalog import Catalog, build_catalog
from rules import Baseline

OVERLAY = {
    "metrics": {"heart_rate": {"base": Baseline(55, 66), "abs_high": 100.0, "series": [60.0, 61.0, 70.0, 71.0, 72.0]}},
    "sans": {"series": [8.0, 22.0], "days": [30, 90]},
}


class Reloj:
    def __init__(self):
        self.t = 0.0

    def __call__(self):
        return self.t


def hacer(loader=None, ttl=30.0, reloj=None):
    return Catalog(data.METRICS, {"series": data.SANS_SERIES, "days": data.SANS_DAYS},
                   loader=loader, ttl=ttl, clock=reloj or Reloj())


def test_sin_base_usa_los_datos_de_ejemplo():
    snap = hacer().snapshot()
    assert snap.source == "ejemplo"
    assert snap.metrics["systolic"]["series"] == data.SYSTOLIC_14
    assert snap.metrics["spo2"]["base"] is None  # sin datos de ejemplo todavía


def test_con_base_la_sobrepone_sobre_el_catalogo():
    snap = hacer(loader=lambda: OVERLAY).snapshot()
    assert snap.source == "db"
    hr = snap.metrics["heart_rate"]
    assert (hr["base"].low, hr["base"].high, hr["abs_high"]) == (55, 66, 100.0)
    assert hr["series"] == [60.0, 61.0, 70.0, 71.0, 72.0]
    assert hr["label"] == "FC en reposo"  # texto, regla y fuente siguen siendo del catálogo
    assert hr["alert_when"] == "above"
    assert (snap.sans_series, snap.sans_days) == ([8.0, 22.0], [30, 90])


def test_lo_que_la_base_no_trae_se_queda_como_estaba():
    snap = hacer(loader=lambda: OVERLAY).snapshot()
    assert snap.metrics["systolic"] == data.METRICS["systolic"]


def test_no_modifica_data_metrics():
    antes = dict(data.METRICS["heart_rate"])
    hacer(loader=lambda: OVERLAY).snapshot()
    # El overlay trae otra base y otra serie para FC: data.METRICS no debe moverse.
    assert data.METRICS["heart_rate"]["base"] == antes["base"]
    assert data.METRICS["heart_rate"]["series"] == antes["series"]


def test_base_vacia_cuenta_como_ejemplo():
    snap = hacer(loader=lambda: {"metrics": {}, "sans": {"series": [], "days": []}}).snapshot()
    assert snap.source == "ejemplo"


def test_si_la_base_falla_la_app_sigue_con_datos_de_ejemplo():
    def roto():
        raise ConnectionError("servidor caído")

    snap = hacer(loader=roto).snapshot()
    assert snap.source == "ejemplo"
    assert snap.metrics["systolic"]["series"] == data.SYSTOLIC_14


def test_registra_solo_el_tipo_del_error_para_diagnosticar():
    def roto():
        raise ConnectionError("password authentication failed for user x with secreto")

    cat = hacer(loader=roto)
    assert cat.last_error is None
    cat.snapshot()
    assert cat.last_error == "ConnectionError"


def test_cachea_la_lectura_dentro_del_ttl_y_recarga_despues():
    llamadas = []
    reloj = Reloj()

    def loader():
        llamadas.append(1)
        return OVERLAY

    cat = hacer(loader=loader, ttl=30.0, reloj=reloj)
    cat.snapshot()
    reloj.t = 29.0
    cat.snapshot()
    assert len(llamadas) == 1
    reloj.t = 31.0
    cat.snapshot()
    assert len(llamadas) == 2


def test_un_fallo_tambien_se_cachea_para_no_golpear_al_servidor():
    llamadas = []
    reloj = Reloj()

    def roto():
        llamadas.append(1)
        raise TimeoutError("sin respuesta")

    cat = hacer(loader=roto, ttl=30.0, reloj=reloj)
    cat.snapshot()
    cat.snapshot()
    assert len(llamadas) == 1
    reloj.t = 31.0
    cat.snapshot()
    assert len(llamadas) == 2


def test_se_recupera_cuando_la_base_vuelve():
    estado = {"caida": True}
    reloj = Reloj()

    def loader():
        if estado["caida"]:
            raise ConnectionError("caída")
        return OVERLAY

    cat = hacer(loader=loader, ttl=30.0, reloj=reloj)
    assert cat.snapshot().source == "ejemplo"
    estado["caida"] = False
    reloj.t = 31.0
    assert cat.snapshot().source == "db"


# --- build_catalog: arma el catálogo desde las variables de entorno -------------


class _Cursor:
    def __init__(self, conn):
        self.conn = conn
        self.rows = []

    def execute(self, sql, params=None):
        self.rows = []
        if "FROM astronauts" in sql:
            self.rows = [("a-1",)]
        elif "FROM baselines" in sql:
            self.rows = [("heart_rate", Decimal("55"), Decimal("66"))]

    def fetchall(self):
        return self.rows

    def fetchone(self):
        return self.rows[0] if self.rows else None


class _Conn:
    def __init__(self):
        self.cerrada = False

    def cursor(self):
        return _Cursor(self)

    def close(self):
        self.cerrada = True


def test_build_sin_variables_no_toca_la_red():
    def no_debe_llamarse(cfg):
        raise AssertionError("no debía conectar")

    cat = build_catalog({}, connect_fn=no_debe_llamarse)
    assert cat.snapshot().source == "ejemplo"


def test_build_con_variables_conecta_lee_y_cierra():
    conexiones = []

    def conectar(cfg):
        assert cfg.host == "db.ejemplo.test"
        c = _Conn()
        conexiones.append(c)
        return c

    cat = build_catalog({"TIRELUS_DB_HOST": "db.ejemplo.test"}, connect_fn=conectar)
    snap = cat.snapshot()
    assert snap.source == "db"
    assert snap.metrics["heart_rate"]["base"].high == 66.0
    assert len(conexiones) == 1 and conexiones[0].cerrada


def test_build_con_configuracion_invalida_no_tumba_la_app():
    cat = build_catalog({"TIRELUS_DB_HOST": "h", "TIRELUS_DB_PORT": "abc"}, connect_fn=lambda cfg: None)
    assert cat.snapshot().source == "ejemplo"


# --- cada cuánto se relee la base ------------------------------------------


def contador_de_intentos(cargas: list):
    def connect_fn(cfg):
        cargas.append(cfg.host)
        raise ConnectionError("solo se cuentan los intentos de relectura")

    return connect_fn


def test_el_ttl_por_defecto_es_de_treinta_segundos():
    cargas, reloj = [], Reloj()
    cat = build_catalog(env={"TIRELUS_DB_HOST": "servidor"}, connect_fn=contador_de_intentos(cargas), clock=reloj)
    cat.snapshot()
    reloj.t = 29.0
    cat.snapshot()
    assert len(cargas) == 1  # dentro del TTL no se vuelve a molestar al servidor
    reloj.t = 31.0
    cat.snapshot()
    assert len(cargas) == 2


def test_el_ttl_sale_de_tirelus_db_ttl():
    """Para la demo conviene un refresco corto; en la nave, uno largo."""
    cargas, reloj = [], Reloj()
    cat = build_catalog(
        env={"TIRELUS_DB_HOST": "servidor", "TIRELUS_DB_TTL": "5"},
        connect_fn=contador_de_intentos(cargas),
        clock=reloj,
    )
    cat.snapshot()
    reloj.t = 4.0
    cat.snapshot()
    assert len(cargas) == 1
    reloj.t = 6.0
    cat.snapshot()
    assert len(cargas) == 2


def test_un_ttl_invalido_no_desactiva_la_base():
    cargas, reloj = [], Reloj()
    cat = build_catalog(
        env={"TIRELUS_DB_HOST": "servidor", "TIRELUS_DB_TTL": "cada rato"},
        connect_fn=contador_de_intentos(cargas),
        clock=reloj,
    )
    cat.snapshot()
    reloj.t = 31.0
    cat.snapshot()
    assert len(cargas) == 2  # vuelve al TTL de 30 s en vez de quedarse sin base
