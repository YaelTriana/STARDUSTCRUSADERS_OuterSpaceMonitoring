"""Lectura de línea base, límites y series desde PostgreSQL (con una conexión DB-API falsa)."""

from decimal import Decimal

from db import load_overlay

IDS = ["systolic", "heart_rate", "sleep_hours", "mood"]
ASTRO = "11111111-2222-3333-4444-555555555555"


class FakeCursor:
    def __init__(self, conn):
        self.conn = conn
        self._rows = []

    def execute(self, sql, params=None):
        self.conn.executed.append((sql, params))
        self._rows = []
        for clave, filas in self.conn.rows.items():
            if clave in sql:
                self._rows = filas
                break

    def fetchall(self):
        return list(self._rows)

    def fetchone(self):
        return self._rows[0] if self._rows else None

    def close(self):
        pass


class FakeConn:
    """Devuelve filas según la tabla que mencione la consulta (FROM astronauts, FROM baselines...)."""

    def __init__(self, rows):
        self.rows = rows
        self.executed = []

    def cursor(self):
        return FakeCursor(self)


def conn_completa():
    return FakeConn({
        "FROM astronauts": [(ASTRO,)],
        "FROM baselines": [("systolic", Decimal("110"), Decimal("126")), ("heart_rate", Decimal("55"), Decimal("66"))],
        "FROM thresholds": [("systolic", None, Decimal("160")), ("sleep_hours", Decimal("5"), None)],
        "FROM measurements": [
            ("systolic", Decimal("118"), 45),
            ("systolic", Decimal("120"), 46),
            ("systolic", Decimal("132"), 47),
            ("retinal_delta", Decimal("8"), 30),
            ("retinal_delta", Decimal("22"), 90),
        ],
    })


def test_devuelve_base_limites_y_serie_como_floats():
    ov = load_overlay(conn_completa(), IDS, ASTRO)
    sis = ov["metrics"]["systolic"]
    assert (sis["base"].low, sis["base"].high) == (110.0, 126.0)
    assert sis["abs_high"] == 160.0
    assert sis["series"] == [118.0, 120.0, 132.0]
    assert all(type(v) is float for v in sis["series"])


def test_critico_bajo_se_convierte_en_abs_low():
    ov = load_overlay(conn_completa(), IDS, ASTRO)
    assert ov["metrics"]["sleep_hours"] == {"abs_low": 5.0}


def test_solo_trae_lo_que_la_base_tiene():
    ov = load_overlay(conn_completa(), IDS, ASTRO)
    assert set(ov["metrics"]["heart_rate"]) == {"base"}
    assert "mood" not in ov["metrics"]


def test_ignora_indicadores_fuera_del_catalogo():
    conn = FakeConn({
        "FROM astronauts": [(ASTRO,)],
        "FROM baselines": [("spo2", Decimal("95"), Decimal("100"))],
    })
    assert load_overlay(conn, IDS, ASTRO)["metrics"] == {}


def test_la_serie_de_sans_sale_del_indicador_retinal_delta():
    ov = load_overlay(conn_completa(), IDS, ASTRO)
    assert ov["sans"] == {"series": [8.0, 22.0], "days": [30, 90]}
    assert "retinal_delta" not in ov["metrics"]


def test_sans_ignora_lecturas_sin_dia_de_mision():
    conn = FakeConn({
        "FROM astronauts": [(ASTRO,)],
        "FROM measurements": [("retinal_delta", Decimal("8"), None), ("retinal_delta", Decimal("22"), 90)],
    })
    assert load_overlay(conn, IDS, ASTRO)["sans"] == {"series": [22.0], "days": [90]}


def test_sin_tripulante_configurado_usa_el_primero_de_la_base():
    conn = conn_completa()
    ov = load_overlay(conn, IDS, None)
    assert ov["metrics"]["systolic"]["series"] == [118.0, 120.0, 132.0]
    params_baselines = [p for sql, p in conn.executed if "FROM baselines" in sql][0]
    assert ASTRO in params_baselines


def test_sin_tripulantes_en_la_base_no_devuelve_nada():
    conn = FakeConn({"FROM astronauts": []})
    assert load_overlay(conn, IDS, None) == {"metrics": {}, "sans": {"series": [], "days": []}}
