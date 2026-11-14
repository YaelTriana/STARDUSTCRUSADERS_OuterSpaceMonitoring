import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Medición guiada de presión arterial. La evaluación la hace Python.
class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
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
        _RangeBar(value: _sysValue, low: _baseLow, high: _baseHigh, status: _status ?? VStatus.sinDato),
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
        child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 280, child: steps),
                const SizedBox(width: 24),
                Expanded(child: form),
                const SizedBox(width: 24),
                const SizedBox(width: 320, child: aside),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                steps,
                const SizedBox(height: 20),
                form,
                const SizedBox(height: 20),
                aside,
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
  const _RangeBar({required this.value, required this.low, required this.high, required this.status});
  final double? value;
  final double low;
  final double high;
  final VStatus status;

  static const _min = 90.0;
  static const _max = 160.0;

  @override
  Widget build(BuildContext context) {
    double frac(double v) => ((v - _min) / (_max - _min)).clamp(0.0, 1.0);
    final delta = value == null ? null : value! - high;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(color: VColors.surface2, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Expanded(child: Text('Sistólica frente a tu rango personal', style: TextStyle(fontSize: 14))),
          if (delta != null)
            Text(delta > 0 ? '+${delta.toStringAsFixed(0)} sobre tu base' : 'dentro de tu base',
                style: mono(size: 14, color: statusColor(status))),
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
          Text(_min.toStringAsFixed(0), style: mono(size: 12, color: VColors.muted)),
          Text('Tu rango prevuelo ${low.toStringAsFixed(0)}–${high.toStringAsFixed(0)}', style: mono(size: 12, color: VColors.muted)),
          Text(_max.toStringAsFixed(0), style: mono(size: 12, color: VColors.muted)),
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
