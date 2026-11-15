import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tirelus/api.dart';
import 'package:tirelus/data/models.dart';

/// Python rechaza con 422 los valores fuera del rango de captura (p. ej. "1" o "12"
/// mientras se escribe "120"). La app no debe lanzar: debe mostrar "sin dato".
void main() {
  http.Response ok(String status) => http.Response(jsonEncode({'status': status}), 200);
  final fueraDeRango = http.Response(
      jsonEncode({
        'detail': {'message': 'Valor fuera del rango válido de captura', 'valid_range': [50, 260]}
      }),
      422);

  test('evaluate devuelve sin dato cuando Python responde 422', () async {
    final status = await http.runWithClient(
      () => TirelusApi().evaluate('systolic', 12),
      () => MockClient((_) async => fueraDeRango),
    );
    expect(status, VStatus.sinDato);
  });

  test('evaluateSans devuelve sin dato cuando Python responde 422', () async {
    final status = await http.runWithClient(
      () => TirelusApi().evaluateSans(9999),
      () => MockClient((_) async => fueraDeRango),
    );
    expect(status, VStatus.sinDato);
  });

  test('un valor válido sigue devolviendo el estado de Python', () async {
    final status = await http.runWithClient(
      () => TirelusApi().evaluate('systolic', 120),
      () => MockClient((_) async => ok('nominal')),
    );
    expect(status, VStatus.nominal);
  });

  test('otros errores del servidor siguen lanzando', () async {
    expect(
      http.runWithClient(
        () => TirelusApi().evaluate('systolic', 120),
        () => MockClient((_) async => http.Response('boom', 500)),
      ),
      throwsException,
    );
  });
}
