import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/data/models.dart';

import 'fake_api.dart';

void main() {
  test('lee etiqueta, unidad y dirección de la métrica', () {
    final t = Trend.fromJson(trendJson(metric: 'sleep_hours', label: 'Horas de sueño', unit: 'h', alertWhen: 'below'));
    expect(t.metric, 'sleep_hours');
    expect(t.label, 'Horas de sueño');
    expect(t.unit, 'h');
    expect(t.alertsWhenBelow, isTrue);
  });

  test('la racha relevante sigue la dirección que preocupa', () {
    expect(Trend.fromJson(trendJson(above: 3, below: 0)).sustainedStreak, 3);
    expect(Trend.fromJson(trendJson(alertWhen: 'below', above: 0, below: 4)).sustainedStreak, 4);
  });

  test('sin serie o sin base no hay datos', () {
    expect(Trend.fromJson(trendJson(series: [], base: null, status: 'sin_dato', above: 0)).hasData, isFalse);
    expect(Trend.fromJson(trendJson()).hasData, isTrue);
  });

  test('respuestas viejas sin campos nuevos no truenan', () {
    final j = trendJson()..remove('consecutive_below')..remove('alert_when')..remove('label');
    final t = Trend.fromJson(j);
    expect(t.alertsWhenBelow, isFalse);
    expect(t.sustainedStreak, 3);
  });
}
