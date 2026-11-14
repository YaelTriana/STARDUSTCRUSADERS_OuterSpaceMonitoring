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
}
