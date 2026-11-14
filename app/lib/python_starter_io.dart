import 'dart:async';

import 'package:serious_python/serious_python.dart';

/// Arranca el Python embebido (Windows, Android, iOS, macOS, Linux).
void startEmbeddedPython(int port) {
  unawaited(SeriousPython.run(
    appFileName: 'main.py',
    // TODO(P1): pasar la carpeta de datos de la app para que el resumen médico
    // sobreviva reinicios en un lugar estable, p. ej. con path_provider:
    //   'TIRELUS_DATA_DIR': (await getApplicationSupportDirectory()).path
    // Mientras no llegue, Python usa ~/.tirelus (o una carpeta junto a main.py).
    environmentVariables: {'TIRELUS_PORT': '$port'},
    sync: false,
  ));
}
