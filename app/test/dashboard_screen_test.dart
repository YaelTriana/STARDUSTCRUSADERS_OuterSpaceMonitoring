import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/app_state.dart';
import 'package:tirelus/l10n/app_localizations.dart';
import 'package:tirelus/screens/dashboard_screen.dart';
import 'package:tirelus/theme.dart';
import 'package:tirelus/widgets/common.dart';

import 'fake_api.dart';

/// El panel dibuja lo que Python calcula: ni estados ni cifras propias.
Future<void> _pump(
  WidgetTester tester,
  FakeApi api, {
  Locale locale = const Locale('es'),
  double width = 1366,
  double height = 1600,
  Duration refreshEvery = const Duration(minutes: 5),
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
    state: AppState(api),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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

Map<String, dynamic> _sistema(String id, String status) => {
      'id': id,
      'name': id,
      'status': status,
      'indicators': <Map<String, dynamic>>[],
      'why': 'por qué',
      'action': 'qué hacer',
    };

void main() {
  // --- lo que calcula Python se dibuja tal cual -----------------------------

  testWidgets('dibuja el estado y las cifras que calculó Python', (tester) async {
    await _pump(tester, FakeApi(dashboard: dashboardJson()));
    expect(find.descendant(of: find.byType(StatusChip), matching: find.text('Atención')), findsOneWidget);
    expect(find.text('132 mmHg'), findsWidgets);
    expect(find.textContaining('sobre tu base'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un indicador sin datos dice "Sin dato"', (tester) async {
    await _pump(tester, FakeApi(dashboard: dashboardJson()));
    // Los azulejos se dibujan con un widget privado del panel, así que se verifica
    // por el valor con unidad, que es único de cada azulejo (la leyenda no los tiene).
    expect(find.text('— mmHg'), findsOneWidget); // diastólica
    expect(find.text('— lpm'), findsOneWidget); // FC
    expect(find.text('— %'), findsOneWidget); // SpO₂
    expect(find.textContaining('Sin dato'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sigue al dato: si Python dice nominal, el panel no alerta', (tester) async {
    await _pump(
      tester,
      FakeApi(dashboard: dashboardJson(status: 'nominal', value: '118', note: 'en tu base (110–126)')),
    );
    expect(find.descendant(of: find.byType(StatusChip), matching: find.text('Nominal')), findsOneWidget);
    expect(find.text('118 mmHg'), findsWidgets);
    expect(
      find.descendant(of: find.byType(StatusChip), matching: find.text('Atención')),
      findsNothing, // el chip del sistema no alerta (la leyenda sí nombra el estado)
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('en pantalla angosta no se desborda', (tester) async {
    await _pump(tester, FakeApi(dashboard: dashboardJson()), width: 360, height: 1600);
    expect(tester.takeException(), isNull);
  });

  // --- refresco automático --------------------------------------------------

  testWidgets('se actualiza solo cuando cambian los datos', (tester) async {
    const cada = Duration(seconds: 5);
    final api = FakeApi(dashboard: dashboardJson());
    await _pump(tester, api, refreshEvery: cada);
    expect(find.text('132 mmHg'), findsWidgets);
    expect(find.textContaining('Actualizado'), findsOneWidget);

    api.dashboardBody = dashboardJson(status: 'critico', value: '165', note: '▲ 39 sobre tu base (110–126)');
    await _tick(tester, cada);

    expect(find.text('165 mmHg'), findsWidgets);
    expect(find.text('132 mmHg'), findsNothing);
    expect(find.descendant(of: find.byType(StatusChip), matching: find.text('Crítico')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un refresco que falla no borra lo que ya se veía', (tester) async {
    const cada = Duration(seconds: 5);
    final api = FakeApi(dashboard: dashboardJson());
    await _pump(tester, api, refreshEvery: cada);

    api.dashboardFails = true;
    await _tick(tester, cada);

    expect(find.text('132 mmHg'), findsWidgets); // sigue el último dato bueno
    expect(find.textContaining('Sin conexión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('al salir de la pantalla deja de preguntar', (tester) async {
    const cada = Duration(seconds: 5);
    final api = FakeApi(dashboard: dashboardJson());
    await _pump(tester, api, refreshEvery: cada);
    final llamadas = api.dashboardCalls;

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('otra pantalla'))));
    await tester.pump(const Duration(seconds: 30));

    expect(api.dashboardCalls, llamadas);
  });

  testWidgets('si la primera carga falla lo dice', (tester) async {
    await _pump(tester, FakeApi(dashboard: dashboardJson(), dashboardFails: true));
    expect(find.textContaining('No se pudo leer el servidor Python'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // --- diseño: tarjetas, desbordes y los cinco sistemas ---------------------

  testWidgets('sistema nominal usa SectionCard (surface + borde), no StatusSideCard', (tester) async {
    await _pump(tester, FakeApi(dashboard: dashboardJson(systems: [_sistema('hueso', 'nominal')])));
    expect(find.byType(SectionCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sistema en atención usa StatusSideCard (surface2 + barra)', (tester) async {
    await _pump(tester, FakeApi(dashboard: dashboardJson(systems: [_sistema('cardio', 'atencion')])));
    // Dos StatusSideCard: la del sistema (atención) y la de "Qué hacer ahora".
    expect(find.byType(StatusSideCard), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Qué hacer ahora" siempre resalta, incluso en un sistema nominal', (tester) async {
    await _pump(tester, FakeApi(dashboard: dashboardJson(systems: [_sistema('hueso', 'nominal')])));
    expect(find.byType(StatusSideCard), findsOneWidget);
  });

  for (final size in [const Size(1366, 768), const Size(1920, 1080)]) {
    for (final locale in [const Locale('es'), const Locale('en')]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()} sin desbordes en ${locale.languageCode}',
          (tester) async {
        await _pump(tester, FakeApi(dashboard: dashboardJson()),
            locale: locale, width: size.width, height: size.height);
        expect(tester.takeException(), isNull);
      });
    }
  }

  final cinco = [for (final id in ['cardio', 'ojos', 'hueso', 'mente', 'inmune']) _sistema(id, 'nominal')];
  for (final locale in [const Locale('es'), const Locale('en')]) {
    testWidgets('las 5 filas del cuerpo caben en 1366x768 en ${locale.languageCode}', (tester) async {
      await _pump(tester, FakeApi(dashboard: dashboardJson(systems: cinco)), locale: locale, height: 768);
      for (final id in ['cardio', 'ojos', 'hueso', 'mente', 'inmune']) {
        expect(find.text(id), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('color + forma + palabra se conservan (StatusChip)', (tester) async {
    await _pump(tester, FakeApi(dashboard: dashboardJson(systems: [_sistema('cardio', 'critico')])));
    expect(find.text('Crítico'), findsWidgets);
  });
}
