import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../core/summary_export.dart';
import '../core/touch.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/hold_button.dart';
import '../widgets/trend_chart.dart';

/// Tendencia con alerta por desviación sostenida (la regla vive en Python).
///
/// Objetivo: ver la dirección del cambio y decidir si escalar.
class TrendScreen extends StatefulWidget {
  const TrendScreen({super.key, this.onGoTo});

  /// Para ir a Medición desde el estado "sin dato".
  final ValueChanged<int>? onGoTo;

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> {
  Future<List<Map<String, dynamic>>>? _metrics;
  final Map<String, Future<Trend>> _trends = {};
  String _metric = 'systolic';
  int _days = 14; // la API entrega 14 días; 7 muestra los últimos 7
  bool _table = false;
  int? _selected; // índice dentro de la ventana visible; null = último punto
  bool _cmoSent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _metrics ??= AppScope.of(context).api.metrics();
  }

  Future<Trend> _trendFor(String id) => _trends.putIfAbsent(id, () => AppScope.of(context).api.trend(id));

  void _reload() => setState(() {
        _metrics = AppScope.of(context).api.metrics();
        _trends.clear();
      });

  bool _isOut(double v, Trend t) => v > t.baseHigh || v < t.baseLow;

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Map<String, dynamic>>>(
      future: _metrics!,
      onRetry: _reload,
      builder: (context, metrics) {
        final info = metrics.firstWhere((m) => m['id'] == _metric, orElse: () => metrics.first);
        return LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 1000;
          return SingleChildScrollView(
            padding: EdgeInsets.all(c.maxWidth < 600 ? VSpace.lg : 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _controls(context, metrics),
              const SizedBox(height: 20),
              AsyncView<Trend>(
                future: _trendFor(info['id'] as String),
                onRetry: _reload,
                loading: const Column(children: [SkeletonBox(height: 360)]),
                builder: (context, trend) => trend.series.isEmpty
                    ? _empty(context)
                    : _content(context, trend, info, wide),
              ),
            ]),
          );
        });
      },
    );
  }

  Widget _controls(BuildContext context, List<Map<String, dynamic>> metrics) {
    final l = AppLocalizations.of(context);
    const style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(Touch.min, Touch.min)),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    return Wrap(spacing: Touch.gapCritical, runSpacing: Touch.gapCritical, crossAxisAlignment: WrapCrossAlignment.center, children: [
      for (final m in metrics)
        ChoiceChip(
          label: Text('${m['label']}', style: const TextStyle(fontSize: VType.body)),
          selected: _metric == m['id'],
          onSelected: (_) => setState(() {
            _metric = m['id'] as String;
            _selected = null;
          }),
        ),
      SegmentedButton<int>(
        showSelectedIcon: false,
        style: style,
        segments: [
          ButtonSegment(value: 7, label: Text(l.trendRange7)),
          ButtonSegment(value: 14, label: Text(l.trendRange14)),
        ],
        selected: {_days},
        onSelectionChanged: (s) => setState(() {
          _days = s.first;
          _selected = null;
        }),
      ),
      SegmentedButton<bool>(
        showSelectedIcon: false,
        style: style,
        segments: [
          ButtonSegment(value: false, icon: const Icon(Icons.show_chart), label: Text(l.trendViewChart)),
          ButtonSegment(value: true, icon: const Icon(Icons.table_rows_outlined), label: Text(l.trendViewTable)),
        ],
        selected: {_table},
        onSelectionChanged: (s) => setState(() => _table = s.first),
      ),
    ]);
  }

  Widget _empty(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const StatusShape(VStatus.sinDato, size: 18),
          const SizedBox(width: VSpace.md),
          Expanded(child: Text(l.trendNoData, style: Theme.of(context).textTheme.titleLarge)),
        ]),
        if (widget.onGoTo != null) ...[
          const SizedBox(height: VSpace.lg),
          OutlinedButton.icon(onPressed: () => widget.onGoTo!(1), icon: const Icon(Icons.straighten), label: Text(l.trendMeasure)),
        ],
      ]),
    );
  }

  Widget _content(BuildContext context, Trend trend, Map<String, dynamic> info, bool wide) {
    final l = AppLocalizations.of(context);
    final unit = '${info['unit']}';
    final label = '${info['label']}';
    final t = Theme.of(context).textTheme;

    final n = _days.clamp(1, trend.series.length);
    final start = trend.series.length - n;
    final series = trend.series.sublist(start);
    final firstDay = trend.firstDay + start;
    final idx = (_selected ?? series.length - 1).clamp(0, series.length - 1);
    final value = series[idx];
    final out = _isOut(value, trend);

    final detail = SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.sm, vertical: VSpace.sm),
      child: Row(children: [
        IconButton(
          tooltip: l.trendPrev,
          constraints: const BoxConstraints(minWidth: Touch.min, minHeight: Touch.min),
          onPressed: idx > 0 ? () => setState(() => _selected = idx - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Column(children: [
            Text(l.trendPointDetail(firstDay + idx, value.toStringAsFixed(0), unit), style: mono(size: 22)),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              StatusShape(out ? VStatus.atencion : VStatus.nominal, size: 12),
              const SizedBox(width: 6),
              Text(out ? l.trendOutOfRange : l.trendInRange, style: const TextStyle(fontSize: VType.body)),
            ]),
          ]),
        ),
        IconButton(
          tooltip: l.trendNext,
          constraints: const BoxConstraints(minWidth: Touch.min, minHeight: Touch.min),
          onPressed: idx < series.length - 1 ? () => setState(() => _selected = idx + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ]),
    );

    final chart = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, children: [
            Text(label, style: t.headlineSmall),
            Text.rich(TextSpan(children: [
              TextSpan(text: trend.series.last.toStringAsFixed(0), style: mono(size: 34)),
              TextSpan(text: ' $unit', style: mono(size: 14, color: VColors.muted)),
            ])),
          ]),
          const SizedBox(height: 16),
          if (_table)
            _DataTable(series: series, firstDay: firstDay, trend: trend, unit: unit)
          else
            TrendChart(
              series: series,
              firstDay: firstDay,
              baseLow: trend.baseLow,
              baseHigh: trend.baseHigh,
              selected: idx,
              onSelect: (i) => setState(() => _selected = i),
              baseLabel: l.rangeBase(trend.baseLow.toStringAsFixed(0), trend.baseHigh.toStringAsFixed(0)),
              semanticsLabel: l.trendChartSemantics(label, series.length, series.first.toStringAsFixed(0),
                  series.last.toStringAsFixed(0), trend.baseLow.toStringAsFixed(0), trend.baseHigh.toStringAsFixed(0)),
            ),
        ]),
      ),
      const SizedBox(height: 16),
      detail,
      const SizedBox(height: 16),
      Wrap(spacing: 14, runSpacing: 14, children: [
        SizedBox(width: 220, child: MetricTile(label: l.trendAvg7, value: '${trend.avg7}', valueSize: 26)),
        SizedBox(
          width: 220,
          child: MetricTile(
            label: l.trendOutDays,
            value: l.trendOutDaysValue(trend.daysOutOfRange, trend.series.length),
            valueColor: trend.daysOutOfRange > 0 ? VColors.atencion : null,
            valueSize: 26,
          ),
        ),
        SizedBox(
          width: 220,
          child: MetricTile(label: l.trendStreakAbove, value: l.trendStreakValue(trend.consecutiveAbove), valueSize: 26),
        ),
      ]),
    ]);

    final aside = _aside(context, trend, label, unit);

    return wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: chart),
            const SizedBox(width: 24),
            SizedBox(width: 360, child: aside),
          ])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [chart, const SizedBox(height: 20), aside]);
  }

  Widget _aside(BuildContext context, Trend trend, String label, String unit) {
    final l = AppLocalizations.of(context);
    final state = AppScope.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (trend.status == VStatus.nominal)
        AlertBanner(title: l.trendNoAlertTitle, body: l.trendNoAlertBody, status: VStatus.nominal)
      else
        AlertBanner(
          title: l.trendAlertTitle(l.status(trend.status)),
          body: l.trendAlertBody(trend.consecutiveAbove),
          status: trend.status,
        ),
      const SizedBox(height: 16),
      SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.trendPlanTitle, style: overline()),
          const SizedBox(height: 10),
          Text(l.trendPlanBody, style: const TextStyle(fontSize: VType.body, height: 1.6)),
        ]),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          await state.addToSummary(l.trendSummaryEntry(label, trend.consecutiveAbove, trend.series.last.toStringAsFixed(0), unit));
          messenger.showSnackBar(SnackBar(content: Text(l.trendAddedSummary)));
        },
        child: Text(l.trendAddSummary),
      ),
      const SizedBox(height: Touch.gapCritical),
      OutlinedButton.icon(
        onPressed: () => _export(trend, label, unit),
        icon: const Icon(Icons.copy_all_outlined),
        label: Text(l.trendExport),
      ),
      const SizedBox(height: Touch.gapCritical),
      HoldToConfirmButton(label: l.trendHoldCmo, onConfirmed: _notifyCmo),
      if (_cmoSent) ...[
        const SizedBox(height: VSpace.sm),
        Row(children: [
          const StatusShape(VStatus.nominal, size: 12),
          const SizedBox(width: 8),
          Expanded(child: Text(l.trendCmoSent, style: const TextStyle(fontSize: VType.label, color: VColors.muted))),
        ]),
      ],
      const SizedBox(height: 12),
      Text(trend.rule, style: const TextStyle(fontSize: VType.label, color: VColors.muted, height: 1.5)),
      if (state.medicalSummary.isNotEmpty) ...[
        const SizedBox(height: 20),
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.trendSummaryBoxTitle, style: overline()),
            const SizedBox(height: 10),
            for (final item in state.medicalSummary)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $item', style: const TextStyle(fontSize: 14, height: 1.5)),
              ),
          ]),
        ),
      ],
    ]);
  }

  /// Copia el resumen al portapapeles y lo confirma de forma visible.
  ///
  /// La fuente principal es `GET /summary/export` (Python). Si el motor no responde,
  /// el texto se arma aquí con lo que ya hay en pantalla, para que Exportar siempre funcione.
  Future<void> _export(Trend trend, String label, String unit) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final state = AppScope.of(context);
    String text;
    String? filename;
    try {
      final export = await state.api.exportSummary();
      text = export['text'] as String;
      filename = export['filename'] as String?;
    } catch (_) {
      text = buildSummaryText(l, metricLabel: label, unit: unit, trend: trend, items: state.medicalSummary);
    }
    await Clipboard.setData(ClipboardData(text: text));
    messenger.showSnackBar(SnackBar(content: Text(filename == null ? l.trendExported : l.trendExportedFile(filename))));
  }

  /// Aviso al CMO con ventana para deshacer: se "envía" al cerrarse el aviso sin pulsar Deshacer.
  void _notifyCmo() {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final controller = messenger.showSnackBar(SnackBar(
      duration: Touch.undoWindow,
      content: Text(l.trendCmoQueued),
      action: SnackBarAction(label: l.trendCmoUndo, onPressed: () {}),
    ));
    controller.closed.then((reason) {
      if (!mounted) return;
      if (reason == SnackBarClosedReason.action) {
        setState(() => _cmoSent = false);
        messenger.showSnackBar(SnackBar(content: Text(l.trendCmoCancelled)));
      } else {
        setState(() => _cmoSent = true);
      }
    });
  }
}

/// Tabla alternativa a la gráfica (para lectores de pantalla y lectura exacta).
class _DataTable extends StatelessWidget {
  const _DataTable({required this.series, required this.firstDay, required this.trend, required this.unit});
  final List<double> series;
  final int firstDay;
  final Trend trend;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    TextStyle head() => overline(color: VColors.muted);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(bottom: VSpace.sm),
        child: Row(children: [
          Expanded(child: Text(l.trendTableDay, style: head())),
          Expanded(child: Text('${l.trendTableValue} ($unit)', style: head())),
          Expanded(flex: 2, child: Text(l.trendTableState, style: head())),
        ]),
      ),
      for (var i = series.length - 1; i >= 0; i--)
        Container(
          constraints: const BoxConstraints(minHeight: Touch.min),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: VColors.border))),
          child: Row(children: [
            Expanded(child: Text('D${firstDay + i}', style: mono(size: 14, color: VColors.muted))),
            Expanded(child: Text(series[i].toStringAsFixed(0), style: mono(size: 18))),
            Expanded(
              flex: 2,
              child: Row(children: [
                StatusShape(series[i] > trend.baseHigh || series[i] < trend.baseLow ? VStatus.atencion : VStatus.nominal, size: 12),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    series[i] > trend.baseHigh || series[i] < trend.baseLow ? l.trendOutOfRange : l.trendInRange,
                    style: const TextStyle(fontSize: VType.body),
                  ),
                ),
              ]),
            ),
          ]),
        ),
    ]);
  }
}
