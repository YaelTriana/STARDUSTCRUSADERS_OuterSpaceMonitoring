import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:serious_python/serious_python.dart';

import 'python_env.dart';

/// Arranca el Python embebido (Windows, Android, iOS, macOS, Linux).
void startEmbeddedPython(int port) => unawaited(_start(port));

Future<void> _start(int port) async {
  String? dataDir;
  try {
    // Carpeta estable por app: %APPDATA% en Windows, files/ en Android.
    dataDir = (await getApplicationSupportDirectory()).path;
  } catch (e) {
    // Sin carpeta Python usa su respaldo; la app sigue funcionando.
    debugPrint('TIRELUS: no se obtuvo la carpeta de datos ($e)');
  }
  await SeriousPython.run(
    appFileName: 'main.py',
    environmentVariables: pythonEnvironment(port: port, dataDir: dataDir),
    sync: false,
  );
}
