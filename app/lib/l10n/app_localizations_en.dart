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
  String trendAlertBody(int days, String direction) {
    return 'You have been $direction your pre-flight range for $days days in a row. This is not an emergency, but your flight surgeon should take a look.';
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
  String trendSummaryEntry(
    String metric,
    int days,
    String direction,
    String value,
    String unit,
  ) {
    return '$metric: $days days $direction baseline (today $value $unit)';
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

  @override
  String trendStreakLabel(String direction) {
    return 'Streak $direction baseline';
  }

  @override
  String get dirAbove => 'above';

  @override
  String get dirBelow => 'below';

  @override
  String get trendPlanSleep =>
      '1. Check the light, noise and temperature of your rest station.\n2. Keep to your scheduled sleep period for 3 nights.\n3. Share the summary at your private medical conference.';

  @override
  String get trendPlanDefault =>
      '1. Repeat the measurement at the same time for 3 days.\n2. Note what may have influenced it (sleep, workload, exercise).\n3. Share the summary at your private medical conference.';

  @override
  String get navEyes => 'Eyes';

  @override
  String rangeUnder(String delta) {
    return '$delta below your baseline';
  }

  @override
  String measGenericSummaryEntry(
    String metric,
    String value,
    String unit,
    String status,
  ) {
    return '$metric: $value $unit · $status vs your baseline';
  }

  @override
  String get measSavedOk => 'Measurement saved.';

  @override
  String get measSavedAdded =>
      'Measurement saved and added to your medical conference summary.';

  @override
  String get measNoBase =>
      'There is no pre-flight baseline for this metric yet, so there is nothing to compare against.';

  @override
  String measGenericRangeTitle(String metric) {
    return '$metric vs your personal range';
  }

  @override
  String get measRuleOrigin => 'WHERE THE RULE COMES FROM';

  @override
  String get autoRealtimeTitle => 'Real-time link to Earth';

  @override
  String get autoRealtimeBody =>
      'On the ISS you consult the flight surgeon directly.\nSwitch the environment to Moon or Mars to see autonomous mode.';

  @override
  String get autoReminder =>
      'TIRELUS guides, it does not diagnose. Medical decisions belong to your CMO with the flight surgeon.';

  @override
  String get autoPrivacy =>
      'Medical data: only you, the CMO and the flight surgeon. Never on shared screens.';

  @override
  String get autoProtocolOverline => 'GUIDED PROTOCOL · WITH THE CMO';

  @override
  String autoProgress(int done, int total) {
    return 'Step $done of $total';
  }

  @override
  String get autoOpenGuide => 'Open guide';

  @override
  String get autoGuideClose => 'Got it';

  @override
  String get autoLogContinue => 'Log and continue';

  @override
  String get autoStepLogged =>
      'Step logged. It was added to the delayed message.';

  @override
  String get autoAllDone =>
      'Protocol complete. Review the on-board decision and send the message to Earth.';

  @override
  String get autoNoWait =>
      'Decisions do not wait for Earth\'s reply. TIRELUS guides, logs each step and sends it with a delay.';

  @override
  String get autoMessageTitle => 'DELAYED MESSAGE TO THE FLIGHT SURGEON';

  @override
  String get autoMessageMeta => 'Compressed text · no video';

  @override
  String autoDelayLabel(String delay) {
    return 'Delay $delay';
  }

  @override
  String get autoHoldSend => 'Hold to send to Earth';

  @override
  String get autoTimelineTitle => 'MESSAGE TIMELINE';

  @override
  String get autoTlDrafted => 'Drafted on board';

  @override
  String get autoTlQueued => 'Queued to send';

  @override
  String get autoTlSent => 'Sent';

  @override
  String autoTlArrival(String time) {
    return 'Reaches Earth in $time';
  }

  @override
  String get autoTlArrived => 'Reached Earth';

  @override
  String autoTlResponse(String time) {
    return 'Reply possible in $time or more';
  }

  @override
  String get autoTlResponseIn => 'Reply received (example)';

  @override
  String get autoTlResponseBody =>
      'Example: keep the daily self-test and repeat the OCT in 24 h. Any change, escalate to the flight surgeon.';

  @override
  String autoEtaAssumption(String oneWay) {
    return 'Example timings (design assumption): one way $oneWay; a reply cannot arrive before the round trip.';
  }

  @override
  String get autoSpeedUp => 'Speed up time (demo only)';

  @override
  String get autoQueueTitle => 'COMMUNICATION QUEUE';

  @override
  String get autoQueueThisProtocol => 'This protocol';

  @override
  String get autoQueueDraft => 'Draft';

  @override
  String get autoQueueSent => 'Sent';

  @override
  String get autoQueueReceived => 'Received';

  @override
  String get autoDecisionTitle => 'ON-BOARD DECISION';

  @override
  String get autoDecisionIntro =>
      'Protocol options to discuss with your CMO. They are not a diagnosis or an order.';

  @override
  String get autoPros => 'Pros';

  @override
  String get autoCons => 'Cons';

  @override
  String get autoOpt1Title => 'Keep monitoring with a daily self-test';

  @override
  String get autoOpt1Pros =>
      'Uses no resources and keeps the trend up to date.';

  @override
  String get autoOpt1Cons => 'If it gets worse, it may take longer to notice.';

  @override
  String get autoOpt2Title => 'Repeat the OCT in 24 hours';

  @override
  String get autoOpt2Pros =>
      'Confirms whether retinal thickness keeps rising against your baseline.';

  @override
  String get autoOpt2Cons => 'Takes CMO and imaging-equipment time.';

  @override
  String get autoOpt3Title => 'Request a deferred priority consult';

  @override
  String get autoOpt3Pros =>
      'It is on record and the flight surgeon sees it first.';

  @override
  String get autoOpt3Cons => 'The reply takes the communication round trip.';

  @override
  String get autoMedkitTitle => 'MEDICAL KIT · EXAMPLE INVENTORY';

  @override
  String get autoMedkitNote =>
      'Example data. The CMO confirms the real inventory.';

  @override
  String get autoMedkitItem1 => 'Artificial tears';

  @override
  String get autoMedkitItem1Qty => '12 vials';

  @override
  String get autoMedkitItem2 => 'Portable OCT';

  @override
  String get autoMedkitItem2Qty => '1 unit';

  @override
  String get autoMedkitItem3 => 'Adjustable-focus glasses';

  @override
  String get autoMedkitItem3Qty => '2 pairs';

  @override
  String get sansTitle => 'Eyes and brain (SANS)';

  @override
  String get sansIntro =>
      'Log your OCT result: how much your retinal thickness changed from your pre-flight baseline.';

  @override
  String get sansFieldLabel => 'Thickness change (µm)';

  @override
  String get sansFieldHint => 'e.g. 8';

  @override
  String get sansPublished =>
      'The only metric with thresholds published by NASA. For all others, thresholds are design assumptions.';

  @override
  String get sansBarSemantics =>
      'Thresholds: plus 20 microns first sign, 55 microns clinical concern';

  @override
  String sansBarValue(String value) {
    return '; your value: $value microns';
  }

  @override
  String get sansMarkNone => '0 µm';

  @override
  String get sansMarkAttention => '+20 µm · first sign';

  @override
  String get sansMarkCritical => '55 µm · clinical concern';

  @override
  String sansYourValue(String value, String status) {
    return 'Your value: +$value µm · $status';
  }

  @override
  String get sansAlertCriticalTitle => 'Critical: tell your CMO today';

  @override
  String get sansAlertCriticalBody =>
      'The change reaches the level of clinical concern. Tell your CMO and your flight surgeon.';

  @override
  String get sansAlertAttentionTitle => 'Attention: first sign of SANS';

  @override
  String get sansAlertAttentionBody =>
      'Consider repeating the OCT next cycle and discussing it at your private medical conference.';

  @override
  String get sansAddSummary => 'Add to medical summary';

  @override
  String get sansAdded => 'Added to the medical summary.';

  @override
  String sansSummaryEntry(String value, String status) {
    return 'SANS: retinal thickness +$value µm vs baseline · $status';
  }

  @override
  String get sansHistoryTitle => 'OCT HISTORY';

  @override
  String get sansHistoryEmpty =>
      'No example OCT yet. Once there are readings, you will see each cycle here.';

  @override
  String sansHistoryRow(String day, String value) {
    return 'D$day · +$value µm';
  }

  @override
  String get sansWhatTitle => 'WHAT YOU ARE MEASURING';

  @override
  String get sansWhatBody =>
      'OCT measures the thickness of the retina around the optic nerve. If it thickens, it can be an early sign of SANS.';

  @override
  String get sansWhyTitle => 'WHY IT MATTERS HERE';

  @override
  String get sansWhyBody =>
      'Without gravity, fluids shift toward the head. On long missions this is linked to changes in the eye and in vision.';

  @override
  String get sansDoTitle => 'WHAT TO DO';

  @override
  String get sansDoBody =>
      'Always measure under the same conditions and log the change against your baseline. TIRELUS does not diagnose: if there is a signal, tell your CMO, who escalates to the flight surgeon.';

  @override
  String get summaryOffline =>
      'Could not save to the engine. It is kept on this screen only and will be lost when you close the app.';

  @override
  String get measEvalFailed =>
      'Could not evaluate with the engine. Check the connection and try again.';
}
