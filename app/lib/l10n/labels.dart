import '../data/models.dart';
import 'app_localizations.dart';

/// Etiquetas traducidas de los enums de la UI (los `label` de models.dart
/// quedan solo como respaldo sin contexto).
extension AppLocalizationsLabels on AppLocalizations {
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
