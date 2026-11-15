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

/// Respuesta de /dashboard como la arma Python: cardio calculado por panel.py
/// (un indicador con datos y el resto en "Sin dato") y los demás sistemas mockup.
Map<String, dynamic> dashboardJson({
  String status = 'atencion',
  String value = '132',
  String note = '▲ 6 sobre tu base (110–126)',
}) =>
    {
      'mission_day': 47,
      'sample_data': true,
      'streak_days': 12,
      'exercise': {'done_min': 112, 'goal_min': 120},
      'tasks': [
        {'time': '09:30', 'title': 'Medir presión arterial', 'detail': 'Guía paso a paso', 'pending': true},
      ],
      'systems': [
        {
          'id': 'cardio',
          'name': 'Corazón y circulación',
          'status': status,
          'computed': true,
          'why': 'En microgravedad los líquidos se desplazan hacia la cabeza.',
          'action': 'Repite la medición tras 5 min en reposo.',
          'indicators': [
            {'label': 'Presión sistólica', 'value': value, 'unit': 'mmHg', 'note': note, 'status': status},
            {'label': 'Presión diastólica', 'value': '—', 'unit': 'mmHg', 'note': 'Sin dato', 'status': 'sin_dato'},
            {'label': 'FC en reposo', 'value': '—', 'unit': 'lpm', 'note': 'Sin dato', 'status': 'sin_dato'},
            {'label': 'SpO₂', 'value': '—', 'unit': '%', 'note': 'Sin dato', 'status': 'sin_dato'},
          ],
        },
        for (final s in ['ojos', 'hueso', 'mente', 'inmune'])
          {
            'id': s,
            'name': s,
            'status': 'nominal',
            'computed': true,
            'why': 'texto educativo',
            'action': 'qué hacer',
            'indicators': [
              {'label': 'indicador', 'value': '1', 'unit': '', 'note': 'nota', 'status': 'nominal'},
            ],
          },
      ],
    };

/// API falsa para pruebas de widgets: no abre conexiones.
class FakeApi extends TirelusApi {
  FakeApi({
    this.trends = const {},
    this.sansStatus = 'nominal',
    this.evalStatus = 'nominal',
    this.dashboardBody,
    this.dashboardFails = false,
  }) : super(baseUrl: 'http://fake.invalid');

  final Map<String, Map<String, dynamic>> trends;
  /// Mutable a propósito: las pruebas lo cambian entre un refresco y el siguiente.
  Map<String, dynamic>? dashboardBody;
  bool dashboardFails;
  int dashboardCalls = 0;
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
  Future<Dashboard> dashboard() async {
    dashboardCalls++;
    if (dashboardFails) throw Exception('sin servidor');
    return Dashboard.fromJson(dashboardBody!);
  }

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
  Future<VStatus> evaluateSans(double deltaMicrons) async {
    evaluated['sans'] = deltaMicrons;
    return statusFromApi(sansStatus);
  }
}
