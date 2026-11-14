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

  @override
  String get trendViewChart => 'Gráfica';

  @override
  String get trendViewTable => 'Tabla';

  @override
  String get trendRange7 => '7 días';

  @override
  String get trendRange14 => '14 días';

  @override
  String trendToday(String value, String unit) {
    return '$value $unit hoy';
  }

  @override
  String get trendAvg7 => 'Promedio 7 días';

  @override
  String get trendOutDays => 'Días fuera de rango';

  @override
  String trendOutDaysValue(int out, int total) {
    return '$out de $total';
  }

  @override
  String trendStreakValue(int days) {
    return '$days días';
  }

  @override
  String get trendNoAlertTitle => 'Sin alertas';

  @override
  String get trendNoAlertBody =>
      'Tus lecturas recientes están dentro de tu rango.';

  @override
  String trendAlertTitle(String status) {
    return '$status: tendencia sostenida';
  }

  @override
  String trendAlertBody(int days, String direction) {
    return 'Llevas $days días seguidos $direction tu rango prevuelo. No es una emergencia, pero conviene que tu flight surgeon lo vea.';
  }

  @override
  String get trendNoData => 'Aún no hay datos de ejemplo para esta métrica.';

  @override
  String get trendMeasure => 'Medir';

  @override
  String get trendPlanTitle => 'PLAN SUGERIDO';

  @override
  String get trendPlanBody =>
      '1. Mide dos veces al día (mañana y noche) durante 3 días.\n2. Registra sal en la dieta, sueño y estrés del día.\n3. Comparte el resumen en tu conferencia médica privada.';

  @override
  String get trendAddSummary => 'Agregar al resumen médico';

  @override
  String get trendAddedSummary => 'Agregado al resumen médico.';

  @override
  String trendSummaryEntry(
    String metric,
    int days,
    String direction,
    String value,
    String unit,
  ) {
    return '$metric: $days días $direction la base (hoy $value $unit)';
  }

  @override
  String get trendHoldCmo => 'Mantén presionado para avisar al CMO';

  @override
  String get trendCmoQueued => 'Aviso al CMO en camino. Puedes deshacerlo.';

  @override
  String get trendCmoUndo => 'Deshacer';

  @override
  String get trendCmoSent => 'Aviso enviado al CMO de la tripulación.';

  @override
  String get trendCmoCancelled => 'Aviso cancelado.';

  @override
  String get trendExport => 'Exportar resumen';

  @override
  String get trendExported => 'Resumen copiado al portapapeles';

  @override
  String get trendSummaryBoxTitle => 'RESUMEN PARA LA CONFERENCIA MÉDICA';

  @override
  String trendPointDetail(int day, String value, String unit) {
    return 'Día $day · $value $unit';
  }

  @override
  String get trendInRange => 'Dentro de tu rango';

  @override
  String get trendOutOfRange => 'Fuera de tu rango';

  @override
  String get trendPrev => 'Punto anterior';

  @override
  String get trendNext => 'Punto siguiente';

  @override
  String trendChartSemantics(
    String label,
    int n,
    String first,
    String last,
    String low,
    String high,
  ) {
    return '$label de los últimos $n días: de $first a $last; rango prevuelo $low a $high';
  }

  @override
  String get trendTableDay => 'Día';

  @override
  String get trendTableValue => 'Valor';

  @override
  String get trendTableState => 'Estado';

  @override
  String get exportHeader => 'RESUMEN PARA LA CONFERENCIA MÉDICA · TIRELUS';

  @override
  String exportDay(int day) {
    return 'Día de misión $day';
  }

  @override
  String get exportSampleNote =>
      'Datos de ejemplo. Los umbrales son supuestos de diseño; TIRELUS no diagnostica.';

  @override
  String exportMetricLine(
    String metric,
    String value,
    String unit,
    String low,
    String high,
    String avg,
  ) {
    return '$metric: hoy $value $unit; rango prevuelo $low–$high; promedio 7 días $avg';
  }

  @override
  String exportDaysLine(int out, int total, int streak) {
    return '$out de $total días fuera de rango; $streak días seguidos sobre la base.';
  }

  @override
  String get exportItemsHeader => 'Registros para comentar:';

  @override
  String get exportNoItems => 'Sin registros pendientes.';

  @override
  String trendExportedFile(String filename) {
    return 'Resumen copiado al portapapeles ($filename). Solo para ti, el CMO y el flight surgeon.';
  }

  @override
  String trendStreakLabel(String direction) {
    return 'Racha $direction tu base';
  }

  @override
  String get dirAbove => 'sobre';

  @override
  String get dirBelow => 'bajo';

  @override
  String get trendPlanSleep =>
      '1. Revisa luz, ruido y temperatura de tu estación de descanso.\n2. Respeta tu periodo de sueño programado durante 3 noches.\n3. Comparte el resumen en tu conferencia médica privada.';

  @override
  String get trendPlanDefault =>
      '1. Repite la medición a la misma hora durante 3 días.\n2. Anota lo que pudo influir (sueño, carga de trabajo, ejercicio).\n3. Comparte el resumen en tu conferencia médica privada.';

  @override
  String get navEyes => 'Ojos';

  @override
  String rangeUnder(String delta) {
    return '$delta bajo tu base';
  }

  @override
  String measGenericSummaryEntry(
    String metric,
    String value,
    String unit,
    String status,
  ) {
    return '$metric: $value $unit · $status frente a tu base';
  }

  @override
  String get measSavedOk => 'Medición guardada.';

  @override
  String get measSavedAdded =>
      'Medición guardada y agregada al resumen de tu conferencia médica.';

  @override
  String get measNoBase =>
      'Aún no hay línea base prevuelo para esta métrica, así que no hay contra qué comparar.';

  @override
  String measGenericRangeTitle(String metric) {
    return '$metric frente a tu rango personal';
  }

  @override
  String get measRuleOrigin => 'DE DÓNDE SALE LA REGLA';
}
