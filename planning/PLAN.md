# Plan de acción · TIRELUS (NASA Space Apps Challenge 2026)

Objetivo: entregar un prototipo funcional y la presentación antes del cierre del hackathon (14–15 nov 2026). Confirmen la hora límite exacta en la guía de entrega de su sede.

## Estado actual (15 nov)

| Entregable | Estado |
|---|---|
| Investigación de riesgos, requisitos de astronautas y habilidades médicas a bordo | Hecho |
| Lineamientos visuales (inspirado en el Horizon Design System de NASA, sin marca oficial) | Hecho |
| Propuesta visual (7 pantallas) y pizarrón de flujos de trabajo | Hecho |
| Instrucciones para Claude (`CLAUDE.md`) y 31 skills en `.claude/skills/` | Hecho (PR #1 y #2, en `main`) |
| Decisión de arquitectura: Flutter + Python embebido con serious_python | Hecho |
| Mockup: motor de reglas en Python (20 pruebas pasan) + API local + 7 pantallas Flutter | Hecho (PR #3, en `main`) |
| Exportar el resumen médico, validación de rangos, capa de PostgreSQL con respaldo | Hecho (en `main`) |
| Esquema y poblado de la base (`db/004_populate.sql`, 30 tripulantes) | Hecho en `main`; falta confirmar la carga en el servidor |
| UI de Jenny (ES/EN, navegación adaptable, modo Autónomo guiado) | Hecho (fusionado en `main` el 15 nov) |
| Empaquetado real con serious_python y Docker | Descartado el 14 nov (la demo corre en modo desarrollo) |
| Android | Recortado de la demo; se intenta al final |
| Video demo, presentación y página del proyecto | **Pendiente** |

## Arquitectura

- **UI:** Flutter (Dart) en `app/`.
- **Lógica:** Python en `app/python_app/`, embebido con serious_python 6.x. No se porta a Dart.
- **Comunicación:** API HTTP local (FastAPI) en `127.0.0.1:8765`.
- **Demo:** Windows en modo desarrollo. Android se intenta al final, solo si sobra tiempo.
- **Base de datos:** PostgreSQL. Servidor compartido en la red local para el hackathon; interno en la nave como concepto final. Datos sintéticos del repo [`SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring`](https://github.com/MerelyMeredith/SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring).

## 1. Alcance mínimo (MVP)

- Panel principal con figura corporal interactiva y semáforo por sistema.
- Medición guiada: captura, comparación contra la línea base y explicación.
- Tendencia con alerta por desviación sostenida.
- Resumen exportable para la conferencia médica privada.
- Selector de entorno (ISS, Luna o Marte) que cambia el retraso y activa el modo autónomo.
- **Extras:** consola de base, visor de casco y variante de mano (ya están en el mockup como pantallas de demostración).

## 2. Fases

| Fase | Tiempo | Entregable | Estado |
|---|---|---|---|
| 0. Arranque | 1 h | Repo, roles, alcance cerrado | Hecho |
| 1. Base técnica | 1–2 h | Proyecto Flutter, tema, navegación, serious_python instalado | Hecho |
| 2. Datos y lógica | 3–4 h | Datos de ejemplo, motor de reglas en Python con pytest, API local | Hecho |
| 3. Pantallas centrales | 6–8 h | Panel, medición, tendencia con alerta | Hecho (mockup) |
| 4. Integración real (P0) | 3–6 h | Exportar el resumen médico; PostgreSQL probado contra el servidor del equipo. Empaquetado descartado | Hecho |
| 5. MVP completo (P1) y pulido (P2) | 5–8 h | P1: guardar el resumen entre reinicios, medición y tendencia de SANS, generalizar a más métricas. P2: selector de entorno en pantallas angostas, pruebas de widgets, accesibilidad | A medias: faltan datos de respaldo en `data.py`, y confirmar la carga del poblado |
| 6. Entrega | 3 h | Video demo, presentación, página del proyecto con fuentes citadas | Pendiente |

> El detalle de cada tarea (cómo hacerla y cuánto toma) está en la **matriz de pendientes**, [`pendientes.md`](../pendientes.md). Esa matriz es la fuente única: si cambia una tarea, se actualiza allá.

## 3. Calendario

- **Sábado tarde:** fase 4 (exportar resumen y PostgreSQL). El empaquetado se descartó; la demo corre en modo desarrollo.
- **Domingo temprano:** fase 5 y congelar funciones a mediodía.
- **Domingo tarde:** fase 6, con 2 h de margen antes del cierre.

## 4. Roles (equipo de 4 a 6)

| Rol | Personas | Responsable de |
|---|---|---|
| Front-end Flutter | 2 | Pantallas, navegación, conexión con la API local |
| Python y empaquetado | 1 | Motor de reglas, API, serious_python en Windows/Android |
| Contenido científico | 1 | Textos educativos, umbrales con su fuente |
| Diseño y pitch | 1–2 | Propuesta visual, video, presentación, entrega |

## 5. Comandos clave

```powershell
# Pruebas del motor de reglas
cd app; .\.venv-py\Scripts\python -m pytest tests_py -q

# Desarrollo: servidor Python aparte + Flutter
.\.venv-py\Scripts\python python_app\main.py
flutter run -d windows --dart-define=TIRELUS_DEV_SERVER=true

# Empaquetado real (Windows)
$env:SERIOUS_PYTHON_VERSION = "3.12"
$env:SERIOUS_PYTHON_SITE_PACKAGES = "$PWD\build\site-packages"
$env:SERIOUS_PYTHON_APP = "$PWD\build\python_app"
dart run serious_python:main package python_app -p Windows -r -r -r python_app/requirements.txt --cleanup
flutter run -d windows
```

## 6. Riesgos y qué recortar primero

- **FastAPI no arranca embebido en Android:** cambiar a Flask o `http.server`.
- **Atraso general:** visor, base y voz quedan como pantallas de demostración sin lógica nueva.
- **Umbrales:** presentarlos siempre como supuestos de diseño, salvo los de SANS (+20 µm y 55 µm), que sí tienen cifra publicada.
- **Marca:** no usar el logotipo ni la insignia de NASA; solo marca propia y citas a las fuentes.
- **Plan B de demo:** tener un video grabado por si falla la demostración en vivo.

## 7. Pendientes técnicos

- Decidir la gestión de estado de Flutter (Riverpod o Bloc) y agregar solo un paquete de skills.
- Escribir las skills propias: `tirelus-motor-reglas`, `tirelus-datos-sinteticos`, `tirelus-contrato-api`, `tirelus-ui-cabina`.
