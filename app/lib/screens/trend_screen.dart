import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/trend_chart.dart';

/// Tendencia de 14 días con alerta por desviación sostenida (regla en Python).
/// Sirve para cualquier métrica del catálogo de `/metrics`.
class TrendScreen extends StatefulWidget {
  const TrendScreen({super.key, this.initialMetric = 'systolic'});
  final String initialMetric;

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

/// Plan sugerido por métrica. Texto orientativo: la app no diagnostica.
const _plans = {
  'systolic': '1. Mide dos veces al día (mañana y noche) durante 3 días.\n'
      '2. Registra sal en la dieta, sueño y estrés del día.\n'
      '3. Comparte el resumen en tu conferencia médica privada.',
  'sleep_hours': '1. Revisa luz, ruido y temperatura de tu estación de descanso.\n'
      '2. Respeta tu periodo de sueño programado durante 3 noches.\n'
      '3. Comparte el resumen en tu conferencia médica privada.',
};
const _defaultPlan = '1. Repite la medición a la misma hora durante 3 días.\n'
    '2. Anota lo que pudo influir (sueño, carga de trabajo, ejercicio).\n'
    '3. Comparte el resumen en tu conferencia médica privada.';

class _TrendScreenState extends State<TrendScreen> {
  late String _metric = widget.initialMetric;
  Future<Trend>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).api.trend(_metric);
  }

  void _select(String metric) {
    if (metric == _metric) return;
    setState(() {
      _metric = metric;
      _future = AppScope.of(context).api.trend(metric);
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          MetricSelector(selected: _metric, onSelected: _select),
          const SizedBox(height: 20),
          AsyncView<Trend>(
            key: ValueKey(_metric),
            future: _future!,
            builder: (context, trend) => trend.hasData ? _TrendBody(trend: trend) : _NoData(trend: trend),
          ),
        ]),
      );
}

/// Fila de chips con las métricas del catálogo de Python.
class MetricSelector extends StatefulWidget {
  const MetricSelector({super.key, required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  State<MetricSelector> createState() => _MetricSelectorState();
}

class _MetricSelectorState extends State<MetricSelector> {
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).api.metrics();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          final metrics = snap.data ?? const [];
          if (metrics.isEmpty) return const SizedBox.shrink();
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final m in metrics)
              ChoiceChip(
                key: Key('metric-${m['id']}'),
                label: Text(m['label'] as String),
                selected: m['id'] == widget.selected,
                onSelected: (_) => widget.onSelected(m['id'] as String),
              ),
          ]);
        },
      );
}

class _NoData extends StatelessWidget {
  const _NoData({required this.trend});
  final Trend trend;

  @override
  Widget build(BuildContext context) => SectionCard(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(trend.label, style: Theme.of(context).textTheme.headlineSmall),
            const StatusChip(VStatus.sinDato),
          ]),
          const SizedBox(height: 14),
          const Text('Aún no hay datos de ejemplo para esta métrica. '
              'En cuanto haya línea base y lecturas, aquí aparece la tendencia con su alerta.',
              style: TextStyle(fontSize: 15, height: 1.55)),
          const SizedBox(height: 14),
          Text(trend.rule, style: const TextStyle(fontSize: 12, color: VColors.muted, height: 1.5)),
          if (trend.source.isNotEmpty)
            Text(trend.source, style: const TextStyle(fontSize: 12, color: VColors.muted, height: 1.5)),
        ]),
      );
}

class _TrendBody extends StatelessWidget {
  const _TrendBody({required this.trend});
  final Trend trend;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final last = trend.series.last;
    final streak = trend.sustainedStreak;
    final dir = trend.directionWord;

    final chart = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, children: [
            Text(trend.label, style: t.headlineSmall),
            Text.rich(TextSpan(children: [
              TextSpan(text: trend.fmt(last), style: mono(size: 34)),
              TextSpan(text: ' ${trend.unit} hoy', style: mono(size: 14, color: VColors.muted)),
            ])),
          ]),
          const SizedBox(height: 16),
          TrendChart(trend: trend),
        ]),
      ),
      const SizedBox(height: 16),
      Wrap(spacing: 14, runSpacing: 14, children: [
        SizedBox(width: 220, child: MetricTile(label: 'Promedio 7 días', value: '${trend.avg7}', unit: trend.unit, valueSize: 26)),
        SizedBox(
          width: 220,
          child: MetricTile(
            label: 'Días fuera de rango',
            value: '${trend.daysOutOfRange} de ${trend.series.length}',
            valueColor: trend.daysOutOfRange > 0 ? VColors.atencion : null,
            valueSize: 26,
          ),
        ),
        SizedBox(width: 220, child: MetricTile(label: 'Racha $dir tu base', value: '$streak días', valueSize: 26)),
      ]),
    ]);

    final aside = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (trend.status == VStatus.nominal)
        const AlertBanner(title: 'Sin alertas', body: 'Tus lecturas recientes están dentro de tu rango.', status: VStatus.nominal)
      else
        AlertBanner(
          title: '${trend.status.label}: tendencia sostenida',
          body: 'Llevas $streak días seguidos $dir tu rango prevuelo. No es una emergencia, '
              'pero conviene que tu flight surgeon lo vea.',
          status: trend.status,
        ),
      const SizedBox(height: 16),
      SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PLAN SUGERIDO', style: overline()),
          const SizedBox(height: 10),
          Text(_plans[trend.metric] ?? _defaultPlan, style: const TextStyle(fontSize: 15, height: 1.6)),
        ]),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          await state.addToSummary('${trend.label}: $streak días $dir la base (hoy ${trend.fmt(last)} ${trend.unit})');
          messenger.showSnackBar(const SnackBar(content: Text('Agregado al resumen médico.')));
        },
        child: const Text('Agregar al resumen médico'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Aviso enviado al CMO de la tripulación.'))),
        child: const Text('Avisar al CMO ahora'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            final export = await state.api.exportSummary();
            await Clipboard.setData(ClipboardData(text: export['text'] as String));
            messenger.showSnackBar(SnackBar(
              content: Text('Resumen copiado al portapapeles (${export['filename']}). '
                  'Solo para ti, el CMO y el flight surgeon.'),
            ));
          } catch (_) {
            messenger.showSnackBar(const SnackBar(content: Text('No se pudo exportar el resumen. Intenta de nuevo.')));
          }
        },
        icon: const Icon(Icons.ios_share),
        label: const Text('Exportar resumen médico'),
      ),
      const SizedBox(height: 12),
      Text(trend.rule, style: const TextStyle(fontSize: 12, color: VColors.muted, height: 1.5)),
      if (state.medicalSummary.isNotEmpty) ...[
        const SizedBox(height: 20),
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('RESUMEN PARA LA CONFERENCIA MÉDICA', style: overline()),
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

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 1000;
      return wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: chart),
              const SizedBox(width: 24),
              SizedBox(width: 360, child: aside),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [chart, const SizedBox(height: 20), aside]);
    });
  }
}
