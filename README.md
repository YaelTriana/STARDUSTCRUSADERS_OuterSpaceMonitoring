# TIRELUS

**Automonitoreo de salud para astronautas.** La app recoge indicadores de salud de cada tripulante, los compara contra su línea base personal y le dice qué hacer o a quién escalar cuando algo se desvía.

Proyecto del equipo **STARDUST CRUSADERS** (Instituto Tecnológico de Tijuana) para el NASA Space Apps Challenge 2026, 14–15 de noviembre.

> **TIRELUS no diagnostica.** Señala desviaciones y sugiere el siguiente paso (astronauta → CMO → flight surgeon). Todos los umbrales son supuestos de diseño, salvo los de SANS. Los datos de la demo son sintéticos y se muestran como "Datos de ejemplo".

## Contenido

- [Qué hace](#qué-hace)
- [Cómo decide](#cómo-decide)
- [Arquitectura](#arquitectura)
- [Inicio rápido](#inicio-rápido)
- [Pruebas](#pruebas)
- [Configuración](#configuración)
- [Base de datos](#base-de-datos)
- [Datos sintéticos](#datos-sintéticos)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Estado del proyecto](#estado-del-proyecto)
- [Documentación](#documentación)
- [Diseño](#diseño)
- [Fuentes](#fuentes)
- [Equipo](#equipo)

## Qué hace

| Función | Descripción |
|---|---|
| Panel principal | Figura corporal interactiva con un semáforo por sistema: corazón, ojos (SANS), hueso y músculo, sueño y ánimo, inmune. Se calcula con el motor de reglas y se refresca solo. |
| Medición guiada | Captura un dato, lo compara contra la línea base personal y explica qué mide y por qué cambia en el espacio. |
| Tendencia | Serie de 14 días con alerta por desviación sostenida. |
| Resumen médico | Exporta en Markdown el resumen para la conferencia médica privada semanal. |
| Entorno | Selector ISS / Luna / Marte: cambia el retraso de comunicación y activa un modo autónomo con protocolo guiado y mensajes diferidos. |
| Extras | Consola de base (vista compartida sin datos clínicos) y pantallas de EVA, como concepto. |

La interfaz está en español e inglés.

## Cómo decide

- **Línea base personal.** Cada lectura se compara contra el rango prevuelo del propio tripulante, no contra un promedio poblacional.
- **Desviación sostenida.** Tres días seguidos fuera de la línea base marcan "atención". Un límite clínico terrestre de respaldo marca "crítico".
- **Umbrales.** NASA no publica umbrales de alerta en vuelo para presión, frecuencia cardiaca ni laboratorio. Por eso cada umbral es un **supuesto de diseño** y la app lo etiqueta así.
- **SANS, la única excepción con cifra publicada.** +20 µm de grosor retiniano es el primer signo; 55 µm o Frisén 1 es preocupación clínica.
- **Estados.** Cada estado combina color, forma y palabra: nominal, atención, crítico o sin dato.
- **Privacidad.** Los datos médicos de cada tripulante solo los ven él mismo, el CMO y el flight surgeon. Nunca aparecen en pantallas compartidas.

## Arquitectura

```
Flutter (app/lib)  ──HTTP──▶  API local en Python (app/python_app)  ──opcional──▶  PostgreSQL (db/)
     interfaz                 127.0.0.1:8765 · motor de reglas                     línea base, límites y lecturas
```

- **Interfaz:** Flutter (Dart). Solo habla con la API local; nunca con la base de datos.
- **Lógica:** Python con FastAPI y uvicorn. El motor de reglas (`rules.py`) es Python estándar y es el único dueño de la lógica: no se porta a Dart.
- **Datos:** `catalog.py` sobrepone lo que lee de PostgreSQL a los datos de ejemplo de `data.py`. Si la base no está configurada o no responde, la app sigue con los datos de ejemplo.
- **Plataforma de la demo:** Windows, en modo desarrollo. El empaquetado con serious_python, Docker y Android se dejaron fuera de la demo (ver [`planning/HISTORIAL.md`](planning/HISTORIAL.md)).

Rutas principales de la API:

| Ruta | Para qué |
|---|---|
| `GET /health` | Estado del servidor y origen de los datos (`data_source`: `db` o `ejemplo`) |
| `GET /dashboard` | Panel con los cinco sistemas |
| `GET /metrics` | Catálogo de métricas |
| `GET /trend/{metric}` · `GET /trend/sans` | Serie, línea base y estado de la tendencia |
| `POST /evaluate/{metric}` · `POST /evaluate/sans` | Evalúa una lectura capturada (422 si está fuera del rango de captura) |
| `GET /environments` · `GET /autonomous` | Entornos y modo autónomo |
| `GET /summary` · `POST /summary` · `GET /summary/export` | Resumen médico y su exportación |

## Inicio rápido

Requisitos: Flutter con Dart 3.12 o posterior, Python 3.12 y Windows con las herramientas de escritorio de Flutter.

Preparar el entorno de Python (una sola vez):

```powershell
cd app
python -m venv .venv-py
.\.venv-py\Scripts\python -m pip install -r python_app/requirements.txt pytest httpx
```

Correr la app en dos terminales, ambas desde `app/`:

```powershell
.\.venv-py\Scripts\python python_app/main.py
```

```powershell
flutter run -d windows --dart-define=TIRELUS_DEV_SERVER=true
```

Sin más configuración la app usa los datos de ejemplo de `data.py`. Para leer de PostgreSQL, ver [Base de datos](#base-de-datos).

## Pruebas

Desde `app/`:

```powershell
.\.venv-py\Scripts\python -m pytest tests_py -q
```

```powershell
flutter test
```

- **Python (168 pruebas):** motor de reglas, panel, API, rangos de captura, exportación, configuración, TLS, lectura de PostgreSQL y carga de datos sintéticos.
- **Flutter (98 pruebas):** cliente de la API, panel con refresco, semáforo, selector de entorno, contraste, áreas táctiles, tendencia, medición y SANS.

El motor de reglas se desarrolla con pruebas primero (TDD).

## Configuración

Banderas de compilación de la app, todas opcionales:

| Bandera | Para qué |
|---|---|
| `--dart-define=TIRELUS_DEV_SERVER=true` | La app no arranca el Python embebido: usa el servidor que ya corre |
| `--dart-define=TIRELUS_PORT=8766` | Puerto de la API local (por defecto 8765) |
| `--dart-define=TIRELUS_REFRESH_SECONDS=2` | Cada cuánto el panel vuelve a pedir datos (por defecto 5 s) |

Variables de entorno del servidor Python:

| Variable | Por defecto | Para qué |
|---|---|---|
| `TIRELUS_HOST` | `127.0.0.1` | Interfaz en la que escucha la API |
| `TIRELUS_DB_HOST` | sin definir | Host de PostgreSQL. Sin ella, la API usa los datos de ejemplo |
| `TIRELUS_DB_PORT` · `TIRELUS_DB_NAME` · `TIRELUS_DB_USER` · `TIRELUS_DB_PASSWORD` | `5432` · `tirelus` · `postgres` · — | Conexión a la base |
| `TIRELUS_DB_TIMEOUT` | `3` | Segundos de espera al conectar |
| `TIRELUS_DB_TTL` | `30` | Segundos entre relecturas de la base (2 para ver cambios en vivo) |
| `TIRELUS_DB_SSL` · `TIRELUS_DB_SSL_CA` | `off` | `require` cifra sin verificar el certificado; `verify` cifra y verifica |
| `TIRELUS_ASTRONAUT_ID` | primer tripulante de la base | Tripulante que muestra la app |

Las credenciales van solo en variables de entorno o en `.env` (ignorado por git). Nunca en el código ni en el repo.

## Base de datos

PostgreSQL, con el esquema en `db/`. El mismo código funciona contra cualquier servidor cambiando solo las variables `TIRELUS_DB_*`.

| Etapa | Dónde corre | Para qué |
|---|---|---|
| Desarrollo y hackathon | Servidor compartido en la red local | Que todo el equipo use los mismos datos |
| Versión final (concepto) | PostgreSQL interno en la nave | Funcionar sin Internet ni retraso de comunicación con la Tierra |

Para la demo la API muestra un tripulante fijo; el servidor compartido solo guarda datos sintéticos.

El detalle está en [`db/README.md`](db/README.md): cómo conectarse al servidor del equipo, qué contiene cada archivo de `db/`, la prueba de estabilidad del 14 nov y la seguridad. La auditoría del esquema está en [`db/AUDITORIA.md`](db/AUDITORIA.md).

## Datos sintéticos

Los datos de la demo salen del generador del equipo, [`SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring`](https://github.com/MerelyMeredith/SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring). Produce un CSV por tripulante con 68 variables, a partir de distribuciones paramétricas y una cascada causal. En el repo del generador:

```bash
python app/main.py generate --patients 4 --days 90
```

> Antes de generar, pon `blood_pressure_interval_days_min/max` en **1** dentro de `config/synthetic_data_config.json`: por defecto la presión llega cada 3–14 días y la regla de desviación sostenida necesita lecturas diarias. El examen retiniano sigue limitado a 1–2 por corrida, así que la serie de SANS queda corta.

En este repo, `tools/sim_sinteticos.py` traduce esos CSV a los indicadores de `db/schema.sql` y los escribe en PostgreSQL. Con las variables `TIRELUS_DB_*` definidas y desde la raíz del repo:

```bash
python tools/sim_sinteticos.py cargar --csv <carpeta output/patients del generador>
```

```bash
python tools/sim_sinteticos.py vivo --csv <carpeta output/patients del generador> --cada 15
```

```bash
python tools/sim_sinteticos.py limpiar
```

- `cargar` crea la tripulación (el primero como CMO), calcula la línea base personal con los primeros 14 días (media ± 2 desviaciones) y escribe el historial. Imprime el `TIRELUS_ASTRONAUT_ID` de cada tripulante.
- `vivo` escribe un día de misión cada N segundos: el panel avanza solo mientras se mira la app.
- Cada lectura lleva un `client_id` determinista (recargar no duplica) y la marca `Datos de ejemplo (sintéticos)`; `limpiar` borra exactamente eso.
- **Supuestos de diseño del mapeo:** el ánimo (1–5) se deriva del estrés percibido invertido, porque el generador no trae autorreporte de ánimo. SANS es el cambio de `RNFL_Thickness_um` frente a la primera lectura.

`tools/sim_tiempo_real.py` trae escenarios escritos a mano que empujan un sistema de nominal a atención a crítico, útil para grabar la demo. Con el TTL por defecto el panel refleja un cambio de la base en unos 30 s; con `TIRELUS_DB_TTL=2` y `TIRELUS_REFRESH_SECONDS=2`, en menos de 1 s. Las mediciones están en [`planning/SIMULACION-TIEMPO-REAL.md`](planning/SIMULACION-TIEMPO-REAL.md).

## Estructura del repositorio

```
app/
  lib/            Interfaz Flutter: pantallas, widgets, tema, cliente de la API, textos ES/EN
  python_app/     API local y lógica: main.py, rules.py, panel.py, catalog.py, db.py, data.py
  tests_py/       Pruebas pytest
  test/           Pruebas de Flutter
db/               Esquema y poblado de PostgreSQL, auditoría y detalle de la base
tools/            Carga y simulación de datos sintéticos
planning/         Plan, auditoría del MVP, historial y planeación a futuro
pendientes.md     Tareas pendientes por área
CLAUDE.md         Reglas del proyecto para el asistente de código
docker/, docker-compose.yml, tirelus.ps1    Sin probar; no se usan en la demo
```

## Estado del proyecto

| # | Punto del MVP | Estado |
|---|---|---|
| 1 | Panel con figura corporal y semáforo por sistema | ✅ Los cinco sistemas calculados por el motor de reglas, con refresco automático |
| 2 | Medición guiada contra la línea base | 🟡 Pantallas listas. Con PostgreSQL cargado hay métricas con línea base personal; sin base, `data.py` solo trae la sistólica |
| 3 | Tendencia con alerta por desviación sostenida | 🟡 Pantallas y regla listas. El eje de días todavía usa un día de misión fijo |
| 4 | Resumen exportable para la conferencia médica | ✅ Se exporta en Markdown (portapapeles) |
| 5 | Selector ISS / Luna / Marte y modo autónomo | ✅ Listo |
| — | Extras: consola de base y EVA | ✅ Pantallas hechas |
| — | Datos compartidos en PostgreSQL | ✅ API leyendo del servidor del equipo y cargador de datos sintéticos probado |
| — | Simulación en tiempo real | ✅ `tools/sim_sinteticos.py` y `tools/sim_tiempo_real.py` |
| — | Entrega (video, presentación, página con fuentes) | 🔴 Sin empezar |

Lo que falta está en [`pendientes.md`](pendientes.md).

## Documentación

| Documento | Contenido |
|---|---|
| [`pendientes.md`](pendientes.md) | Tareas pendientes por área, con prioridad y esfuerzo |
| [`planning/PLAN.md`](planning/PLAN.md) | Plan del hackathon: fases, calendario, roles y riesgos |
| [`planning/AUDITORIA.md`](planning/AUDITORIA.md) | Auditoría del MVP frente al reto: qué mejorar y qué recortar |
| [`planning/HISTORIAL.md`](planning/HISTORIAL.md) | Lo que ya se hizo y lo que se descartó |
| [`planning/FUTURO.md`](planning/FUTURO.md) | Lo que queda para después de la demo: umbrales de respaldo y deuda técnica |
| [`planning/SIMULACION-TIEMPO-REAL.md`](planning/SIMULACION-TIEMPO-REAL.md) | Qué cambia en la interfaz cuando cambia la base, medido |
| [`db/README.md`](db/README.md) · [`db/AUDITORIA.md`](db/AUDITORIA.md) | Detalle y auditoría de la base de datos |

## Diseño

Inspirado en el Horizon Design System de NASA, con marca propia.

- **Tipografía:** Inter (títulos), Public Sans (texto) y DM Mono (cifras y etiquetas).
- **Tema oscuro de cabina:** espacio `#060B18`, superficie `#0E1830`, señal `#4D8DFF`, texto `#E8EEF9`.
- **Estados:** nominal `#3DD68C`, atención `#F7B23B`, crítico `#FF6B5E`.
- **Accesibilidad:** contraste mínimo de 4.5:1 y áreas táctiles de al menos 44 px, verificados por pruebas.

Este proyecto no usa la insignia, el logotipo ni ninguna marca oficial de NASA, y no está afiliado a NASA ni respaldado por ella.

## Fuentes

- **NASA Human Research Program (HRP):** riesgos de salud en vuelos espaciales y SANS.
- **NASA Technical Reports Server (NTRS):** la app cita el documento 20250000330 para el examen periódico de salud. Falta confirmar ese identificador.
- **Umbrales de SANS** (+20 µm y 55 µm o Frisén 1): son la única cifra publicada que usa la app. La referencia exacta sigue pendiente de confirmar (ver [`pendientes.md`](pendientes.md)).
- **Datos de referencia del diseño:** unas 2 h diarias de ejercicio, periodo de sueño de 8.5 h, batería cognitiva de unos 16 min, conferencia médica privada semanal, y retraso de comunicación de 4–12 s a la Luna y hasta 20 min a Marte.
- **Datos sintéticos:** el generador parte de cuatro conjuntos públicos de Kaggle, citados en [su repositorio](https://github.com/MerelyMeredith/SyntheticData_STARDUSTCRUSADERS_OuterSpaceMonitoring).

Los umbrales que no tienen fuente publicada se presentan siempre como supuestos de diseño.

## Equipo

STARDUST CRUSADERS · Instituto Tecnológico de Tijuana.

| Área | Responsable |
|---|---|
| Base de datos | Francisco |
| Datos sintéticos | Prina |
| Backend | Angel |
| Front-end | Jenny |
| Integración y documentación | Yael |
