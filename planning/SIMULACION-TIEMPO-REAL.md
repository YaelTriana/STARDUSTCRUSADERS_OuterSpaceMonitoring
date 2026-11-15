# Simulación: ¿qué cambia en el frontend cuando cambian los datos en PostgreSQL?

Corrida el 14 nov 2026 sobre `main` en `7813df2`. Herramienta: [`tools/sim_tiempo_real.py`](../tools/sim_tiempo_real.py)
(se puede repetir contra el servidor del equipo; ver el final).

## Cómo se montó

El servidor del equipo (192.168.10.2) **no se alcanza** desde la máquina donde se corrió esto, así que se
levantó un PostgreSQL local desechable. La fidelidad es alta:

| Pieza | Qué se usó |
|---|---|
| Base | PostgreSQL **18.7** local, la misma versión del servidor del equipo |
| Esquema | `db/schema.sql` + `db/002_ojos.sql` + `db/003_demo.sql` sin modificar (13 tablas, 1 tripulante, 14 lecturas de sistólica) |
| API | El servidor real `app/python_app/main.py`, sin parches |
| Driver | `pg8000`, el mismo que usa la app |
| Frontend | No se abrió Flutter: se midió lo que la app recibe, endpoint por endpoint |

Los tres scripts de `db/` cargaron sin un solo error.

## Línea de tiempo medida

| t | Evento en la base | Qué cambió en la API | Cuándo |
|---|---|---|---|
| 0 s | — | estado inicial: `data_source: db`, sistólica 14 puntos, FC y SANS en `sin_dato` | — |
| 0.6 s | `INSERT` sistólica D48 = 145 mmHg | serie `…131, 132` → `…132, 145`; días seguidos arriba 5 → 6 | **30.6 s después** |
| 31 s | `INSERT` sistólica D49 = 9999 mmHg | el 9999 **no** entró a la serie; pero la serie pasó de 14 a 13 puntos | 30 s después |
| 63 s | `INSERT` línea base de FC (55–66) + 14 lecturas (hasta 78 lpm) | `heart_rate`: `sin_dato` → **atencion**; `/metrics` marca `heart_rate: true` | **30.5 s después** |
| 94 s | `INSERT` OCT `retinal_delta` +8 µm (D30) y +22 µm (D90) | SANS: `sin_dato` → **atencion**, serie `[8, 22]` | **30.5 s después** |
| 124 s | se apaga PostgreSQL | `data_source: db` → `ejemplo` y **todo lo de la base desaparece** | inmediato (0.0 s) |

## Lo que la simulación confirma

### 1. El camino de lectura funciona de verdad
Medición, tendencia, el catálogo de métricas y SANS **sí** siguen a la base. Cargar datos en PostgreSQL es
suficiente para que esas tres pantallas dejen de decir "Sin dato", tal como dice la matriz del README. No
hace falta tocar nada de eso.

### 2. "Tiempo real" hoy significa 30 segundos
Las tres mediciones dieron 30.5–30.6 s, que es el TTL del catálogo (`catalog.build_catalog(ttl=30.0)`).
Además es **perezoso**: el reloj no corre solo, el refresco ocurre en la primera petición después de que
expira la caché. Si nadie pide nada, nada se actualiza. Bajar el TTL acerca el refresco, pero pega cada
petición contra la base; lo correcto es refrescar en segundo plano y servir siempre lo último conocido.

### 3. El panel **nunca** cambió — ni una vez
Los cinco estados del semáforo, el texto de cardio ("132/84 · ▲ base 118/76") y el día de misión (47) salieron
idénticos al principio y al final, con la base cambiando debajo todo el tiempo. Es la confirmación
experimental del hallazgo A1 de la auditoría: `/dashboard` sirve `data.SYSTEMS` (texto fijo) sin pasar por el
catálogo. **Cargar datos en la base no mueve el panel: hay que reescribir el endpoint.**

### 4. El eje de días de la tendencia es ficción cuando los datos vienen de la base
`/trend/{metric}` calcula `first_day = MISSION_DAY - len(series) + 1`, con `MISSION_DAY = 47` fijo en
`data.py`; el `mission_day` que `db.py` lee de la base solo se usa para SANS. Se vio en vivo: al descartarse
el 9999, la serie pasó de 14 a 13 puntos y el eje se corrió de D34 a D35, etiquetando el último punto como
**D47 cuando la lectura real es D48**. En la demo, el día que marque el gráfico no va a coincidir con la base.
De paso: `lib/main.dart:194` imprime `DÍA DE MISIÓN 047` como texto literal, y `Dashboard.missionDay` se
parsea y nunca se usa.

### 5. El filtro de rangos funciona, pero se come un lugar de la ventana
Lo nuevo del PR #13 hace lo que promete contra una base real: el 9999 no llegó a la app. El detalle es que
la ventana de 14 lecturas se aplica en SQL **antes** del filtro, así que cada fila inválida acorta la serie
en silencio (14 → 13). Con varias lecturas malas, la tendencia se queda corta sin avisar. Arreglo: pedir
más filas de las necesarias, o filtrar en el SQL (`indicators` ya tiene `valid_min`/`valid_max`).

### 6. La degradación es elegante, pero **pierde los datos y se nota**
Con la base caída, la API volvió a `ejemplo` al instante y la app retrocedió: FC y SANS regresaron a
"Sin dato" y la sistólica volvió a la serie de ejemplo (el 145 desapareció). Si durante la demo el switch
tose dos segundos, el jurado ve los datos esfumarse y volver. Propuesta: conservar el último snapshot bueno
y marcarlo ("última lectura conocida, hace N min") en vez de regresar a `data.py` cuando ya había datos.

### 7. Precisión sobre la caída (corrige lo que yo mismo escribí en la auditoría)
Un servidor **apagado** falla al instante (conexión rechazada, 0.0 s). Los 2–3 s de espera que reporta el
README aplican al caso distinto de un servidor **inalcanzable** (la red se traga los paquetes y hay que
esperar el `timeout`). Los dos casos importan: con refresco automático, el segundo congela la pantalla cada
30 s.

### 8. La escritura idempotente quedó probada sin buscarlo
Una segunda corrida volvió a insertar los mismos `client_id` y nada cambió: cero filas duplicadas. El
camino de escritura que falta en la app (hallazgo A2) puede apoyarse en eso con confianza.

## Segunda corrida: el módulo cardio del panel ya calculado

Después de reescribir el sistema **cardio** de `/dashboard` para que salga del catálogo y del motor de
reglas (`app/python_app/panel.py`), se repitió la simulación con `tools/sim_tiempo_real.py panel`:

Con `tools/sim_tiempo_real.py vivo` (TTL del catálogo en 2 s y una lectura del panel por segundo), cada
INSERT apareció **en el tick siguiente, en menos de 1 s**:

| segundo | Panel que sirvió la API |
|---|---|
| t+00 | `cardio ATENCIÓN · 132 mmHg ▲ 6 sobre tu base (110–126) · 5 días seguidos` (datos de `003_demo.sql`) |
| t+04 | ⇢ 14 lecturas dentro de la base → `cardio NOMINAL · 121 mmHg · en tu base (110–126)` |
| t+14 | ⇢ 3 lecturas seguidas sobre la base → `cardio ATENCIÓN · 134 mmHg ▲ 8 sobre tu base · 3 días seguidos` |
| t+24 | ⇢ una lectura de 165 mmHg → `cardio CRÍTICO · 165 mmHg ▲ 39 sobre tu base · 4 días seguidos` |
| t+34 | ⇢ línea base de FC + 14 lecturas → el azulejo de FC deja de decir "Sin dato": `78 lpm ▲ 12 sobre tu base (55–66) · 4 días seguidos` |

El estado del sistema, el valor de cada azulejo, la variación frente a la línea base y el conteo de días
salen todos de PostgreSQL pasando por `rules.py`. Lo que quedó fijo en `data.py` es solo el texto educativo
("por qué cambia en el espacio", "qué hacer ahora"), que es contenido y no lógica. Los otros cuatro sistemas
siguen siendo mockup y cada bloque lo dice en el campo `computed`.

**El TTL manda.** `TIRELUS_DB_TTL` (segundos) decide cada cuánto se relee la base: 2 s para que se vea
cambiar en la demo, 30 s por defecto, más a bordo para no generar tráfico. Con el modo `panel` del script
(TTL por defecto) los mismos cuatro pasos tardaron 30.5 s cada uno.

El estado del sistema, el valor de cada azulejo, la variación frente a la línea base y el conteo de días
salen todos de PostgreSQL pasando por `rules.py`. Lo que quedó fijo en `data.py` es solo el texto educativo
("por qué cambia en el espacio", "qué hacer ahora"), que es contenido y no lógica.

Los otros cuatro sistemas (ojos, hueso, mente, inmune) siguen siendo mockup y cada bloque lo dice en el
campo `computed`, para no confundir lo medido con lo escrito a mano.

Un detalle que destapó la simulación: un azulejo mostraba "132 mmHg · ▲ 6 sobre tu base" con estado
**nominal** — correcto según la regla (un día aislado no es desviación sostenida) pero contradictorio
a la vista, y además Medición sí llama "atención" a ese mismo 132 porque responde otra pregunta ("¿esta
lectura está fuera de tu rango?" vs. "¿hay desviación sostenida?"). Se resolvió en el texto, no en la regla:
la nota ahora dice en qué parte del conteo va ("1 de 3 días").

## Qué falta para la escena que se pidió

El camino de datos ya está. Para que "los dashboards cambien según lo que llega a la base" faltan tres cosas,
en este orden:

1. ~~**`/dashboard` por el catálogo y el motor de reglas**~~ — hecho para **cardio** (módulo 1 de 5);
   faltan ojos, hueso, mente e inmune, que son el mismo patrón (~20 min cada uno en cuanto sus métricas
   tengan datos).
2. **Refresco en Flutter** (45 min). Hoy cada pantalla pide sus datos una vez y nunca vuelve a preguntar.
3. **Refresco del catálogo en segundo plano y TTL decidido** (30 min). Para que el refresco no quede atado a
   los 30 s perezosos ni se congele cuando la base no responde.

Opcional pero barato de sumar mientras se toca eso: el día de misión real (puntos 4) y conservar el último
snapshot bueno (punto 6).

## Cómo repetirla

```bash
# en vivo: TTL de 2 s, una línea por segundo (lo más parecido a ver la app moverse)
app/.venv/bin/python tools/sim_tiempo_real.py vivo

# contra el servidor del equipo (escribe filas sintéticas marcadas y borrables)
export TIRELUS_DB_HOST=192.168.10.2 TIRELUS_DB_USER=tirelus_equipo \
       TIRELUS_DB_PASSWORD=... TIRELUS_SIM_CONFIRMAR=1
app/.venv/bin/python tools/sim_tiempo_real.py
app/.venv/bin/python tools/sim_tiempo_real.py limpiar   # borra solo lo que insertó
```

Todo lo que escribe queda marcado con `note = 'Datos de ejemplo (simulación)'` y `limpiar` borra exactamente
eso (y la línea base de FC que crea). Contra un host que no sea local, la herramienta exige
`TIRELUS_SIM_CONFIRMAR=1` para no ensuciar el servidor compartido por accidente. La receta para levantar un
PostgreSQL local desechable está en el encabezado del script.
