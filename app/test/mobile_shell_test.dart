import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/app_state.dart';
import 'package:tirelus/l10n/app_localizations.dart';
import 'package:tirelus/main.dart';
import 'package:tirelus/theme.dart';

import 'fake_api.dart';

/// Tamaños de referencia de celulares Android reales (densidad lógica, no px
/// físicos): Samsung chico ~360x800, Samsung grande (S23/S24) ~412x915.
Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
    state: AppState(FakeApi()),
    child: MaterialApp(
      theme: tirelusTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Shell(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(360, 800), const Size(412, 915)]) {
    testWidgets('barra inferior móvil sin desbordes en ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await _pump(tester, size);
      expect(find.byType(NavigationBar), findsOneWidget);
      // Las 5 etiquetas (4 destinos + "Más") deben verse, nunca cortarse por overflow.
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
  }
}
