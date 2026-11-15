"""Motor de reglas de TIRELUS (puro Python, sin dependencias).

SUPUESTOS DE DISEÑO: NASA no publica umbrales de alerta en vuelo para presión
ni frecuencia cardiaca. Se combina la línea base personal prevuelo, la tendencia
sostenida y un límite clínico terrestre de respaldo. La app no diagnostica:
solo señala desviaciones.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from enum import Enum


class Status(str, Enum):
    NOMINAL = "nominal"
    ATENCION = "atencion"
    CRITICO = "critico"
    SIN_DATO = "sin_dato"


# Días seguidos fuera de la base para marcar "atención" (supuesto de diseño).
SUSTAINED_DAYS = 3

# Umbrales publicados de SANS: µm sobre la base de grosor retiniano peripapilar.
SANS_ATTENTION_UM = 20.0
SANS_CRITICAL_UM = 55.0


@dataclass(frozen=True)
class Baseline:
    """Rango personal medido antes del vuelo."""

    low: float
    high: float

    def contains(self, value: float) -> bool:
        return self.low <= value <= self.high


@dataclass(frozen=True)
class TrendResult:
    status: Status
    consecutive_above: int
    days_out_of_range: int
    delta_from_high: float
    consecutive_below: int = 0
    delta_from_low: float = 0.0


def evaluate_reading(
    value: float,
    base: Baseline,
    absolute_high: float | None = None,
    absolute_low: float | None = None,
) -> Status:
    """Lectura aislada: dentro de la base → nominal; fuera → atención;
    más allá del límite absoluto de respaldo → crítico."""
    if (absolute_high is not None and value >= absolute_high) or (
        absolute_low is not None and value <= absolute_low
    ):
        return Status.CRITICO
    return Status.NOMINAL if base.contains(value) else Status.ATENCION


def within_valid_range(value: float, valid_range: tuple[float, float]) -> bool:
    """True si el valor es finito y cae dentro de [min, max] (extremos incluidos).

    El rango es de captura (supuesto de diseño, igual a indicators.valid_min/valid_max):
    fuera de él es un error de captura, no un estado de salud.
    """
    low, high = valid_range
    return math.isfinite(value) and low <= value <= high


def _streak(series: list[float], outside) -> int:
    """Días seguidos, contando desde hoy hacia atrás, que cumplen `outside`."""
    count = 0
    for value in reversed(series):
        if not outside(value):
            break
        count += 1
    return count


def evaluate_trend(
    series: list[float],
    base: Baseline,
    absolute_high: float | None = None,
    absolute_low: float | None = None,
    direction: str = "above",
) -> TrendResult:
    """Serie diaria (la última lectura es hoy).

    direction indica hacia dónde preocupa la desviación sostenida:
    "above" (presión), "below" (sueño, ánimo) o "both" (FC, temperatura:
    preocupa en cualquiera de los dos sentidos). Con "both" cada racha se
    cuenta por separado: cruzar de un lado al otro no las suma. Los límites
    absolutos de respaldo marcan "crítico" en cualquier dirección.
    """
    if direction not in ("above", "below", "both"):
        raise ValueError(f"direction debe ser 'above', 'below' o 'both', no {direction!r}")
    if not series:
        return TrendResult(Status.SIN_DATO, 0, 0, 0.0)

    above = _streak(series, lambda v: v > base.high)
    below = _streak(series, lambda v: v < base.low)
    out_of_range = sum(1 for v in series if not base.contains(v))
    last = series[-1]
    sustained = {"above": above, "below": below, "both": max(above, below)}[direction]

    if (absolute_high is not None and last >= absolute_high) or (
        absolute_low is not None and last <= absolute_low
    ):
        status = Status.CRITICO
    elif sustained >= SUSTAINED_DAYS:
        status = Status.ATENCION
    else:
        status = Status.NOMINAL

    return TrendResult(
        status,
        above,
        out_of_range,
        last - base.high,
        consecutive_below=below,
        delta_from_low=round(last - base.low, 4),
    )


def evaluate_sans(delta_microns: float) -> Status:
    """Cambio de grosor retiniano frente a la base (umbrales publicados)."""
    if delta_microns >= SANS_CRITICAL_UM:
        return Status.CRITICO
    if delta_microns >= SANS_ATTENTION_UM:
        return Status.ATENCION
    return Status.NOMINAL
