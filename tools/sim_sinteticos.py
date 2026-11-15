"""Simula en tiempo real las entradas de la tripulación usando los datos sintéticos del equipo.

Los datos salen del generador del equipo (repo `SyntheticData_STARDUSTCRUSADERS`), que
produce un CSV por tripulante con 68 columnas. Este script los traduce a los indicadores
de `db/schema.sql` y los escribe en PostgreSQL:

    cargar  línea base personal prevuelo + el historial hasta un día de misión
    vivo    un día de misión cada N segundos, para ver moverse el panel
    limpiar borra la tripulación sintética (y en cascada sus lecturas)

La app no se entera de nada: sigue hablando solo con su API local, que relee la base
cada `TIRELUS_DB_TTL` segundos.

Uso (desde la raíz del repo, con el venv de `app/`):

    export TIRELUS_DB_HOST=192.168.10.2 TIRELUS_DB_USER=tirelus_equipo TIRELUS_DB_PASSWORD=...
    app/.venv/bin/python tools/sim_sinteticos.py cargar --csv ~/Desktop/SyntheticData_*/output/patients
    app/.venv/bin/python tools/sim_sinteticos.py vivo   --csv ~/Desktop/SyntheticData_*/output/patients --cada 5
    app/.venv/bin/python tools/sim_sinteticos.py limpiar

Para que la presión arterial llegue a diario (el generador la trae cada 3–14 días, que
rompe la regla de desviación sostenida), genere con `blood_pressure_interval_days_min/max`
en 1 dentro de `config/synthetic_data_config.json`.

Todo lo que escribe queda marcado con `note = 'Datos de ejemplo (sintéticos)'`.
"""

from __future__ import annotations

import argparse
import csv
import math
import os
import statistics
import sys
import time
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Iterable, Sequence

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "app/python_app"))

SIM_NOTE = "Datos de ejemplo (sintéticos)"

# Namespace fijo: el client_id de cada lectura es determinista, así que recargar
# los mismos datos no duplica filas (la base es idempotente por client_id).
NAMESPACE = uuid.UUID("7f3d9a52-1c4b-4e8a-9f16-2b5d8c0e4a71")

# Escala de Stress_Level en el generador (config: sleep_and_cognition.stress_level).
ESTRES_MIN, ESTRES_MAX = 0.0, 10.0
# Ánimo de la app (db/schema.sql: indicators.mood, 1–5 pts).
ANIMO_MIN, ANIMO_MAX = 1.0, 5.0

# Columna del generador que lleva el grosor retiniano. SANS no es el grosor sino su
# CAMBIO frente a la base personal, así que se trata aparte (ver deltas_retinianos).
COLUMNA_RETINA = "RNFL_Thickness_um"


def animo_desde_estres(estres: float) -> float:
    """Estrés 0–10 → ánimo 1–5, invertido: más estrés, menos ánimo.

    Supuesto de diseño: el generador no trae un autorreporte de ánimo; se deriva del
    estrés percibido, que sí modela (y que correlaciona con sueño y regulación emocional).
    """
    proporcion = (estres - ESTRES_MIN) / (ESTRES_MAX - ESTRES_MIN)
    proporcion = min(1.0, max(0.0, proporcion))
    return round(ANIMO_MAX - proporcion * (ANIMO_MAX - ANIMO_MIN), 2)


@dataclass(frozen=True)
class Columna:
    """Una columna del CSV y el indicador de TIRELUS al que va."""

    indicator: str
    transform: Callable[[float], float] | None = None


@dataclass(frozen=True)
class Lectura:
    indicator: str
    value: float
    mission_day: int


MAPEO: dict[str, Columna] = {
    "Heart_Rate": Columna("heart_rate"),
    "Systolic_BP": Columna("systolic"),
    "Diastolic_BP": Columna("diastolic"),
    "Oxygen_Saturation_pct": Columna("spo2"),
    "Body_Temperature_c": Columna("temperature"),
    "Respiratory_Rate_bpm": Columna("respiratory_rate"),
    "Derived_HRV_s": Columna("hrv"),
    "Sleep_Hours": Columna("sleep_hours"),
    "Weight_kg": Columna("body_mass"),
    "PVT_Reaction_Time_ms": Columna("pvt_ms"),
    "Stress_Level": Columna("mood", animo_desde_estres),
    "Macular_Thickness_um": Columna("macular_thickness"),
    "Intraocular_Pressure_mmhg": Columna("intraocular_pressure"),
    "Cup_to_Disc_Ratio": Columna("cup_to_disc_ratio"),
}


def _numero(valor: Any) -> float | None:
    """Valor numérico de una celda del CSV, o None si viene vacía o NaN."""
    if valor is None:
        return None
    texto = str(valor).strip()
    if not texto or texto.lower() in ("nan", "none", "null"):
        return None
    try:
        numero = float(texto)
    except ValueError:
        return None  # columnas de texto (Visual_Acuity "20/40", Workout_Type…)
    return None if math.isnan(numero) or math.isinf(numero) else numero


def lecturas_de_fila(fila: dict[str, Any], dia: int) -> list[Lectura]:
    """Traduce una fila del CSV a lecturas de TIRELUS. Las celdas vacías se ignoran."""
    lecturas: list[Lectura] = []
    for columna, destino in MAPEO.items():
        numero = _numero(fila.get(columna))
        if numero is None:
            continue
        valor = destino.transform(numero) if destino.transform else numero
        lecturas.append(Lectura(destino.indicator, valor, dia))
    return lecturas


def linea_base(valores: Sequence[float], desviaciones: float = 2.0) -> tuple[float, float] | None:
    """Rango personal prevuelo: media ± `desviaciones` desviaciones estándar.

    Dos desviaciones dejan fuera ~5 % de los días por azar, que es lo que se espera de
    un rango de referencia personal; con una, un tercio de los días saldría "fuera".
    Hacen falta al menos dos lecturas. Si no hay variación se abre un ancho mínimo:
    un rango de ancho cero marcaría cualquier lectura como desviación.
    """
    limpios = [float(v) for v in valores]
    if len(limpios) < 2:
        return None
    media = statistics.fmean(limpios)
    mitad = max(desviaciones * statistics.pstdev(limpios), abs(media) * 0.01, 0.1)
    return round(media - mitad, 2), round(media + mitad, 2)


def deltas_retinianos(serie: Sequence[float]) -> list[float]:
    """SANS: cambio de grosor retiniano frente a la primera medición (la base)."""
    if not serie:
        return []
    base = float(serie[0])
    return [round(float(v) - base, 2) for v in serie]


def client_id(patient_id: str, indicator: str, dia: int) -> str:
    """Id estable de la lectura: recargar los mismos datos no duplica filas."""
    return str(uuid.uuid5(NAMESPACE, f"{patient_id}|{indicator}|{dia}"))


def astronaut_id(patient_id: str) -> str:
    """Id estable del tripulante derivado de su id en el generador (SC-00001)."""
    return str(uuid.uuid5(NAMESPACE, f"astronauta|{patient_id}"))


# --- lectura de los CSV del generador --------------------------------------

NOMBRES = ["Tripulante A", "Tripulante B", "Tripulante C", "Tripulante D", "Tripulante E", "Tripulante F"]


@dataclass
class Tripulante:
    patient_id: str
    nombre: str
    rol: str
    filas: list[dict[str, Any]]

    @property
    def id(self) -> str:
        return astronaut_id(self.patient_id)

    @property
    def dias(self) -> int:
        return len(self.filas)


def leer_tripulacion(ruta: Path, cuantos: int) -> list[Tripulante]:
    """Lee los CSV por paciente del generador (output/patients/) en orden."""
    archivos = sorted(ruta.glob("*.csv")) if ruta.is_dir() else [ruta]
    if not archivos:
        raise SystemExit(f"No hay CSV en {ruta}")
    tripulacion: list[Tripulante] = []
    for indice, archivo in enumerate(archivos[:cuantos]):
        with archivo.open(encoding="utf-8") as f:
            filas = list(csv.DictReader(f))
        if not filas:
            continue
        patient_id = filas[0].get("Patient_ID") or archivo.stem
        nombre = NOMBRES[indice] if indice < len(NOMBRES) else f"Tripulante {indice + 1}"
        # El primero es el CMO, como en la vista de la base (data.HABITAT).
        tripulacion.append(Tripulante(patient_id, nombre, "cmo" if indice == 0 else "astronauta", filas))
    return tripulacion


def bases_de(tripulante: Tripulante, dias_base: int, desviaciones: float) -> dict[str, tuple[float, float]]:
    """Línea base por indicador con los primeros `dias_base` días (ventana prevuelo)."""
    porIndicador: dict[str, list[float]] = {}
    for dia, fila in enumerate(tripulante.filas[:dias_base], start=1):
        for lectura in lecturas_de_fila(fila, dia):
            porIndicador.setdefault(lectura.indicator, []).append(lectura.value)
    bases = {}
    for indicador, valores in porIndicador.items():
        base = linea_base(valores, desviaciones)
        if base is not None:
            bases[indicador] = base
    return bases


def lecturas_retinianas(tripulante: Tripulante) -> list[Lectura]:
    """Las lecturas de SANS: delta de grosor retiniano con su día de misión."""
    crudas = [
        (dia, _numero(fila.get(COLUMNA_RETINA)))
        for dia, fila in enumerate(tripulante.filas, start=1)
    ]
    con_dato = [(dia, valor) for dia, valor in crudas if valor is not None]
    deltas = deltas_retinianos([valor for _, valor in con_dato])
    return [Lectura("retinal_delta", delta, dia) for (dia, _), delta in zip(con_dato, deltas)]


# --- PostgreSQL ------------------------------------------------------------


def _conexion() -> Any:
    import db as db_module  # app/python_app/db.py

    import pg8000.dbapi

    cfg = db_module.config_from_env(os.environ)
    if cfg is None:
        raise SystemExit("Falta TIRELUS_DB_HOST: sin base no hay nada que simular.")
    return pg8000.dbapi.connect(
        user=cfg.user,
        password=cfg.password or None,
        host=cfg.host,
        port=cfg.port,
        database=cfg.name,
        timeout=cfg.timeout,
    )


def _ejecutar(conn: Any, sentencia: str, args: tuple = ()) -> list:
    cur = conn.cursor()
    try:
        cur.execute(sentencia, args)
        filas = cur.fetchall() if cur.description else []
        conn.commit()
        return filas
    finally:
        cur.close()


def guardar_tripulante(conn: Any, tripulante: Tripulante) -> None:
    _ejecutar(
        conn,
        "INSERT INTO astronauts (id, name, role) VALUES (%s, %s, %s)"
        " ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, role = EXCLUDED.role",
        (tripulante.id, f"{tripulante.nombre} ({tripulante.patient_id} · datos de ejemplo)", tripulante.rol),
    )


def guardar_bases(conn: Any, tripulante: Tripulante, bases: dict[str, tuple[float, float]]) -> None:
    for indicador, (low, high) in bases.items():
        _ejecutar(
            conn,
            "INSERT INTO baselines (astronaut_id, indicator_id, body_state, low, high)"
            " VALUES (%s, %s, 'reposo', %s, %s)"
            " ON CONFLICT (astronaut_id, indicator_id, body_state)"
            " DO UPDATE SET low = EXCLUDED.low, high = EXCLUDED.high, computed_at = now()",
            (tripulante.id, indicador, low, high),
        )


def guardar_lecturas(conn: Any, tripulante: Tripulante, lecturas: Iterable[Lectura], antiguedad_dias: int = 0) -> int:
    """Escribe lecturas con `measured_at` escalonado: el día más nuevo es ahora."""
    escritas = 0
    for lectura in lecturas:
        _ejecutar(
            conn,
            "INSERT INTO measurements (client_id, astronaut_id, indicator_id, body_state, value,"
            " measured_at, mission_day, environment, note)"
            " VALUES (%s, %s, %s, 'reposo', %s, now() - make_interval(secs => %s), %s, 'iss', %s)"
            " ON CONFLICT (client_id) DO NOTHING",
            (
                client_id(tripulante.patient_id, lectura.indicator, lectura.mission_day),
                tripulante.id,
                lectura.indicator,
                lectura.value,
                antiguedad_dias * 86400 + (tripulante.dias - lectura.mission_day),
                lectura.mission_day,
                SIM_NOTE,
            ),
        )
        escritas += 1
    return escritas


def lecturas_del_dia(tripulante: Tripulante, dia: int) -> list[Lectura]:
    """Todas las lecturas de un día de misión, SANS incluido."""
    if not 1 <= dia <= tripulante.dias:
        return []
    lecturas = lecturas_de_fila(tripulante.filas[dia - 1], dia)
    lecturas += [l for l in lecturas_retinianas(tripulante) if l.mission_day == dia]
    return lecturas


# --- modos -----------------------------------------------------------------


def modo_cargar(args: argparse.Namespace) -> None:
    tripulacion = leer_tripulacion(Path(args.csv).expanduser(), args.tripulantes)
    conn = _conexion()
    try:
        for tripulante in tripulacion:
            guardar_tripulante(conn, tripulante)
            bases = bases_de(tripulante, args.dias_base, args.desviaciones)
            guardar_bases(conn, tripulante, bases)
            hasta = args.hasta_dia or tripulante.dias
            total = 0
            for dia in range(1, hasta + 1):
                total += guardar_lecturas(conn, tripulante, lecturas_del_dia(tripulante, dia))
            print(
                f"{tripulante.nombre} ({tripulante.patient_id}): {len(bases)} líneas base · "
                f"{total} lecturas de D1 a D{hasta}\n    TIRELUS_ASTRONAUT_ID={tripulante.id}"
            )
            faltan = sorted({c.indicator for c in MAPEO.values()} - set(bases))
            if faltan:
                print(f"    sin línea base (pocas lecturas en los primeros {args.dias_base} días): {', '.join(faltan)}")
    finally:
        conn.close()


def modo_vivo(args: argparse.Namespace) -> None:
    tripulacion = leer_tripulacion(Path(args.csv).expanduser(), args.tripulantes)
    conn = _conexion()
    try:
        for tripulante in tripulacion:
            guardar_tripulante(conn, tripulante)
            guardar_bases(conn, tripulante, bases_de(tripulante, args.dias_base, args.desviaciones))
        dias = min(t.dias for t in tripulacion)
        hasta = min(args.hasta_dia or dias, dias)
        print(f"día de misión cada {args.cada:.0f} s · de D{args.desde_dia} a D{hasta} · Ctrl+C para parar")
        for dia in range(args.desde_dia, hasta + 1):
            resumen = []
            for tripulante in tripulacion:
                lecturas = lecturas_del_dia(tripulante, dia)
                guardar_lecturas(conn, tripulante, lecturas)
                valores = {l.indicator: l.value for l in lecturas}
                if "systolic" in valores:
                    resumen.append(f"{tripulante.nombre[-1]}: PA {valores['systolic']:.0f}")
                elif "heart_rate" in valores:
                    resumen.append(f"{tripulante.nombre[-1]}: FC {valores['heart_rate']:.0f}")
            print(f"  D{dia:<4} {len(tripulacion)} tripulantes · {' · '.join(resumen)}", flush=True)
            time.sleep(args.cada)
        print("fin de los datos · borra con: tools/sim_sinteticos.py limpiar")
    finally:
        conn.close()


def modo_limpiar(args: argparse.Namespace) -> None:
    conn = _conexion()
    try:
        lecturas = _ejecutar(conn, "DELETE FROM measurements WHERE note = %s RETURNING id", (SIM_NOTE,))
        # Los tripulantes sintéticos se borran por su id derivado: la cascada se lleva
        # sus líneas base y lo que quede de sus lecturas.
        ids = [astronaut_id(f"SC-{n:05d}") for n in range(1, 101)]
        tripulantes = _ejecutar(
            conn, "DELETE FROM astronauts WHERE id = ANY(%s) RETURNING name", (ids,)
        )
        print(f"Borradas {len(lecturas)} lecturas y {len(tripulantes)} tripulantes sintéticos.")
    finally:
        conn.close()


def main(argv: Sequence[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Simula entradas de la tripulación con los datos sintéticos del equipo.")
    sub = parser.add_subparsers(dest="modo", required=True)

    def comunes(p: argparse.ArgumentParser) -> None:
        p.add_argument("--csv", required=True, help="carpeta output/patients del generador (o un CSV)")
        p.add_argument("--tripulantes", type=int, default=4, help="cuántos CSV usar (por defecto 4)")
        p.add_argument("--dias-base", type=int, default=14, help="días prevuelo para la línea base (14)")
        p.add_argument("--desviaciones", type=float, default=2.0, help="ancho de la base en desviaciones (2)")
        p.add_argument("--hasta-dia", type=int, default=None, help="último día de misión a escribir")

    cargar = sub.add_parser("cargar", help="línea base + historial completo")
    comunes(cargar)
    cargar.set_defaults(func=modo_cargar)

    vivo = sub.add_parser("vivo", help="un día de misión cada N segundos")
    comunes(vivo)
    vivo.add_argument("--cada", type=float, default=5.0, help="segundos por día de misión (5)")
    vivo.add_argument("--desde-dia", type=int, default=1, help="día de misión inicial (1)")
    vivo.set_defaults(func=modo_vivo)

    limpiar = sub.add_parser("limpiar", help="borra la tripulación sintética y sus lecturas")
    limpiar.set_defaults(func=modo_limpiar)

    args = parser.parse_args(argv)
    args.func(args)


if __name__ == "__main__":
    main()
