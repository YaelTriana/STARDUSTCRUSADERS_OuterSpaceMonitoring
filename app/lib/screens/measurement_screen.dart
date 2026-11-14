import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'trend_screen.dart' show MetricSelector;

/// Medición guiada contra la línea base personal. La evaluación la hace Python.
/// Presión arterial tiene su formulario completo; el resto de las métricas del
/// catálogo usa un campo con su unidad.
class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key, this.initialMetric = 'systolic'});
  final String initialMetric;

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  late String _metric = widget.initialMetric;

  @override
  Widget build(BuildContext context) {
    final header = MetricSelector(selected: _metric, onSelected: (m) => setState(() => _metric = m));
    return _metric == 'systolic'
        ? _BloodPressureMeasurement(header: header)
        : _GenericMeasurement(key: ValueKey(_metric), metric: _metric, header: header);
  }
}

/// Medición guiada de presión arterial.
class _BloodPressureMeasurement extends StatefulWidget {
  const _BloodPressureMeasurement({required this.header});
  final Widget header;

  @override
  State<_BloodPressureMeasurement> createState() => _BloodPressureState();
}

class _BloodPressureState extends State<_BloodPressureMeasurement> {
  final _sys = TextEditingController(text: '132');
  final _dia = TextEditingController(text: '84');
  final _hr = TextEditingController(text: '64');
  VStatus? _status;
  bool _busy = false;

  // Rango prevuelo (en producción viene del perfil del tripulante).
  static const _baseLow = 110.0;
  static const _baseHigh = 126.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());
  }

  @override
  void dispose() {
    _sys.dispose();
    _dia.dispose();
    _hr.dispose();
    super.dispose();
  }

  double? get _sysValue => double.tryParse(_sys.text);

  Future<void> _evaluate() async {
    final v = _sysValue;
    if (v == null) {
      setState(() => _status = VStatus.sinDato);
      return;
    }
    setState(() => _busy = true);
    try {
      final s = await AppScope.of(context).api.evaluateSystolic(v);
      if (mounted) setState(() => _status = s);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final state = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_status != null && _status != VStatus.nominal) {
      await state.addToSummary('PA ${_sys.text}/${_dia.text} mmHg · ${_status!.label.toLowerCase()} frente a tu base');
    }
    messenger.showSnackBar(SnackBar(
      content: Text(_status == VStatus.nominal
          ? 'Medición guardada. Dentro de tu rango.'
          : 'Medición guardada y agregada al resumen de tu conferencia médica.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final steps = Column(children: const [
      _Step(title: 'Prepárate', detail: '5 min en reposo, anclado con los pies en la barra', done: true),
      _Step(title: 'Coloca el brazalete', detail: 'Brazo izquierdo, 2 cm sobre el codo', done: true),
      _Step(title: 'Mide y registra', detail: 'Lee el monitor o la prenda Bio-Monitor', current: true),
      _Step(title: 'Cómo te sientes', detail: 'Síntomas y ánimo (opcional)'),
    ]);

    final form = SectionCard(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('Registra tu lectura', style: t.headlineMedium),
          if (_status != null) StatusChip(_status!),
          if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ]),
        const SizedBox(height: 22),
        Wrap(spacing: 16, runSpacing: 16, children: [
          _NumField(label: 'Sistólica (mmHg)', controller: _sys, onChanged: (_) => _evaluate()),
          _NumField(label: 'Diastólica (mmHg)', controller: _dia),
          _NumField(label: 'Frecuencia cardiaca (lpm)', controller: _hr),
        ]),
        const SizedBox(height: 22),
        _RangeBar(
          title: 'Sistólica frente a tu rango personal',
          value: _sysValue,
          low: _baseLow,
          high: _baseHigh,
          min: 90,
          max: 160,
          status: _status ?? VStatus.sinDato,
        ),
        const SizedBox(height: 24),
        Wrap(spacing: 12, runSpacing: 12, children: [
          FilledButton(onPressed: _save, child: const Text('Guardar medición')),
          OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Te recordaremos repetir la medición en 5 min.'))),
            child: const Text('Repetir en 5 min'),
          ),
        ]),
      ]),
    );

    const aside = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _InfoCard(
          title: 'QUÉ ESTÁS MIDIENDO',
          body: 'La fuerza con la que la sangre empuja las arterias: el número alto al latir el corazón, '
              'el bajo entre latidos.'),
      SizedBox(height: 16),
      _InfoCard(
          title: 'POR QUÉ IMPORTA AQUÍ',
          body: 'Sin gravedad, los líquidos suben hacia el pecho y la cabeza. El sistema cardiovascular se '
              'adapta y eso puede cambiar tus lecturas.'),
      SizedBox(height: 16),
      _InfoCard(
          title: 'CONSEJO',
          body: 'Mide a la misma hora y sin haber hecho ejercicio en los 30 min previos, para comparar '
              'contra tu base.'),
    ]);

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 1100;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          widget.header,
          const SizedBox(height: 20),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 280, child: steps),
              const SizedBox(width: 24),
              Expanded(child: form),
              const SizedBox(width: 24),
              const SizedBox(width: 320, child: aside),
            ])
          else ...[
            steps,
            const SizedBox(height: 20),
            form,
            const SizedBox(height: 20),
            aside,
          ],
        ]),
      );
    });
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.title, required this.detail, this.done = false, this.current = false});
  final String title;
  final String detail;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: current ? VColors.surface2 : (done ? VColors.surface : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: current ? VColors.signal : VColors.border, width: current ? 2 : 1),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(done ? Icons.check_circle : (current ? Icons.radio_button_checked : Icons.radio_button_unchecked),
              color: done ? VColors.nominal : (current ? VColors.signal : VColors.borderStrong)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: done || current ? VColors.text : VColors.muted)),
              const SizedBox(height: 2),
              Text(detail, style: const TextStyle(fontSize: 13, color: VColors.muted)),
            ]),
          ),
        ]),
      );
}

class _NumField extends StatelessWidget {
  const _NumField({required this.label, required this.controller, this.onChanged});
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 200,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          style: mono(size: 30),
          decoration: InputDecoration(labelText: label),
        ),
      );
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.title,
    required this.value,
    required this.low,
    required this.high,
    required this.min,
    required this.max,
    required this.status,
    this.decimals = 0,
  });
  final String title;
  final double? value;
  final double low;
  final double high;
  final double min;
  final double max;
  final VStatus status;
  final int decimals;

  String _f(double v) => v.toStringAsFixed(decimals);

  @override
  Widget build(BuildContext context) {
    double frac(double v) => ((v - min) / (max - min)).clamp(0.0, 1.0);
    final v = value;
    final label = v == null
        ? null
        : v > high
            ? '+${_f(v - high)} sobre tu base'
            : v < low
                ? '${_f(v - low)} bajo tu base'
                : 'dentro de tu base';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(color: VColors.surface2, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          if (label != null)
            Flexible(child: Text(label, textAlign: TextAlign.end, style: mono(size: 14, color: statusColor(status)))),
        ]),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          return SizedBox(
            height: 26,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(top: 6, left: 0, right: 0, child: Container(height: 14, decoration: BoxDecoration(color: VColors.border, borderRadius: BorderRadius.circular(7)))),
              Positioned(
                top: 6,
                left: w * frac(low),
                width: w * (frac(high) - frac(low)),
                child: Container(height: 14, decoration: BoxDecoration(color: const Color(0xFF2B6B4F), borderRadius: BorderRadius.circular(7))),
              ),
              if (value != null)
                Positioned(
                  left: (w * frac(value!) - 2).clamp(0.0, w - 4),
                  top: 0,
                  child: Container(width: 4, height: 26, decoration: BoxDecoration(color: statusColor(status), borderRadius: BorderRadius.circular(2))),
                ),
            ]),
          );
        }),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_f(min), style: mono(size: 12, color: VColors.muted)),
          Flexible(
            child: Text('Tu rango prevuelo ${_f(low)}–${_f(high)}',
                textAlign: TextAlign.center, style: mono(size: 12, color: VColors.muted)),
          ),
          Text(_f(max), style: mono(size: 12, color: VColors.muted)),
        ]),
      ]),
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

/// Medición de una métrica del catálogo con un solo valor (FC, sueño, ánimo…).
class _GenericMeasurement extends StatefulWidget {
  const _GenericMeasurement({super.key, required this.metric, required this.header});
  final String metric;
  final Widget header;

  @override
  State<_GenericMeasurement> createState() => _GenericMeasurementState();
}

class _GenericMeasurementState extends State<_GenericMeasurement> {
  final _value = TextEditingController();
  Future<Trend>? _info;
  VStatus? _status;
  int _request = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // /trend/{metric} trae etiqueta, unidad, base, regla y fuente.
    _info ??= AppScope.of(context).api.trend(widget.metric);
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  double? get _parsed => double.tryParse(_value.text.replaceAll(',', '.'));

  Future<void> _evaluate() async {
    final v = _parsed;
    final id = ++_request;
    if (v == null) {
      setState(() => _status = null);
      return;
    }
    final s = await AppScope.of(context).api.evaluate(widget.metric, v);
    if (mounted && id == _request) setState(() => _status = s);
  }

  Future<void> _save(Trend info) async {
    final state = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final flagged = _status == VStatus.atencion || _status == VStatus.critico;
    if (flagged) {
      await state.addToSummary('${info.label}: ${_value.text} ${info.unit} · ${_status!.label.toLowerCase()} frente a tu base');
    }
    messenger.showSnackBar(SnackBar(
      content: Text(flagged
          ? 'Medición guardada y agregada al resumen de tu conferencia médica.'
          : 'Medición guardada.'),
    ));
  }

  Widget _form(BuildContext context, Trend info) {
    final t = Theme.of(context).textTheme;
    if (!info.hasBase) {
      return SectionCard(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(info.label, style: t.headlineMedium),
            const StatusChip(VStatus.sinDato),
          ]),
          const SizedBox(height: 14),
          const Text('Aún no hay línea base prevuelo para esta métrica, así que no hay contra qué comparar.',
              style: TextStyle(fontSize: 15, height: 1.55)),
        ]),
      );
    }
    final span = info.baseHigh - info.baseLow;
    final decimals = span < 5 ? 1 : 0;
    return SectionCard(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('Registra tu lectura', style: t.headlineMedium),
          if (_status != null) StatusChip(_status!),
        ]),
        const SizedBox(height: 22),
        SizedBox(
          width: 260,
          child: TextField(
            key: const Key('generic-input'),
            controller: _value,
            onChanged: (_) => _evaluate(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: mono(size: 30),
            decoration: InputDecoration(labelText: '${info.label} (${info.unit})'),
          ),
        ),
        const SizedBox(height: 22),
        _RangeBar(
          title: '${info.label} frente a tu rango personal',
          value: _parsed,
          low: info.baseLow,
          high: info.baseHigh,
          min: info.baseLow - span,
          max: info.baseHigh + span,
          decimals: decimals,
          status: _status ?? VStatus.sinDato,
        ),
        const SizedBox(height: 24),
        Wrap(children: [FilledButton(onPressed: () => _save(info), child: const Text('Guardar medición'))]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          widget.header,
          const SizedBox(height: 20),
          AsyncView<Trend>(
            future: _info!,
            builder: (context, info) {
              final aside = _InfoCard(
                title: 'DE DÓNDE SALE LA REGLA',
                body: [info.rule, if (info.source.isNotEmpty) info.source].join('\n\n'),
              );
              return LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth >= 1000;
                return wide
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: _form(context, info)),
                        const SizedBox(width: 24),
                        SizedBox(width: 340, child: aside),
                      ])
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        _form(context, info),
                        const SizedBox(height: 20),
                        aside,
                      ]);
              });
            },
          ),
        ]),
      );
}
