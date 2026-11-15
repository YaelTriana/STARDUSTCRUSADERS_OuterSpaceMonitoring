import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/api.dart';

/// El puerto de la API local no puede estar escrito a mano en Dart: `CLAUDE.md`
/// dice que va por `TIRELUS_PORT`, y en la demo el 8765 puede estar ocupado.
void main() {
  test('el puerto sale de --dart-define=TIRELUS_PORT, u 8765 por omisión', () {
    const definido = String.fromEnvironment('TIRELUS_PORT');
    expect(tirelusPort, definido.isEmpty ? 8765 : int.parse(definido));
  });

  test('la URL base de la API usa ese puerto', () {
    expect(TirelusApi().baseUrl, 'http://127.0.0.1:$tirelusPort');
  });
}
