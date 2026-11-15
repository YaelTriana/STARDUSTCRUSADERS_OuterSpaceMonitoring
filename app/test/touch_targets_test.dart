import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/app_state.dart';
import 'package:tirelus/data/models.dart';
import 'package:tirelus/l10n/app_localizations.dart';
import 'package:tirelus/screens/autonomous_screen.dart';
import 'package:tirelus/screens/measurement_screen.dart';
import 'package:tirelus/screens/sans_screen.dart';
import 'package:tirelus/screens/trend_screen.dart';
import 'package:tirelus/theme.dart';

import 'fake_api.dart';

/// Piso de área táctil del proyecto: 44 px (la meta de diseño es 48 dp).
const _floor = 44.0;

Future<void> _pump(WidgetTester tester, Widget screen, {MissionEnv env = MissionEnv.marte}) async {
  tester.view.physicalSize = const Size(1300, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final api = FakeApi(trends: {'systolic': trendJson()});
  await tester.pumpWidget(AppScope(
    state: AppState(api)..setEnv(env),
    child: MaterialApp(
      theme: tirelusTheme(),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: screen),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Todos los controles pulsables que pintamos con widgets de botón o chip.
void _expectBigEnough(WidgetTester tester) {
  final types = <Type>[ButtonStyleButton, IconButton, ChoiceChip];
  for (final type in types) {
    for (final e in find.byType(type).evaluate()) {
      final size = tester.getSize(find.byWidget(e.widget));
      expect(size.height, greaterThanOrEqualTo(_floor), reason: '$type de alto ${size.height} (${e.widget})');
      expect(size.width, greaterThanOrEqualTo(_floor), reason: '$type de ancho ${size.width} (${e.widget})');
    }
  }
}

void main() {
  testWidgets('Medición: botones y chips de al menos 44 px', (tester) async {
    await _pump(tester, const MeasurementScreen());
    _expectBigEnough(tester);
  });

  testWidgets('Tendencia: botones, chips y flechas de al menos 44 px', (tester) async {
    await _pump(tester, const TrendScreen());
    _expectBigEnough(tester);
  });

  testWidgets('Autónomo: botones de al menos 44 px', (tester) async {
    await _pump(tester, const AutonomousScreen());
    _expectBigEnough(tester);
  });

  testWidgets('SANS: botones de al menos 44 px', (tester) async {
    await _pump(tester, const SansScreen());
    _expectBigEnough(tester);
  });
}
