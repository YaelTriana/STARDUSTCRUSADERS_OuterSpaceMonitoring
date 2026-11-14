"""Servidor local de TIRELUS.

Se ejecuta embebido en la app Flutter con serious_python y escucha solo en
127.0.0.1. En desarrollo también se puede correr directo:

    python python_app/main.py
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

# Permite importar rules/data tanto embebido como desde la terminal.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from fastapi import FastAPI, HTTPException  # noqa: E402
from fastapi.middleware.cors import CORSMiddleware  # noqa: E402
from pydantic import BaseModel  # noqa: E402

import data  # noqa: E402
from rules import (  # noqa: E402
    SANS_ATTENTION_UM,
    SANS_CRITICAL_UM,
    Status,
    evaluate_reading,
    evaluate_sans,
    evaluate_trend,
)

app = FastAPI(title="TIRELUS API local", version="0.1.0")

# Solo para desarrollo con Flutter Web apuntando al servidor local.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- Resumen médico persistente ---------------------------------------------
# Se guarda en summary.json dentro de la carpeta de datos de la app. Flutter
# debe pasar esa carpeta en la variable TIRELUS_DATA_DIR al arrancar Python
# (ver lib/python_starter_io.dart). Si no llega, se usa ~/.tirelus.


def _summary_path() -> Path:
    folder = os.environ.get("TIRELUS_DATA_DIR")
    if not folder:
        try:
            folder = str(Path.home() / ".tirelus")
        except RuntimeError:  # embebido (Android) puede no tener HOME
            folder = str(Path(__file__).resolve().parent / "data")
    return Path(folder) / "summary.json"


def _load_summary() -> list[str]:
    path = _summary_path()
    try:
        items = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return []  # sin archivo o archivo dañado: se empieza vacío
    return [str(i) for i in items] if isinstance(items, list) else []


def _save_summary(items: list[str]) -> None:
    path = _summary_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
    tmp.replace(path)  # escritura atómica: no deja el archivo a medias


class Reading(BaseModel):
    value: float


class SummaryItem(BaseModel):
    item: str


@app.get("/health")
def health() -> dict:
    return {"ok": True, "app": "TIRELUS"}


@app.get("/dashboard")
def dashboard() -> dict:
    return {
        "mission_day": data.MISSION_DAY,
        "systems": data.SYSTEMS,
        "tasks": data.TASKS,
        "exercise": data.EXERCISE,
        "streak_days": data.STREAK_DAYS,
        "sample_data": True,
    }


@app.get("/environments")
def environments() -> dict:
    return data.ENVIRONMENTS


@app.get("/metrics")
def metrics() -> dict:
    """Catálogo de métricas con medición y tendencia."""
    return {
        "metrics": [
            {"id": key, "label": m["label"], "unit": m["unit"], "has_data": bool(m["series"]) and m["base"] is not None}
            for key, m in data.METRICS.items()
        ]
    }


# Las rutas de SANS van antes de /{metric} para que FastAPI no las confunda.
@app.get("/trend/sans")
def trend_sans() -> dict:
    series = data.SANS_SERIES
    last = series[-1] if series else None
    return {
        "metric": "sans",
        "label": "Grosor retiniano (cambio frente a la base)",
        "unit": "µm",
        "series": series,
        "days": data.SANS_DAYS,
        "status": evaluate_sans(last).value if last is not None else Status.SIN_DATO.value,
        "thresholds": {"attention_um": SANS_ATTENTION_UM, "critical_um": SANS_CRITICAL_UM},
        "source": data.SANS_SOURCE,
        "sample_data": True,
    }


@app.post("/evaluate/sans")
def evaluate_sans_reading(reading: Reading) -> dict:
    """reading.value = cambio de grosor retiniano en µm frente a la base."""
    return {
        "metric": "sans",
        "status": evaluate_sans(reading.value).value,
        "delta_um": reading.value,
        "thresholds": {"attention_um": SANS_ATTENTION_UM, "critical_um": SANS_CRITICAL_UM},
        "source": data.SANS_SOURCE,
    }


def _metric(metric: str) -> dict:
    m = data.METRICS.get(metric)
    if m is None:
        raise HTTPException(status_code=404, detail=f"Métrica desconocida: {metric}")
    return m


def _base_json(m: dict) -> dict | None:
    base = m["base"]
    return None if base is None else {"low": base.low, "high": base.high}


@app.get("/trend/{metric}")
def trend(metric: str) -> dict:
    m = _metric(metric)
    series, base = m["series"], m["base"]
    common = {
        "metric": metric,
        "label": m["label"],
        "unit": m["unit"],
        "alert_when": m["alert_when"],
        "rule": m["rule"],
        "source": m["source"],
        "sample_data": True,
    }
    if not series or base is None:
        # Aún no hay datos de ejemplo para esta métrica (ver data.METRICS).
        return {**common, "series": [], "first_day": data.MISSION_DAY, "base": _base_json(m),
                "status": Status.SIN_DATO.value, "consecutive_above": 0, "days_out_of_range": 0,
                "delta_from_high": 0, "avg7": 0}

    result = evaluate_trend(series, base, absolute_high=m["abs_high"])
    last7 = series[-7:]
    return {
        **common,
        "series": series,
        "first_day": data.MISSION_DAY - len(series) + 1,
        "base": _base_json(m),
        "status": result.status.value,
        "consecutive_above": result.consecutive_above,
        "days_out_of_range": result.days_out_of_range,
        "delta_from_high": result.delta_from_high,
        "avg7": round(sum(last7) / len(last7)),
    }


@app.post("/evaluate/{metric}")
def evaluate(metric: str, reading: Reading) -> dict:
    m = _metric(metric)
    base = m["base"]
    if base is None:
        return {"metric": metric, "status": Status.SIN_DATO.value, "delta_from_high": 0, "base": None}
    status = evaluate_reading(reading.value, base, absolute_high=m["abs_high"], absolute_low=m["abs_low"])
    return {
        "metric": metric,
        "status": status.value,
        "delta_from_high": reading.value - base.high,
        "base": _base_json(m),
    }


@app.get("/autonomous")
def autonomous(env: str = "marte") -> dict:
    info = data.ENVIRONMENTS.get(env, data.ENVIRONMENTS["marte"])
    return {"env": info, **data.AUTONOMOUS_PROTOCOL}


@app.get("/habitat")
def habitat() -> dict:
    return data.HABITAT


@app.get("/eva")
def eva() -> dict:
    return data.EVA


@app.get("/summary")
def get_summary() -> dict:
    return {"items": _load_summary()}


@app.post("/summary")
def add_summary(entry: SummaryItem) -> dict:
    items = _load_summary()
    if entry.item not in items:
        items.append(entry.item)
        _save_summary(items)
    return {"items": items}


def run() -> None:
    import uvicorn

    port = int(os.environ.get("TIRELUS_PORT", "8765"))
    # log_config=None: embebido puede no haber stdout/stderr utilizables.
    uvicorn.run(app, host="127.0.0.1", port=port, log_config=None, access_log=False)


if __name__ == "__main__":
    run()
