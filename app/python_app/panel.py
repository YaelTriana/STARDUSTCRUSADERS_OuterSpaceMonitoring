"""Arma los bloques del panel (semáforo por sistema) desde el catálogo.

Nada de cifras escritas a mano: cada azulejo sale de las métricas del catálogo
(datos de ejemplo o PostgreSQL) y su estado lo decide `rules.evaluate_trend`,
la misma regla que usa la pantalla de Tendencia, para que las dos nunca
discrepen. El texto educativo de cada sistema ("por qué cambia", "qué hacer")
sigue en `data.py`: es contenido, no lógica.

Una métrica sin línea base o sin lecturas queda en "Sin dato", igual que en
Medición y Tendencia; el sistema toma el peor estado de sus métricas con datos.
"""

from __future__ import annotations

from typing import Sequence

from rules import (
    SANS_ATTENTION_UM,
    SANS_CRITICAL_UM,
    SUSTAINED_DAYS,
    Status,
    evaluate_sans,
    evaluate_trend,
)

SIN_DATO = "—"

# SANS es el único indicador con cifras publicadas, así que lleva su propio azulejo.
SANS_LABEL = "Grosor retiniano (cambio)"
SANS_SISTEMA = "ojos"

# De mejor a peor: el sistema hereda el peor estado de sus indicadores con datos.
_SEVERIDAD = {Status.SIN_DATO: 0, Status.NOMINAL: 1, Status.ATENCION: 2, Status.CRITICO: 3}


def _fmt(value: float) -> str:
    """Entero si el dato es entero; un decimal si no (horas, SpO₂, ánimo)."""
    return f"{value:.0f}" if float(value).is_integer() else f"{value:.1f}"


def _nota(last: float, base, streak: int) -> str:
    """Variación frente a la línea base personal, con el rango y el conteo de días.

    El conteo evita el azulejo contradictorio (un valor sobre la base con estado
    nominal): la regla pide SUSTAINED_DAYS días seguidos, y la nota dice en qué
    parte del conteo va.
    """
    rango = f"({_fmt(base.low)}–{_fmt(base.high)})"
    if last > base.high:
        cuerpo = f"▲ {_fmt(last - base.high)} sobre tu base {rango}"
    elif last < base.low:
        cuerpo = f"▼ {_fmt(base.low - last)} bajo tu base {rango}"
    else:
        return f"en tu base {rango}"
    if streak <= 0:
        return cuerpo
    if streak >= SUSTAINED_DAYS:
        return f"{cuerpo} · {streak} días seguidos"
    return f"{cuerpo} · {streak} de {SUSTAINED_DAYS} días"


def _con_signo(valor: float) -> str:
    """El cambio de SANS se lee con signo: +8, +22, -3."""
    return f"+{_fmt(valor)}" if valor > 0 else _fmt(valor)


def build_sans_indicator(serie: Sequence[float]) -> dict:
    """Azulejo de SANS: cambio de grosor retiniano frente a la base del OCT.

    No se compara contra la línea base personal como el resto: los umbrales de SANS
    (+20 µm primer signo, 55 µm preocupación clínica) son las únicas cifras publicadas
    del proyecto, y los aplica `rules.evaluate_sans`.
    """
    if not serie:
        return {
            "label": SANS_LABEL,
            "value": SIN_DATO,
            "unit": "µm",
            "note": "Sin dato",
            "status": Status.SIN_DATO.value,
        }
    ultimo = float(serie[-1])
    return {
        "label": SANS_LABEL,
        "value": _con_signo(ultimo),
        "unit": "µm",
        "note": f"atención desde +{_fmt(SANS_ATTENTION_UM)} µm · preocupación clínica {_fmt(SANS_CRITICAL_UM)} µm",
        "status": evaluate_sans(ultimo).value,
    }


def build_indicator(metric: dict) -> dict:
    """Un azulejo del panel a partir de una métrica del catálogo."""
    series, base = metric["series"], metric["base"]
    if not series or base is None:
        return {
            "label": metric["label"],
            "value": SIN_DATO,
            "unit": metric["unit"],
            "note": "Sin dato",
            "status": Status.SIN_DATO.value,
        }
    result = evaluate_trend(
        series,
        base,
        absolute_high=metric["abs_high"],
        absolute_low=metric["abs_low"],
        direction=metric["alert_when"],
    )
    last = series[-1]
    # Los días seguidos se cuentan del lado donde está el valor, no del lado que alerta.
    if last > base.high:
        streak = result.consecutive_above
    elif last < base.low:
        streak = result.consecutive_below
    else:
        streak = 0
    return {
        "label": metric["label"],
        "value": _fmt(last),
        "unit": metric["unit"],
        "note": _nota(last, base, streak),
        "status": result.status.value,
    }


def _peor(statuses: list[str]) -> str:
    conocidos = [Status(s) for s in statuses if s != Status.SIN_DATO.value]
    if not conocidos:
        return Status.SIN_DATO.value
    return max(conocidos, key=lambda s: _SEVERIDAD[s]).value


def build_system(
    system_id: str,
    metrics: dict,
    content: dict,
    sans: Sequence[float] | None = None,
) -> dict:
    """Bloque del panel para un sistema: estado, azulejos y texto educativo.

    `metrics` es `catalog.snapshot().metrics`; `content` la entrada de `data.SYSTEMS`
    con el nombre y los textos de ese sistema. `sans` es la serie de OCT del catálogo:
    cuando se pasa (sistema de ojos), su azulejo va primero porque es el indicador con
    cifras publicadas.
    """
    indicators = [] if sans is None else [build_sans_indicator(sans)]
    indicators += [
        build_indicator(metric) for metric in metrics.values() if metric.get("system") == system_id
    ]
    return {
        "id": system_id,
        "name": content["name"],
        "status": _peor([i["status"] for i in indicators]),
        "indicators": indicators,
        "why": content["why"],
        "action": content["action"],
        "computed": True,
    }
