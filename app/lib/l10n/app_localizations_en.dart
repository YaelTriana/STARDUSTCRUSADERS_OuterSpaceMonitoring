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

  @override
  String get panelBodyTitle => 'STATUS BY SYSTEM · TAP A ZONE';

  @override
  String get panelWhyTitle => 'WHY IT CHANGES IN SPACE';

  @override
  String get panelActionTitle => 'WHAT TO DO NOW';

  @override
  String summaryAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count systems need attention',
      one: '1 system needs attention',
    );
    return '$_temp0';
  }

  @override
  String get summaryAllClear => 'All your systems are in range';

  @override
  String get sourceChip => 'Source: NASA HRP';

  @override
  String get sourceNoteTitle => 'About this information';

  @override
  String get sourceNoteBody =>
      'The explanations are based on NASA Human Research Program (HRP) publications. This app\'s alert thresholds are design assumptions, not official flight values. TIRELUS does not diagnose: it helps you decide whom to notify.';

  @override
  String get close => 'Close';

  @override
  String get noDataMeasure => 'No data · measure';

  @override
  String get errorEngine => 'Could not read the local Python server.';

  @override
  String get loading => 'Loading…';

  @override
  String taskPending(String time) {
    return 'PENDING · $time';
  }

  @override
  String taskToday(String time) {
    return 'TODAY · $time';
  }

  @override
  String get exerciseLabel => 'EXERCISE';

  @override
  String exerciseProgress(int hours, int minutes) {
    return '$hours h $minutes min of ~2 h';
  }

  @override
  String get streakLabel => 'LOGGING STREAK';

  @override
  String get streakDays => 'days';

  @override
  String get streakBadge => '“Orbital Consistency” badge';

  @override
  String get measTitle => 'Log your reading';

  @override
  String measStepCounter(int step, int total, String title) {
    return 'Step $step of $total · $title';
  }

  @override
  String get measStep1Title => 'Get ready';

  @override
  String get measStep1Detail => '5 min at rest, feet anchored to the bar';

  @override
  String get measStep2Title => 'Put on the cuff';

  @override
  String get measStep2Detail => 'Left arm, 2 cm above the elbow';

  @override
  String get measStep3Title => 'Measure and log';

  @override
  String get measStep3Detail => 'Read the monitor or the Bio-Monitor garment';

  @override
  String get measStep4Title => 'Result';

  @override
  String get measStep4Detail => 'What it means and what to do';

  @override
  String get measNext => 'Next';

  @override
  String get measBack => 'Back';

  @override
  String get measSeeResult => 'See result';

  @override
  String get measSys => 'Systolic';

  @override
  String get measDia => 'Diastolic';

  @override
  String get measHr => 'Heart rate';

  @override
  String get measSource => 'Data source';

  @override
  String get measSourceManual => 'Manual';

  @override
  String get measSourceWearable => 'Wearable (sample)';

  @override
  String get measSourceUltrasound => 'Ultrasound (sample)';

  @override
  String get keypadBackspace => 'Delete';

  @override
  String get keypadNextField => 'Next field';

  @override
  String get measFillRequired => 'Enter the systolic and diastolic values.';

  @override
  String get measSysLtDia => 'Systolic must be higher than diastolic.';

  @override
  String measConfirmTitle(String value) {
    return 'Are you sure it is $value?';
  }

  @override
  String get measConfirmBody =>
      'That value is unusual. Check the monitor before saving it.';

  @override
  String get measConfirmFix => 'Fix it';

  @override
  String get measConfirmKeep => 'Yes, it is correct';

  @override
  String get rangeTitle => 'Systolic vs your personal range';

  @override
  String rangeOver(String delta) {
    return '+$delta above your baseline';
  }

  @override
  String get rangeInside => 'within your baseline';

  @override
  String rangeBase(String low, String high) {
    return 'Your pre-flight range $low–$high';
  }

  @override
  String get resultNominal => 'Within your range. Keep up your routine.';

  @override
  String get resultAtencion =>
      'Repeat the measurement after 5 min at rest. If it stays above your baseline for 3 days, TIRELUS adds it to your medical conference summary.';

  @override
  String get resultCritico =>
      'This is well above your baseline. TIRELUS does not diagnose: repeat the measurement at rest and notify your CMO.';

  @override
  String get resultNoData =>
      'There is no baseline yet to compare this reading. Save it so TIRELUS has it as a reference.';

  @override
  String get repeatIn5 => 'Repeat in 5 min';

  @override
  String repeatCountdown(String time) {
    return 'Repeat in $time';
  }

  @override
  String get repeatCancel => 'Cancel reminder';

  @override
  String get repeatDue => 'Time to repeat your measurement.';

  @override
  String get measSave => 'Save measurement';

  @override
  String get savedOk => 'Measurement saved. Within your range.';

  @override
  String get savedSummary =>
      'Measurement saved and added to your medical conference summary.';

  @override
  String summaryEntry(String sys, String dia, String status) {
    return 'BP $sys/$dia mmHg · $status vs your baseline';
  }

  @override
  String get helpWhatTitle => 'What you are measuring';

  @override
  String get helpWhatBody =>
      'The force of blood pushing on your arteries: the top number as the heart beats, the bottom one between beats.';

  @override
  String get helpWhyTitle => 'Why it matters here';

  @override
  String get helpWhyBody =>
      'Without gravity, fluids shift toward the chest and head. The cardiovascular system adapts, and that can change your readings.';

  @override
  String get helpTipTitle => 'Tip';

  @override
  String get helpTipBody =>
      'Measure at the same time of day and without exercise in the previous 30 min, to compare against your baseline.';

  @override
  String get trendViewChart => 'Chart';

  @override
  String get trendViewTable => 'Table';

  @override
  String get trendRange7 => '7 days';

  @override
  String get trendRange14 => '14 days';

  @override
  String trendToday(String value, String unit) {
    return '$value $unit today';
  }

  @override
  String get trendAvg7 => '7-day average';

  @override
  String get trendOutDays => 'Days out of range';

  @override
  String trendOutDaysValue(int out, int total) {
    return '$out of $total';
  }

  @override
  String get trendStreakAbove => 'Streak above baseline';

  @override
  String trendStreakValue(int days) {
    return '$days days';
  }

  @override
  String get trendNoAlertTitle => 'No alerts';

  @override
  String get trendNoAlertBody => 'Your recent readings are within your range.';

  @override
  String trendAlertTitle(String status) {
    return '$status: sustained trend';
  }

  @override
  String trendAlertBody(int days) {
    return 'You have been above your pre-flight range for $days days in a row. This is not an emergency, but your flight surgeon should take a look.';
  }

  @override
  String get trendNoData => 'There is no sample data for this metric yet.';

  @override
  String get trendMeasure => 'Measure';

  @override
  String get trendPlanTitle => 'SUGGESTED PLAN';

  @override
  String get trendPlanBody =>
      '1. Measure twice a day (morning and night) for 3 days.\n2. Log salt intake, sleep and stress for the day.\n3. Share the summary at your private medical conference.';

  @override
  String get trendAddSummary => 'Add to medical summary';

  @override
  String get trendAddedSummary => 'Added to the medical summary.';

  @override
  String trendSummaryEntry(String metric, int days, String value, String unit) {
    return '$metric: $days days above baseline (today $value $unit)';
  }

  @override
  String get trendHoldCmo => 'Press and hold to notify the CMO';

  @override
  String get trendCmoQueued => 'CMO notification on its way. You can undo it.';

  @override
  String get trendCmoUndo => 'Undo';

  @override
  String get trendCmoSent => 'Notification sent to the crew\'s CMO.';

  @override
  String get trendCmoCancelled => 'Notification cancelled.';

  @override
  String get trendExport => 'Export summary';

  @override
  String get trendExported => 'Summary copied to the clipboard';

  @override
  String get trendSummaryBoxTitle => 'MEDICAL CONFERENCE SUMMARY';

  @override
  String trendPointDetail(int day, String value, String unit) {
    return 'Day $day · $value $unit';
  }

  @override
  String get trendInRange => 'Within your range';

  @override
  String get trendOutOfRange => 'Out of your range';

  @override
  String get trendPrev => 'Previous point';

  @override
  String get trendNext => 'Next point';

  @override
  String trendChartSemantics(
    String label,
    int n,
    String first,
    String last,
    String low,
    String high,
  ) {
    return '$label over the last $n days: from $first to $last; pre-flight range $low to $high';
  }

  @override
  String get trendTableDay => 'Day';

  @override
  String get trendTableValue => 'Value';

  @override
  String get trendTableState => 'Status';

  @override
  String get exportHeader => 'MEDICAL CONFERENCE SUMMARY · TIRELUS';

  @override
  String exportDay(int day) {
    return 'Mission day $day';
  }

  @override
  String get exportSampleNote =>
      'Sample data. Thresholds are design assumptions; TIRELUS does not diagnose.';

  @override
  String exportMetricLine(
    String metric,
    String value,
    String unit,
    String low,
    String high,
    String avg,
  ) {
    return '$metric: today $value $unit; pre-flight range $low–$high; 7-day average $avg';
  }

  @override
  String exportDaysLine(int out, int total, int streak) {
    return '$out of $total days out of range; $streak days in a row above baseline.';
  }

  @override
  String get exportItemsHeader => 'Items to discuss:';

  @override
  String get exportNoItems => 'No pending items.';

  @override
  String trendExportedFile(String filename) {
    return 'Summary copied to the clipboard ($filename). Only for you, the CMO and the flight surgeon.';
  }
}
