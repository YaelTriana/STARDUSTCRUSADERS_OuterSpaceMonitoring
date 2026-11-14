// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'TIRELUS';

  @override
  String get navPanel => 'Panel';

  @override
  String get navMeasurement => 'Medición';

  @override
  String get navTrend => 'Tendencia';

  @override
  String get navAutonomous => 'Autónomo';

  @override
  String get navBase => 'Base';

  @override
  String get navVisor => 'Visor';

  @override
  String get navHandheld => 'De mano';

  @override
  String get navMore => 'Más';

  @override
  String missionDayLabel(String day, String env) {
    return 'DÍA DE MISIÓN $day · $env';
  }

  @override
  String get linkRealtime => 'Enlace: tiempo real';

  @override
  String linkAutonomous(String delay) {
    return 'Modo autónomo · $delay';
  }

  @override
  String get sampleData => 'Datos de ejemplo';

  @override
  String get bootStarting => 'Iniciando el motor en Python…';

  @override
  String get bootError => 'No se pudo iniciar el motor en Python.';

  @override
  String get retry => 'Reintentar';

  @override
  String get statusNominal => 'Nominal';

  @override
  String get statusAttention => 'Atención';

  @override
  String get statusCritical => 'Crítico';

  @override
  String get statusNoData => 'Sin dato';

  @override
  String statusSemantics(String status) {
    return 'Estado: $status';
  }

  @override
  String get envIss => 'ISS';

  @override
  String get envMoon => 'Luna';

  @override
  String get envMars => 'Marte';

  @override
  String get delayRealtime => 'tiempo real';

  @override
  String get delayMoon => '4–12 s';

  @override
  String get delayMars => 'hasta 20 min';

  @override
  String get envSelectorLabel => 'Entorno de misión';

  @override
  String get languageSwitchTooltip => 'Cambiar idioma a inglés';
}
