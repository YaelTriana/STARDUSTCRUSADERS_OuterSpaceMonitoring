import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/app_state.dart';

import 'fake_api.dart';

/// API cuyo motor no responde al guardar en el resumen.
class _DownApi extends FakeApi {
  @override
  Future<List<String>> addToSummary(String item) async => throw Exception('motor caído');
}

class _UpApi extends FakeApi {
  @override
  Future<List<String>> addToSummary(String item) async => [item];
}

void main() {
  test('si el motor no responde, el hallazgo queda en memoria y avisa con false', () async {
    final state = AppState(_DownApi());
    final ok = await state.addToSummary('PA 132/84 · atención');
    expect(ok, isFalse);
    expect(state.medicalSummary, ['PA 132/84 · atención']);
  });

  test('no duplica el mismo hallazgo si se reintenta sin motor', () async {
    final state = AppState(_DownApi());
    await state.addToSummary('PA 132/84 · atención');
    await state.addToSummary('PA 132/84 · atención');
    expect(state.medicalSummary, hasLength(1));
  });

  test('con motor devuelve true y usa la lista del motor', () async {
    final state = AppState(_UpApi());
    expect(await state.addToSummary('x'), isTrue);
    expect(state.medicalSummary, ['x']);
  });
}
