import 'dart:async';

import 'package:serious_python/serious_python.dart';

/// Arranca el Python embebido (Windows, Android, iOS, macOS, Linux).
void startEmbeddedPython(int port) {
  unawaited(SeriousPython.run(
    appFileName: 'main.py',
    environmentVariables: {'TIRELUS_PORT': '$port'},
    sync: false,
  ));
}
