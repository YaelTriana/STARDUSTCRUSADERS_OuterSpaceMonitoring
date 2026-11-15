import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/app_state.dart';
import 'package:tirelus/screens/sans_screen.dart';
import 'package:tirelus/theme.dart';

import 'fake_api.dart';

Future<void> _pump(WidgetTester tester, FakeApi api, {double width = 1300}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
    state: AppState(api),
    child: MaterialApp(theme: tirelusTheme(), home: const Scaffold(body: SansScreen())),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('evalúa el cambio de grosor con Python y muestra el estado', (tester) async {
    final api = FakeApi(sansStatus: 'atencion');
    await _pump(tester, api);
    await tester.enterText(find.byKey(const Key('sans-input')), '22');
    await tester.pumpAndSettle();
    expect(api.evaluated['sans'], 22);
    expect(find.text('Atención'), findsWidgets);
  });

  testWidgets('escribe el valor con su estado, no solo con color', (tester) async {
    await _pump(tester, FakeApi(sansStatus: 'critico'));
    await tester.enterText(find.byKey(const Key('sans-input')), '58');
    await tester.pumpAndSettle();
    expect(find.textContaining('Tu valor: +58 µm · Crítico'), findsOneWidget);
    expect(find.text('Crítico: avisa hoy a tu CMO'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
  });

  testWidgets('muestra los umbrales publicados y su fuente', (tester) async {
    await _pump(tester, FakeApi());
    expect(find.textContaining('+20 µm'), findsWidgets);
    expect(find.textContaining('55 µm'), findsWidgets);
    expect(find.textContaining('Umbrales publicados de SANS'), findsOneWidget);
  });

  testWidgets('sin serie de OCT avisa que no hay datos', (tester) async {
    await _pump(tester, FakeApi());
    expect(find.textContaining('Aún no hay OCT de ejemplo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pantalla angosta sin desbordes', (tester) async {
    await _pump(tester, FakeApi(), width: 360);
    expect(tester.takeException(), isNull);
  });
}
