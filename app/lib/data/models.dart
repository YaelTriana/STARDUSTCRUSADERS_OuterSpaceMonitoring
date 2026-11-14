/// Modelos de la UI. Los datos y las reglas viven en Python (app/python_app);
/// aquí solo se leen las respuestas de la API local.
enum VStatus { nominal, atencion, critico, sinDato }

VStatus statusFromApi(String? s) => switch (s) {
      'nominal' => VStatus.nominal,
      'atencion' => VStatus.atencion,
      'critico' => VStatus.critico,
      _ => VStatus.sinDato,
    };

extension VStatusLabel on VStatus {
  String get label => switch (this) {
        VStatus.nominal => 'Nominal',
        VStatus.atencion => 'Atención',
        VStatus.critico => 'Crítico',
        VStatus.sinDato => 'Sin dato',
      };
}

/// Entorno de misión: define el retraso de comunicación con Tierra.
enum MissionEnv { iss, luna, marte }

extension MissionEnvInfo on MissionEnv {
  String get label => switch (this) {
        MissionEnv.iss => 'ISS',
        MissionEnv.luna => 'Luna',
        MissionEnv.marte => 'Marte',
      };

  String get delay => switch (this) {
        MissionEnv.iss => 'tiempo real',
        MissionEnv.luna => '4–12 s',
        MissionEnv.marte => 'hasta 20 min',
      };

  bool get autonomous => this != MissionEnv.iss;
}

class Indicator {
  const Indicator({required this.label, required this.value, required this.unit, required this.note, required this.status});

  factory Indicator.fromJson(Map<String, dynamic> j) => Indicator(
        label: j['label'] as String,
        value: j['value'] as String,
        unit: j['unit'] as String,
        note: j['note'] as String,
        status: statusFromApi(j['status'] as String?),
      );

  final String label;
  final String value;
  final String unit;
  final String note;
  final VStatus status;
}

class BodySystem {
  const BodySystem({
    required this.id,
    required this.name,
    required this.status,
    required this.indicators,
    required this.why,
    required this.action,
  });

  factory BodySystem.fromJson(Map<String, dynamic> j) => BodySystem(
        id: j['id'] as String,
        name: j['name'] as String,
        status: statusFromApi(j['status'] as String?),
        indicators: [for (final i in j['indicators'] as List) Indicator.fromJson(i as Map<String, dynamic>)],
        why: j['why'] as String,
        action: j['action'] as String,
      );

  final String id;
  final String name;
  final VStatus status;
  final List<Indicator> indicators;
  final String why;
  final String action;
}

class Dashboard {
  const Dashboard({
    required this.missionDay,
    required this.systems,
    required this.tasks,
    required this.exerciseDone,
    required this.exerciseGoal,
    required this.streakDays,
  });

  factory Dashboard.fromJson(Map<String, dynamic> j) => Dashboard(
        missionDay: j['mission_day'] as int,
        systems: [for (final s in j['systems'] as List) BodySystem.fromJson(s as Map<String, dynamic>)],
        tasks: [for (final t in j['tasks'] as List) t as Map<String, dynamic>],
        exerciseDone: j['exercise']['done_min'] as int,
        exerciseGoal: j['exercise']['goal_min'] as int,
        streakDays: j['streak_days'] as int,
      );

  final int missionDay;
  final List<BodySystem> systems;
  final List<Map<String, dynamic>> tasks;
  final int exerciseDone;
  final int exerciseGoal;
  final int streakDays;

  BodySystem system(String id) => systems.firstWhere((s) => s.id == id, orElse: () => systems.first);
}

class Trend {
  const Trend({
    required this.series,
    required this.firstDay,
    required this.baseLow,
    required this.baseHigh,
    required this.status,
    required this.consecutiveAbove,
    required this.daysOutOfRange,
    required this.deltaFromHigh,
    required this.avg7,
    required this.rule,
    this.metric = 'systolic',
    this.label = 'Presión sistólica',
    this.unit = 'mmHg',
    this.alertsWhenBelow = false,
    this.consecutiveBelow = 0,
    this.deltaFromLow = 0,
    this.source = '',
    this.hasBase = true,
  });

  factory Trend.fromJson(Map<String, dynamic> j) => Trend(
        series: [for (final v in j['series'] as List) (v as num).toDouble()],
        firstDay: j['first_day'] as int,
        // base es null cuando la métrica aún no tiene datos de ejemplo (status sin_dato).
        baseLow: ((j['base'] as Map?)?['low'] as num?)?.toDouble() ?? 0,
        baseHigh: ((j['base'] as Map?)?['high'] as num?)?.toDouble() ?? 0,
        hasBase: j['base'] != null,
        status: statusFromApi(j['status'] as String?),
        consecutiveAbove: j['consecutive_above'] as int,
        consecutiveBelow: (j['consecutive_below'] as int?) ?? 0,
        daysOutOfRange: j['days_out_of_range'] as int,
        deltaFromHigh: (j['delta_from_high'] as num).toDouble(),
        deltaFromLow: ((j['delta_from_low'] as num?) ?? 0).toDouble(),
        avg7: (j['avg7'] as num).toInt(),
        rule: j['rule'] as String,
        metric: (j['metric'] as String?) ?? 'systolic',
        label: (j['label'] as String?) ?? 'Presión sistólica',
        unit: (j['unit'] as String?) ?? 'mmHg',
        alertsWhenBelow: j['alert_when'] == 'below',
        source: (j['source'] as String?) ?? '',
      );

  final List<double> series;
  final int firstDay;
  final double baseLow;
  final double baseHigh;
  final bool hasBase;
  final VStatus status;
  final int consecutiveAbove;
  final int consecutiveBelow;
  final int daysOutOfRange;
  final double deltaFromHigh;
  final double deltaFromLow;
  final int avg7;
  final String rule;
  final String metric;
  final String label;
  final String unit;
  final String source;

  /// true si preocupa que la métrica baje (sueño, ánimo).
  final bool alertsWhenBelow;

  /// Días seguidos fuera de la base en la dirección que preocupa.
  int get sustainedStreak => alertsWhenBelow ? consecutiveBelow : consecutiveAbove;

  /// "sobre" o "bajo", según la dirección que preocupa.
  String get directionWord => alertsWhenBelow ? 'bajo' : 'sobre';

  bool get hasData => series.isNotEmpty && hasBase;

  /// Decimales para mostrar cifras: horas y puntos con 1, el resto entero.
  int get decimals => series.any((v) => v != v.roundToDouble()) ? 1 : 0;

  String fmt(double v) => v.toStringAsFixed(decimals);
}
