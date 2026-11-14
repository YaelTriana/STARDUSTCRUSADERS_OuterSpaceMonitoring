import '../data/models.dart';
import '../l10n/app_localizations.dart';

/// Arma el texto del resumen para la conferencia médica privada.
///
/// Es texto plano para pegar o compartir. Siempre dice que son datos de ejemplo
/// y que los umbrales son supuestos de diseño (TIRELUS no diagnostica).
String buildSummaryText(
  AppLocalizations l, {
  required String metricLabel,
  required String unit,
  required Trend trend,
  required List<String> items,
}) {
  final b = StringBuffer()
    ..writeln(l.exportHeader)
    ..writeln(l.exportDay(trend.firstDay + (trend.series.isEmpty ? 0 : trend.series.length - 1)))
    ..writeln(l.exportSampleNote)
    ..writeln();
  if (trend.series.isNotEmpty) {
    b
      ..writeln(l.exportMetricLine(
        metricLabel,
        trend.series.last.toStringAsFixed(0),
        unit,
        trend.baseLow.toStringAsFixed(0),
        trend.baseHigh.toStringAsFixed(0),
        '${trend.avg7}',
      ))
      ..writeln(l.exportDaysLine(trend.daysOutOfRange, trend.series.length, trend.consecutiveAbove))
      ..writeln();
  }
  b.writeln(l.exportItemsHeader);
  if (items.isEmpty) {
    b.writeln('- ${l.exportNoItems}');
  } else {
    for (final i in items) {
      b.writeln('- $i');
    }
  }
  return b.toString().trimRight();
}
