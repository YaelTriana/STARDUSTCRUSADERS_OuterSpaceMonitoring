import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'data/models.dart';
import 'python_starter_stub.dart' if (dart.library.io) 'python_starter_io.dart';

/// Puerto del servidor Python local (se pasa a Python como TIRELUS_PORT).
const tirelusPort = 8765;

/// En desarrollo se puede correr el servidor aparte (`python python_app/main.py`)
/// y lanzar Flutter con `--dart-define=TIRELUS_DEV_SERVER=true` para no
/// arrancar el Python embebido.
const _devServer = bool.fromEnvironment('TIRELUS_DEV_SERVER');

/// Arranca el Python embebido (serious_python) y espera a que responda /health.
class PythonRuntime {
  static bool _started = false;

  static Future<void> start(TirelusApi api) async {
    // Web (Pyodide) no puede abrir un servidor HTTP local: se usa el servidor de desarrollo.
    if (!_started && !kIsWeb && !_devServer) {
      _started = true;
      startEmbeddedPython(tirelusPort);
    }
    await api.waitUntilReady();
  }
}

/// Cliente de la API local de Python.
class TirelusApi {
  TirelusApi({this.baseUrl = 'http://127.0.0.1:$tirelusPort'});

  final String baseUrl;

  /// Idioma que se le pide a Python ('es' o 'en'). Lo cambia AppState.
  String lang = 'es';

  String _withLang(String path) => '$path${path.contains('?') ? '&' : '?'}lang=$lang';

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl${_withLang(path)}')).timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) throw Exception('GET $path → ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(Uri.parse('$baseUrl${_withLang(path)}'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) throw Exception('POST $path → ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  /// Espera hasta ~30 s a que el servidor Python arranque.
  Future<void> waitUntilReady({Duration timeout = const Duration(seconds: 30)}) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      try {
        final body = await _get('/health');
        if (body['ok'] == true) return;
      } catch (_) {
        if (DateTime.now().isAfter(deadline)) {
          throw TimeoutException('El servidor Python local no respondió en $baseUrl');
        }
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
  }

  Future<Dashboard> dashboard() async => Dashboard.fromJson(await _get('/dashboard'));

  Future<Trend> systolicTrend() async => Trend.fromJson(await _get('/trend/systolic'));

  Future<VStatus> evaluateSystolic(double value) async =>
      statusFromApi((await _post('/evaluate/systolic', {'value': value}))['status'] as String?);

  Future<Map<String, dynamic>> autonomous(MissionEnv env) => _get('/autonomous?env=${env.name}');

  Future<Map<String, dynamic>> habitat() => _get('/habitat');

  Future<Map<String, dynamic>> eva() => _get('/eva');

  Future<List<String>> addToSummary(String item) async =>
      [for (final i in (await _post('/summary', {'item': item}))['items'] as List) i as String];
}
