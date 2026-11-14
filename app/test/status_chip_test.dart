import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/data/models.dart';
import 'package:tirelus/theme.dart';
import 'package:tirelus/widgets/common.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('Semáforo: color + forma + palabra', () {
    testWidgets('cada estado muestra su palabra y su forma', (tester) async {
      for (final s in VStatus.values) {
        await tester.pumpWidget(_wrap(StatusChip(s)));
        expect(find.text(s.label), findsOneWidget, reason: 'falta la palabra de ${s.name}');
        final shape = tester.widget<StatusShape>(find.byType(StatusShape));
        expect(shape.status, s, reason: 'la forma no corresponde a ${s.name}');
      }
    });

    testWidgets('la píldora usa el color del estado', (tester) async {
      await tester.pumpWidget(_wrap(const StatusChip(VStatus.atencion)));
      final box = tester.widget<Container>(
        find.descendant(of: find.byType(StatusChip), matching: find.byType(Container)).first,
      );
      expect((box.decoration! as BoxDecoration).color, VColors.atencion);
    });

    testWidgets('el lector de pantalla anuncia el estado', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const StatusChip(VStatus.critico)));
      expect(find.bySemanticsLabel(RegExp('Estado: Crítico')), findsOneWidget);
      handle.dispose();
    });
  });

  test('cada estado tiene un color distinto', () {
    final colors = VStatus.values.map(statusColor).toSet();
    expect(colors.length, VStatus.values.length);
  });

  test('las palabras de la API se traducen al estado correcto', () {
    expect(statusFromApi('nominal'), VStatus.nominal);
    expect(statusFromApi('atencion'), VStatus.atencion);
    expect(statusFromApi('critico'), VStatus.critico);
    expect(statusFromApi('otro'), VStatus.sinDato);
    expect(statusFromApi(null), VStatus.sinDato);
  });
}
