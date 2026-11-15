"""Acceso opcional a PostgreSQL (solo lectura).

Decisión de despliegue (ver CLAUDE.md): en desarrollo un servidor externo compartido
y en la versión final un PostgreSQL interno de la nave. El código es el mismo; solo
cambian las variables de entorno:

    TIRELUS_DB_HOST        obligatoria; sin ella la base queda desactivada
    TIRELUS_DB_PORT        5432
    TIRELUS_DB_NAME        tirelus
    TIRELUS_DB_USER        postgres
    TIRELUS_DB_PASSWORD    (vacía)
    TIRELUS_DB_TIMEOUT     3 (segundos)
    TIRELUS_DB_SSL         off | require (cifra sin verificar certificado) | verify (cifra y verifica)
    TIRELUS_DB_SSL_CA      ruta del certificado de la autoridad (solo con verify)
    TIRELUS_ASTRONAUT_ID   uuid del tripulante; si falta se usa el primero de la tabla

Nunca se escriben credenciales en el código ni en el repo. El driver es pg8000
(Python puro, empaquetable con serious_python) y se importa solo al conectar.
"""

from __future__ import annotations

import ssl
from dataclasses import dataclass, field
from typing import Any, Mapping, Sequence

from rules import Baseline

SANS_INDICATOR = "retinal_delta"  # indicador de SANS en db/schema.sql
SERIES_DAYS = 14  # últimas lecturas por indicador (D34–D47 en la demo)


@dataclass(frozen=True)
class DbConfig:
    host: str
    port: int = 5432
    name: str = "tirelus"
    user: str = "postgres"
    password: str = field(default="", repr=False)  # nunca en repr/str ni en logs
    timeout: float = 3.0
    astronaut_id: str | None = None
    ssl_mode: str = "off"  # off | require (cifra sin verificar) | verify (cifra y verifica certificado y host)
    ssl_ca: str | None = None  # certificado de la autoridad (solo con verify)


SSL_MODES = ("off", "require", "verify")


def config_from_env(env: Mapping[str, str]) -> DbConfig | None:
    """Lee la conexión de las variables de entorno. None = base desactivada."""
    host = (env.get("TIRELUS_DB_HOST") or "").strip()
    if not host:
        return None
    try:
        port = int(env.get("TIRELUS_DB_PORT") or 5432)
    except ValueError:
        raise ValueError("TIRELUS_DB_PORT debe ser un número entero") from None
    try:
        timeout = float(env.get("TIRELUS_DB_TIMEOUT") or 3.0)
    except ValueError:
        raise ValueError("TIRELUS_DB_TIMEOUT debe ser un número") from None
    ssl_mode = (env.get("TIRELUS_DB_SSL") or "off").strip().lower()
    if ssl_mode not in SSL_MODES:
        raise ValueError("TIRELUS_DB_SSL debe ser off, require o verify") from None
    return DbConfig(
        ssl_mode=ssl_mode,
        ssl_ca=(env.get("TIRELUS_DB_SSL_CA") or "").strip() or None,
        host=host,
        port=port,
        name=env.get("TIRELUS_DB_NAME") or "tirelus",
        user=env.get("TIRELUS_DB_USER") or "postgres",
        password=env.get("TIRELUS_DB_PASSWORD") or "",
        timeout=timeout,
        astronaut_id=(env.get("TIRELUS_ASTRONAUT_ID") or "").strip() or None,
    )


def ssl_context_for(config: DbConfig) -> ssl.SSLContext | None:
    """Contexto TLS según TIRELUS_DB_SSL. None = sin cifrado (por defecto)."""
    if config.ssl_mode == "off":
        return None
    if config.ssl_mode == "verify":
        return ssl.create_default_context(cafile=config.ssl_ca)
    ctx = ssl.create_default_context()
    ctx.check_hostname = False  # antes de bajar verify_mode, o Python lo rechaza
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def connect(config: DbConfig) -> Any:
    """Abre una conexión DB-API con pg8000 (importado aquí para no exigirlo si no se usa)."""
    import pg8000.dbapi

    return pg8000.dbapi.connect(
        ssl_context=ssl_context_for(config),
        user=config.user,
        password=config.password or None,
        host=config.host,
        port=config.port,
        database=config.name,
        timeout=config.timeout,
    )


def _empty_overlay() -> dict:
    return {"metrics": {}, "sans": {"series": [], "days": []}}


def load_overlay(conn: Any, metric_ids: Sequence[str], astronaut_id: str | None = None) -> dict:
    """Lee de PostgreSQL lo que sobrepone a data.METRICS: base, límites y series.

    Devuelve {"metrics": {id: {"base", "abs_high", "abs_low", "series"}}, "sans": {"series", "days"}}
    con solo los campos que la base tiene. Todo en reposo (body_state = 'reposo').
    """
    ids = list(metric_ids)
    wanted = set(ids)
    overlay = _empty_overlay()
    metrics = overlay["metrics"]
    cur = conn.cursor()
    try:
        if astronaut_id is None:
            cur.execute("SELECT id FROM astronauts ORDER BY created_at LIMIT 1")
            row = cur.fetchone()
            if row is None:
                return overlay
            astronaut_id = str(row[0])

        cur.execute(
            "SELECT indicator_id, low, high FROM baselines "
            "WHERE astronaut_id = %s AND body_state = 'reposo' AND indicator_id = ANY(%s)",
            (astronaut_id, ids),
        )
        for indicator, low, high in cur.fetchall():
            if indicator in wanted:
                metrics.setdefault(indicator, {})["base"] = Baseline(float(low), float(high))

        # Límite clínico de respaldo (supuesto de diseño) genérico, sin entorno específico.
        cur.execute(
            "SELECT indicator_id, critico_low, critico_high FROM thresholds "
            "WHERE body_state = 'reposo' AND environment IS NULL AND indicator_id = ANY(%s)",
            (ids,),
        )
        for indicator, critico_low, critico_high in cur.fetchall():
            if indicator not in wanted:
                continue
            if critico_low is not None:
                metrics.setdefault(indicator, {})["abs_low"] = float(critico_low)
            if critico_high is not None:
                metrics.setdefault(indicator, {})["abs_high"] = float(critico_high)

        # Últimas SERIES_DAYS lecturas por indicador, de la más vieja a la más nueva.
        cur.execute(
            "SELECT indicator_id, value, mission_day FROM ("
            "  SELECT indicator_id, value, mission_day, measured_at,"
            "         row_number() OVER (PARTITION BY indicator_id ORDER BY measured_at DESC) AS rn"
            "  FROM measurements"
            "  WHERE astronaut_id = %s AND body_state = 'reposo' AND indicator_id = ANY(%s)"
            ") ultimas WHERE rn <= %s ORDER BY indicator_id, measured_at",
            (astronaut_id, ids + [SANS_INDICATOR], SERIES_DAYS),
        )
        for indicator, value, day in cur.fetchall():
            if indicator == SANS_INDICATOR:
                if day is not None:  # SANS necesita el día de misión de cada OCT
                    overlay["sans"]["series"].append(float(value))
                    overlay["sans"]["days"].append(int(day))
            elif indicator in wanted:
                metrics.setdefault(indicator, {}).setdefault("series", []).append(float(value))
    finally:
        cur.close() if hasattr(cur, "close") else None
    return overlay
