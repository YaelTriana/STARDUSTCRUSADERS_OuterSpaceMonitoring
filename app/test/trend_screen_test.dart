import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/app_state.dart';
import 'package:tirelus/l10n/app_localizations.dart';
import 'package:tirelus/screens/trend_screen.dart';
import 'package:tirelus/theme.dart';

import 'fake_api.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeApi api, {
  String metric = 'systolic',
  double width = 1300,
  double height = 1400,
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
      home: Scaffold(body: TrendScreen(initialMetric: metric)),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  final api = FakeApi(trends: {
    'systolic': trendJson(),
    'sleep_hours': trendJson(
      metric: 'sleep_hours', label: 'Horas de sueño', unit: 'h', alertWhen: 'below',
      series: [7.5, 6.2, 6.0, 5.8], base: {'low': 6.5, 'high': 8.5}, above: 0, below: 3,
    ),
    'mood': trendJson(metric: 'mood', label: 'Ánimo (1–5)', unit: 'pts', series: [], base: null, status: 'sin_dato', above: 0),
  });

  testWidgets('muestra la métrica que recibe como parámetro', (tester) async {
    await _pump(tester, api, metric: 'sleep_hours');
    expect(find.text('Horas de sueño'), findsWidgets);
    expect(find.textContaining('bajo tu rango'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('métrica sin datos muestra "Sin dato" sin tronar', (tester) async {
    await _pump(tester, api, metric: 'mood');
    expect(find.textContaining('Aún no hay datos de ejemplo'), findsOneWidget);
    expect(find.text('Agregar al resumen médico'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el selector cambia de métrica', (tester) async {
    await _pump(tester, api);
    expect(find.text('Presión sistólica'), findsWidgets);
    await tester.tap(find.byKey(const Key('metric-sleep_hours')));
    await tester.pumpAndSettle();
    expect(find.textContaining('bajo tu rango'), findsWidgets);
  });

  testWidgets('pantalla angosta sin desbordes', (tester) async {
    await _pump(tester, api, metric: 'sleep_hours', width: 360);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('es'), const Locale('en')]) {
    testWidgets('1366x768 sin desbordes en ${locale.languageCode} (plan sugerido con pasos numerados)', (tester) async {
      await _pump(tester, api, width: 1366, height: 768, locale: locale);
      // Tres pasos ("1.", "2.", "3.") pintados como círculos, no como texto plano.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
