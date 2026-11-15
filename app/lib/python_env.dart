/// Variables de entorno con las que arranca el Python embebido.
///
/// - `TIRELUS_PORT`: puerto de la API local en 127.0.0.1.
/// - `TIRELUS_DATA_DIR`: carpeta de datos de la app (donde vive `summary.json`).
///   Si no llega, Python usa `~/.tirelus` o una carpeta junto a `main.py`.
/// - `TIRELUS_SIM` / `TIRELUS_SIM_CADA`: simulación embebida. Es lo que le da vida
///   propia al binario (.exe en Windows, .app en macOS): el Python que viaja dentro
///   avanza el día de misión con los datos sintéticos que lleva empaquetados, sin
///   PostgreSQL y sin red. Se enciende al compilar:
///   `--dart-define=TIRELUS_SIM=vivo --dart-define=TIRELUS_SIM_CADA=15`.
Map<String, String> pythonEnvironment({
  required int port,
  String? dataDir,
  String sim = simMode,
  String simCada = simSeconds,
}) =>
    {
      'TIRELUS_PORT': '$port',
      if (dataDir != null && dataDir.isNotEmpty) 'TIRELUS_DATA_DIR': dataDir,
      if (sim.isNotEmpty) 'TIRELUS_SIM': sim,
      if (sim.isNotEmpty && simCada.isNotEmpty) 'TIRELUS_SIM_CADA': simCada,
    };

/// `vivo` enciende la simulación embebida; vacío (por defecto) la deja apagada.
const simMode = String.fromEnvironment('TIRELUS_SIM');

/// Segundos por día de misión en la simulación embebida.
const simSeconds = String.fromEnvironment('TIRELUS_SIM_CADA', defaultValue: '15');
