"""Simulador embebido: la app se mueve sola, sin PostgreSQL y sin red.

Es lo que hace que el .exe y el .app tengan vida propia: los datos sintéticos del
equipo viajan dentro de la app y el simulador avanza el día de misión con el reloj.
Se conecta como otro loader del catálogo, el mismo mecanismo que usa PostgreSQL.
"""

import sim
from rules import Baseline

CSV = """Patient_ID,Timestamp,Heart_Rate,Systolic_BP,Sleep_Hours,Stress_Level,RNFL_Thickness_um
SC-00001,2026-01-01,60,120,7.5,5.0,100
SC-00001,2026-01-02,61,122,7.2,5.2,
SC-00001,2026-01-03,62,124,7.0,5.4,
SC-00001,2026-01-04,64,128,6.6,6.0,
SC-00001,2026-01-05,66,132,6.2,6.5,108
SC-00002,2026-01-01,70,118,8.0,4.0,95
SC-00002,2026-01-02,71,119,7.9,4.1,
"""


def tripulacion():
    return sim.leer_csv(CSV)


def test_lee_un_tripulante_por_patient_id():
    t = tripulacion()
    assert [x.patient_id for x in t] == ["SC-00001", "SC-00002"]
    assert t[0].dias == 5 and t[1].dias == 2


def test_cada_dia_trae_los_indicadores_mapeados():
    primero = tripulacion()[0]
    dia1 = primero.lecturas(1)
    assert dia1["heart_rate"] == 60.0
    assert dia1["systolic"] == 120.0
    assert dia1["sleep_hours"] == 7.5
    assert dia1["mood"] == 3.0  # estrés 5.0 invertido a escala 1–5


def test_las_celdas_vacias_no_producen_lectura():
    assert "retinal_delta" not in tripulacion()[0].lecturas(2)


def test_el_overlay_tiene_la_forma_que_espera_el_catalogo():
    o = sim.overlay(tripulacion()[0], dia=5, dias_base=3)
    assert set(o) == {"metrics", "sans"}
    assert set(o["sans"]) == {"series", "days"}
    fc = o["metrics"]["heart_rate"]
    assert isinstance(fc["base"], Baseline)
    assert fc["series"][-1] == 66.0  # la última lectura es la del día actual


def test_la_serie_termina_en_el_dia_actual_y_no_pasa_de_la_ventana():
    o = sim.overlay(tripulacion()[0], dia=3, dias_base=2, ventana=2)
    assert o["metrics"]["heart_rate"]["series"] == [61.0, 62.0]


def test_la_linea_base_sale_de_los_primeros_dias_no_de_todos():
    o = sim.overlay(tripulacion()[0], dia=5, dias_base=3)
    base = o["metrics"]["heart_rate"]["base"]
    assert base.low < 61.0 < base.high  # media de 60, 61, 62
    assert base.high < 66.0  # el día 5 queda fuera de la base: por eso se desvía


def test_sans_es_el_cambio_del_rnfl_contra_la_primera_lectura():
    o = sim.overlay(tripulacion()[0], dia=5, dias_base=3)
    assert o["sans"]["series"] == [0.0, 8.0]
    assert o["sans"]["days"] == [1, 5]


def test_el_dia_avanza_con_el_reloj():
    # Arranca en la ventana completa (14) para que la tendencia tenga historia.
    assert sim.dia_actual(transcurrido=0.0, cada=15.0, total=90, desde=14) == 14
    assert sim.dia_actual(transcurrido=14.0, cada=15.0, total=90, desde=14) == 14
    assert sim.dia_actual(transcurrido=15.0, cada=15.0, total=90, desde=14) == 15
    assert sim.dia_actual(transcurrido=150.0, cada=15.0, total=90, desde=14) == 24


def test_al_llegar_al_final_la_mision_se_queda_en_el_ultimo_dia():
    assert sim.dia_actual(transcurrido=99999.0, cada=15.0, total=90, desde=14) == 90


def test_el_simulador_es_un_loader_del_catalogo():
    reloj = iter([0.0, 0.0, 60.0])
    s = sim.Simulador(tripulacion()[0], cada=15.0, dias_base=2, clock=lambda: next(reloj))
    primero = s()
    assert primero["metrics"]["heart_rate"]["series"][-1] == 62.0  # día 3 (tope de este CSV)
    assert s()["metrics"]["heart_rate"]["series"][-1] == 66.0  # 60 s después: día 5


def test_el_csv_que_viaja_en_la_app_existe_y_se_lee():
    """Si este archivo falta, el .exe arrancaría sin datos que simular."""
    tripulacion_real = sim.cargar_tripulacion()
    assert tripulacion_real, "el CSV embebido no trae tripulantes"
    primero = tripulacion_real[0]
    assert primero.dias >= 60, f"solo {primero.dias} días: muy poco para una misión"
    o = sim.overlay(primero, dia=20)
    assert o["metrics"]["systolic"]["series"], "la sistólica debería tener lecturas"


# --- conexión con el catálogo y la API --------------------------------------

import os  # noqa: E402

from fastapi.testclient import TestClient  # noqa: E402

import catalog  # noqa: E402
import main  # noqa: E402


def test_el_catalogo_usa_el_simulador_cuando_tirelus_sim_esta_encendido():
    cat = catalog.build_catalog(env={"TIRELUS_SIM": "vivo"})
    snap = cat.snapshot()
    assert snap.source == "simulacion"
    assert snap.metrics["systolic"]["series"], "la sistólica debería venir del simulador"


def test_sin_tirelus_sim_el_catalogo_no_simula():
    assert catalog.build_catalog(env={}).snapshot().source == "ejemplo"


def test_el_simulador_manda_sobre_postgresql_porque_se_pidio_explicito():
    cat = catalog.build_catalog(env={"TIRELUS_SIM": "vivo", "TIRELUS_DB_HOST": "servidor-que-no-existe"})
    assert cat.snapshot().source == "simulacion"


def test_health_dice_que_los_datos_son_simulados(monkeypatch):
    monkeypatch.setattr(main, "catalog", catalog.build_catalog(env={"TIRELUS_SIM": "vivo"}))
    assert TestClient(main.app).get("/health").json()["data_source"] == "simulacion"


def test_con_el_simulador_los_datos_cambian_sin_esperar_el_ttl_largo():
    """Leer el simulador no cuesta red: con el TTL de 30 s el panel se vería congelado."""
    reloj = [0.0]
    cat = catalog.build_catalog(
        env={"TIRELUS_SIM": "vivo", "TIRELUS_SIM_CADA": "1"}, clock=lambda: reloj[0]
    )
    primera = cat.snapshot().metrics["heart_rate"]["series"][-1]
    reloj[0] = 5.0  # cinco segundos después el simulador ya avanzó cinco días
    assert cat.snapshot().metrics["heart_rate"]["series"][-1] != primera


def test_un_ttl_explicito_le_gana_al_del_simulador():
    reloj = [0.0]
    cat = catalog.build_catalog(
        env={"TIRELUS_SIM": "vivo", "TIRELUS_SIM_CADA": "1", "TIRELUS_DB_TTL": "60"},
        clock=lambda: reloj[0],
    )
    primera = cat.snapshot().metrics["heart_rate"]["series"][-1]
    reloj[0] = 5.0
    assert cat.snapshot().metrics["heart_rate"]["series"][-1] == primera  # sigue cacheado
