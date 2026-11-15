"""Simulación: ¿qué del frontend cambia cuando cambian los datos en PostgreSQL?

Arranca el servidor real de `app/python_app/main.py` contra la base configurada,
inserta lecturas sintéticas y registra, endpoint por endpoint, qué cambia y cuánto
tarda en cambiar. Sirve para verificar la capa de datos sin abrir la app Flutter.

Uso (desde la raíz del repo, con el venv de `app/`):

    # contra un PostgreSQL local de prueba
    export TIRELUS_DB_HOST=127.0.0.1 TIRELUS_DB_PORT=55432 \
           TIRELUS_DB_NAME=tirelus TIRELUS_DB_USER=tirelus_sim
    app/.venv/bin/python tools/sim_tiempo_real.py

    # contra el servidor del equipo (escribe filas sintéticas: hay que confirmar)
    export TIRELUS_DB_HOST=192.168.10.2 TIRELUS_DB_USER=tirelus_equipo \
           TIRELUS_DB_PASSWORD=... TIRELUS_SIM_CONFIRMAR=1
    app/.venv/bin/python tools/sim_tiempo_real.py

    # borrar lo que insertó la simulación
    app/.venv/bin/python tools/sim_tiempo_real.py limpiar

Un PostgreSQL local de prueba, desechable (no toca el servidor del equipo):

    initdb -D /tmp/tirelus_pg -U tirelus_sim --auth=trust
    pg_ctl -D /tmp/tirelus_pg -l /tmp/tirelus_pg.log \
           -o "-p 55432 -c listen_addresses=127.0.0.1" start
    createdb -h 127.0.0.1 -p 55432 -U tirelus_sim tirelus
    for f in db/schema.sql db/002_ojos.sql db/003_demo.sql; do \
        psql -h 127.0.0.1 -p 55432 -U tirelus_sim -d tirelus -f $f; done

Con `TIRELUS_SIM_PGDATA` apuntando a ese directorio, la simulación además apaga la
base al final para medir la degradación a datos de ejemplo.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PYTHON_APP = REPO / "app/python_app"

API_PORT = int(os.environ.get("TIRELUS_SIM_API_PORT") or 8777)
BASE_URL = f"http://127.0.0.1:{API_PORT}"
ASTRO = os.environ.get("TIRELUS_ASTRONAUT_ID") or "00000000-0000-4000-8000-000000000001"

# Marca de todo lo que escribe la simulación: `limpiar` borra exactamente esto.
SIM_NOTE = "Datos de ejemplo (simulación)"

# Identificador de esta corrida. Va dentro del client_id porque la base es
# idempotente por client_id: sin esto, una segunda corrida con las mismas
# etiquetas no insertaría nada y el panel se quedaría quieto sin avisar.
RUN_ID = os.environ.get("TIRELUS_SIM_RUN") or f"{int(time.time())}"
SIM_HR_BASE = (55, 66)
TTL_MAX_WAIT = 45.0  # el catálogo cachea 30 s (catalog.build_catalog)

T0 = time.monotonic()


def t() -> str:
    return f"[t+{time.monotonic() - T0:5.1f}s]"


def log(msg: str) -> None:
    print(f"{t()} {msg}", flush=True)


# --- base de datos ---------------------------------------------------------


def _db_kwargs() -> dict:
    sys.path.insert(0, str(PYTHON_APP))
    import db as db_module

    cfg = db_module.config_from_env(os.environ)
    if cfg is None:
        raise SystemExit("Falta TIRELUS_DB_HOST: la simulación necesita una base.")
    return {
        "host": cfg.host,
        "port": cfg.port,
        "database": cfg.name,
        "user": cfg.user,
        "password": cfg.password or None,
        "timeout": cfg.timeout,
    }


def sql(statement: str, args: tuple = ()) -> list:
    import pg8000.dbapi

    conn = pg8000.dbapi.connect(**_db_kwargs())
    try:
        cur = conn.cursor()
        cur.execute(statement, args)
        rows = cur.fetchall() if cur.description else []
        conn.commit()
        return rows
    finally:
        conn.close()


def insert_measurement(
    indicator: str, value: float, day: int, tag: str, offset_days: int = 0, offset_secs: int | None = None
) -> None:
    """Escribe una lectura como la escribiría la app: client_id idempotente.

    `offset_secs` ordena lecturas dentro del mismo día (la ventana de la serie
    se arma por `measured_at`, así que los empates serían ambiguos).
    """
    antiguedad = offset_days * 86400 if offset_secs is None else offset_secs
    tag = f"{RUN_ID}-{tag}"  # único por corrida; dentro de la corrida sigue siendo idempotente
    sql(
        "INSERT INTO measurements (client_id, astronaut_id, indicator_id, body_state, value,"
        " measured_at, mission_day, environment, note)"
        " VALUES (md5(%s)::uuid, %s, %s, 'reposo', %s, now() - make_interval(secs => %s), %s, 'iss', %s)"
        " ON CONFLICT (client_id) DO NOTHING",
        (tag, ASTRO, indicator, value, antiguedad, day, SIM_NOTE),
    )


def limpiar() -> None:
    """Borra solo lo que escribió esta simulación."""
    borradas = sql("DELETE FROM measurements WHERE note = %s RETURNING id", (SIM_NOTE,))
    bases = sql(
        "DELETE FROM baselines WHERE astronaut_id = %s AND indicator_id = 'heart_rate'"
        " AND low = %s AND high = %s RETURNING indicator_id",
        (ASTRO, *SIM_HR_BASE),
    )
    print(f"Borradas {len(borradas)} lecturas y {len(bases)} líneas base de la simulación.")


# --- API -------------------------------------------------------------------


def get(path: str) -> dict:
    with urllib.request.urlopen(f"{BASE_URL}{path}", timeout=20) as res:
        return json.loads(res.read().decode("utf-8"))


def snapshot() -> dict:
    """Lo que vería el frontend, resumido en campos comparables."""
    dash = get("/dashboard")
    cardio = next(s for s in dash["systems"] if s["id"] == "cardio")
    systolic = get("/trend/systolic")
    hr = get("/trend/heart_rate")
    sans = get("/trend/sans")
    return {
        "data_source": get("/health")["data_source"],
        "panel_estados": {s["id"]: s["status"] for s in dash["systems"]},
        "panel_cardio_estado": cardio["status"],
        "panel_cardio_calculado": cardio.get("computed", False),
        "panel_cardio_azulejos": [
            f'{i["label"]}: {i["value"]} {i["unit"]} · {i["note"]} [{i["status"]}]' for i in cardio["indicators"]
        ],
        "panel_dia_mision": dash["mission_day"],
        "systolic_fin": systolic["series"][-3:],
        "systolic_n": len(systolic["series"]),
        "systolic_status": systolic["status"],
        "systolic_dias_arriba": systolic["consecutive_above"],
        "systolic_first_day": systolic["first_day"],
        "hr_status": hr["status"],
        "hr_fin": hr["series"][-3:],
        "sans_status": sans["status"],
        "sans_serie": sans["series"],
        "metrics_con_datos": {m["id"]: m["has_data"] for m in get("/metrics")["metrics"]},
    }


def diff(before: dict, after: dict) -> list[str]:
    return [f"{k}: {before[k]!r} → {after[k]!r}" for k in before if before[k] != after[k]]


def esperar_cambio(before: dict, field: str) -> tuple[float, dict]:
    """Espera a que la API refleje el cambio. Devuelve (segundos, snapshot)."""
    start = time.monotonic()
    while time.monotonic() - start < TTL_MAX_WAIT:
        snap = snapshot()
        if snap[field] != before[field]:
            return time.monotonic() - start, snap
        time.sleep(1.0)
    return -1.0, snapshot()


def mostrar(titulo: str, snap: dict) -> None:
    print(f"\n{'=' * 78}\n{t()} {titulo}\n{'=' * 78}")
    for key, value in snap.items():
        print(f"  {key:22} {value}")


def mostrar_cambios(before: dict, after: dict) -> None:
    cambios = diff(before, after)
    print("  cambios:" + ("".join(f"\n    - {c}" for c in cambios) if cambios else " ninguno"))


# --- servidor --------------------------------------------------------------


def arrancar_api(log_path: Path) -> subprocess.Popen:
    env = dict(os.environ, TIRELUS_PORT=str(API_PORT), TIRELUS_ASTRONAUT_ID=ASTRO)
    proc = subprocess.Popen(
        [sys.executable, "main.py"],
        cwd=str(PYTHON_APP),
        env=env,
        stdout=log_path.open("w"),
        stderr=subprocess.STDOUT,
    )
    for _ in range(60):
        try:
            if get("/health")["ok"]:
                return proc
        except (urllib.error.URLError, OSError):
            time.sleep(0.5)
    proc.terminate()
    raise SystemExit(f"la API no arrancó; revisa {log_path}")


def confirmar_servidor_compartido() -> None:
    host = os.environ.get("TIRELUS_DB_HOST", "")
    if host in ("127.0.0.1", "localhost", "::1") or os.environ.get("TIRELUS_SIM_CONFIRMAR"):
        return
    raise SystemExit(
        f"La simulación escribe filas sintéticas en {host}, que no es local.\n"
        "Si de verdad quieres correrla ahí: TIRELUS_SIM_CONFIRMAR=1 (y después 'limpiar')."
    )


def simular() -> None:
    confirmar_servidor_compartido()
    log_path = Path(tempfile.gettempdir()) / "tirelus_sim_api.log"
    log("arrancando la API real contra PostgreSQL…")
    proc = arrancar_api(log_path)
    log("API arriba")
    try:
        s0 = snapshot()
        mostrar("ESTADO INICIAL", s0)

        print(f"\n{t()} EVENTO 1 · INSERT sistólica D48 = 145 mmHg (base 110–126)")
        insert_measurement("systolic", 145, 48, "sim-systolic-48")
        log("fila escrita; esperando a que la API la refleje…")
        secs, s1 = esperar_cambio(s0, "systolic_fin")
        log(f"la API cambió {secs:.1f} s después del INSERT")
        mostrar_cambios(s0, s1)

        print(f"\n{t()} EVENTO 2 · INSERT sistólica D49 = 9999 mmHg (valid_max = 260)")
        insert_measurement("systolic", 9999, 49, "sim-systolic-49")
        time.sleep(32)
        s2 = snapshot()
        mostrar_cambios(s1, s2)
        log("el 9999 no debe aparecer en la serie (filtro de rangos del catálogo)")

        print(f"\n{t()} EVENTO 3 · INSERT línea base de FC (55–66) + 14 lecturas (hasta 78 lpm)")
        sql(
            "INSERT INTO baselines (astronaut_id, indicator_id, body_state, low, high)"
            " VALUES (%s, 'heart_rate', 'reposo', %s, %s) ON CONFLICT DO NOTHING",
            (ASTRO, *SIM_HR_BASE),
        )
        for i, value in enumerate([58, 59, 57, 60, 61, 59, 62, 64, 63, 66, 69, 71, 74, 78]):
            insert_measurement("heart_rate", value, 34 + i, f"sim-hr-{34 + i}", offset_days=13 - i)
        secs, s3 = esperar_cambio(s2, "hr_status")
        log(f"la API reflejó FC {secs:.1f} s después")
        mostrar_cambios(s2, s3)

        print(f"\n{t()} EVENTO 4 · INSERT OCT retinal_delta: +8 µm (D30) y +22 µm (D90)")
        insert_measurement("retinal_delta", 8, 30, "sim-oct-30", offset_days=2)
        insert_measurement("retinal_delta", 22, 90, "sim-oct-90", offset_days=1)
        secs, s4 = esperar_cambio(s3, "sans_status")
        log(f"la API reflejó SANS {secs:.1f} s después")
        mostrar_cambios(s3, s4)

        mostrar("ESTADO FINAL", s4)

        pgdata = os.environ.get("TIRELUS_SIM_PGDATA")
        if pgdata:
            print(f"\n{t()} EVENTO 5 · apagando PostgreSQL para ver la degradación")
            subprocess.run(["pg_ctl", "-D", pgdata, "-m", "fast", "stop"], capture_output=True, check=False)
            time.sleep(31)
            inicio = time.monotonic()
            s5 = snapshot()
            log(f"con la base caída, la ronda de peticiones tardó {time.monotonic() - inicio:.1f} s")
            mostrar_cambios(s4, s5)
        else:
            print(f"\n{t()} EVENTO 5 omitido (define TIRELUS_SIM_PGDATA para probar la degradación)")

        print(f"\n{'=' * 78}\nLO QUE NO CAMBIÓ EN NINGÚN EVENTO\n{'=' * 78}")
        for key in ("panel_estados", "panel_cardio", "panel_dia_mision"):
            if s0[key] == s4[key]:
                print(f"  {key:22} {s0[key]}")
        print("\n  El panel (/dashboard) sirve data.SYSTEMS: texto fijo, sin pasar por el catálogo.")
        print("  Recuerda borrar lo insertado: python tools/sim_tiempo_real.py limpiar")
    finally:
        proc.terminate()
        proc.wait(timeout=10)
        log("API detenida")


def simular_panel() -> None:
    """Mueve el sistema cardio del panel: nominal → atención → crítico."""
    confirmar_servidor_compartido()
    log("arrancando la API real contra PostgreSQL…")
    proc = arrancar_api(Path(tempfile.gettempdir()) / "tirelus_sim_api.log")
    log("API arriba")
    try:
        print(f"\n{t()} PASO 0 · 14 lecturas dentro de la base (110–126): el panel debe quedar nominal")
        for i, value in enumerate([118, 120, 119, 121, 118, 122, 120, 119, 123, 121, 120, 124, 122, 121]):
            insert_measurement("systolic", value, 50 + i, f"sim-panel-nom-{i}", offset_secs=14 - i)
        secs, s0 = esperar_cambio(snapshot(), "panel_cardio_estado")
        mostrar(f"CARDIO NOMINAL (la API tardó {secs:.1f} s en reflejarlo)", s0)

        print(f"\n{t()} PASO 1 · 3 lecturas seguidas sobre la base (129, 131, 134)")
        for i, value in enumerate([129, 131, 134]):
            insert_measurement("systolic", value, 64 + i, f"sim-panel-up-{i}", offset_secs=2 - i)
        secs, s1 = esperar_cambio(s0, "panel_cardio_estado")
        log(f"la API cambió {secs:.1f} s después")
        mostrar_cambios(s0, s1)

        print(f"\n{t()} PASO 2 · lectura de 165 mmHg (límite de respaldo: 160, supuesto de diseño)")
        insert_measurement("systolic", 165, 67, "sim-panel-crit", offset_secs=0)
        secs, s2 = esperar_cambio(s1, "panel_cardio_estado")
        log(f"la API cambió {secs:.1f} s después")
        mostrar_cambios(s1, s2)

        print(f"\n{t()} PASO 3 · línea base de FC (55–66) + 14 lecturas (hasta 78 lpm)")
        sql(
            "INSERT INTO baselines (astronaut_id, indicator_id, body_state, low, high)"
            " VALUES (%s, 'heart_rate', 'reposo', %s, %s) ON CONFLICT DO NOTHING",
            (ASTRO, *SIM_HR_BASE),
        )
        for i, value in enumerate([58, 59, 57, 60, 61, 59, 62, 64, 63, 66, 69, 71, 74, 78]):
            insert_measurement("heart_rate", value, 50 + i, f"sim-panel-hr-{i}", offset_secs=14 - i)
        secs, s3 = esperar_cambio(s2, "panel_cardio_azulejos")
        log(f"la API cambió {secs:.1f} s después")
        mostrar_cambios(s2, s3)

        mostrar("ESTADO FINAL DEL PANEL", s3)
        print("  Recuerda borrar lo insertado: python tools/sim_tiempo_real.py limpiar")
    finally:
        proc.terminate()
        proc.wait(timeout=10)
        log("API detenida")


# --- modo vivo: una línea por segundo mientras la base cambia --------------


def _azulejo(snap: dict, etiqueta: str) -> str:
    for linea in snap["panel_cardio_azulejos"]:
        if linea.startswith(etiqueta):
            cuerpo = linea.split(": ", 1)[1]
            return cuerpo.replace(" · Sin dato [sin_dato]", " —").replace("[", "").replace("]", "")
    return "?"


def _linea_panel(snap: dict) -> str:
    return (
        f"cardio {snap['panel_cardio_estado'].upper():9}"
        f" │ {_azulejo(snap, 'Presión sistólica'):58}"
        f" │ FC {_azulejo(snap, 'FC en reposo')}"
    )


def simular_vivo(segundos: int = 46) -> None:
    """Inserta en la base mientras imprime el panel cada segundo."""
    confirmar_servidor_compartido()
    os.environ.setdefault("TIRELUS_DB_TTL", "2")  # refresco corto: para verlo cambiar
    log(f"TTL del catálogo: {os.environ['TIRELUS_DB_TTL']} s · arrancando la API…")
    proc = arrancar_api(Path(tempfile.gettempdir()) / "tirelus_sim_api.log")

    def nominales() -> None:
        for i, value in enumerate([118, 120, 119, 121, 118, 122, 120, 119, 123, 121, 120, 124, 122, 121]):
            insert_measurement("systolic", value, 50 + i, f"sim-vivo-nom-{i}", offset_secs=14 - i)

    def sobre_la_base() -> None:
        for i, value in enumerate([129, 131, 134]):
            insert_measurement("systolic", value, 64 + i, f"sim-vivo-up-{i}", offset_secs=2 - i)

    def critica() -> None:
        insert_measurement("systolic", 165, 67, "sim-vivo-crit", offset_secs=0)

    def frecuencia_cardiaca() -> None:
        sql(
            "INSERT INTO baselines (astronaut_id, indicator_id, body_state, low, high)"
            " VALUES (%s, 'heart_rate', 'reposo', %s, %s) ON CONFLICT DO NOTHING",
            (ASTRO, *SIM_HR_BASE),
        )
        for i, value in enumerate([58, 59, 57, 60, 61, 59, 62, 64, 63, 66, 69, 71, 74, 78]):
            insert_measurement("heart_rate", value, 50 + i, f"sim-vivo-hr-{i}", offset_secs=14 - i)

    guion = {
        4: ("14 lecturas DENTRO de la base (110–126)", nominales),
        14: ("3 lecturas SEGUIDAS sobre la base (129, 131, 134)", sobre_la_base),
        24: ("una lectura de 165 mmHg (respaldo de diseño: 160)", critica),
        34: ("línea base de FC (55–66) + 14 lecturas hasta 78 lpm", frecuencia_cardiaca),
    }
    try:
        print(f"\n{'segundo':>8}  panel que sirve la API")
        print("-" * 118)
        anterior = None
        for segundo in range(segundos):
            if segundo in guion:
                titulo, accion = guion[segundo]
                accion()
                print(f"{'':>8}  ⇢ INSERT en PostgreSQL: {titulo}")
            linea = _linea_panel(snapshot())
            marca = " ◀ cambió" if anterior is not None and linea != anterior else ""
            print(f"{f't+{segundo:02d}s':>8}  {linea}{marca}")
            anterior = linea
            time.sleep(1.0)
        print("-" * 118)
        print("  Recuerda borrar lo insertado: python tools/sim_tiempo_real.py limpiar")
    finally:
        proc.terminate()
        proc.wait(timeout=10)
        log("API detenida")


# --- modo ciclo: mueve la base en bucle, para mirar la app mientras cambia ----


def _escenas() -> list:
    """Cuatro escenas que recorren los tres estados del semáforo de cardio."""

    def todo_en_rango(ronda: int) -> None:
        for i, value in enumerate([118, 120, 119, 121, 118, 122, 120, 119, 123, 121, 120, 124, 122, 121]):
            insert_measurement("systolic", value, 50 + i, f"sim-ciclo-{ronda}-sys-ok-{i}", offset_secs=28 - i)
        for i, value in enumerate([58, 59, 57, 60, 61, 59, 62, 64, 63, 61, 60, 62, 59, 61]):
            insert_measurement("heart_rate", value, 50 + i, f"sim-ciclo-{ronda}-hr-ok-{i}", offset_secs=28 - i)

    def sistolica_sostenida(ronda: int) -> None:
        for i, value in enumerate([129, 131, 134]):
            insert_measurement("systolic", value, 64 + i, f"sim-ciclo-{ronda}-sys-up-{i}", offset_secs=2 - i)

    def sistolica_critica(ronda: int) -> None:
        insert_measurement("systolic", 165, 67, f"sim-ciclo-{ronda}-sys-crit", offset_secs=0)

    def fc_arriba(ronda: int) -> None:
        sql(
            "INSERT INTO baselines (astronaut_id, indicator_id, body_state, low, high)"
            " VALUES (%s, 'heart_rate', 'reposo', %s, %s) ON CONFLICT DO NOTHING",
            (ASTRO, *SIM_HR_BASE),
        )
        for i, value in enumerate([69, 71, 74, 78]):
            insert_measurement("heart_rate", value, 68 + i, f"sim-ciclo-{ronda}-hr-up-{i}", offset_secs=3 - i)

    return [
        ("sistólica y FC dentro de la base", "cardio NOMINAL", todo_en_rango),
        ("3 lecturas seguidas sobre la base (129, 131, 134)", "cardio ATENCIÓN", sistolica_sostenida),
        ("una lectura de 165 mmHg (respaldo 160)", "cardio CRÍTICO", sistolica_critica),
        ("FC sube a 78 lpm (base 55–66)", "el azulejo de FC pasa a atención", fc_arriba),
    ]


def simular_ciclo(minutos: float = 20.0, cada: float = 12.0) -> None:
    """Cambia la base cada `cada` segundos, en bucle, sin levantar ninguna API.

    Pensado para dejarlo corriendo mientras se mira la app: la app habla con su
    propio servidor y aquí solo se mueven los datos.
    """
    confirmar_servidor_compartido()
    escenas = _escenas()
    fin = time.monotonic() + minutos * 60
    log(f"moviendo los datos cada {cada:.0f} s durante {minutos:.0f} min · Ctrl+C para parar")
    ronda = 0
    while time.monotonic() < fin:
        for titulo, efecto, accion in escenas:
            if time.monotonic() >= fin:
                break
            accion(ronda)
            print(f"{t()} INSERT · {titulo:52} → {efecto}", flush=True)
            time.sleep(cada)
        ronda += 1
    log("ciclo terminado · borra lo insertado con: tools/sim_tiempo_real.py limpiar")


def main() -> None:
    if len(sys.argv) > 1 and sys.argv[1] == "ciclo":
        simular_ciclo(minutos=float(sys.argv[2]) if len(sys.argv) > 2 else 20.0)
        return
    if len(sys.argv) > 1 and sys.argv[1] == "vivo":
        simular_vivo()
        return
    if len(sys.argv) > 1 and sys.argv[1] == "panel":
        simular_panel()
        return
    if len(sys.argv) > 1 and sys.argv[1] == "limpiar":
        limpiar()
        return
    if len(sys.argv) > 1:
        raise SystemExit(f"Uso: {Path(sys.argv[0]).name} [ciclo [minutos]|vivo|panel|limpiar]")
    simular()


if __name__ == "__main__":
    main()
