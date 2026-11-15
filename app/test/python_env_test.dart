import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/python_env.dart';

void main() {
  test('pasa el puerto a Python', () {
    expect(pythonEnvironment(port: 8765)['TIRELUS_PORT'], '8765');
  });

  test('pasa la carpeta de datos de la app cuando existe', () {
    final env = pythonEnvironment(port: 8765, dataDir: r'C:\Users\x\AppData\Roaming\tirelus');
    expect(env['TIRELUS_DATA_DIR'], r'C:\Users\x\AppData\Roaming\tirelus');
  });

  test('sin carpeta no manda la variable (Python usa su respaldo)', () {
    expect(pythonEnvironment(port: 8765).containsKey('TIRELUS_DATA_DIR'), isFalse);
    expect(pythonEnvironment(port: 8765, dataDir: '').containsKey('TIRELUS_DATA_DIR'), isFalse);
  });

  // --- simulación embebida: lo que le da vida al .exe y al .app ---------------

  test('pasa la simulación embebida cuando se compila con ella', () {
    final env = pythonEnvironment(port: 8765, sim: 'vivo', simCada: '15');
    expect(env['TIRELUS_SIM'], 'vivo');
    expect(env['TIRELUS_SIM_CADA'], '15');
  });

  test('sin simulación no manda las variables (el binario queda en datos de ejemplo)', () {
    final env = pythonEnvironment(port: 8765, sim: '');
    expect(env.containsKey('TIRELUS_SIM'), isFalse);
    expect(env.containsKey('TIRELUS_SIM_CADA'), isFalse);
  });

  test('la simulación se enciende al compilar, con --dart-define=TIRELUS_SIM', () {
    const definida = String.fromEnvironment('TIRELUS_SIM');
    expect(pythonEnvironment(port: 8765).containsKey('TIRELUS_SIM'), definida.isNotEmpty);
  });
}
