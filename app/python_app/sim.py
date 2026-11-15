"""Simulador embebido: la misión avanza sola, sin PostgreSQL y sin red.

Es lo que le da vida propia al binario (.exe en Windows, .app en macOS): los datos
sintéticos del equipo viajan dentro de la app en `datos/tripulacion.csv` y este
módulo avanza el día de misión con el reloj, sirviendo la ventana de lecturas que
le toca a cada momento.

Se conecta al catálogo como OTRO LOADER, el mismo mecanismo que usa PostgreSQL
(ver `catalog.build_catalog`): la app, el panel y el motor de reglas no se enteran
de dónde vienen los datos.

Solo biblioteca estándar: nada de pandas ni de drivers, para que empaquete en
cualquier plataforma. El directorio de la app es de solo lectura, así que aquí
nunca se escribe: el día se deriva del reloj.

Variables de entorno:
    TIRELUS_SIM        "vivo" lo enciende; cualquier otra cosa lo deja apagado
    TIRELUS_SIM_CADA   segundos por día de misión (15 por defecto)
    TIRELUS_SIM_BASE   días de la ventana prevuelo para la línea base (14)
"""

from __future__ import annotations

import csv
import math
import os
import statistics
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence

from rules import Baseline

RUTA_CSV = Path(__file__).resolve().parent / "datos" / "tripulacion.csv"

VENTANA = 14  # días que muestra la tendencia
DIAS_BASE = 14  # ventana prevuelo de la línea base personal
CADA = 15.0  # segundos por día de misión

# Escala del estrés percibido en el generador, y del ánimo en la app (1–5).
ESTRES_MAX = 10.0
ANIMO_MIN, ANIMO_MAX = 1.0, 5.0

COLUMNA_RETINA = "RNFL_Thickness_um"


def animo_desde_estres(estres: float) -> float:
    """Estrés 0–10 → ánimo 1–5, invertido. Supuesto de diseño documentado.

    Misma fórmula que `tools/sim_sinteticos.py` y `db/generate_populate_sql.py`:
    el dataset no trae autorreporte de ánimo, pero sí estrés percibido.
    """
    proporcion = min(1.0, max(0.0, float(estres) / ESTRES_MAX))
    return round(ANIMO_MAX - proporcion * (ANIMO_MAX - ANIMO_MIN), 2)


# Columna del CSV → indicador de la app (los mismos ids de db/schema.sql).
MAPEO: dict[str, tuple[str, Callable[[float], float] | None]] = {
    "Heart_Rate": ("heart_rate", None),
    "Systolic_BP": ("systolic", None),
    "Diastolic_BP": ("diastolic", None),
    "Oxygen_Saturation_pct": ("spo2", None),
    "Body_Temperature_c": ("temperature", None),
    "Respiratory_Rate_bpm": ("respiratory_rate", None),
    "Derived_HRV_s": ("hrv", None),
    "Sleep_Hours": ("sleep_hours", None),
    "Weight_kg": ("body_mass", None),
    "PVT_Reaction_Time_ms": ("pvt_ms", None),
    "Stress_Level": ("mood", animo_desde_estres),
    "Macular_Thickness_um": ("macular_thickness", None),
    "Intraocular_Pressure_mmhg": ("intraocular_pressure", None),
    "Cup_to_Disc_Ratio": ("cup_to_disc_ratio", None),
}


def _numero(valor: Any) -> float | None:
    """Número de una celda del CSV, o None si viene vacía o no es finita."""
    if valor is None:
        return None
    texto = str(valor).strip()
    if not texto or texto.lower() in ("nan", "none", "null"):
        return None
    try:
        numero = float(texto)
    except ValueError:
        return None
    return None if math.isnan(numero) or math.isinf(numero) else numero


@dataclass(frozen=True)
class Tripulante:
    """Un tripulante del CSV embebido, con sus lecturas por día de misión."""

    patient_id: str
    filas: tuple[dict[str, Any], ...]

    @property
    def dias(self) -> int:
        return len(self.filas)

    def lecturas(self, dia: int) -> dict[str, float]:
        """Indicador → valor del día de misión indicado (D1 es la primera fila)."""
        if not 1 <= dia <= self.dias:
            return {}
        fila = self.filas[dia - 1]
        lecturas: dict[str, float] = {}
        for columna, (indicador, transformar) in MAPEO.items():
            numero = _numero(fila.get(columna))
            if numero is None:
                continue
            lecturas[indicador] = transformar(numero) if transformar else numero
        if (retina := _numero(fila.get(COLUMNA_RETINA))) is not None:
            lecturas[COLUMNA_RETINA] = retina
        return lecturas


def leer_csv(texto: str) -> list[Tripulante]:
    """Lee el CSV del generador y agrupa por tripulante, en orden de aparición."""
    porTripulante: dict[str, list[dict[str, Any]]] = {}
    for fila in csv.DictReader(texto.splitlines()):
        porTripulante.setdefault(fila["Patient_ID"], []).append(fila)
    return [Tripulante(pid, tuple(filas)) for pid, filas in porTripulante.items()]


def cargar_tripulacion(ruta: Path | None = None) -> list[Tripulante]:
    """Los tripulantes del CSV que viaja dentro de la app."""
    archivo = ruta or RUTA_CSV
    if not archivo.exists():
        return []
    return leer_csv(archivo.read_text(encoding="utf-8"))


def linea_base(valores: Sequence[float], desviaciones: float = 2.0) -> tuple[float, float] | None:
    """Rango personal prevuelo: media ± `desviaciones` desviaciones estándar.

    Igual que `tools/sim_sinteticos.py`: dos desviaciones dejan fuera ~5 % de los días
    por azar. Con menos de dos lecturas no hay base, y si no hay variación se abre un
    ancho mínimo para que un rango de ancho cero no marque todo como desviación.
    """
    limpios = [float(v) for v in valores]
    if len(limpios) < 2:
        return None
    media = statistics.fmean(limpios)
    mitad = max(desviaciones * statistics.pstdev(limpios), abs(media) * 0.01, 0.1)
    return round(media - mitad, 2), round(media + mitad, 2)


def overlay(
    tripulante: Tripulante,
    dia: int,
    dias_base: int = DIAS_BASE,
    ventana: int = VENTANA,
    desviaciones: float = 2.0,
) -> dict:
    """Lo que el catálogo sobrepone a los datos de ejemplo, al día de misión `dia`.

    Misma forma que `db.load_overlay`: línea base de la ventana prevuelo y la serie
    de los últimos `ventana` días hasta hoy. SANS va aparte, como cambio del RNFL
    peripapilar frente a la primera lectura (los umbrales publicados son de esa medida).
    """
    dia = max(1, min(dia, tripulante.dias))
    primeros = range(1, min(dias_base, dia) + 1)
    ventana_dias = range(max(1, dia - ventana + 1), dia + 1)

    porIndicador: dict[str, list[float]] = {}
    for d in primeros:
        for indicador, valor in tripulante.lecturas(d).items():
            porIndicador.setdefault(indicador, []).append(valor)

    metrics: dict[str, dict] = {}
    for indicador, valores in porIndicador.items():
        if indicador == COLUMNA_RETINA:
            continue
        if (base := linea_base(valores, desviaciones)) is not None:
            metrics.setdefault(indicador, {})["base"] = Baseline(*base)

    for d in ventana_dias:
        for indicador, valor in tripulante.lecturas(d).items():
            if indicador == COLUMNA_RETINA:
                continue
            metrics.setdefault(indicador, {}).setdefault("series", []).append(valor)

    # SANS: todas las lecturas de OCT hasta hoy, como cambio frente a la primera.
    retina = [(d, v[COLUMNA_RETINA]) for d in range(1, dia + 1) if (v := tripulante.lecturas(d)).get(COLUMNA_RETINA)]
    sans = {"series": [], "days": []}
    if retina:
        primera = retina[0][1]
        sans = {"series": [round(v - primera, 2) for _, v in retina], "days": [d for d, _ in retina]}
    return {"metrics": metrics, "sans": sans}


def dia_actual(transcurrido: float, cada: float, total: int, desde: int = DIAS_BASE) -> int:
    """Día de misión según el tiempo corrido. Al llegar al final se queda ahí."""
    avance = int(max(0.0, transcurrido) // max(cada, 0.001))
    return max(1, min(total, desde + avance))


class Simulador:
    """Loader del catálogo: cada llamada devuelve el overlay del día que toca."""

    def __init__(
        self,
        tripulante: Tripulante,
        cada: float = CADA,
        dias_base: int = DIAS_BASE,
        ventana: int = VENTANA,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        self._tripulante = tripulante
        self._cada = cada
        self._dias_base = dias_base
        self._ventana = ventana
        self._clock = clock
        self._inicio = clock()

    @property
    def dia(self) -> int:
        """Día de misión en este instante."""
        return dia_actual(
            self._clock() - self._inicio,
            self._cada,
            self._tripulante.dias,
            desde=min(self._dias_base + 1, self._tripulante.dias),
        )

    def __call__(self) -> dict:
        return overlay(self._tripulante, self.dia, self._dias_base, self._ventana)


def encendido(env: Mapping[str, str] | None = None) -> bool:
    """True si TIRELUS_SIM pide la simulación embebida."""
    env = os.environ if env is None else env
    return (env.get("TIRELUS_SIM") or "").strip().lower() in ("vivo", "on", "1", "true")


def desde_env(env: Mapping[str, str] | None = None, clock: Callable[[], float] = time.monotonic) -> Simulador | None:
    """Arma el simulador con lo que digan las variables de entorno, o None."""
    env = os.environ if env is None else env
    if not encendido(env):
        return None
    tripulacion = cargar_tripulacion()
    if not tripulacion:
        return None
    try:
        cada = float(env.get("TIRELUS_SIM_CADA") or CADA)
    except ValueError:
        cada = CADA
    try:
        dias_base = int(env.get("TIRELUS_SIM_BASE") or DIAS_BASE)
    except ValueError:
        dias_base = DIAS_BASE
    return Simulador(tripulacion[0], cada=max(cada, 0.1), dias_base=max(dias_base, 2), clock=clock)
