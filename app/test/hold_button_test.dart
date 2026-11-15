import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/core/touch.dart';
import 'package:tirelus/widgets/hold_button.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester) => tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: HoldToConfirmButton(label: 'Avisar', onConfirmed: () {}))),
      ));

  testWidgets('un toque rápido no confirma la acción crítica', (tester) async {
    var confirmed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: HoldToConfirmButton(label: 'Avisar', onConfirmed: () => confirmed++))),
    ));
    await tester.tap(find.text('Avisar'));
    await tester.pumpAndSettle();
    expect(confirmed, 0);
  });

  testWidgets('mantener presionado ~1 s sí confirma', (tester) async {
    var confirmed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: HoldToConfirmButton(label: 'Avisar', onConfirmed: () => confirmed++))),
    ));
    final g = await tester.startGesture(tester.getCenter(find.text('Avisar')));
    // Flutter dispara onTapDown ~100 ms después de tocar (para distinguirlo de un scroll)
    // y la animación arranca en el cuadro siguiente.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(Touch.holdToConfirm + const Duration(milliseconds: 100));
    await g.up();
    await tester.pumpAndSettle();
    expect(confirmed, 1);
  });

  testWidgets('mide al menos 64 dp de alto', (tester) async {
    await pumpButton(tester);
    expect(tester.getSize(find.byType(HoldToConfirmButton)).height, greaterThanOrEqualTo(Touch.primary));
  });
}
