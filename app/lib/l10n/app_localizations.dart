import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'TIRELUS'**
  String get appTitle;

  /// No description provided for @navPanel.
  ///
  /// In es, this message translates to:
  /// **'Panel'**
  String get navPanel;

  /// No description provided for @navMeasurement.
  ///
  /// In es, this message translates to:
  /// **'Medición'**
  String get navMeasurement;

  /// No description provided for @navTrend.
  ///
  /// In es, this message translates to:
  /// **'Tendencia'**
  String get navTrend;

  /// No description provided for @navAutonomous.
  ///
  /// In es, this message translates to:
  /// **'Autónomo'**
  String get navAutonomous;

  /// No description provided for @navBase.
  ///
  /// In es, this message translates to:
  /// **'Base'**
  String get navBase;

  /// No description provided for @navVisor.
  ///
  /// In es, this message translates to:
  /// **'Visor'**
  String get navVisor;

  /// No description provided for @navHandheld.
  ///
  /// In es, this message translates to:
  /// **'De mano'**
  String get navHandheld;

  /// No description provided for @navMore.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get navMore;

  /// No description provided for @missionDayLabel.
  ///
  /// In es, this message translates to:
  /// **'DÍA DE MISIÓN {day} · {env}'**
  String missionDayLabel(String day, String env);

  /// No description provided for @linkRealtime.
  ///
  /// In es, this message translates to:
  /// **'Enlace: tiempo real'**
  String get linkRealtime;

  /// No description provided for @linkAutonomous.
  ///
  /// In es, this message translates to:
  /// **'Modo autónomo · {delay}'**
  String linkAutonomous(String delay);

  /// No description provided for @sampleData.
  ///
  /// In es, this message translates to:
  /// **'Datos de ejemplo'**
  String get sampleData;

  /// No description provided for @bootStarting.
  ///
  /// In es, this message translates to:
  /// **'Iniciando el motor en Python…'**
  String get bootStarting;

  /// No description provided for @bootError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar el motor en Python.'**
  String get bootError;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @statusNominal.
  ///
  /// In es, this message translates to:
  /// **'Nominal'**
  String get statusNominal;

  /// No description provided for @statusAttention.
  ///
  /// In es, this message translates to:
  /// **'Atención'**
  String get statusAttention;

  /// No description provided for @statusCritical.
  ///
  /// In es, this message translates to:
  /// **'Crítico'**
  String get statusCritical;

  /// No description provided for @statusNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin dato'**
  String get statusNoData;

  /// No description provided for @statusSemantics.
  ///
  /// In es, this message translates to:
  /// **'Estado: {status}'**
  String statusSemantics(String status);

  /// No description provided for @envIss.
  ///
  /// In es, this message translates to:
  /// **'ISS'**
  String get envIss;

  /// No description provided for @envMoon.
  ///
  /// In es, this message translates to:
  /// **'Luna'**
  String get envMoon;

  /// No description provided for @envMars.
  ///
  /// In es, this message translates to:
  /// **'Marte'**
  String get envMars;

  /// No description provided for @delayRealtime.
  ///
  /// In es, this message translates to:
  /// **'tiempo real'**
  String get delayRealtime;

  /// No description provided for @delayMoon.
  ///
  /// In es, this message translates to:
  /// **'4–12 s'**
  String get delayMoon;

  /// No description provided for @delayMars.
  ///
  /// In es, this message translates to:
  /// **'hasta 20 min'**
  String get delayMars;

  /// No description provided for @envSelectorLabel.
  ///
  /// In es, this message translates to:
  /// **'Entorno de misión'**
  String get envSelectorLabel;

  /// No description provided for @languageSwitchTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cambiar idioma a inglés'**
  String get languageSwitchTooltip;

  /// No description provided for @panelBodyTitle.
  ///
  /// In es, this message translates to:
  /// **'ESTADO POR SISTEMA · TOCA UNA ZONA'**
  String get panelBodyTitle;

  /// No description provided for @panelWhyTitle.
  ///
  /// In es, this message translates to:
  /// **'POR QUÉ CAMBIA EN EL ESPACIO'**
  String get panelWhyTitle;

  /// No description provided for @panelActionTitle.
  ///
  /// In es, this message translates to:
  /// **'QUÉ HACER AHORA'**
  String get panelActionTitle;

  /// No description provided for @summaryAttention.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 sistema requiere atención} other{{count} sistemas requieren atención}}'**
  String summaryAttention(int count);

  /// No description provided for @summaryAllClear.
  ///
  /// In es, this message translates to:
  /// **'Todos tus sistemas están en rango'**
  String get summaryAllClear;

  /// No description provided for @sourceChip.
  ///
  /// In es, this message translates to:
  /// **'Fuente: NASA HRP'**
  String get sourceChip;

  /// No description provided for @sourceNoteTitle.
  ///
  /// In es, this message translates to:
  /// **'Sobre esta información'**
  String get sourceNoteTitle;

  /// No description provided for @sourceNoteBody.
  ///
  /// In es, this message translates to:
  /// **'Las explicaciones se basan en publicaciones del Human Research Program (HRP) de NASA. Los umbrales de alerta de esta app son supuestos de diseño, no valores oficiales de vuelo. TIRELUS no diagnostica: te ayuda a decidir a quién avisar.'**
  String get sourceNoteBody;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @noDataMeasure.
  ///
  /// In es, this message translates to:
  /// **'Sin dato · medir'**
  String get noDataMeasure;

  /// No description provided for @errorEngine.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer el servidor Python local.'**
  String get errorEngine;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando…'**
  String get loading;

  /// No description provided for @taskPending.
  ///
  /// In es, this message translates to:
  /// **'PENDIENTE · {time}'**
  String taskPending(String time);

  /// No description provided for @taskToday.
  ///
  /// In es, this message translates to:
  /// **'HOY · {time}'**
  String taskToday(String time);

  /// No description provided for @exerciseLabel.
  ///
  /// In es, this message translates to:
  /// **'EJERCICIO'**
  String get exerciseLabel;

  /// No description provided for @exerciseProgress.
  ///
  /// In es, this message translates to:
  /// **'{hours} h {minutes} min de ~2 h'**
  String exerciseProgress(int hours, int minutes);

  /// No description provided for @streakLabel.
  ///
  /// In es, this message translates to:
  /// **'RACHA DE REGISTRO'**
  String get streakLabel;

  /// No description provided for @streakDays.
  ///
  /// In es, this message translates to:
  /// **'días'**
  String get streakDays;

  /// No description provided for @streakBadge.
  ///
  /// In es, this message translates to:
  /// **'Insignia «Constancia orbital»'**
  String get streakBadge;

  /// No description provided for @measTitle.
  ///
  /// In es, this message translates to:
  /// **'Registra tu lectura'**
  String get measTitle;

  /// No description provided for @measStepCounter.
  ///
  /// In es, this message translates to:
  /// **'Paso {step} de {total} · {title}'**
  String measStepCounter(int step, int total, String title);

  /// No description provided for @measStep1Title.
  ///
  /// In es, this message translates to:
  /// **'Prepárate'**
  String get measStep1Title;

  /// No description provided for @measStep1Detail.
  ///
  /// In es, this message translates to:
  /// **'5 min en reposo, anclado con los pies en la barra'**
  String get measStep1Detail;

  /// No description provided for @measStep2Title.
  ///
  /// In es, this message translates to:
  /// **'Coloca el brazalete'**
  String get measStep2Title;

  /// No description provided for @measStep2Detail.
  ///
  /// In es, this message translates to:
  /// **'Brazo izquierdo, 2 cm sobre el codo'**
  String get measStep2Detail;

  /// No description provided for @measStep3Title.
  ///
  /// In es, this message translates to:
  /// **'Mide y registra'**
  String get measStep3Title;

  /// No description provided for @measStep3Detail.
  ///
  /// In es, this message translates to:
  /// **'Lee el monitor o la prenda Bio-Monitor'**
  String get measStep3Detail;

  /// No description provided for @measStep4Title.
  ///
  /// In es, this message translates to:
  /// **'Resultado'**
  String get measStep4Title;

  /// No description provided for @measStep4Detail.
  ///
  /// In es, this message translates to:
  /// **'Qué significa y qué hacer'**
  String get measStep4Detail;

  /// No description provided for @measNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get measNext;

  /// No description provided for @measBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get measBack;

  /// No description provided for @measSeeResult.
  ///
  /// In es, this message translates to:
  /// **'Ver resultado'**
  String get measSeeResult;

  /// No description provided for @measSys.
  ///
  /// In es, this message translates to:
  /// **'Sistólica'**
  String get measSys;

  /// No description provided for @measDia.
  ///
  /// In es, this message translates to:
  /// **'Diastólica'**
  String get measDia;

  /// No description provided for @measHr.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia cardiaca'**
  String get measHr;

  /// No description provided for @measSource.
  ///
  /// In es, this message translates to:
  /// **'Fuente del dato'**
  String get measSource;

  /// No description provided for @measSourceManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get measSourceManual;

  /// No description provided for @measSourceWearable.
  ///
  /// In es, this message translates to:
  /// **'Wearable (ejemplo)'**
  String get measSourceWearable;

  /// No description provided for @measSourceUltrasound.
  ///
  /// In es, this message translates to:
  /// **'Ultrasonido (ejemplo)'**
  String get measSourceUltrasound;

  /// No description provided for @keypadBackspace.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get keypadBackspace;

  /// No description provided for @keypadNextField.
  ///
  /// In es, this message translates to:
  /// **'Siguiente campo'**
  String get keypadNextField;

  /// No description provided for @measFillRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe la sistólica y la diastólica.'**
  String get measFillRequired;

  /// No description provided for @measSysLtDia.
  ///
  /// In es, this message translates to:
  /// **'La sistólica debe ser mayor que la diastólica.'**
  String get measSysLtDia;

  /// No description provided for @measConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que es {value}?'**
  String measConfirmTitle(String value);

  /// No description provided for @measConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Ese valor es poco común. Revisa el monitor antes de guardarlo.'**
  String get measConfirmBody;

  /// No description provided for @measConfirmFix.
  ///
  /// In es, this message translates to:
  /// **'Corregir'**
  String get measConfirmFix;

  /// No description provided for @measConfirmKeep.
  ///
  /// In es, this message translates to:
  /// **'Sí, es correcto'**
  String get measConfirmKeep;

  /// No description provided for @rangeTitle.
  ///
  /// In es, this message translates to:
  /// **'Sistólica frente a tu rango personal'**
  String get rangeTitle;

  /// No description provided for @rangeOver.
  ///
  /// In es, this message translates to:
  /// **'+{delta} sobre tu base'**
  String rangeOver(String delta);

  /// No description provided for @rangeInside.
  ///
  /// In es, this message translates to:
  /// **'dentro de tu base'**
  String get rangeInside;

  /// No description provided for @rangeBase.
  ///
  /// In es, this message translates to:
  /// **'Tu rango prevuelo {low}–{high}'**
  String rangeBase(String low, String high);

  /// No description provided for @resultNominal.
  ///
  /// In es, this message translates to:
  /// **'Dentro de tu rango. Sigue con tu rutina.'**
  String get resultNominal;

  /// No description provided for @resultAtencion.
  ///
  /// In es, this message translates to:
  /// **'Repite la medición tras 5 min en reposo. Si sigue sobre tu base 3 días, TIRELUS la agrega al resumen de tu conferencia médica.'**
  String get resultAtencion;

  /// No description provided for @resultCritico.
  ///
  /// In es, this message translates to:
  /// **'Está muy por encima de tu base. TIRELUS no diagnostica: repite la medición en reposo y avisa a tu CMO.'**
  String get resultCritico;

  /// No description provided for @resultNoData.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay base para comparar esta lectura. Guárdala para que TIRELUS la tenga como referencia.'**
  String get resultNoData;

  /// No description provided for @repeatIn5.
  ///
  /// In es, this message translates to:
  /// **'Repetir en 5 min'**
  String get repeatIn5;

  /// No description provided for @repeatCountdown.
  ///
  /// In es, this message translates to:
  /// **'Repetir en {time}'**
  String repeatCountdown(String time);

  /// No description provided for @repeatCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar recordatorio'**
  String get repeatCancel;

  /// No description provided for @repeatDue.
  ///
  /// In es, this message translates to:
  /// **'Es hora de repetir tu medición.'**
  String get repeatDue;

  /// No description provided for @measSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar medición'**
  String get measSave;

  /// No description provided for @savedOk.
  ///
  /// In es, this message translates to:
  /// **'Medición guardada. Dentro de tu rango.'**
  String get savedOk;

  /// No description provided for @savedSummary.
  ///
  /// In es, this message translates to:
  /// **'Medición guardada y agregada al resumen de tu conferencia médica.'**
  String get savedSummary;

  /// No description provided for @summaryEntry.
  ///
  /// In es, this message translates to:
  /// **'PA {sys}/{dia} mmHg · {status} frente a tu base'**
  String summaryEntry(String sys, String dia, String status);

  /// No description provided for @helpWhatTitle.
  ///
  /// In es, this message translates to:
  /// **'Qué estás midiendo'**
  String get helpWhatTitle;

  /// No description provided for @helpWhatBody.
  ///
  /// In es, this message translates to:
  /// **'La fuerza con la que la sangre empuja las arterias: el número alto al latir el corazón, el bajo entre latidos.'**
  String get helpWhatBody;

  /// No description provided for @helpWhyTitle.
  ///
  /// In es, this message translates to:
  /// **'Por qué importa aquí'**
  String get helpWhyTitle;

  /// No description provided for @helpWhyBody.
  ///
  /// In es, this message translates to:
  /// **'Sin gravedad, los líquidos suben hacia el pecho y la cabeza. El sistema cardiovascular se adapta y eso puede cambiar tus lecturas.'**
  String get helpWhyBody;

  /// No description provided for @helpTipTitle.
  ///
  /// In es, this message translates to:
  /// **'Consejo'**
  String get helpTipTitle;

  /// No description provided for @helpTipBody.
  ///
  /// In es, this message translates to:
  /// **'Mide a la misma hora y sin haber hecho ejercicio en los 30 min previos, para comparar contra tu base.'**
  String get helpTipBody;

  /// No description provided for @trendViewChart.
  ///
  /// In es, this message translates to:
  /// **'Gráfica'**
  String get trendViewChart;

  /// No description provided for @trendViewTable.
  ///
  /// In es, this message translates to:
  /// **'Tabla'**
  String get trendViewTable;

  /// No description provided for @trendRange7.
  ///
  /// In es, this message translates to:
  /// **'7 días'**
  String get trendRange7;

  /// No description provided for @trendRange14.
  ///
  /// In es, this message translates to:
  /// **'14 días'**
  String get trendRange14;

  /// No description provided for @trendToday.
  ///
  /// In es, this message translates to:
  /// **'{value} {unit} hoy'**
  String trendToday(String value, String unit);

  /// No description provided for @trendAvg7.
  ///
  /// In es, this message translates to:
  /// **'Promedio 7 días'**
  String get trendAvg7;

  /// No description provided for @trendOutDays.
  ///
  /// In es, this message translates to:
  /// **'Días fuera de rango'**
  String get trendOutDays;

  /// No description provided for @trendOutDaysValue.
  ///
  /// In es, this message translates to:
  /// **'{out} de {total}'**
  String trendOutDaysValue(int out, int total);

  /// No description provided for @trendStreakValue.
  ///
  /// In es, this message translates to:
  /// **'{days} días'**
  String trendStreakValue(int days);

  /// No description provided for @trendNoAlertTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin alertas'**
  String get trendNoAlertTitle;

  /// No description provided for @trendNoAlertBody.
  ///
  /// In es, this message translates to:
  /// **'Tus lecturas recientes están dentro de tu rango.'**
  String get trendNoAlertBody;

  /// No description provided for @trendAlertTitle.
  ///
  /// In es, this message translates to:
  /// **'{status}: tendencia sostenida'**
  String trendAlertTitle(String status);

  /// No description provided for @trendAlertBody.
  ///
  /// In es, this message translates to:
  /// **'Llevas {days} días seguidos {direction} tu rango prevuelo. No es una emergencia, pero conviene que tu flight surgeon lo vea.'**
  String trendAlertBody(int days, String direction);

  /// No description provided for @trendNoData.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay datos de ejemplo para esta métrica.'**
  String get trendNoData;

  /// No description provided for @trendMeasure.
  ///
  /// In es, this message translates to:
  /// **'Medir'**
  String get trendMeasure;

  /// No description provided for @trendPlanTitle.
  ///
  /// In es, this message translates to:
  /// **'PLAN SUGERIDO'**
  String get trendPlanTitle;

  /// No description provided for @trendPlanBody.
  ///
  /// In es, this message translates to:
  /// **'1. Mide dos veces al día (mañana y noche) durante 3 días.\n2. Registra sal en la dieta, sueño y estrés del día.\n3. Comparte el resumen en tu conferencia médica privada.'**
  String get trendPlanBody;

  /// No description provided for @trendAddSummary.
  ///
  /// In es, this message translates to:
  /// **'Agregar al resumen médico'**
  String get trendAddSummary;

  /// No description provided for @trendAddedSummary.
  ///
  /// In es, this message translates to:
  /// **'Agregado al resumen médico.'**
  String get trendAddedSummary;

  /// No description provided for @trendSummaryEntry.
  ///
  /// In es, this message translates to:
  /// **'{metric}: {days} días {direction} la base (hoy {value} {unit})'**
  String trendSummaryEntry(
    String metric,
    int days,
    String direction,
    String value,
    String unit,
  );

  /// No description provided for @trendHoldCmo.
  ///
  /// In es, this message translates to:
  /// **'Mantén presionado para avisar al CMO'**
  String get trendHoldCmo;

  /// No description provided for @trendCmoQueued.
  ///
  /// In es, this message translates to:
  /// **'Aviso al CMO en camino. Puedes deshacerlo.'**
  String get trendCmoQueued;

  /// No description provided for @trendCmoUndo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get trendCmoUndo;

  /// No description provided for @trendCmoSent.
  ///
  /// In es, this message translates to:
  /// **'Aviso enviado al CMO de la tripulación.'**
  String get trendCmoSent;

  /// No description provided for @trendCmoCancelled.
  ///
  /// In es, this message translates to:
  /// **'Aviso cancelado.'**
  String get trendCmoCancelled;

  /// No description provided for @trendExport.
  ///
  /// In es, this message translates to:
  /// **'Exportar resumen'**
  String get trendExport;

  /// No description provided for @trendExported.
  ///
  /// In es, this message translates to:
  /// **'Resumen copiado al portapapeles'**
  String get trendExported;

  /// No description provided for @trendSummaryBoxTitle.
  ///
  /// In es, this message translates to:
  /// **'RESUMEN PARA LA CONFERENCIA MÉDICA'**
  String get trendSummaryBoxTitle;

  /// No description provided for @trendPointDetail.
  ///
  /// In es, this message translates to:
  /// **'Día {day} · {value} {unit}'**
  String trendPointDetail(int day, String value, String unit);

  /// No description provided for @trendInRange.
  ///
  /// In es, this message translates to:
  /// **'Dentro de tu rango'**
  String get trendInRange;

  /// No description provided for @trendOutOfRange.
  ///
  /// In es, this message translates to:
  /// **'Fuera de tu rango'**
  String get trendOutOfRange;

  /// No description provided for @trendPrev.
  ///
  /// In es, this message translates to:
  /// **'Punto anterior'**
  String get trendPrev;

  /// No description provided for @trendNext.
  ///
  /// In es, this message translates to:
  /// **'Punto siguiente'**
  String get trendNext;

  /// No description provided for @trendChartSemantics.
  ///
  /// In es, this message translates to:
  /// **'{label} de los últimos {n} días: de {first} a {last}; rango prevuelo {low} a {high}'**
  String trendChartSemantics(
    String label,
    int n,
    String first,
    String last,
    String low,
    String high,
  );

  /// No description provided for @trendTableDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get trendTableDay;

  /// No description provided for @trendTableValue.
  ///
  /// In es, this message translates to:
  /// **'Valor'**
  String get trendTableValue;

  /// No description provided for @trendTableState.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get trendTableState;

  /// No description provided for @exportHeader.
  ///
  /// In es, this message translates to:
  /// **'RESUMEN PARA LA CONFERENCIA MÉDICA · TIRELUS'**
  String get exportHeader;

  /// No description provided for @exportDay.
  ///
  /// In es, this message translates to:
  /// **'Día de misión {day}'**
  String exportDay(int day);

  /// No description provided for @exportSampleNote.
  ///
  /// In es, this message translates to:
  /// **'Datos de ejemplo. Los umbrales son supuestos de diseño; TIRELUS no diagnostica.'**
  String get exportSampleNote;

  /// No description provided for @exportMetricLine.
  ///
  /// In es, this message translates to:
  /// **'{metric}: hoy {value} {unit}; rango prevuelo {low}–{high}; promedio 7 días {avg}'**
  String exportMetricLine(
    String metric,
    String value,
    String unit,
    String low,
    String high,
    String avg,
  );

  /// No description provided for @exportDaysLine.
  ///
  /// In es, this message translates to:
  /// **'{out} de {total} días fuera de rango; {streak} días seguidos sobre la base.'**
  String exportDaysLine(int out, int total, int streak);

  /// No description provided for @exportItemsHeader.
  ///
  /// In es, this message translates to:
  /// **'Registros para comentar:'**
  String get exportItemsHeader;

  /// No description provided for @exportNoItems.
  ///
  /// In es, this message translates to:
  /// **'Sin registros pendientes.'**
  String get exportNoItems;

  /// No description provided for @trendExportedFile.
  ///
  /// In es, this message translates to:
  /// **'Resumen copiado al portapapeles ({filename}). Solo para ti, el CMO y el flight surgeon.'**
  String trendExportedFile(String filename);

  /// No description provided for @trendStreakLabel.
  ///
  /// In es, this message translates to:
  /// **'Racha {direction} tu base'**
  String trendStreakLabel(String direction);

  /// No description provided for @dirAbove.
  ///
  /// In es, this message translates to:
  /// **'sobre'**
  String get dirAbove;

  /// No description provided for @dirBelow.
  ///
  /// In es, this message translates to:
  /// **'bajo'**
  String get dirBelow;

  /// No description provided for @trendPlanSleep.
  ///
  /// In es, this message translates to:
  /// **'1. Revisa luz, ruido y temperatura de tu estación de descanso.\n2. Respeta tu periodo de sueño programado durante 3 noches.\n3. Comparte el resumen en tu conferencia médica privada.'**
  String get trendPlanSleep;

  /// No description provided for @trendPlanDefault.
  ///
  /// In es, this message translates to:
  /// **'1. Repite la medición a la misma hora durante 3 días.\n2. Anota lo que pudo influir (sueño, carga de trabajo, ejercicio).\n3. Comparte el resumen en tu conferencia médica privada.'**
  String get trendPlanDefault;

  /// No description provided for @navEyes.
  ///
  /// In es, this message translates to:
  /// **'Ojos'**
  String get navEyes;

  /// No description provided for @rangeUnder.
  ///
  /// In es, this message translates to:
  /// **'{delta} bajo tu base'**
  String rangeUnder(String delta);

  /// No description provided for @measGenericSummaryEntry.
  ///
  /// In es, this message translates to:
  /// **'{metric}: {value} {unit} · {status} frente a tu base'**
  String measGenericSummaryEntry(
    String metric,
    String value,
    String unit,
    String status,
  );

  /// No description provided for @measSavedOk.
  ///
  /// In es, this message translates to:
  /// **'Medición guardada.'**
  String get measSavedOk;

  /// No description provided for @measSavedAdded.
  ///
  /// In es, this message translates to:
  /// **'Medición guardada y agregada al resumen de tu conferencia médica.'**
  String get measSavedAdded;

  /// No description provided for @measNoBase.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay línea base prevuelo para esta métrica, así que no hay contra qué comparar.'**
  String get measNoBase;

  /// No description provided for @measGenericRangeTitle.
  ///
  /// In es, this message translates to:
  /// **'{metric} frente a tu rango personal'**
  String measGenericRangeTitle(String metric);

  /// No description provided for @measRuleOrigin.
  ///
  /// In es, this message translates to:
  /// **'DE DÓNDE SALE LA REGLA'**
  String get measRuleOrigin;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
