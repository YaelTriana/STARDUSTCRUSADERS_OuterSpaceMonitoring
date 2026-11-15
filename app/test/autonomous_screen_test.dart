import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/app_state.dart';
import 'package:tirelus/data/models.dart';
import 'package:tirelus/screens/autonomous_screen.dart';

import 'fake_api.dart';
import 'test_helpers.dart';

Future<void> _pump(WidgetTester tester, MissionEnv env, {double width = 1300}) async {
  tester.view.physicalSize = Size(width, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final state = AppState(FakeApi())..setEnv(env);
  await tester.pumpWidget(AppScope(
    state: state,
    child: localizedApp(home: const Scaffold(body: AutonomousScreen())),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('en ISS dice que el enlace es en tiempo real y mantiene el recordatorio', (tester) async {
    await _pump(tester, MissionEnv.iss);
    expect(find.text('Enlace con Tierra en tiempo real'), findsOneWidget);
    expect(find.textContaining('TIRELUS orienta, no diagnostica'), findsOneWidget);
  });

  testWidgets('en Marte muestra protocolo, decisión a bordo y el recordatorio permanente', (tester) async {
    await _pump(tester, MissionEnv.marte);
    expect(find.text('Visión borrosa de cerca'), findsOneWidget);
    expect(find.textContaining('TIRELUS orienta, no diagnostica'), findsOneWidget);
    expect(find.text('DECISIÓN A BORDO'), findsOneWidget);
    expect(find.textContaining('Datos de ejemplo'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Registrar y continuar" avanza el protocolo y agrega el paso al mensaje', (tester) async {
    await _pump(tester, MissionEnv.marte);
    expect(find.textContaining('Paso 2 de 3'), findsOneWidget);
    await tester.tap(find.text('Registrar y continuar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paso 3 de 3'), findsOneWidget);
    // El mensaje es un solo texto de varias líneas.
    expect(find.textContaining('✓ OCT con guía'), findsOneWidget);
  });

  testWidgets('pantalla angosta sin desbordes', (tester) async {
    await _pump(tester, MissionEnv.marte, width: 360);
    expect(tester.takeException(), isNull);
  });
}
