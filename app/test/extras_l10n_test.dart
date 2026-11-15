import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/app_state.dart';
import 'package:tirelus/screens/base_screen.dart';
import 'package:tirelus/screens/eva_screens.dart';

import 'fake_api.dart';
import 'test_helpers.dart';

Future<void> _pump(WidgetTester tester, Widget screen, Locale locale) async {
  tester.view.physicalSize = const Size(1400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
    state: AppState(FakeApi()),
    child: localizedApp(locale: locale, home: Scaffold(body: screen)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Base en español', (tester) async {
    await _pump(tester, const BaseScreen(), const Locale('es'));
    expect(find.text('Tripulación'), findsOneWidget);
    expect(find.text('AGENDA MÉDICA DE HOY'), findsOneWidget);
  });

  testWidgets('Base en inglés', (tester) async {
    await _pump(tester, const BaseScreen(), const Locale('en'));
    expect(find.text('Crew'), findsOneWidget);
    expect(find.text("TODAY'S MEDICAL AGENDA"), findsOneWidget);
    expect(find.text('Tripulación'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('De mano en inglés', (tester) async {
    await _pump(tester, const HandheldScreen(), const Locale('en'));
    expect(find.text('Call the CMO'), findsOneWidget);
    expect(find.text('Llamar al CMO'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Visor en inglés', (tester) async {
    await _pump(tester, const VisorScreen(), const Locale('en'));
    expect(find.textContaining('FUTURE CONCEPT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
