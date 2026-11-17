# Empaquetado: binario para Windows y macOS con la simulación dentro

Estado al 15 nov: la **simulación embebida ya está hecha y probada** (`app/python_app/sim.py`).
Falta compilar los binarios, y eso necesita las dos máquinas.

> El empaquetado se había descartado el 14 nov para la demo del hackathon. Se retoma para la
> versión repartible: ver [`FUTURO.md`](FUTURO.md).

## 1. La simulación embebida (hecha)

El binario no puede depender de PostgreSQL ni de la red: nadie que abra el `.exe` va a tener el
servidor del equipo. Así que los datos sintéticos del equipo **viajan dentro de la app** y un
simulador avanza el día de misión con el reloj.

| Pieza | Qué es |
|---|---|
| `app/python_app/datos/tripulacion.csv` | 4 tripulantes × 100 días del generador del equipo, solo las 17 columnas que la app usa (31 KB) |
| `app/python_app/sim.py` | lee ese CSV, calcula la línea base prevuelo y sirve la ventana de 14 días del día actual. Solo biblioteca estándar: nada de pandas ni drivers |
| `catalog.build_catalog` | elige el origen: **1)** `TIRELUS_SIM=vivo` (simulador), **2)** `TIRELUS_DB_HOST` (PostgreSQL), **3)** datos de ejemplo de `data.py` |

`GET /health` dice de dónde salen los datos: `simulacion`, `db` o `ejemplo`.

Para correrlo en desarrollo:

```bash
cd app
TIRELUS_SIM=vivo TIRELUS_SIM_CADA=4 python python_app/main.py   # un día de misión cada 4 s
curl 127.0.0.1:8765/health      # data_source: simulacion
```

Variables: `TIRELUS_SIM` (`vivo` lo enciende), `TIRELUS_SIM_CADA` (segundos por día, 15),
`TIRELUS_SIM_BASE` (días de la ventana prevuelo, 14).

Dentro del binario la enciende Flutter al compilar, y la app se la pasa al Python embebido:

```
--dart-define=TIRELUS_SIM=vivo --dart-define=TIRELUS_SIM_CADA=15
```

El TTL del catálogo baja solo a 1 s cuando el origen es el simulador (leerlo no cuesta red), así
que el panel se mueve sin tocar nada más.

## 2. Windows (`.exe`)

Se compila **en Windows**: Flutter de escritorio no cruza plataformas. Requiere Visual Studio con
el componente "Desarrollo para el escritorio con C++" (el bloqueo del 14 nov; revisar con
`flutter doctor`).

```powershell
cd app
$env:SERIOUS_PYTHON_VERSION = "3.12"
dart run serious_python:main package python_app -p Windows -r -r -r python_app/requirements.txt --cleanup
flutter build windows --dart-define=TIRELUS_SIM=vivo --dart-define=TIRELUS_SIM_CADA=15
# resultado: build\windows\x64\runner\Release\
```

El resultado es una **carpeta** (`tirelus.exe` + DLLs + `data\`), no un archivo suelto: para
repartir uno solo, comprimirla en ZIP o armar instalador (Inno Setup o MSIX).

## 3. macOS (`.app`)

Se compila **en una Mac**, y la carpeta de la plataforma todavía no existe en el repo:

```bash
cd app
flutter create --platforms=macos .
dart run serious_python:main package python_app -p Darwin -r -r -r python_app/requirements.txt --cleanup
flutter build macos --dart-define=TIRELUS_SIM=vivo --dart-define=TIRELUS_SIM_CADA=15
# resultado: build/macos/Build/Products/Release/tirelus.app
```

Dos tropiezos propios de macOS:

1. **Entitlements.** El sandbox bloquea el servidor local si no se agregan
   `com.apple.security.network.server` y `com.apple.security.network.client` en
   `macos/Runner/Release.entitlements` (y en `DebugProfile.entitlements`). Sin eso, el Python
   embebido arranca pero la app nunca alcanza `/health`.
2. **Firma y notarización.** Sin firmar, Gatekeeper bloquea el `.app` en otras Macs (se abre con
   clic derecho → Abrir). Para repartirlo de verdad hay que firmarlo y notarizarlo con una cuenta
   de desarrollador.

## 4. Qué verificar en cualquiera de los dos

- [ ] La app arranca y el panel aparece (no se queda en "Iniciando el motor en Python…").
- [ ] `GET /health` dentro de la app dice `data_source: simulacion`.
- [ ] El panel cambia solo cada `TIRELUS_SIM_CADA` segundos, **con el wifi apagado**.
- [ ] Las tipografías se ven bien sin red (ya van empaquetadas en `app/assets/google_fonts/`).
- [ ] El resumen médico se guarda y sobrevive al reinicio (va en la carpeta de datos de la app,
      no en la carpeta del programa, que es de solo lectura).

## 5. Lo que no entra en el binario

`tools/sim_tiempo_real.py` y `tools/sim_sinteticos.py` se quedan fuera: son herramientas de
escritorio que escriben en PostgreSQL. El binario trae `sim.py`, que no necesita servidor.
Si se quiere el binario leyendo la base compartida, basta arrancarlo con `TIRELUS_DB_HOST`
definido (y sin `TIRELUS_SIM`), porque `pg8000` es Python puro y sí se empaqueta.

## 6. Android: sin PostgreSQL

El acceso a PostgreSQL desde Android sigue sin diseñarse (CLAUDE.md, "por definir"). `db.py`
importa `pg8000` solo dentro de `connect()`, nunca al arrancar, así que no hace falta tocar esa
lógica. Lo que sí hace falta es no empaquetar `pg8000` ni sus 4 dependencias (`scramp`,
`asn1crypto`, `python-dateutil`, `tzdata`) en el `.apk`: son peso muerto porque `TIRELUS_DB_HOST`
no se define en el celular, así que `connect()` nunca se llama. Para Android se usa
`python_app/requirements-android.txt` (los mismos 7 paquetes del servidor, sin la fila de la
base) en vez de `python_app/requirements.txt`:

```powershell
cd app
$env:SERIOUS_PYTHON_VERSION = "3.12"
dart run serious_python:main package python_app -p Android -r -r -r python_app/requirements-android.txt --cleanup
flutter build apk --dart-define=TIRELUS_SIM=vivo --dart-define=TIRELUS_SIM_CADA=15
```
