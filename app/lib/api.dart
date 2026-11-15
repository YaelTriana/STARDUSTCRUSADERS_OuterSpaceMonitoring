import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'data/models.dart';
import 'python_starter_stub.dart' if (dart.library.io) 'python_starter_io.dart';

/// Puerto del servidor Python local. Se le pasa a Python en `TIRELUS_PORT` y se
/// puede cambiar al compilar (`--dart-define=TIRELUS_PORT=8766`) cuando el 8765
/// está ocupado o se corren dos servidores a la vez.
const tirelusPort = int.fromEnvironment('TIRELUS_PORT', defaultValue: 8765);

/// Cada cuánto el panel vuelve a preguntar por los datos: la base puede cambiar
/// en cualquier momento (otro tripulante, el CMO, un script de carga). Ajustable
/// sin tocar la lógica: `--dart-define=TIRELUS_REFRESH_SECONDS=2`.
const dashboardRefresh = Duration(seconds: int.fromEnvironment('TIRELUS_REFRESH_SECONDS', defaultValue: 5));

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

/// Python respondió 422: el valor está fuera del rango de captura.
class _OutOfRange implements Exception {
  const _OutOfRange();
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
    if (res.statusCode == 422) throw const _OutOfRange();
    if (res.statusCode != 200) throw Exception('POST $path → ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  /// Evalúa con Python. Un valor fuera del rango de captura (422) no es un estado de
  /// salud, sino un error de captura o una captura a medias ("1" mientras se escribe
  /// "120"): se devuelve "sin dato" en vez de lanzar.
  Future<VStatus> _evaluatePath(String path, double value) async {
    try {
      return statusFromApi((await _post(path, {'value': value}))['status'] as String?);
    } on _OutOfRange {
      return VStatus.sinDato;
    }
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

  /// Catálogo de métricas (`id`, `label`, `unit`, `has_data`).
  Future<List<Map<String, dynamic>>> metrics() async =>
      [for (final m in (await _get('/metrics'))['metrics'] as List) m as Map<String, dynamic>];

  /// Tendencia de cualquier métrica del catálogo: systolic, heart_rate, sleep_hours, mood.
  Future<Trend> trend(String metric) async => Trend.fromJson(await _get('/trend/$metric'));

  Future<VStatus> evaluate(String metric, double value) => _evaluatePath('/evaluate/$metric', value);

  /// Respuesta completa de /evaluate: `status`, `delta_from_high` y `base` ({low, high} o null).
  Future<Map<String, dynamic>> evaluateRaw(String metric, double value) => _post('/evaluate/$metric', {'value': value});

  // Atajos que ya usan las pantallas actuales.
  Future<Trend> systolicTrend() => trend('systolic');

  Future<VStatus> evaluateSystolic(double value) => evaluate('systolic', value);

  /// SANS: [deltaMicrons] = cambio de grosor retiniano en µm frente a la base.
  /// Umbrales publicados: +20 µm atención, 55 µm crítico (los aplica Python).
  Future<VStatus> evaluateSans(double deltaMicrons) => _evaluatePath('/evaluate/sans', deltaMicrons);

  /// Serie de OCT: `series` (µm), `days`, `status`, `thresholds`, `source`.
  Future<Map<String, dynamic>> sansTrend() => _get('/trend/sans');

  Future<Map<String, dynamic>> autonomous(MissionEnv env) => _get('/autonomous?env=${env.name}');

  Future<Map<String, dynamic>> habitat() => _get('/habitat');

  Future<Map<String, dynamic>> eva() => _get('/eva');

  /// Resumen en Markdown para la conferencia médica privada:
  /// `text`, `filename`, `items`, `mission_day`, `sample_data`.
  Future<Map<String, dynamic>> exportSummary() => _get('/summary/export');

  Future<List<String>> addToSummary(String item) async =>
      [for (final i in (await _post('/summary', {'item': item}))['items'] as List) i as String];
}
