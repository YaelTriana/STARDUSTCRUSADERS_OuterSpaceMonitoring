// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TIRELUS';

  @override
  String get navPanel => 'Dashboard';

  @override
  String get navMeasurement => 'Measure';

  @override
  String get navTrend => 'Trend';

  @override
  String get navAutonomous => 'Autonomous';

  @override
  String get navBase => 'Base';

  @override
  String get navVisor => 'Visor';

  @override
  String get navHandheld => 'Handheld';

  @override
  String get navMore => 'More';

  @override
  String missionDayLabel(String day, String env) {
    return 'MISSION DAY $day · $env';
  }

  @override
  String get linkRealtime => 'Link: real time';

  @override
  String linkAutonomous(String delay) {
    return 'Autonomous mode · $delay';
  }

  @override
  String get sampleData => 'Sample data';

  @override
  String get bootStarting => 'Starting the Python engine…';

  @override
  String get bootError => 'The Python engine could not start.';

  @override
  String get retry => 'Retry';

  @override
  String get statusNominal => 'Nominal';

  @override
  String get statusAttention => 'Attention';

  @override
  String get statusCritical => 'Critical';

  @override
  String get statusNoData => 'No data';

  @override
  String statusSemantics(String status) {
    return 'Status: $status';
  }

  @override
  String get envIss => 'ISS';

  @override
  String get envMoon => 'Moon';

  @override
  String get envMars => 'Mars';

  @override
  String get delayRealtime => 'real time';

  @override
  String get delayMoon => '4–12 s';

  @override
  String get delayMars => 'up to 20 min';

  @override
  String get envSelectorLabel => 'Mission environment';

  @override
  String get languageSwitchTooltip => 'Switch language to Spanish';
}
