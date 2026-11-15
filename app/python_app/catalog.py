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


@dataclass(frozen=True)
class Snapshot:
    metrics: dict
    sans_series: list
    sans_days: list
    source: str  # "db" o "ejemplo"


class Catalog:
    def __init__(
        self,
        base_metrics: dict,
        base_sans: dict,
        loader: Callable[[], dict] | None = None,
        ttl: float = 30.0,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        self._base = Snapshot(base_metrics, list(base_sans["series"]), list(base_sans["days"]), "ejemplo")
        self._loader = loader
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
        if sans["series"]:
            return Snapshot(metrics, list(sans["series"]), list(sans["days"]), "db")
        return Snapshot(metrics, self._base.sans_series, self._base.sans_days, "db")


def build_catalog(
    env: Mapping[str, str] | None = None,
    connect_fn: Callable[[db.DbConfig], Any] | None = None,
    ttl: float = 30.0,
) -> Catalog:
    """Arma el catálogo según las variables de entorno TIRELUS_DB_*."""
    env = os.environ if env is None else env
    connect_fn = connect_fn or db.connect
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

    return Catalog(data.METRICS, {"series": data.SANS_SERIES, "days": data.SANS_DAYS}, loader=loader, ttl=ttl)
