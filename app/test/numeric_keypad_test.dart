import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/core/touch.dart';
import 'package:tirelus/widgets/numeric_keypad.dart';

void main() {
  Future<List<String>> pump(WidgetTester tester, {List<String>? log}) async {
    final events = log ?? <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: NumericKeypad(
            onDigit: (d) => events.add(d),
            onBackspace: () => events.add('<'),
            onNextField: () => events.add('>'),
            backspaceLabel: 'Borrar',
            nextFieldLabel: 'Siguiente campo',
          ),
        ),
      ),
    ));
    return events;
  }

  testWidgets('cada tecla responde al toque', (tester) async {
    final events = await pump(tester);
    for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) {
      await tester.tap(find.byKey(ValueKey('key-$d')));
    }
    await tester.tap(find.byKey(const ValueKey('key-backspace')));
    await tester.tap(find.byKey(const ValueKey('key-next')));
    expect(events, ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '<', '>']);
  });

  testWidgets('las teclas miden al menos 64 dp de alto y están separadas', (tester) async {
    await pump(tester);
    final one = tester.getRect(find.byKey(const ValueKey('key-1')));
    final two = tester.getRect(find.byKey(const ValueKey('key-2')));
    final four = tester.getRect(find.byKey(const ValueKey('key-4')));
    expect(one.height, greaterThanOrEqualTo(Touch.primary));
    expect(two.left - one.right, greaterThanOrEqualTo(Touch.gap));
    expect(four.top - one.bottom, greaterThanOrEqualTo(Touch.gap));
  });
}
