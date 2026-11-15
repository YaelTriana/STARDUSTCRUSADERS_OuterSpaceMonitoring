import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/core/summary_export.dart';
import 'package:tirelus/data/models.dart';
import 'package:tirelus/l10n/app_localizations_en.dart';
import 'package:tirelus/l10n/app_localizations_es.dart';

const _trend = Trend(
  series: [118, 120, 126, 128, 130, 132],
  firstDay: 42,
  baseLow: 110,
  baseHigh: 126,
  status: VStatus.atencion,
  consecutiveAbove: 3,
  daysOutOfRange: 3,
  deltaFromHigh: 6,
  avg7: 126,
  rule: 'regla',
);

void main() {
  test('resumen en español: cifras, aviso de datos de ejemplo y registros', () {
    final text = buildSummaryText(AppLocalizationsEs(),
        metricLabel: 'Presión sistólica', unit: 'mmHg', trend: _trend, items: ['PA 132/84 mmHg · atención frente a tu base']);
    expect(text, contains('RESUMEN PARA LA CONFERENCIA MÉDICA'));
    expect(text, contains('Datos de ejemplo'));
    expect(text, contains('Presión sistólica: hoy 132 mmHg; rango prevuelo 110–126'));
    expect(text, contains('3 de 6 días fuera de rango'));
    expect(text, contains('- PA 132/84 mmHg'));
    expect(text, contains('supuestos de diseño'));
  });

  test('resumen en inglés y sin registros', () {
    final text = buildSummaryText(AppLocalizationsEn(), metricLabel: 'Systolic pressure', unit: 'mmHg', trend: _trend, items: []);
    expect(text, contains('MEDICAL CONFERENCE SUMMARY'));
    expect(text, contains('Sample data'));
    expect(text, contains('No pending items.'));
  });
}
