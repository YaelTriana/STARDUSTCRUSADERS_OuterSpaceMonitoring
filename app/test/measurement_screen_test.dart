import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/app_state.dart';
import 'package:tirelus/l10n/app_localizations.dart';
import 'package:tirelus/screens/measurement_screen.dart';
import 'package:tirelus/theme.dart';

import 'fake_api.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeApi api, {
  String metric = 'systolic',
  double width = 1300,
  double height = 1600,
  Locale locale = const Locale('es'),
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
    state: AppState(api),
    child: MaterialApp(
      theme: tirelusTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MeasurementScreen(initialMetric: metric)),
    ),
  ));
  await tester.pumpAndSettle();
}

FakeApi _api({String evalStatus = 'nominal'}) => FakeApi(evalStatus: evalStatus, trends: {
      'systolic': trendJson(),
      'sleep_hours': trendJson(
        metric: 'sleep_hours', label: 'Horas de sueño', unit: 'h', alertWhen: 'below',
        series: [7.5, 6.2, 6.0, 5.8], base: {'low': 6.5, 'high': 8.5}, above: 0, below: 3,
      ),
      'mood': trendJson(metric: 'mood', label: 'Ánimo (1–5)', unit: 'pts', series: [], base: null, status: 'sin_dato', above: 0),
    });

void main() {
  testWidgets('presión arterial abre el asistente de pasos con el teclado táctil', (tester) async {
    await _pump(tester, _api());
    expect(find.textContaining('Paso 1 de 4'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Diastólica'), findsWidgets);
    expect(find.byKey(const ValueKey('key-5')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('otra métrica usa un campo con su unidad y evalúa en Python', (tester) async {
    final api = _api(evalStatus: 'atencion');
    await _pump(tester, api, metric: 'sleep_hours');
    expect(find.text('Horas de sueño (h)'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('generic-input')), '5.8');
    await tester.pumpAndSettle();
    expect(api.evaluated['sleep_hours'], 5.8);
    expect(find.text('Atención'), findsWidgets);
    expect(find.textContaining('6.5–8.5'), findsOneWidget);
  });

  testWidgets('métrica sin línea base lo dice y no evalúa', (tester) async {
    final api = _api();
    await _pump(tester, api, metric: 'mood');
    expect(find.textContaining('Aún no hay línea base'), findsOneWidget);
    expect(api.evaluated, isEmpty);
  });

  testWidgets('el selector cambia de métrica y en angosto no se desborda', (tester) async {
    await _pump(tester, _api(), width: 360);
    await tester.tap(find.byKey(const Key('metric-sleep_hours')));
    await tester.pumpAndSettle();
    expect(find.text('Horas de sueño (h)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('es'), const Locale('en')]) {
    testWidgets('1366x768 sin desbordes en ${locale.languageCode} (campo activo resaltado)', (tester) async {
      await _pump(tester, _api(), width: 1366, height: 768, locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
