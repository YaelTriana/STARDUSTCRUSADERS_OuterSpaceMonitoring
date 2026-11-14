import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python_app"))

import data  # noqa: E402
from rules import Baseline, Status, evaluate_reading, evaluate_sans, evaluate_trend  # noqa: E402

BASE = Baseline(110, 126)


class TestEvaluateReading:
    def test_dentro_de_la_base_es_nominal(self):
        assert evaluate_reading(118, BASE) is Status.NOMINAL

    def test_los_bordes_cuentan_como_dentro(self):
        assert evaluate_reading(110, BASE) is Status.NOMINAL
        assert evaluate_reading(126, BASE) is Status.NOMINAL

    def test_fuera_de_la_base_es_atencion(self):
        assert evaluate_reading(132, BASE) is Status.ATENCION
        assert evaluate_reading(105, BASE) is Status.ATENCION

    def test_limite_absoluto_es_critico(self):
        assert evaluate_reading(160, BASE, absolute_high=160) is Status.CRITICO
        assert evaluate_reading(80, BASE, absolute_low=85) is Status.CRITICO


class TestEvaluateTrend:
    def test_serie_vacia_es_sin_dato(self):
        assert evaluate_trend([], BASE).status is Status.SIN_DATO

    def test_dos_dias_sobre_la_base_sigue_nominal(self):
        r = evaluate_trend([120, 122, 128, 130], BASE)
        assert r.consecutive_above == 2
        assert r.status is Status.NOMINAL

    def test_tres_dias_seguidos_es_atencion(self):
        r = evaluate_trend([120, 128, 129, 131], BASE)
        assert r.consecutive_above == 3
        assert r.status is Status.ATENCION

    def test_un_dia_en_rango_rompe_la_racha(self):
        r = evaluate_trend([128, 129, 125, 131], BASE)
        assert r.consecutive_above == 1
        assert r.status is Status.NOMINAL

    def test_hoy_sobre_limite_absoluto_es_critico(self):
        assert evaluate_trend([120, 165], BASE, absolute_high=160).status is Status.CRITICO

    def test_datos_de_ejemplo(self):
        r = evaluate_trend(data.SYSTOLIC_14, data.SYSTOLIC_BASE, absolute_high=data.SYSTOLIC_ABS_HIGH)
        assert r.status is Status.ATENCION
        assert r.days_out_of_range == 5
        assert r.delta_from_high == 6


class TestEvaluateSans:
    def test_menos_de_20_um_es_nominal(self):
        assert evaluate_sans(8) is Status.NOMINAL

    def test_20_um_es_atencion(self):
        assert evaluate_sans(20) is Status.ATENCION

    def test_55_um_es_critico(self):
        assert evaluate_sans(55) is Status.CRITICO
