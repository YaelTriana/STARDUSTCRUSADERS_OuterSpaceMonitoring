"""Catálogo de métricas: datos de ejemplo (data.py) + capa opcional de PostgreSQL.

Si hay base configurada y responde, sus base, límites y series sobreponen a los de
data.METRICS. Si no hay base, o falla, la app sigue con los datos de ejemplo: la
demo nunca depende de la red. Textos, reglas y fuentes siempre salen de data.py.
"""

from __future__ import annotations

import os
import threading
import time
from dataclasses import dataclass
from typing import Any, Callable, Mapping

import data
import db
import sim
from rules import within_valid_range


@dataclass(frozen=True)
class Snapshot:
    metrics: dict
    sans_series: list
    sans_days: list
    source: str  # "db", "simulacion" o "ejemplo"


class Catalog:
    def __init__(
        self,
        base_metrics: dict,
        base_sans: dict,
        loader: Callable[[], dict] | None = None,
        ttl: float = 30.0,
        clock: Callable[[], float] = time.monotonic,
        source: str = "db",
    ) -> None:
        self._base = Snapshot(base_metrics, list(base_sans["series"]), list(base_sans["days"]), "ejemplo")
        self._loader = loader
        self._source = source  # de dónde vienen los datos cuando el loader responde
        self._ttl = ttl
        self._clock = clock
        self._lock = threading.Lock()
        self._snap: Snapshot | None = None
        self._expires = 0.0
        self.last_error: str | None = None  # solo el tipo del error: nunca el mensaje (puede traer datos de conexión)

    def snapshot(self) -> Snapshot:
        if self._loader is None:
            return self._base
        with self._lock:
            now = self._clock()
            if self._snap is None or now >= self._expires:
                self._snap = self._refresh()
                self._expires = now + self._ttl  # los fallos también se cachean: no se golpea al servidor
            return self._snap

    def _refresh(self) -> Snapshot:
        try:
            overlay = self._loader()  # type: ignore[misc]
        except Exception as err:  # noqa: BLE001 - cualquier fallo de red o SQL cae a datos de ejemplo
            self.last_error = type(err).__name__
            return self._base
        self.last_error = None
        sans = overlay["sans"]
        if not overlay["metrics"] and not sans["series"]:
            return self._base
        metrics = {key: dict(value) for key, value in self._base.metrics.items()}
        for key, fields in overlay["metrics"].items():
            if key in metrics:
                metrics[key].update(fields)
                # La base no valida rangos: se descartan lecturas fuera del rango de captura.
                valid = metrics[key].get("valid_range")
                if valid is not None and "series" in fields:
                    metrics[key]["series"] = [v for v in fields["series"] if within_valid_range(v, valid)]
        if sans["series"]:
            pairs = [(v, d) for v, d in zip(sans["series"], sans["days"]) if within_valid_range(v, data.SANS_VALID_RANGE)]
            return Snapshot(metrics, [v for v, _ in pairs], [d for _, d in pairs], self._source)
        return Snapshot(metrics, self._base.sans_series, self._base.sans_days, self._source)


DEFAULT_TTL = 30.0  # segundos entre relecturas de la base
# Con el simulador embebido leer el origen no cuesta red: cachear 30 s dejaría el
# panel congelado dentro del binario. Un TTL explícito le gana a este.
TTL_SIMULACION = 1.0


def ttl_from_env(env: Mapping[str, str]) -> float:
    """Cada cuánto se relee la base (TIRELUS_DB_TTL, en segundos).

    Corto para la demo (se ve cambiar), largo a bordo (menos tráfico). Un valor
    inválido no desactiva la base: se usa el de por defecto.
    """
    try:
        ttl = float(env.get("TIRELUS_DB_TTL") or DEFAULT_TTL)
    except ValueError:
        return DEFAULT_TTL
    return ttl if ttl > 0 else DEFAULT_TTL


def build_catalog(
    env: Mapping[str, str] | None = None,
    connect_fn: Callable[[db.DbConfig], Any] | None = None,
    ttl: float | None = None,
    clock: Callable[[], float] = time.monotonic,
) -> Catalog:
    """Arma el catálogo según las variables de entorno.

    Tres orígenes posibles, en este orden:
      1. `TIRELUS_SIM=vivo` → el simulador embebido (sin red; lo que lleva el .exe).
         Manda sobre la base porque se pidió explícitamente.
      2. `TIRELUS_DB_HOST` → PostgreSQL.
      3. nada → los datos de ejemplo de data.py.
    """
    env = os.environ if env is None else env
    connect_fn = connect_fn or db.connect
    ttl = ttl_from_env(env) if ttl is None else ttl

    simulador = sim.desde_env(env, clock)
    if simulador is not None:
        return Catalog(
            data.METRICS,
            {"series": data.SANS_SERIES, "days": data.SANS_DAYS},
            loader=simulador,
            ttl=ttl if "TIRELUS_DB_TTL" in env else TTL_SIMULACION,
            clock=clock,
            source="simulacion",
        )

    try:
        cfg = db.config_from_env(env)
    except ValueError:
        cfg = None  # configuración inválida: se queda con los datos de ejemplo

    loader = None
    if cfg is not None:

        def loader() -> dict:
            conn = connect_fn(cfg)
            try:
                return db.load_overlay(conn, list(data.METRICS), cfg.astronaut_id)
            finally:
                conn.close()

    return Catalog(
        data.METRICS,
        {"series": data.SANS_SERIES, "days": data.SANS_DAYS},
        loader=loader,
        ttl=ttl,
        clock=clock,
    )
