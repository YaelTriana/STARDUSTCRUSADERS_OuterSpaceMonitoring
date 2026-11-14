import 'package:tirelus/api.dart';
import 'package:tirelus/data/models.dart';

/// Respuesta de /trend/{metric} como la arma Python.
Map<String, dynamic> trendJson({
  String metric = 'systolic',
  String label = 'Presión sistólica',
  String unit = 'mmHg',
  String alertWhen = 'above',
  List<num> series = const [118, 127, 129, 131],
  Map<String, num>? base = const {'low': 110, 'high': 126},
  String status = 'atencion',
  int above = 3,
  int below = 0,
}) =>
    {
      'metric': metric,
      'label': label,
      'unit': unit,
      'alert_when': alertWhen,
      'rule': 'Supuesto de diseño: 3 días consecutivos.',
      'source': 'Fuente de prueba.',
      'sample_data': true,
      'series': series,
      'first_day': 44,
      'base': base,
      'status': status,
      'consecutive_above': above,
      'consecutive_below': below,
      'days_out_of_range': above + below,
      'delta_from_high': 5,
      'delta_from_low': -0.7,
      'avg7': 126,
    };

/// API falsa para pruebas de widgets: no abre conexiones.
class FakeApi extends TirelusApi {
  FakeApi({this.trends = const {}, this.sansStatus = 'nominal', this.evalStatus = 'nominal'})
      : super(baseUrl: 'http://fake.invalid');

  final Map<String, Map<String, dynamic>> trends;
  final String sansStatus;
  final String evalStatus;
  final evaluated = <String, double>{};

  @override
  Future<List<Map<String, dynamic>>> metrics() async => [
        for (final e in trends.entries)
          {'id': e.key, 'label': e.value['label'], 'unit': e.value['unit'], 'has_data': (e.value['series'] as List).isNotEmpty},
      ];

  @override
  Future<Trend> trend(String metric) async => Trend.fromJson(trends[metric]!);

  @override
  Future<Map<String, dynamic>> sansTrend() async => {
        'series': <num>[],
        'days': <int>[],
        'status': 'sin_dato',
        'thresholds': {'attention_um': 20.0, 'critical_um': 55.0},
        'source': 'Umbrales publicados de SANS.',
      };

  @override
  Future<VStatus> evaluate(String metric, double value) async {
    evaluated[metric] = value;
    return statusFromApi(evalStatus);
  }

  @override
  Future<Map<String, dynamic>> evaluateRaw(String metric, double value) async {
    evaluated[metric] = value;
    return {
      'status': evalStatus,
      'base': {'low': 110, 'high': 126},
    };
  }

  @override
  Future<VStatus> evaluateSans(double deltaMicrons) async {
    evaluated['sans'] = deltaMicrons;
    return statusFromApi(sansStatus);
  }
}
