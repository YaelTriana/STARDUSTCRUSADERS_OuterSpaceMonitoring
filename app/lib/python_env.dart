/// Variables de entorno con las que arranca el Python embebido.
///
/// - `TIRELUS_PORT`: puerto de la API local en 127.0.0.1.
/// - `TIRELUS_DATA_DIR`: carpeta de datos de la app (donde vive `summary.json`).
///   Si no llega, Python usa `~/.tirelus` o una carpeta junto a `main.py`.
Map<String, String> pythonEnvironment({required int port, String? dataDir}) => {
      'TIRELUS_PORT': '$port',
      if (dataDir != null && dataDir.isNotEmpty) 'TIRELUS_DATA_DIR': dataDir,
    };
