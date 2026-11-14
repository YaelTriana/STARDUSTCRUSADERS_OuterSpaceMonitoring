"""Servidor local de TIRELUS.

Se ejecuta embebido en la app Flutter con serious_python y escucha solo en
127.0.0.1. En desarrollo también se puede correr directo:

    python python_app/main.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

# Permite importar rules/data tanto embebido como desde la terminal.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from fastapi import FastAPI  # noqa: E402
from fastapi.middleware.cors import CORSMiddleware  # noqa: E402
from pydantic import BaseModel  # noqa: E402

import data  # noqa: E402
from rules import evaluate_reading, evaluate_trend  # noqa: E402

app = FastAPI(title="TIRELUS API local", version="0.1.0")

# Solo para desarrollo con Flutter Web apuntando al servidor local.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_summary: list[str] = []


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


@app.get("/trend/systolic")
def trend_systolic() -> dict:
    series = data.SYSTOLIC_14
    base = data.SYSTOLIC_BASE
    result = evaluate_trend(series, base, absolute_high=data.SYSTOLIC_ABS_HIGH)
    first_day = data.MISSION_DAY - len(series) + 1
    last7 = series[-7:]
    return {
        "series": series,
        "first_day": first_day,
        "base": {"low": base.low, "high": base.high},
        "status": result.status.value,
        "consecutive_above": result.consecutive_above,
        "days_out_of_range": result.days_out_of_range,
        "delta_from_high": result.delta_from_high,
        "avg7": round(sum(last7) / len(last7)),
        "rule": "Supuesto de diseño: 3 días consecutivos sobre la base personal.",
        "sample_data": True,
    }


@app.post("/evaluate/systolic")
def evaluate_systolic(reading: Reading) -> dict:
    base = data.SYSTOLIC_BASE
    status = evaluate_reading(reading.value, base, absolute_high=data.SYSTOLIC_ABS_HIGH)
    return {
        "status": status.value,
        "delta_from_high": reading.value - base.high,
        "base": {"low": base.low, "high": base.high},
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
    return {"items": _summary}


@app.post("/summary")
def add_summary(entry: SummaryItem) -> dict:
    if entry.item not in _summary:
        _summary.append(entry.item)
    return {"items": _summary}


def run() -> None:
    import uvicorn

    port = int(os.environ.get("TIRELUS_PORT", "8765"))
    # log_config=None: embebido puede no haber stdout/stderr utilizables.
    uvicorn.run(app, host="127.0.0.1", port=port, log_config=None, access_log=False)


if __name__ == "__main__":
    run()
