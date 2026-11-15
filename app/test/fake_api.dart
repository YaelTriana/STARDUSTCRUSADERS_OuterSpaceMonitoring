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

/// Respuesta de /dashboard como la arma Python (ver python_app/data.py).
Map<String, dynamic> dashboardJson({
  int missionDay = 47,
  List<Map<String, dynamic>>? systems,
  List<Map<String, dynamic>> tasks = const [],
  int exerciseDone = 0,
  int exerciseGoal = 120,
  int streakDays = 0,
}) =>
    {
      'mission_day': missionDay,
      'systems': systems ??
          [
            {
              'id': 'cardio',
              'name': 'Corazón y circulación',
              'status': 'atencion',
              'indicators': [
                {'label': 'Presión arterial', 'value': '132/84', 'unit': 'mmHg', 'note': '▲ base 118/76', 'status': 'atencion'},
              ],
              'why': 'Por qué cambia de prueba.',
              'action': 'Qué hacer de prueba.',
            },
            {
              'id': 'hueso',
              'name': 'Huesos y músculo',
              'status': 'nominal',
              'indicators': [
                {'label': 'Ejercicio hoy', 'value': '1:52', 'unit': 'h', 'note': 'meta ~2 h', 'status': 'nominal'},
              ],
              'why': 'Por qué cambia de prueba.',
              'action': 'Qué hacer de prueba.',
            },
          ],
      'tasks': tasks,
      'exercise': {'done_min': exerciseDone, 'goal_min': exerciseGoal},
      'streak_days': streakDays,
      'sample_data': true,
    };

/// API falsa para pruebas de widgets: no abre conexiones.
class FakeApi extends TirelusApi {
  FakeApi({this.trends = const {}, this.sansStatus = 'nominal', this.evalStatus = 'nominal', Map<String, dynamic>? dashboard})
      : dashboardData = dashboard ?? dashboardJson(),
        super(baseUrl: 'http://fake.invalid');

  final Map<String, Map<String, dynamic>> trends;
  final String sansStatus;
  final String evalStatus;
  final Map<String, dynamic> dashboardData;
  final evaluated = <String, double>{};

  @override
  Future<Dashboard> dashboard() async => Dashboard.fromJson(dashboardData);

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
  Future<Map<String, dynamic>> habitat() async => {
        'day': 18,
        'gravity': '0.17 g',
        'link': '~4 s',
        'environment': [
          {'label': 'CO₂', 'value': '2.6', 'unit': 'mmHg', 'status': 'nominal'},
        ],
        'alert': 'Alerta de prueba',
        'crew': [
          {'name': 'Tripulante A', 'location': 'HÁBITAT', 'detail': 'Detalle', 'progress': 0.6},
        ],
        'agenda': [
          {'time': '08:00', 'title': 'Vitales'},
        ],
        'team_challenge': {'title': 'Reto', 'done': 3, 'total': 5},
      };

  @override
  Future<Map<String, dynamic>> eva() async => {
        'elapsed': '02:18',
        'o2_left': '5:42',
        'return_in_min': 48,
        'hr': 128,
        'spo2': 97,
        'temp': 37.6,
        'co2': 'nominal',
        'effort': 'alto',
        'alert': 'Alerta EVA',
      };

  @override
  Future<Map<String, dynamic>> autonomous(MissionEnv env) async => {
        'title': 'Visión borrosa de cerca',
        'steps': [
          {'title': 'Autoprueba', 'detail': 'Detalle uno', 'state': 'done'},
          {'title': 'OCT con guía', 'detail': 'Detalle dos', 'state': 'current'},
          {'title': 'Comparar con tu base', 'detail': 'Detalle tres', 'state': 'todo'},
        ],
        'message': 'D212 · mensaje de prueba',
        'queue': [
          {'title': 'Resumen semanal D210', 'state': 'Recibido'},
          {'title': 'Este protocolo', 'state': 'Borrador'},
        ],
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
