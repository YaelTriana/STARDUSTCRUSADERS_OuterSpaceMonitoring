import 'package:flutter/widgets.dart';

import 'api.dart';
import 'data/models.dart';

/// Estado global mínimo del mockup (sin paquete de gestión de estado:
/// el equipo decidirá entre Riverpod o Bloc después).
class AppState extends ChangeNotifier {
  AppState(this.api);

  final TirelusApi api;

  MissionEnv env = MissionEnv.iss;
  Locale locale = const Locale('es');
  String selectedSystem = 'cardio';
  List<String> medicalSummary = [];

  void setLocale(Locale value) {
    locale = value;
    api.lang = value.languageCode;
    notifyListeners();
  }

  void toggleLocale() => setLocale(locale.languageCode == 'es' ? const Locale('en') : const Locale('es'));

  void setEnv(MissionEnv value) {
    env = value;
    notifyListeners();
  }

  void selectSystem(String id) {
    selectedSystem = id;
    notifyListeners();
  }

  Future<void> addToSummary(String item) async {
    medicalSummary = await api.addToSummary(item);
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
