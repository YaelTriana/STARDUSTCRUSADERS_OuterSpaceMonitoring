import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/api.dart';
import 'package:tirelus/app_state.dart';
import 'package:tirelus/data/models.dart';
import 'package:tirelus/widgets/env_selector.dart';

/// API falsa: el selector no llama al servidor, pero AppState la necesita.
class FakeApi extends TirelusApi {
  FakeApi() : super(baseUrl: 'http://fake.invalid');
}

Future<AppState> _pump(WidgetTester tester, {required double width}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final state = AppState(FakeApi());
  await tester.pumpWidget(AppScope(
    state: state,
    child: MaterialApp(
      home: Builder(builder: (context) {
        final s = AppScope.of(context);
        return Scaffold(
          appBar: AppBar(actions: [Center(child: EnvSelector(value: s.env, onChanged: s.setEnv))]),
        );
      }),
    ),
  ));
  return state;
}

void main() {
  testWidgets('pantalla ancha: botones segmentados con las 3 opciones completas', (tester) async {
    final state = await _pump(tester, width: 1200);
    expect(find.byType(SegmentedButton<MissionEnv>), findsOneWidget);
    for (final e in MissionEnv.values) {
      expect(find.text(e.label), findsOneWidget);
    }
    await tester.tap(find.text('Marte'));
    await tester.pumpAndSettle();
    expect(state.env, MissionEnv.marte);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pantalla angosta: menú desplegable, sin texto cortado', (tester) async {
    final state = await _pump(tester, width: 360);
    expect(find.byType(SegmentedButton<MissionEnv>), findsNothing);
    expect(find.byKey(const Key('env-menu')), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no debe haber overflow');

    await tester.tap(find.byKey(const Key('env-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Marte').last);
    await tester.pumpAndSettle();
    expect(state.env, MissionEnv.marte);
    expect(find.text('Marte'), findsOneWidget);
  });

  testWidgets('las áreas táctiles miden al menos 44 px', (tester) async {
    await _pump(tester, width: 1200);
    for (final e in MissionEnv.values) {
      final button = find.ancestor(of: find.text(e.label), matching: find.byType(InkWell)).first;
      expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
    }
    await _pump(tester, width: 360);
    expect(tester.getSize(find.byKey(const Key('env-menu'))).height, greaterThanOrEqualTo(44));
  });

  testWidgets('cambiar a Luna o Marte activa el modo autónomo', (tester) async {
    final state = await _pump(tester, width: 1200);
    expect(state.env.autonomous, isFalse);
    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();
    expect(state.env.autonomous, isTrue);
    expect(state.env.delay, '4–12 s');
  });
}
