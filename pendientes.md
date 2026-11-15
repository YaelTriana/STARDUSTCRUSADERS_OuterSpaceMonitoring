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

### Datos · Prina y Angel

Fuente única de los datos sintéticos: el repo [`SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring`](https://github.com/MerelyMeredith/SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring) (genera `dataset.csv`; Angel elabora el dataset). El CSV va en `db/datosdb/` y no se versiona aquí.

| Prioridad | Qué falta | Detalle | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Cargar el poblado completo en el servidor y verificarlo | 🟡 A medias. `db/004_populate.sql` ya está en `main` (30 903 mediciones, 30 tripulantes, 21 indicadores). Falta confirmar la carga en el servidor, `data_source: db`, pantallas sin "Sin dato" y la marca "Datos de ejemplo". | Dataset de Angel | 30 min |
| **P1** | Citar el repo de datos y anotar cómo se generó el dataset | TIRELUS no cita el repo de datos; `data.py` aún nombra `Claude outputs/`. Anotar commit y parámetros (el repo documenta 1800 filas; el poblado usa 3000). | Dataset de Angel | 15 min |
| **P2** | Umbrales de respaldo que faltan | `body_mass`, `hrv`, `macular_thickness`, `rnfl_thickness`, `cup_to_disc_ratio`, `near_vision_logmar`. Supuestos de diseño; no se inventan (`db/AUDITORIA.md` §5.1). | Criterio de la persona de ciencia | 30 min |

## Decisiones

| Prioridad | Qué decidir | Detalle | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Sistema de usuarios | Hoy la API lee un tripulante fijo. Opciones: selección de perfil con rol (astronauta, CMO, flight surgeon) para la demo, o login real. Recomendado: selección de perfil. | Decisión del equipo | 1–2 h |
| **P1** | `heart_rate`: `above` o `both` | La base alerta en ambos sentidos; la app solo hacia arriba. Igual con `respiratory_rate`, `temperature`, `intraocular_pressure`, `rnfl_thickness` y `cup_to_disc_ratio`. Elegir una fuente de verdad para los umbrales (base o `data.py`). Ver `db/AUDITORIA.md` §5.2. | Criterio de la persona de ciencia | 30 min |
| **P1** | Qué hacer con `Claude outputs/` | Carpeta sin versionar con `TIRELUS_matriz_simulacion.xlsx`, que `data.py` cita como origen. Recomendado: cambiar la referencia al repo de datos sintéticos y no subir la carpeta. | — | 5 min |

## Backend · Angel

| Prioridad | Qué falta | Detalle | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Generalizar medición y tendencia a FC, sueño y ánimo | Con la base cargada los datos llegan por `db.py`. Falta el respaldo sin base en `METRICS` de `data.py`: línea base, límite de respaldo (supuesto de diseño) y serie de 14 días por métrica, tomados del dataset. | Dataset de Angel | 20–30 min |
| **P1** | Medición y tendencia de SANS | Falta la serie en `SANS_SERIES` y `SANS_DAYS` de `data.py` (del dataset, como cambio de RNFL), y la referencia NASA exacta en `SANS_SOURCE` (hoy dice "por confirmar"). | Datos y referencia NASA | 15 min |
| **P2** | Android (se intenta al final) | `-p Android` en el empaquetado y `flutter build apk`. Si uvicorn falla, cambiar a Flask o `http.server`. Decidir cómo llega el Python embebido al servidor y si hay caché local. | Empaquetado | 2–3 h |

## Front · Jenny

Sin pendientes: `frontend/jen-trabajo` se fusionó en `main` el 15 nov (`707c4c6`).

## Ramas

| Prioridad | Qué falta | Detalle | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P2** | Cerrar `AngelPrueba` y borrar ramas ya fusionadas | `AngelPrueba` es una capa de PostgreSQL anterior a la de `main` y choca con ella. El resto de ramas `feat/*`, `docs/planning` y `chore/claude-setup` ya están fusionadas. | Confirmación de Angel | 10 min |

## Entrega

| Prioridad | Qué falta | Detalle | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Video, presentación y página del proyecto | Guion del video, presentación, texto del formulario y página con fuentes (NASA HRP, NTRS, CSA, ESA). Revisar los requisitos vigentes de Space Apps 2026 y preparar capturas de la app. | Capturas de la app, nombres del equipo | 3–4 h |
