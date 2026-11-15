# Pendientes · TIRELUS

Matriz de tareas pendientes del hackathon (NASA Space Apps 2026). Se deriva de la sección "Matriz de pendientes" de [`README.md`](README.md); lo hecho y lo descartado quedan allí. Lo que se dejó para después de la demo está en [`planning/FUTURO.md`](planning/FUTURO.md).

**Prioridad:** **P1** = importante para el MVP · **P2** = pulido si sobra tiempo.

**Responsables:** Base de datos (Francisco) · Datos (Prina) · Backend (Angel) · Front (Jenny).

## Base de datos

### Servidor · Francisco

Sin pendientes. La demo usa solo datos sintéticos, así que TLS, la rotación de la contraseña y el PostgreSQL interno de la nave se descartaron para la demo (15 nov) y pasaron a [`planning/FUTURO.md`](planning/FUTURO.md) §4.

### Datos · Prina y Angel

Fuente única de los datos sintéticos: el repo [`SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring`](https://github.com/MerelyMeredith/SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring), citado en el README. Se quedan los datos que ya están en `main` (carga con `tools/sim_sinteticos.py`, de Angel); no hay más trabajo de datos para la demo.

| Prioridad | Qué falta | Detalle | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P2** | Examen retiniano periódico en el generador | `generate.py` programa el OCT solo al día 0 y un segundo examen si hay 90 días o más, ignorando `retinal_exam_interval_days_*` del config. Sin eso, la serie de SANS se queda en 1–2 puntos. | Repo del generador | 30 min |

Los umbrales de respaldo que faltan (`body_mass`, `hrv`, `macular_thickness`, `rnfl_thickness`, `cup_to_disc_ratio`, `near_vision_logmar`) se planearon a futuro: [`planning/FUTURO.md`](planning/FUTURO.md) §1.

## Decisiones

| Prioridad | Qué decidir | Detalle | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Qué hacer con `Claude outputs/` | Carpeta sin versionar con `TIRELUS_matriz_simulacion.xlsx`, que un comentario de `data.py` nombra como origen de las series. Recomendado: no subirla, agregarla a `.gitignore` y cambiar ese comentario para que apunte al repo de datos sintéticos, que ya es la fuente única. | — | 5 min |

Decididas el 15 nov:

- **Sistema de usuarios:** la API se queda con el tripulante fijo para la demo. La deuda técnica está en [`planning/FUTURO.md`](planning/FUTURO.md) §2.
- **Dirección de la alerta:** `heart_rate`, `temperature`, `rnfl_thickness`, `intraocular_pressure` y `cup_to_disc_ratio` deben alertar en ambos sentidos (`both`), igual que en la base. No está en `main`: queda como deuda técnica, con el trabajo en la rama `feat/alerta-ambos-sentidos`. Ver [`planning/FUTURO.md`](planning/FUTURO.md) §3.

## Backend · Angel

Revisado contra `main` el 15 nov. Cómo viajan los datos: `tools/sim_sinteticos.py` lee los CSV del generador y escribe tripulación, línea base (primeros 14 días) y lecturas en PostgreSQL, marcadas "Datos de ejemplo (sintéticos)". `db.py` lee del tripulante fijo la línea base, los límites de respaldo y las últimas 14 lecturas por indicador, y `catalog.py` las sobrepone a `data.METRICS` cada `TIRELUS_DB_TTL` segundos. Si la base falta o falla, la app sigue con `data.py`. Textos, reglas, fuentes y dirección de la alerta salen siempre de `data.py`.

| Prioridad | Qué falta | Detalle | Depende de | Esfuerzo |
|---|---|---|---|---|
| **P1** | Guardar lo que captura el astronauta | No hay endpoint de escritura de lecturas: `POST /evaluate/{metric}` evalúa y descarta, así que la alerta por desviación sostenida no puede nacer durante la demo. `measurements` ya está diseñada para esto. Ver A2 en `planning/AUDITORIA.md`. | — | 1–2 h |
| **P1** | Cerrar CORS por defecto | `main.py` monta `allow_origins=["*"]`. Montarlo solo con `TIRELUS_DEV_CORS`. Ver C en la auditoría. | — | 10 min |
| **P1** | Día de misión real | `data.MISSION_DAY = 47` fijo en `/trend`, `/dashboard` y la exportación, y `lib/main.dart` imprime "047" literal: con datos de la base el día del gráfico no coincide. Ver A6 en la auditoría. | — | 30 min |
| **P1** | Referencia NASA de SANS | `SANS_SOURCE` en `data.py` dice "Referencia NASA por confirmar". Falta la cita exacta de los umbrales +20 µm y 55 µm. | Referencia NASA | 15 min |
| **P2** | Valores de ejemplo en `data.py` (camino sin base de datos) | Con PostgreSQL cargado las pantallas muestran las métricas. Sin base, solo la sistólica tiene datos: las otras 13 métricas y `SANS_SERIES`/`SANS_DAYS` están vacías (`>>> DATOS:`) y la demo de respaldo diría "Sin dato". Se pueden copiar del CSV de un tripulante. | Un CSV del generador | 30 min |
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
