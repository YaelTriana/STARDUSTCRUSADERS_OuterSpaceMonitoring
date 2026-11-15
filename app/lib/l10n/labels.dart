import 'package:flutter/widgets.dart';

import '../data/models.dart';
import 'app_localizations.dart';
import 'app_localizations_es.dart';

/// Etiquetas traducidas de los enums de la UI (los `label` de models.dart
/// quedan solo como respaldo sin contexto).
extension AppLocalizationsLabels on AppLocalizations {
  /// "sobre" / "bajo" según la dirección que preocupa de la métrica.
  String direction(bool alertsWhenBelow) => alertsWhenBelow ? dirBelow : dirAbove;

  String status(VStatus s) => switch (s) {
        VStatus.nominal => statusNominal,
        VStatus.atencion => statusAttention,
        VStatus.critico => statusCritical,
        VStatus.sinDato => statusNoData,
      };

  String envLabel(MissionEnv e) => switch (e) {
        MissionEnv.iss => envIss,
        MissionEnv.luna => envMoon,
        MissionEnv.marte => envMars,
      };

  String envDelay(MissionEnv e) => switch (e) {
        MissionEnv.iss => delayRealtime,
        MissionEnv.luna => delayMoon,
        MissionEnv.marte => delayMars,
      };
}

extension L10nContext on BuildContext {
  /// Textos de TIRELUS. Si el árbol no trae los delegados de idioma (p. ej. una prueba con
  /// un MaterialApp simple), cae en español en vez de tronar.
  AppLocalizations get l10n => Localizations.of<AppLocalizations>(this, AppLocalizations) ?? AppLocalizationsEs();
}
