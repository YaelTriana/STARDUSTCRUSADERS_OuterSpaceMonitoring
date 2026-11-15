"""Carga de los datos sintéticos del equipo hacia PostgreSQL (tools/sim_sinteticos.py).

El generador (repo SyntheticData_STARDUSTCRUSADERS) produce un CSV por tripulante con
68 columnas. Aquí se prueba la traducción a los indicadores de db/schema.sql: el mapeo,
la línea base personal prevuelo, el ánimo derivado del estrés y el delta retiniano de SANS.
"""

import re
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))

import sim_sinteticos as sim  # noqa: E402


def test_el_mapeo_solo_apunta_a_indicadores_que_existen_en_el_esquema():
    """Si el esquema cambia, esta prueba lo caza antes de un INSERT roto."""
    db = Path(__file__).resolve().parents[2] / "db"
    ids: set[str] = set()
    for archivo in ("schema.sql", "002_ojos.sql"):  # los de ojos viven en la migración 002
        texto = (db / archivo).read_text(encoding="utf-8")
        for bloque in texto.split("INSERT INTO indicators")[1:]:
            # Hasta el siguiente INSERT: no se puede cortar en ";" porque los textos
            # del catálogo llevan punto y coma ("vuelo largo; suele ser…").
            ids |= set(re.findall(r"\('([a-z_0-9]+)',", bloque.split("INSERT INTO ")[0]))
    destinos = {m.indicator for m in sim.MAPEO.values()}
    assert destinos <= ids, f"indicadores inexistentes en el esquema: {sorted(destinos - ids)}"


def test_el_animo_sale_del_estres_invertido_en_escala_1_a_5():
    assert sim.animo_desde_estres(0.0) == 5.0  # sin estrés
    assert sim.animo_desde_estres(10.0) == 1.0  # estrés máximo
    assert sim.animo_desde_estres(5.0) == 3.0


def test_el_animo_se_queda_dentro_del_rango_valido_aunque_el_estres_se_salga():
    assert sim.animo_desde_estres(-2.0) == 5.0
    assert sim.animo_desde_estres(99.0) == 1.0


def test_la_linea_base_es_la_media_mas_menos_dos_desviaciones():
    base = sim.linea_base([10.0, 12.0, 14.0])  # media 12, sd poblacional 1.633
    assert base is not None
    low, high = base
    assert round(low, 2) == 8.73
    assert round(high, 2) == 15.27


def test_una_linea_base_necesita_al_menos_dos_lecturas():
    assert sim.linea_base([120.0]) is None
    assert sim.linea_base([]) is None


def test_si_no_hay_variacion_la_base_no_queda_en_cero_de_ancho():
    """Con lecturas idénticas, un rango de ancho cero marcaría todo como desviación."""
    base = sim.linea_base([70.0, 70.0, 70.0])
    assert base is not None
    low, high = base
    assert low < 70.0 < high


def test_el_delta_retiniano_se_mide_contra_la_primera_lectura():
    assert sim.deltas_retinianos([100.0, 108.0, 122.0]) == [0.0, 8.0, 22.0]


def test_el_delta_retiniano_necesita_una_primera_lectura():
    assert sim.deltas_retinianos([]) == []


def test_las_filas_sin_dato_no_producen_lecturas():
    fila = {"Heart_Rate": "", "Sleep_Hours": "6.5", "Systolic_BP": None}
    lecturas = sim.lecturas_de_fila(fila, dia=5)
    assert [(l.indicator, l.value) for l in lecturas] == [("sleep_hours", 6.5)]
    assert lecturas[0].mission_day == 5


def test_una_fila_completa_traduce_cada_columna_a_su_indicador():
    fila = {
        "Heart_Rate": "64", "Systolic_BP": "132", "Diastolic_BP": "84",
        "Oxygen_Saturation_pct": "98", "Body_Temperature_c": "36.7",
        "Respiratory_Rate_bpm": "14", "Derived_HRV_s": "0.12",
        "Sleep_Hours": "6.1", "Weight_kg": "72.4", "PVT_Reaction_Time_ms": "310",
        "Stress_Level": "5.0",
    }
    porIndicador = {l.indicator: l.value for l in sim.lecturas_de_fila(fila, dia=47)}
    assert porIndicador["heart_rate"] == 64.0
    assert porIndicador["systolic"] == 132.0
    assert porIndicador["spo2"] == 98.0
    assert porIndicador["temperature"] == 36.7
    assert porIndicador["body_mass"] == 72.4
    assert porIndicador["pvt_ms"] == 310.0
    assert porIndicador["mood"] == 3.0  # estrés 5 → ánimo 3


def test_el_client_id_es_estable_para_la_misma_lectura():
    """La base es idempotente por client_id: recargar no debe duplicar."""
    a = sim.client_id("SC-00001", "systolic", 47)
    b = sim.client_id("SC-00001", "systolic", 47)
    c = sim.client_id("SC-00001", "systolic", 48)
    assert a == b and a != c
    assert len(a) == 36 and a.count("-") == 4  # uuid


@pytest.mark.parametrize("valor", ["", None, "nan", "NaN"])
def test_los_valores_vacios_o_nan_se_ignoran(valor):
    assert sim.lecturas_de_fila({"Heart_Rate": valor}, dia=1) == []
