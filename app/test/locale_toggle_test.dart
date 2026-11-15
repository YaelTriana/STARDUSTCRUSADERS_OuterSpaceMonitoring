import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/app_state.dart';
import 'package:tirelus/main.dart';

import 'fake_api.dart';

/// FakeApi no abre red real; el arranque solo necesita no colgarse
/// esperando /health contra 'http://fake.invalid'.
class _ReadyFakeApi extends FakeApi {
  _ReadyFakeApi({super.trends});

  @override
  Future<void> waitUntilReady({Duration timeout = const Duration(seconds: 30)}) async {}
}

void main() {
  testWidgets('el botón EN/ES cambia el idioma del Shell', (tester) async {
    final api = _ReadyFakeApi(trends: {'systolic': trendJson()});

    await tester.pumpWidget(TirelusApp(state: AppState(api)));
    await tester.pumpAndSettle();

    expect(find.text('Panel'), findsWidgets);
    expect(find.widgetWithText(TextButton, 'EN'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'EN'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.widgetWithText(TextButton, 'ES'), findsOneWidget);
  });

  testWidgets('el Shell a 1366x768 no genera excepciones de layout', (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final api = _ReadyFakeApi(trends: {'systolic': trendJson()});
    await tester.pumpWidget(TirelusApp(state: AppState(api)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
