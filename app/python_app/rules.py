"""Motor de reglas de TIRELUS (puro Python, sin dependencias).

SUPUESTOS DE DISEÑO: NASA no publica umbrales de alerta en vuelo para presión
ni frecuencia cardiaca. Se combina la línea base personal prevuelo, la tendencia
sostenida y un límite clínico terrestre de respaldo. La app no diagnostica:
solo señala desviaciones.
"""

from __future__ import annotations

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


def evaluate_trend(
    series: list[float],
    base: Baseline,
    absolute_high: float | None = None,
) -> TrendResult:
    """Serie diaria (la última lectura es hoy)."""
    if not series:
        return TrendResult(Status.SIN_DATO, 0, 0, 0.0)

    consecutive = 0
    for value in reversed(series):
        if value > base.high:
            consecutive += 1
        else:
            break

    out_of_range = sum(1 for v in series if not base.contains(v))
    last = series[-1]

    if absolute_high is not None and last >= absolute_high:
        status = Status.CRITICO
    elif consecutive >= SUSTAINED_DAYS:
        status = Status.ATENCION
    else:
        status = Status.NOMINAL

    return TrendResult(status, consecutive, out_of_range, last - base.high)


def evaluate_sans(delta_microns: float) -> Status:
    """Cambio de grosor retiniano frente a la base (umbrales publicados)."""
    if delta_microns >= SANS_CRITICAL_UM:
        return Status.CRITICO
    if delta_microns >= SANS_ATTENTION_UM:
        return Status.ATENCION
    return Status.NOMINAL
