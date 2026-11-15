# Pendientes · TIRELUS

Matriz de tareas pendientes del hackathon (NASA Space Apps 2026). Se deriva de la sección "Matriz de pendientes" de [`README.md`](README.md); lo hecho y lo descartado quedan allí.

**Prioridad:** **P1** = importante para el MVP · **P2** = pulido si sobra tiempo.

**Responsables:** Base de datos (Francisco) · Datos (Prina) · Backend (Angel) · Front (Jenny).

## Base de datos

### Servidor · Francisco

| Prioridad | Qué falta | Detalle | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P2** | Activar TLS en el servidor PostgreSQL | El cliente ya soporta `TIRELUS_DB_SSL=require\|verify`; el servidor responde `ssl = off`. Requiere certificado, `ssl = on` y regla `hostssl` en `pg_hba.conf`. Solo importa si hay datos reales. | Administrador del servidor | 30 min |
| **P2** | Rotar la contraseña del servidor después de la demo | La contraseña de `tirelus_equipo` se compartió por chat. Cambiarla al terminar y avisar por canal privado. | Administrador del servidor | 5 min |
| **P2** | PostgreSQL interno de la nave (concepto) | Documentar el despliegue local sin Internet y mostrarlo en la presentación. No se implementa para la demo. | — | 1 h |

### Data mining · Prina

| Prioridad | Qué falta | Detalle | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Completar en la base los datos de FC, sueño, ánimo y SANS | Solo está cargada la sistólica (`db/003_demo.sql`). Faltan los `>>> DATOS:` de `data.py`, marcados "Datos de ejemplo". `data_source` debe seguir en `db`. | Datos de la persona de ciencia | 1 h |

## Decisiones

| Prioridad | Qué decidir | Detalle | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Sistema de usuarios | Hoy la API lee un tripulante fijo. Opciones: selección de perfil con rol (astronauta, CMO, flight surgeon) para la demo, o login real. Recomendado: selección de perfil. | Decisión del equipo | 1–2 h |
| **P1** | `heart_rate`: `above` o `both` | La base alerta en ambos sentidos; la app solo hacia arriba. Elegir una fuente de verdad para los umbrales (base o `data.py`). Ver `db/AUDITORIA.md`. | Criterio de la persona de ciencia | 30 min |
| **P1** | Qué hacer con `Claude outputs/` | Carpeta sin versionar con `TIRELUS_matriz_simulacion.xlsx`, que `data.py` cita como origen. Subirla al repo o cambiar la referencia. | — | 5 min |

## Backend · Angel

| Prioridad | Qué falta | Detalle | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Generalizar medición y tendencia a FC, sueño y ánimo | Falta en `METRICS` de `data.py`: línea base, límite de respaldo (supuesto de diseño) y serie de 14 días por métrica. La app ya muestra "Sin dato" hasta entonces. | Datos de la persona de ciencia | 20–30 min |
| **P1** | Medición y tendencia de SANS | Falta la serie en `SANS_SERIES` y `SANS_DAYS` de `data.py`, y la referencia NASA exacta en `SANS_SOURCE` (hoy dice "por confirmar"). | Datos y referencia NASA | 15 min |
| **P2** | Android (se intenta al final) | `-p Android` en el empaquetado y `flutter build apk`. Si uvicorn falla, cambiar a Flask o `http.server`. Decidir cómo llega el Python embebido al servidor y si hay caché local. | Empaquetado | 2–3 h |

## Front · Jenny

Sin pendientes definidos por ahora. Sección incluida para trazabilidad.

## Entrega

| Prioridad | Qué falta | Detalle | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Video, presentación y página del proyecto | Guion del video, presentación, texto del formulario y página con fuentes (NASA HRP, NTRS, CSA, ESA). Revisar los requisitos vigentes de Space Apps 2026 y preparar capturas de la app. | Capturas de la app, nombres del equipo | 3–4 h |
