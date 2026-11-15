# Proyecto: TIRELUS · NASA Space Apps Challenge 2026

## Contexto
- Equipo del Instituto Tecnológico de Tijuana en el hackathon NASA Space Apps (14–15 nov 2026).
- Reto: software de automonitoreo de salud para astronautas que recoge indicadores y ayuda a evaluarlos y actuar.
- Nombre de la app: **TIRELUS** (antes VITALIS; si encuentras el nombre viejo, cámbialo).
- Idioma de trabajo: español (México). Términos técnicos en inglés solo cuando sean estándar (flight surgeon, EVA, SANS, CMO).

## Arquitectura
- **UI:** Flutter (Dart) en `app/`.
- **Lógica:** Python en `app/python_app/`, embebido en la app con **serious_python** (v6.x, Flet). La lógica se escribe una sola vez en Python: **no la portes a Dart**.
- **Comunicación:** el Python embebido sirve una API HTTP local en `127.0.0.1` (puerto vía variable `TIRELUS_PORT`); Flutter la consume. Dart no llama funciones de Python directamente.
- **Servidor:** FastAPI + `uvicorn` sin extras. Si falla en Android, cambiar a Flask o `http.server`.
- **Dependencias Python en el dispositivo:** puro Python o binarios publicados en https://pypi.flet.dev (numpy, pandas, scipy, scikit-learn, pydantic-core). statsmodels no está disponible. El motor de reglas va en Python estándar.
- **Plataformas de demo:** Windows y Android. Web (Pyodide) no puede abrir el servidor local.
- **Base de datos:** se decide después. No la propongas ni la diseñes salvo que se pida.
- Detalles de empaquetado y reglas: skill `.claude/skills/tirelus-serious-python/`.
- Skills del proyecto en `.claude/skills/` (origen y licencias en `.claude/SKILLS-SOURCES.md`). No agregues skills que se traslapen con las existentes.

## Alcance mínimo (MVP)
1. Panel principal con figura corporal interactiva y semáforo por sistema (corazón, ojos/SANS, hueso y músculo, sueño y ánimo, inmune).
2. Medición guiada: captura el dato, lo compara contra la línea base personal y explica qué mide y por qué cambia en el espacio.
3. Tendencia con alerta por desviación sostenida.
4. Resumen exportable para la conferencia médica privada.
5. Selector de entorno (ISS / Luna / Marte) que cambia el retraso de comunicación y activa un modo autónomo con mensajes diferidos.
- Extras solo si sobra tiempo: consola de base (vista compartida sin datos clínicos), visor de casco (concepto a futuro) y variante de mano.

## Reglas de dominio (no negociables)
- La app NO diagnostica: señala desviaciones y sugiere qué hacer o a quién escalar (astronauta → CMO → flight surgeon).
- NASA no publica umbrales de alerta en vuelo para presión, frecuencia cardiaca ni laboratorio. Todo umbral es un supuesto de diseño y debe etiquetarse así. Combina línea base personal prevuelo + tendencia sostenida + rangos clínicos terrestres de respaldo.
- Única excepción con cifra publicada, SANS: +20 µm de grosor retiniano = primer signo; 55 µm o Frisén 1 = preocupación clínica.
- Otros datos de referencia: ~2 h diarias de ejercicio, periodo de sueño de 8.5 h, batería cognitiva de ~16 min, conferencia médica privada semanal, retraso de comunicación de 4–12 s a la Luna y hasta 20 min a Marte.
- Privacidad: los datos médicos de cada tripulante solo los ven él mismo, el CMO y el flight surgeon. Nunca en pantallas compartidas.
- Los datos de demo son sintéticos y deben decir "Datos de ejemplo".

## Diseño
- Inspirado en el Horizon Design System de NASA: Inter (títulos), Public Sans (texto), DM Mono (cifras y etiquetas).
- Tema oscuro de cabina. Colores: espacio #060B18, superficie #0B1326, superficie 2 #162647, borde #1C2B4B, señal #4D8DFF, texto #E8EEF9, nominal #16E093, atención #F7B23B, crítico #FF6B5E.
- Cada estado combina color + forma + palabra. Contraste mínimo 4.5:1 y áreas táctiles de al menos 44 px.
- Prohibido usar la insignia ("meatball"), el logotipo ("worm") o cualquier marca oficial de NASA. Solo marca propia y citas a las fuentes.

## Cómo trabajar
- Prioriza lo que se puede entregar en 48 horas. Si algo pone en riesgo el MVP, dilo y propone qué recortar.
- Código: archivos completos y ejecutables, con pruebas pytest en el motor de reglas (TDD).
- Cuando des datos de salud o espaciales, cita la fuente (NASA HRP, NTRS, CSA, ESA). Si no hay fuente, dilo.
- Respuestas directas y en español. Listas o tablas solo cuando ayuden a comparar.

## Flutter: hot reload proactivo
(Regla oficial `flutter-hot-reload.md` de flutter/agent-plugins; requiere el servidor MCP de Dart: `claude mcp add --transport stdio dart -- dart mcp-server`, Dart 3.9+.)

Al editar cualquier archivo `.dart` bajo `lib/`:
1. No lo hagas para archivos fuera de `lib/` (test/, integration_test/, example/…) ni si el cambio solo toca comentarios, docstrings o espacios.
2. Descubre las apps en ejecución con el MCP de Dart (`dtd`, `list_running_apps` o `vm_service`).
3. Ejecuta `hot_reload` tras cambios en widgets (incluidos los `build`) o métodos simples; usa `hot_restart` si cambió lógica fundamental, `initState`, estado global/estático o `main()`.
