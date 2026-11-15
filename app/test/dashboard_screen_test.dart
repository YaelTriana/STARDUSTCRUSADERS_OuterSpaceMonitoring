import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/app_state.dart';
import 'package:tirelus/screens/dashboard_screen.dart';
import 'package:tirelus/theme.dart';
import 'package:tirelus/widgets/common.dart';

import 'fake_api.dart';

/// El panel dibuja lo que Python calcula: ni estados ni cifras propias.
Future<void> _pump(
  WidgetTester tester,
  FakeApi api, {
  double width = 1300,
  Duration refreshEvery = const Duration(minutes: 5),
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
    state: AppState(api),
    child: MaterialApp(
      theme: tirelusTheme(),
      home: Scaffold(body: DashboardScreen(onGoTo: (_) {}, refreshEvery: refreshEvery)),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Un ciclo de refresco: dispara el temporizador y deja resolver la petición.
Future<void> _tick(WidgetTester tester, Duration every) async {
  await tester.pump(every);
  await tester.pump();
}

void main() {
  testWidgets('dibuja el estado y las cifras que calculó Python', (tester) async {
    await _pump(tester, FakeApi(dashboardBody: dashboardJson()));
    expect(find.descendant(of: find.byType(StatusChip), matching: find.text('Atención')), findsOneWidget);
    expect(find.text('132 mmHg'), findsOneWidget);
    expect(find.textContaining('sobre tu base'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un indicador sin datos dice "Sin dato"', (tester) async {
    await _pump(tester, FakeApi(dashboardBody: dashboardJson()));
    expect(
      find.descendant(of: find.byType(MetricTile), matching: find.text('Sin dato')),
      findsNWidgets(3), // los tres azulejos sin datos; la leyenda no cuenta
    );
    expect(find.text('— lpm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sigue al dato: si Python dice nominal, el panel no alerta', (tester) async {
    await _pump(tester, FakeApi(dashboardBody: dashboardJson(status: 'nominal', value: '118', note: 'en tu base (110–126)')));
    expect(find.descendant(of: find.byType(StatusChip), matching: find.text('Nominal')), findsOneWidget);
    expect(find.text('118 mmHg'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(StatusChip), matching: find.text('Atención')),
      findsNothing, // el chip del sistema no alerta (la leyenda sí nombra el estado)
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('en pantalla angosta no se desborda', (tester) async {
    await _pump(tester, FakeApi(dashboardBody: dashboardJson()), width: 360);
    expect(tester.takeException(), isNull);
  });

  testWidgets('se actualiza solo cuando cambian los datos', (tester) async {
    const cada = Duration(seconds: 5);
    final api = FakeApi(dashboardBody: dashboardJson());
    await _pump(tester, api, refreshEvery: cada);
    expect(find.text('132 mmHg'), findsOneWidget);
    expect(find.textContaining('Actualizado'), findsOneWidget);

    api.dashboardBody = dashboardJson(status: 'critico', value: '165', note: '▲ 39 sobre tu base (110–126)');
    await _tick(tester, cada);

    expect(find.text('165 mmHg'), findsOneWidget);
    expect(find.text('132 mmHg'), findsNothing);
    expect(find.text('Crítico'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un refresco que falla no borra lo que ya se veía', (tester) async {
    const cada = Duration(seconds: 5);
    final api = FakeApi(dashboardBody: dashboardJson());
    await _pump(tester, api, refreshEvery: cada);

    api.dashboardFails = true;
    await _tick(tester, cada);

    expect(find.text('132 mmHg'), findsOneWidget); // sigue el último dato bueno
    expect(find.textContaining('Sin conexión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('al salir de la pantalla deja de preguntar', (tester) async {
    const cada = Duration(seconds: 5);
    final api = FakeApi(dashboardBody: dashboardJson());
    await _pump(tester, api, refreshEvery: cada);
    final llamadas = api.dashboardCalls;

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('otra pantalla'))));
    await tester.pump(const Duration(seconds: 30));

    expect(api.dashboardCalls, llamadas);
  });

  testWidgets('si la primera carga falla lo dice', (tester) async {
    await _pump(tester, FakeApi(dashboardBody: dashboardJson(), dashboardFails: true));
    expect(find.textContaining('No se pudo leer el servidor Python'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
