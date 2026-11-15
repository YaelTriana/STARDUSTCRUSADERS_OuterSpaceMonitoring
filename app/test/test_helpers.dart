import 'package:flutter/material.dart';
import 'package:tirelus/l10n/app_localizations.dart';

/// MaterialApp con los textos de TIRELUS (por defecto en español, como la demo).
MaterialApp localizedApp({required Widget home, Locale locale = const Locale('es')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
