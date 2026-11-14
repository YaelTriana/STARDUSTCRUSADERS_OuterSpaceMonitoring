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

  @override
  String get panelBodyTitle => 'ESTADO POR SISTEMA · TOCA UNA ZONA';

  @override
  String get panelWhyTitle => 'POR QUÉ CAMBIA EN EL ESPACIO';

  @override
  String get panelActionTitle => 'QUÉ HACER AHORA';

  @override
  String summaryAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sistemas requieren atención',
      one: '1 sistema requiere atención',
    );
    return '$_temp0';
  }

  @override
  String get summaryAllClear => 'Todos tus sistemas están en rango';

  @override
  String get sourceChip => 'Fuente: NASA HRP';

  @override
  String get sourceNoteTitle => 'Sobre esta información';

  @override
  String get sourceNoteBody =>
      'Las explicaciones se basan en publicaciones del Human Research Program (HRP) de NASA. Los umbrales de alerta de esta app son supuestos de diseño, no valores oficiales de vuelo. TIRELUS no diagnostica: te ayuda a decidir a quién avisar.';

  @override
  String get close => 'Cerrar';

  @override
  String get noDataMeasure => 'Sin dato · medir';

  @override
  String get errorEngine => 'No se pudo leer el servidor Python local.';

  @override
  String get loading => 'Cargando…';

  @override
  String taskPending(String time) {
    return 'PENDIENTE · $time';
  }

  @override
  String taskToday(String time) {
    return 'HOY · $time';
  }

  @override
  String get exerciseLabel => 'EJERCICIO';

  @override
  String exerciseProgress(int hours, int minutes) {
    return '$hours h $minutes min de ~2 h';
  }

  @override
  String get streakLabel => 'RACHA DE REGISTRO';

  @override
  String get streakDays => 'días';

  @override
  String get streakBadge => 'Insignia «Constancia orbital»';

  @override
  String get measTitle => 'Registra tu lectura';

  @override
  String measStepCounter(int step, int total, String title) {
    return 'Paso $step de $total · $title';
  }

  @override
  String get measStep1Title => 'Prepárate';

  @override
  String get measStep1Detail =>
      '5 min en reposo, anclado con los pies en la barra';

  @override
  String get measStep2Title => 'Coloca el brazalete';

  @override
  String get measStep2Detail => 'Brazo izquierdo, 2 cm sobre el codo';

  @override
  String get measStep3Title => 'Mide y registra';

  @override
  String get measStep3Detail => 'Lee el monitor o la prenda Bio-Monitor';

  @override
  String get measStep4Title => 'Resultado';

  @override
  String get measStep4Detail => 'Qué significa y qué hacer';

  @override
  String get measNext => 'Siguiente';

  @override
  String get measBack => 'Atrás';

  @override
  String get measSeeResult => 'Ver resultado';

  @override
  String get measSys => 'Sistólica';

  @override
  String get measDia => 'Diastólica';

  @override
  String get measHr => 'Frecuencia cardiaca';

  @override
  String get measSource => 'Fuente del dato';

  @override
  String get measSourceManual => 'Manual';

  @override
  String get measSourceWearable => 'Wearable (ejemplo)';

  @override
  String get measSourceUltrasound => 'Ultrasonido (ejemplo)';

  @override
  String get keypadBackspace => 'Borrar';

  @override
  String get keypadNextField => 'Siguiente campo';

  @override
  String get measFillRequired => 'Escribe la sistólica y la diastólica.';

  @override
  String get measSysLtDia => 'La sistólica debe ser mayor que la diastólica.';

  @override
  String measConfirmTitle(String value) {
    return '¿Seguro que es $value?';
  }

  @override
  String get measConfirmBody =>
      'Ese valor es poco común. Revisa el monitor antes de guardarlo.';

  @override
  String get measConfirmFix => 'Corregir';

  @override
  String get measConfirmKeep => 'Sí, es correcto';

  @override
  String get rangeTitle => 'Sistólica frente a tu rango personal';

  @override
  String rangeOver(String delta) {
    return '+$delta sobre tu base';
  }

  @override
  String get rangeInside => 'dentro de tu base';

  @override
  String rangeBase(String low, String high) {
    return 'Tu rango prevuelo $low–$high';
  }

  @override
  String get resultNominal => 'Dentro de tu rango. Sigue con tu rutina.';

  @override
  String get resultAtencion =>
      'Repite la medición tras 5 min en reposo. Si sigue sobre tu base 3 días, TIRELUS la agrega al resumen de tu conferencia médica.';

  @override
  String get resultCritico =>
      'Está muy por encima de tu base. TIRELUS no diagnostica: repite la medición en reposo y avisa a tu CMO.';

  @override
  String get resultNoData =>
      'Aún no hay base para comparar esta lectura. Guárdala para que TIRELUS la tenga como referencia.';

  @override
  String get repeatIn5 => 'Repetir en 5 min';

  @override
  String repeatCountdown(String time) {
    return 'Repetir en $time';
  }

  @override
  String get repeatCancel => 'Cancelar recordatorio';

  @override
  String get repeatDue => 'Es hora de repetir tu medición.';

  @override
  String get measSave => 'Guardar medición';

  @override
  String get savedOk => 'Medición guardada. Dentro de tu rango.';

  @override
  String get savedSummary =>
      'Medición guardada y agregada al resumen de tu conferencia médica.';

  @override
  String summaryEntry(String sys, String dia, String status) {
    return 'PA $sys/$dia mmHg · $status frente a tu base';
  }

  @override
  String get helpWhatTitle => 'Qué estás midiendo';

  @override
  String get helpWhatBody =>
      'La fuerza con la que la sangre empuja las arterias: el número alto al latir el corazón, el bajo entre latidos.';

  @override
  String get helpWhyTitle => 'Por qué importa aquí';

  @override
  String get helpWhyBody =>
      'Sin gravedad, los líquidos suben hacia el pecho y la cabeza. El sistema cardiovascular se adapta y eso puede cambiar tus lecturas.';

  @override
  String get helpTipTitle => 'Consejo';

  @override
  String get helpTipBody =>
      'Mide a la misma hora y sin haber hecho ejercicio en los 30 min previos, para comparar contra tu base.';
}
