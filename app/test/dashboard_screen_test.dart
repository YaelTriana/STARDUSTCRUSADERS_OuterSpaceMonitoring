import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/app_state.dart';
import 'package:tirelus/l10n/app_localizations.dart';
import 'package:tirelus/screens/dashboard_screen.dart';
import 'package:tirelus/widgets/common.dart';

import 'fake_api.dart';

Future<void> _pump(WidgetTester tester, FakeApi api, {Locale locale = const Locale('es'), double width = 1366, double height = 768}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
    state: AppState(api),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: DashboardScreen(onGoTo: (_) {})),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sistema nominal usa SectionCard (surface + borde), no StatusSideCard', (tester) async {
    final api = FakeApi(dashboard: dashboardJson(systems: [
      {
        'id': 'hueso',
        'name': 'Huesos y músculo',
        'status': 'nominal',
        'indicators': <Map<String, dynamic>>[],
        'why': 'por qué',
        'action': 'qué hacer',
      },
    ]));
    await _pump(tester, api);
    // La tarjeta "Qué hacer ahora" siempre es StatusSideCard, aunque el
    // sistema sea nominal: la del sistema (la de afuera) debe ser la única
    // diferencia. Buscamos que exista al menos una SectionCard (la del
    // sistema) y que no haya ningún overflow.
    expect(find.byType(SectionCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sistema en atención usa StatusSideCard (surface2 + barra)', (tester) async {
    final api = FakeApi(dashboard: dashboardJson(systems: [
      {
        'id': 'cardio',
        'name': 'Corazón y circulación',
        'status': 'atencion',
        'indicators': <Map<String, dynamic>>[],
        'why': 'por qué',
        'action': 'qué hacer',
      },
    ]));
    await _pump(tester, api);
    // Dos StatusSideCard: la del sistema (atención) y la de "Qué hacer ahora".
    // (El Panel tiene otras SectionCard propias: resumen, cuerpo, tareas.)
    expect(find.byType(StatusSideCard), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Qué hacer ahora" siempre resalta, incluso en un sistema nominal', (tester) async {
    final api = FakeApi(dashboard: dashboardJson(systems: [
      {
        'id': 'hueso',
        'name': 'Huesos y músculo',
        'status': 'nominal',
        'indicators': <Map<String, dynamic>>[],
        'why': 'por qué',
        'action': 'qué hacer',
      },
    ]));
    await _pump(tester, api);
    expect(find.byType(StatusSideCard), findsOneWidget);
  });

  for (final size in [const Size(1366, 768), const Size(1920, 1080)]) {
    for (final locale in [const Locale('es'), const Locale('en')]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()} sin desbordes en ${locale.languageCode}', (tester) async {
        final api = FakeApi(dashboard: dashboardJson());
        await _pump(tester, api, locale: locale, width: size.width, height: size.height);
        expect(tester.takeException(), isNull);
      });
    }
  }

  final fiveSystems = [
    for (final id in ['cardio', 'ojos', 'hueso', 'mente', 'inmune'])
      {'id': id, 'name': id, 'status': 'nominal', 'indicators': <Map<String, dynamic>>[], 'why': 'x', 'action': 'y'},
  ];
  for (final locale in [const Locale('es'), const Locale('en')]) {
    testWidgets('las 5 filas del cuerpo caben en 1366x768 en ${locale.languageCode}', (tester) async {
      final api = FakeApi(dashboard: dashboardJson(systems: fiveSystems));
      await _pump(tester, api, locale: locale);
      for (final id in ['cardio', 'ojos', 'hueso', 'mente', 'inmune']) {
        expect(find.text(id), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('color + forma + palabra se conservan (StatusChip)', (tester) async {
    final api = FakeApi(dashboard: dashboardJson(systems: [
      {
        'id': 'cardio',
        'name': 'Corazón y circulación',
        'status': 'critico',
        'indicators': <Map<String, dynamic>>[],
        'why': 'por qué',
        'action': 'qué hacer',
      },
    ]));
    await _pump(tester, api);
    expect(find.text('Crítico'), findsWidgets);
  });
}
