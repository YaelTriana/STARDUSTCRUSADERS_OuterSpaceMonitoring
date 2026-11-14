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
