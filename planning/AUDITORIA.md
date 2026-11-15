# Auditoría del MVP frente al reto de NASA

Revisada sobre `main` en `7813df2` (PR #13: validación de rangos y TLS). Reemplaza la primera versión,
escrita sobre `266879b`, que todavía trataba el empaquetado como P0.

Esta es la **diagnosis**; las tareas viven en la [matriz de pendientes del README](../README.md#matriz-de-pendientes),
que es la fuente única. La auditoría del esquema está en [`db/AUDITORIA.md`](../db/AUDITORIA.md).

## Verificado en esta máquina

| Comprobación | Resultado |
|---|---|
| `pytest app/tests_py` | 127 pasan (0.4 s) |
| `cd app; flutter test` | 68 pasan |
| `cd app; flutter analyze` | sin problemas |
| Simulación contra PostgreSQL 18.7 con el esquema real de `db/` | corrida; resultados en [`SIMULACION-TIEMPO-REAL.md`](SIMULACION-TIEMPO-REAL.md) |

Las cifras del README son exactas. El empaquetado y Docker ya no se auditan: están descartados
(decisión del 14 nov, `CLAUDE.md`), así que la demo corre en modo desarrollo y los riesgos de
compilación salen de la lista.

El reto pide software que **(1) recoja** indicadores, **(2) ayude a evaluarlos** y **(3) ayude a actuar**.
La app cubre bien (2) y (3) para presión sistólica. Los dos huecos grandes siguen en (1).

---

## A. Lo que el README da por listo y no lo está

> **Al 14 nov por la noche:** el sistema **cardio** del panel ya está calculado desde el catálogo y el motor
> de reglas (`app/python_app/panel.py`, pruebas en `tests_py/test_panel.py` y `test/dashboard_screen_test.dart`),
> verificado contra PostgreSQL en [`SIMULACION-TIEMPO-REAL.md`](SIMULACION-TIEMPO-REAL.md#segunda-corrida-el-módulo-cardio-del-panel-ya-calculado).
> Lo de abajo sigue vigente para los otros cuatro sistemas: ojos, hueso, mente e inmune.

### A1. El panel principal no lee nada de la base — bloquea lo que se pidió del "tiempo real"
La matriz dice que, cargando los datos que faltan, "las pantallas dejan de decir Sin dato". Es cierto para
Medición, Tendencia y Ojos, que pasan por `catalog.snapshot()`. **No para el panel.** `/dashboard`
(`main.py:100-109`) devuelve `data.SYSTEMS`, texto fijo escrito a mano (`data.py:110-178`), sin tocar el
catálogo ni la base. Después de cargar FC, sueño, ánimo y SANS en PostgreSQL, el panel va a seguir diciendo
exactamente lo mismo que hoy:

| Panel (texto fijo) | Lo que dirá el motor con los datos cargados |
|---|---|
| cardio: "base 118/76" (`data.py:116`) | `SYSTOLIC_BASE = Baseline(110, 126)` (`data.py:11`) |
| "FC 64 lpm · base 60", nominal (`data.py:117`) | lo que diga la línea base de `heart_rate` en la base |
| ojos: "+8 µm", nominal (`data.py:130`) | lo que diga la serie de `retinal_delta` |

**Comprobado en vivo:** en la simulación del 14 nov se insertaron lecturas en PostgreSQL durante dos
minutos y medio (sistólica D48 = 145 mmHg, línea base y 14 lecturas de FC, dos OCT de SANS). Medición,
tendencia y SANS siguieron a la base en ~30 s cada una; el panel salió **idéntico** al principio y al final:
mismos cinco estados, mismo "132/84 · ▲ base 118/76", mismo día 47.

El estado del MVP marca el punto 1 como ✅ Listo. Está listo como **pantalla**; no como pantalla
conectada. Mientras `/dashboard` no pase por el catálogo, ningún dato de PostgreSQL puede llegar al
semáforo, y la frase "recoge → evalúa → actúa" se rompe justo en la pantalla que el jurado ve primero.

**Lo que falta (1–1.5 h):** que `/dashboard` calcule el `status` de cada sistema con `evaluate_trend` sobre
`catalog.snapshot().metrics` (cardio ← systolic + heart_rate, mente ← sleep_hours + mood, ojos ← SANS) y que
los indicadores tomen la línea base del catálogo en lugar de llevarla en el texto. Los textos de "por qué
cambia" y "qué hacer" se quedan: son el valor educativo de la app.

### A2. Nada de lo que captura el astronauta se guarda
No existe endpoint de escritura de lecturas: `main.py` solo tiene `POST /evaluate/*` (que evalúa y no
guarda) y `POST /summary` (que guarda una línea de texto). La serie de 14 días es fija, así que la alerta
por desviación sostenida no puede nacer durante la demo.

Lo irónico es que el lado difícil ya está probado: la prueba de estabilidad del README reporta 1000 INSERT
en 1.6 s y que el mismo `client_id` dos veces deja una sola fila — o sea, la escritura idempotente que
`db/schema.sql:237` fue diseñada para soportar ya funciona contra el servidor del equipo. Lo que falta es
el `POST /measurement/{metric}` que la use. 1–2 h.

### A3. Flutter nunca vuelve a preguntar
Cada pantalla pide sus datos una sola vez (`_future ??=` en `didChangeDependencies`) y no hay forma de
refrescar, ni automática ni manual. Hoy no se nota porque los datos son fijos; en el momento en que la base
manda, se nota en la demo: alguien inserta filas y la pantalla sigue igual hasta reiniciar la app.

Dos cosas que conviene saber antes de elegir cómo refrescar:
- `catalog.py` cachea 30 s (`ttl=30.0`). Ese es el techo real de qué tan "en vivo" se ve, y es un parámetro.
- El refresco ocurre **dentro** de la petición HTTP. Medido: un servidor apagado falla al instante
  (conexión rechazada, 0.0 s), pero uno inalcanzable —la red se traga los paquetes— espera el timeout de
  2–3 s. Con refresco automático, ese segundo caso es una pantalla congelada cada 30 s, no un parpadeo.
  Vale la pena refrescar el catálogo en segundo plano y servir siempre lo último conocido.

### A4. Una línea base sigue duplicada en Dart
`app/lib/screens/measurement_screen.dart:49-50` tiene `_baseLow = 110.0` y `_baseHigh = 126.0` escritas a
mano para dibujar la barra de rango. Rompe la regla de arquitectura ("la lógica se escribe una sola vez en
Python") y va a mentir en cuanto la base real llegue de PostgreSQL. `/evaluate/{metric}` ya devuelve `base`:
usar esa. 15 min.

### A5. `sample_data: true` está fijo en las cuatro respuestas
`main.py:108,143,182,289`. Hoy es verdad siempre, pero el día que entren datos reales la etiqueta "Datos de
ejemplo" va a mentir, que es lo contrario de la regla del proyecto. Debería venir de
`catalog.snapshot().source`. Ya es el punto 5 de `db/AUDITORIA.md`. 10 min.

### A6. El eje de días de la tendencia es ficción cuando los datos vienen de la base
`/trend/{metric}` calcula `first_day = MISSION_DAY - len(series) + 1`, con `MISSION_DAY = 47` fijo en
`data.py`; el `mission_day` que `db.py` sí lee de la base solo se usa para SANS. En la simulación, al
descartarse una lectura inválida la serie pasó de 14 a 13 puntos y el eje se corrió un día: el último punto
quedó etiquetado **D47 cuando la lectura real era D48**. Además `lib/main.dart:194` imprime
`DÍA DE MISIÓN 047` como texto literal y `Dashboard.missionDay` se parsea y nunca se usa. 30 min.

### A7. Cuando la base se cae, la app retrocede en vez de esperar
Medido: al apagar PostgreSQL, la API volvió a `ejemplo` y FC y SANS regresaron a "Sin dato" mientras la
sistólica volvía a la serie de ejemplo. Si el switch tose dos segundos durante la demo, el jurado ve los
datos desaparecer y volver. Conservar el último snapshot bueno y etiquetarlo ("última lectura conocida,
hace N min") en lugar de regresar a `data.py` cuando ya había datos de la base. 30 min.

### A8. El filtro de rangos se come un lugar de la ventana de 14 días
La ventana se aplica en SQL **antes** del filtro de `valid_range`, así que cada fila inválida acorta la serie
en silencio (se vio: 14 → 13). Con varias lecturas malas la tendencia se queda corta sin avisar. Pedir más
filas de las necesarias, o filtrar en el SQL (`indicators` ya tiene `valid_min`/`valid_max`). 15 min.

---

## B. Un acoplamiento que afecta la decisión de usuarios (P1 del README)

Hoy la app sirve a **un solo tripulante por proceso**: `TIRELUS_ASTRONAUT_ID` se lee una vez en
`config_from_env` y queda dentro del `cfg` con el que `build_catalog()` arma el loader, y el `Catalog`
guarda un único `Snapshot` en memoria. Si la decisión es "selección de perfil con rol" (lo que el README
recomienda, y estoy de acuerdo para la demo), el id del tripulante tiene que viajar en la petición y la
caché tiene que quedar indexada por tripulante; si no, cambiar de perfil muestra los datos del anterior
hasta que expiren los 30 s.

No es trabajo grande, pero es mejor decidirlo **antes** de reescribir `/dashboard` (A1): las dos cosas
tocan la misma función. Si se hacen juntas, son 30 min más; separadas, se rehace.

---

## C. Privacidad: el lado lejano está endurecido y el cercano abierto

El README ya tiene sección de Seguridad y cubre bien el tramo hacia PostgreSQL (TLS opcional ya escrito,
rotar la contraseña, solo datos sintéticos). Falta el tramo de al lado:

- **`main.py:42-47` monta CORS con `allow_origins=["*"]`.** Mientras el servidor esté arriba, cualquier
  página abierta en el navegador de ese equipo puede leer `http://127.0.0.1:8765/summary`, `/trend/*` y
  `/dashboard` desde JavaScript. Son justo los datos que `CLAUDE.md` declara visibles solo para el
  tripulante, el CMO y el flight surgeon. La app de escritorio no necesita CORS: solo lo necesita Flutter
  Web en desarrollo. **Arreglo: montar el middleware solo si existe `TIRELUS_DEV_CORS`, con el origen
  exacto. 10 min.** Y es buen material de pitch: "el servidor de salud no habla con nadie más que con la app".
- **La API local no pide autenticación.** Para la demo está bien; conviene nombrarlo como limitación con
  plan (token local entre Flutter y Python + roles/RLS en la base, punto 7 de `db/AUDITORIA.md`), porque
  suena mejor dicho por el equipo que preguntado por el jurado.

---

## D. Riesgos de la demo que siguen abiertos

1. **Las tipografías se bajan de Internet.** `lib/theme.dart:2` usa `google_fonts` y el pubspec no declara
   `assets:`: Inter, Public Sans y DM Mono se descargan en el primer arranque. Si el wifi de la sede falla,
   la app pierde su tipografía; y una app para una nave sin Internet dependiendo de fonts.gstatic.com es una
   contradicción que un juez puede señalar. Bajar los `.ttf` a `app/assets/fonts/`, declararlos y poner
   `GoogleFonts.config.allowRuntimeFetching = false`. 30–45 min.
2. **Nombres por defecto de Flutter en todo lo que se ve.** `windows/runner/main.cpp:30` → la barra de
   título dice `tirelus`; `pubspec.yaml:2`, `web/index.html:21` y `web/manifest.json:8` → descripción
   **"A new Flutter project."**. 10 min, y sale en cada captura del video.
3. **Puerto 8765 fijo y arranque que puede colgarse.** `lib/api.dart:11` fija el puerto; si algo lo ocupa,
   la pantalla de arranque espera 30 s y falla. Peor: en `waitUntilReady` (`api.dart:69-82`), si algo
   responde 200 sin `ok: true`, el ciclo gira sin pausa y sin revisar el plazo — la app se queda congelada
   en el splash. Mover el `delay` y la revisión del plazo fuera del `catch`: 15 min.
4. **Modo desarrollo = dos terminales.** Ahora que el empaquetado está descartado, la demo depende de
   arrancar Python y Flutter en orden. Conviene un guion escrito de arranque (y quién lo ejecuta) para no
   improvisarlo frente al jurado.

---

## E. Entrega: sigue siendo lo que más pesa

Video, presentación y página del proyecto siguen sin empezar (3–4 h en la matriz). NASA evalúa con cinco
criterios — impacto, creatividad, validez, relevancia y presentación; confírmenlos en la guía de su sede —
y dos de los cinco se juegan completos ahí, no en el código. Tres detalles:

- **La única cifra publicada del proyecto sigue sin fuente.** `data.py:97`: "Referencia NASA por confirmar".
  Los +20/55 µm son lo único que no se presenta como supuesto de diseño, así que es exactamente lo que un
  jurado que evalúa validez va a ir a verificar. Cerrarla con número de documento (NASA HRP / NTRS): 15 min.
  En el mismo paso, confirmar que `NTRS 20250000330` exista con ese identificador.
- **Idioma.** Todo está en español. El jurado global es internacional: vale la pena subtítulos o narración
  en inglés en el video, y revisar en la guía de la sede en qué idioma debe ir la página del proyecto.
- **Falta `LICENSE` en la raíz** (solo hay licencias dentro de `.claude/skills/`). Son 2 minutos y los
  proyectos de Space Apps se comparten como abiertos.

---

## F. Filas que le faltan a la matriz del README

Para que la matriz siga siendo la fuente única, estas son las que conviene agregar (las de 10–15 min se
pueden agrupar en una sola fila de "pulido"):

| Prioridad | Qué | Esfuerzo |
|---|---|---|
| ~~P1~~ ✅ | `/dashboard` calculado: módulo **cardio** hecho (A1) | — |
| **P1** | Los otros 4 sistemas del panel con el mismo patrón (A1) | ~20 min cada uno |
| **P1** | Refrescar en la app y refresco del catálogo en segundo plano (A3) | 45 min |
| **P1** | Guardar mediciones: `POST /measurement/{metric}` + INSERT (A2) | 1–2 h |
| **P1** | Cerrar CORS por defecto (C) | 10 min |
| **P1** | Día de misión real en tendencia y barra superior (A6) | 30 min |
| **P2** | Conservar el último snapshot bueno cuando la base se cae (A7) | 30 min |
| **P2** | Ventana de 14 días que no se acorte al filtrar rangos (A8) | 15 min |
| **P1** | Fuente exacta de SANS, hoy "por confirmar" (E) | 15 min |
| **P2** | Tipografías empaquetadas, sin red (D1) | 30–45 min |
| **P2** | Nombres de ventana/app/web; `LICENSE`; base duplicada en Dart; `sample_data` del origen; `waitUntilReady` (D2, D3, A4, A5, E) | 1 h en total |

**Orden sugerido con el reloj en contra:** los datos que faltan (ya en la matriz, 45 min) → decidir perfil
de usuario y reescribir `/dashboard` juntos (B + A1) → refresco (A3) → CORS y el paquete de pulido →
mediciones (A2) solo si lo anterior ya quedó. La entrega (E) **en paralelo desde ahora**, no al final.

**Qué recortar si el reloj gana:** A2 antes que A1 — el panel conectado importa más que la escritura;
Android y el PostgreSQL de la nave se quedan como concepto en la presentación; visor, de mano y consola de
base se presentan como pantallas de demostración; el resumen en PDF y `share_plus` no se tocan, el
portapapeles alcanza.

**Lo que ya está bien y conviene presumir:** el motor de reglas separado y probado (127 pruebas), la
honestidad sobre los umbrales (supuesto de diseño vs. cifra publicada), la validación de rangos de captura
que distingue un error de dedo de un estado de salud, la degradación elegante cuando la base no responde
(`catalog.py`, `/health` con `data_source`), la prueba de inyección y concurrencia contra el servidor real,
el modo autónomo con mensajes diferidos, y la accesibilidad verificada en cada corrida
(`test/contrast_test.dart`).
