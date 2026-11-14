import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/trend_chart.dart';

/// Tendencia de 14 días con alerta por desviación sostenida (regla en Python).
class TrendScreen extends StatefulWidget {
  const TrendScreen({super.key});

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> {
  Future<Trend>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).api.systolicTrend();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    return AsyncView<Trend>(
      future: _future!,
      builder: (context, trend) {
        final chart = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionCard(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, children: [
                Text('Presión sistólica', style: t.headlineSmall),
                Text.rich(TextSpan(children: [
                  TextSpan(text: trend.series.last.toStringAsFixed(0), style: mono(size: 34)),
                  TextSpan(text: ' mmHg hoy', style: mono(size: 14, color: VColors.muted)),
                ])),
              ]),
              const SizedBox(height: 16),
              TrendChart(trend: trend),
            ]),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 14, runSpacing: 14, children: [
            SizedBox(width: 220, child: MetricTile(label: 'Promedio 7 días', value: '${trend.avg7}', valueSize: 26)),
            SizedBox(
              width: 220,
              child: MetricTile(
                label: 'Días fuera de rango',
                value: '${trend.daysOutOfRange} de ${trend.series.length}',
                valueColor: trend.daysOutOfRange > 0 ? VColors.atencion : null,
                valueSize: 26,
              ),
            ),
            SizedBox(width: 220, child: MetricTile(label: 'Racha sobre tu base', value: '${trend.consecutiveAbove} días', valueSize: 26)),
          ]),
        ]);

        final aside = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (trend.status == VStatus.nominal)
            const AlertBanner(title: 'Sin alertas', body: 'Tus lecturas recientes están dentro de tu rango.', status: VStatus.nominal)
          else
            AlertBanner(
              title: '${trend.status.label}: tendencia sostenida',
              body: 'Llevas ${trend.consecutiveAbove} días seguidos sobre tu rango prevuelo. No es una emergencia, '
                  'pero conviene que tu flight surgeon lo vea.',
              status: trend.status,
            ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PLAN SUGERIDO', style: overline()),
              const SizedBox(height: 10),
              const Text('1. Mide dos veces al día (mañana y noche) durante 3 días.\n'
                  '2. Registra sal en la dieta, sueño y estrés del día.\n'
                  '3. Comparte el resumen en tu conferencia médica privada.',
                  style: TextStyle(fontSize: 15, height: 1.6)),
            ]),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await state.addToSummary('Sistólica ${trend.consecutiveAbove} días sobre la base (hoy ${trend.series.last.toStringAsFixed(0)} mmHg)');
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: chart),
                    const SizedBox(width: 24),
                    SizedBox(width: 360, child: aside),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [chart, const SizedBox(height: 20), aside]),
          );
        });
      },
    );
  }
}
