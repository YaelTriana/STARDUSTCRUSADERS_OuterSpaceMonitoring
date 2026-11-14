import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Medición y seguimiento de SANS (síndrome neuro-ocular asociado al vuelo espacial).
/// Única métrica con umbrales publicados: +20 µm primer signo, 55 µm preocupación
/// clínica. La evaluación la hace Python (`/evaluate/sans`, `/trend/sans`).
class SansScreen extends StatefulWidget {
  const SansScreen({super.key});

  @override
  State<SansScreen> createState() => _SansScreenState();
}

class _SansScreenState extends State<SansScreen> {
  final _delta = TextEditingController();
  Future<Map<String, dynamic>>? _trend;
  VStatus? _status;
  int _request = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trend ??= AppScope.of(context).api.sansTrend();
  }

  @override
  void dispose() {
    _delta.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(_delta.text.replaceAll(',', '.'));

  Future<void> _evaluate() async {
    final v = _value;
    final id = ++_request;
    if (v == null) {
      setState(() => _status = null);
      return;
    }
    final s = await AppScope.of(context).api.evaluateSans(v);
    // Ignora respuestas viejas si se siguió escribiendo.
    if (mounted && id == _request) setState(() => _status = s);
  }

  Future<void> _addToSummary() async {
    final messenger = ScaffoldMessenger.of(context);
    await AppScope.of(context).addToSummary(
        'SANS: grosor retiniano +${_delta.text} µm frente a la base · ${_status!.label.toLowerCase()}');
    messenger.showSnackBar(const SnackBar(content: Text('Agregado al resumen médico.')));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final flagged = _status == VStatus.atencion || _status == VStatus.critico;

    final form = SectionCard(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('Ojos y cerebro (SANS)', style: t.headlineMedium),
          if (_status != null) StatusChip(_status!),
        ]),
        const SizedBox(height: 8),
        const Text('Registra el resultado de tu OCT: cuánto cambió el grosor de la retina frente a tu base prevuelo.',
            style: TextStyle(fontSize: 15, color: VColors.muted, height: 1.5)),
        const SizedBox(height: 22),
        SizedBox(
          width: 320,
          child: TextField(
            key: const Key('sans-input'),
            controller: _delta,
            onChanged: (_) => _evaluate(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: mono(size: 30),
            decoration: const InputDecoration(labelText: 'Cambio de grosor (µm)', hintText: 'p. ej. 8'),
          ),
        ),
        const SizedBox(height: 22),
        _ThresholdBar(value: _value, status: _status ?? VStatus.sinDato),
        if (flagged) ...[
          const SizedBox(height: 20),
          AlertBanner(
            title: _status == VStatus.critico ? 'Crítico: avisa hoy a tu CMO' : 'Atención: primer signo de SANS',
            body: _status == VStatus.critico
                ? 'El cambio llega al nivel de preocupación clínica. Avisa a tu CMO y a tu flight surgeon.'
                : 'Conviene repetir la OCT en el próximo ciclo y comentarlo en tu conferencia médica privada.',
            status: _status!,
          ),
          const SizedBox(height: 16),
          Wrap(children: [FilledButton(onPressed: _addToSummary, child: const Text('Agregar al resumen médico'))]),
        ],
      ]),
    );

    final history = AsyncView<Map<String, dynamic>>(
      future: _trend!,
      builder: (context, body) {
        final series = [for (final v in body['series'] as List) (v as num).toDouble()];
        final days = [for (final d in body['days'] as List) d as int];
        return SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text('HISTORIAL DE OCT', style: overline()),
              StatusChip(statusFromApi(body['status'] as String?)),
            ]),
            const SizedBox(height: 12),
            if (series.isEmpty)
              const Text('Aún no hay OCT de ejemplo. Cuando haya lecturas, aquí verás cada ciclo.',
                  style: TextStyle(fontSize: 15, height: 1.5))
            else
              for (var i = 0; i < series.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('D${i < days.length ? days[i] : '?'} · +${series[i].toStringAsFixed(0)} µm',
                      style: mono(size: 15)),
                ),
            const SizedBox(height: 12),
            Text(body['source'] as String? ?? '', style: const TextStyle(fontSize: 12, color: VColors.muted, height: 1.5)),
          ]),
        );
      },
    );

    const info = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _InfoCard(
          title: 'QUÉ ESTÁS MIDIENDO',
          body: 'La OCT mide el grosor de la retina alrededor del nervio óptico. Si se engruesa, '
              'puede ser una señal temprana de SANS.'),
      SizedBox(height: 16),
      _InfoCard(
          title: 'POR QUÉ IMPORTA AQUÍ',
          body: 'Sin gravedad, los líquidos se desplazan hacia la cabeza. En misiones largas eso se asocia '
              'con cambios en el ojo y en la visión.'),
    ]);

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 1000;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [form, const SizedBox(height: 20), history])),
                const SizedBox(width: 24),
                const SizedBox(width: 340, child: info),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                form,
                const SizedBox(height: 20),
                history,
                const SizedBox(height: 20),
                info,
              ]),
      );
    });
  }
}

/// Barra de 0 a 70 µm con las marcas publicadas de +20 y 55 µm.
class _ThresholdBar extends StatelessWidget {
  const _ThresholdBar({required this.value, required this.status});
  final double? value;
  final VStatus status;

  static const _max = 70.0;
  static const _attention = 20.0;
  static const _critical = 55.0;

  @override
  Widget build(BuildContext context) {
    double frac(double v) => (v / _max).clamp(0.0, 1.0);
    return Semantics(
      label: 'Umbrales: más 20 micras primer signo, 55 micras preocupación clínica'
          '${value == null ? '' : '; tu valor: ${value!.toStringAsFixed(0)} micras'}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(color: VColors.surface2, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            Widget band(double from, double to, Color color) => Positioned(
                  top: 6,
                  left: w * frac(from),
                  width: w * (frac(to) - frac(from)),
                  child: Container(height: 14, color: color),
                );
            return SizedBox(
              height: 26,
              child: Stack(clipBehavior: Clip.none, children: [
                band(0, _attention, const Color(0xFF2B6B4F)),
                band(_attention, _critical, const Color(0xFF7A5A1E)),
                band(_critical, _max, const Color(0xFF7A2E28)),
                if (value != null)
                  Positioned(
                    left: (w * frac(value!) - 2).clamp(0.0, w - 4),
                    top: 0,
                    child: Container(width: 4, height: 26, color: statusColor(status)),
                  ),
              ]),
            );
          }),
          const SizedBox(height: 10),
          Wrap(spacing: 18, runSpacing: 6, children: [
            Text('0 µm', style: mono(size: 12, color: VColors.muted)),
            Text('+20 µm · primer signo', style: mono(size: 12, color: VColors.muted)),
            Text('55 µm · preocupación clínica', style: mono(size: 12, color: VColors.muted)),
          ]),
        ]),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: overline()),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(fontSize: 15, height: 1.55)),
        ]),
      );
}
