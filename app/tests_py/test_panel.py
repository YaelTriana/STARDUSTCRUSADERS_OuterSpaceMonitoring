"""Panel por sistema calculado desde el catálogo y el motor de reglas (módulo cardio).

El panel no puede llevar cifras escritas a mano: cada azulejo sale del catálogo
(datos de ejemplo o PostgreSQL) y su estado lo decide rules.py.
"""

from fastapi.testclient import TestClient

import data
import panel
from main import app
from rules import Baseline

CONTENIDO_CARDIO = {
    "id": "cardio",
    "name": "Corazón y circulación",
    "why": "porque sí",
    "action": "repite la medición",
}


def con_metricas(**cambios) -> dict:
    """Copia del catálogo de ejemplo con las métricas indicadas reemplazadas."""
    metricas = {key: dict(value) for key, value in data.METRICS.items()}
    for key, campos in cambios.items():
        metricas[key].update(campos)
    return metricas


def azulejo(bloque: dict, label: str) -> dict:
    return next(i for i in bloque["indicators"] if i["label"] == label)


def test_cardio_marca_atencion_por_la_tendencia_sostenida_de_la_sistolica():
    bloque = panel.build_system("cardio", data.METRICS, CONTENIDO_CARDIO)
    assert bloque["status"] == "atencion"


def test_el_azulejo_de_la_sistolica_muestra_el_valor_de_hoy_y_su_variacion():
    bloque = panel.build_system("cardio", data.METRICS, CONTENIDO_CARDIO)
    sistolica = azulejo(bloque, "Presión sistólica")
    assert sistolica["value"] == "132"
    assert sistolica["unit"] == "mmHg"
    assert sistolica["status"] == "atencion"
    assert "6" in sistolica["note"] and "110" in sistolica["note"] and "126" in sistolica["note"]


def test_una_metrica_sin_datos_dice_sin_dato():
    bloque = panel.build_system("cardio", data.METRICS, CONTENIDO_CARDIO)
    fc = azulejo(bloque, "FC en reposo")
    assert (fc["value"], fc["note"], fc["status"]) == ("—", "Sin dato", "sin_dato")


def test_el_estado_del_sistema_es_el_peor_de_sus_indicadores_con_datos():
    metricas = con_metricas(heart_rate={"base": Baseline(55, 66), "abs_high": 100.0,
                                        "series": [60.0, 62.0, 104.0]})
    bloque = panel.build_system("cardio", metricas, CONTENIDO_CARDIO)
    assert azulejo(bloque, "FC en reposo")["status"] == "critico"
    assert bloque["status"] == "critico"  # la sistólica sigue en atención; manda la peor


def test_un_sistema_sin_ninguna_metrica_con_datos_queda_en_sin_dato():
    metricas = con_metricas(systolic={"base": None, "series": []})
    bloque = panel.build_system("cardio", metricas, CONTENIDO_CARDIO)
    assert bloque["status"] == "sin_dato"


def test_el_estado_sigue_a_los_datos_del_catalogo():
    """Lo que se pidió: si la serie vuelve a su rango, el panel deja de alertar."""
    metricas = con_metricas(systolic={"series": [118.0, 120.0, 119.0, 121.0]})
    bloque = panel.build_system("cardio", metricas, CONTENIDO_CARDIO)
    assert bloque["status"] == "nominal"
    assert azulejo(bloque, "Presión sistólica")["value"] == "121"


def test_conserva_el_texto_educativo_del_sistema():
    bloque = panel.build_system("cardio", data.METRICS, CONTENIDO_CARDIO)
    assert bloque["name"] == "Corazón y circulación"
    assert bloque["why"] == "porque sí"
    assert bloque["action"] == "repite la medición"


def test_los_valores_con_decimales_no_se_redondean_a_entero():
    metricas = con_metricas(spo2={"base": Baseline(95, 100), "series": [97.5]})
    bloque = panel.build_system("cardio", metricas, CONTENIDO_CARDIO)
    assert azulejo(bloque, "SpO₂")["value"] == "97.5"


# --- /dashboard ------------------------------------------------------------

client = TestClient(app)

CONTRATO_SISTEMA = {"id", "name", "status", "indicators", "why", "action"}
CONTRATO_AZULEJO = {"label", "value", "unit", "note", "status"}


def sistema(body: dict, system_id: str) -> dict:
    return next(s for s in body["systems"] if s["id"] == system_id)


def test_dashboard_calcula_cardio_desde_el_catalogo():
    cardio = sistema(client.get("/dashboard").json(), "cardio")
    assert cardio["computed"] is True
    assert cardio["status"] == "atencion"
    sistolica = next(i for i in cardio["indicators"] if i["label"] == "Presión sistólica")
    assert (sistolica["value"], sistolica["status"]) == ("132", "atencion")


def test_dashboard_marca_los_sistemas_que_siguen_siendo_mockup():
    body = client.get("/dashboard").json()
    assert [s["id"] for s in body["systems"] if not s["computed"]] == ["ojos", "hueso", "mente", "inmune"]


def test_dashboard_conserva_el_contrato_que_lee_flutter():
    body = client.get("/dashboard").json()
    assert len(body["systems"]) == 5
    for s in body["systems"]:
        assert CONTRATO_SISTEMA <= set(s), s["id"]
        for azulejo_json in s["indicators"]:
            assert CONTRATO_AZULEJO <= set(azulejo_json), azulejo_json


# --- la nota explica por qué un valor fuera de la base aún no alerta --------


def test_un_dia_fuera_de_la_base_dice_en_que_parte_del_conteo_va():
    """Evita el azulejo contradictorio: valor sobre la base pero estado nominal."""
    metricas = con_metricas(systolic={"series": [118.0, 120.0, 132.0]})
    bloque = panel.build_system("cardio", metricas, CONTENIDO_CARDIO)
    sistolica = azulejo(bloque, "Presión sistólica")
    assert sistolica["status"] == "nominal"  # un día aislado no es desviación sostenida
    assert "1 de 3 días" in sistolica["note"]


def test_una_desviacion_sostenida_dice_cuantos_dias_lleva():
    metricas = con_metricas(systolic={"series": [118.0, 129.0, 131.0, 134.0]})
    bloque = panel.build_system("cardio", metricas, CONTENIDO_CARDIO)
    sistolica = azulejo(bloque, "Presión sistólica")
    assert sistolica["status"] == "atencion"
    assert "3 días seguidos" in sistolica["note"]


def test_un_valor_dentro_de_la_base_no_habla_de_dias():
    metricas = con_metricas(systolic={"series": [118.0, 120.0, 119.0]})
    sistolica = azulejo(panel.build_system("cardio", metricas, CONTENIDO_CARDIO), "Presión sistólica")
    assert "días" not in sistolica["note"]
