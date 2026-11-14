import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/touch.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/numeric_keypad.dart';
import 'trend_screen.dart' show MetricSelector;

/// Medición guiada de presión arterial en 4 pasos. La evaluación la hace Python.
///
/// Los rangos de "plausible" son supuestos de diseño para detectar errores de captura,
/// no umbrales clínicos.
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
    final selector = MetricSelector(selected: _metric, onSelected: (m) => setState(() => _metric = m));
    return _metric == 'systolic'
        ? _BloodPressureMeasurement(selector: selector)
        : _GenericMeasurement(key: ValueKey(_metric), metric: _metric, selector: selector);
  }
}

/// Medición guiada de presión arterial (4 pasos, teclado numérico táctil).
class _BloodPressureMeasurement extends StatefulWidget {
  const _BloodPressureMeasurement({required this.selector});
  final Widget selector;

  @override
  State<_BloodPressureMeasurement> createState() => _BloodPressureState();
}

enum _Field { sys, dia, hr }

class _BloodPressureState extends State<_BloodPressureMeasurement> {
  static const _steps = 4;
  static const _repeatDelay = Duration(minutes: 5);

  // Rangos plausibles por campo (mín, máx).
  static const _plausible = {
    _Field.sys: (70, 250),
    _Field.dia: (40, 150),
    _Field.hr: (30, 220),
  };

  int _step = 0;
  _Field _active = _Field.sys;
  // Valores de ejemplo para la demo (datos sintéticos).
  final Map<_Field, String> _values = {_Field.sys: '132', _Field.dia: '84', _Field.hr: '64'};
  String _source = 'manual';

  VStatus? _status;
  bool _busy = false;
  int _evalSeq = 0;
  double _baseLow = 110; // respaldo mientras Python no responde con la base
  double _baseHigh = 126;

  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double? get _sysValue => double.tryParse(_values[_Field.sys]!);

  // ---- captura ----
  void _press(String d) {
    final cur = _values[_active]!;
    if (cur.length >= 3) return;
    setState(() => _values[_active] = cur == '0' ? d : cur + d);
    if (_active == _Field.sys) _evaluate();
  }

  void _backspace() {
    final cur = _values[_active]!;
    if (cur.isEmpty) return;
    setState(() => _values[_active] = cur.substring(0, cur.length - 1));
    if (_active == _Field.sys) _evaluate();
  }

  void _nextField() => setState(() {
        _active = switch (_active) {
          _Field.sys => _Field.dia,
          _Field.dia => _Field.hr,
          _Field.hr => _Field.sys,
        };
      });

  Future<void> _evaluate() async {
    final v = _sysValue;
    if (v == null) {
      setState(() => _status = VStatus.sinDato);
      return;
    }
    final seq = ++_evalSeq;
    setState(() => _busy = true);
    try {
      final r = await AppScope.of(context).api.evaluateRaw('systolic', v);
      if (!mounted || seq != _evalSeq) return;
      setState(() {
        _status = statusFromApi(r['status'] as String?);
        final b = r['base'];
        if (b is Map) {
          _baseLow = (b['low'] as num).toDouble();
          _baseHigh = (b['high'] as num).toDouble();
        }
      });
    } catch (_) {
      if (mounted && seq == _evalSeq) setState(() => _status = VStatus.sinDato);
    } finally {
      if (mounted && seq == _evalSeq) setState(() => _busy = false);
    }
  }

  // ---- navegación entre pasos ----
  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _next() async {
    final l = context.l10n;
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    // Paso 3 → resultado: validar antes de avanzar.
    final sys = int.tryParse(_values[_Field.sys]!);
    final dia = int.tryParse(_values[_Field.dia]!);
    final messenger = ScaffoldMessenger.of(context);
    if (sys == null || dia == null) {
      messenger.showSnackBar(SnackBar(content: Text(l.measFillRequired)));
      return;
    }
    if (sys <= dia) {
      messenger.showSnackBar(SnackBar(content: Text(l.measSysLtDia)));
      return;
    }
    for (final f in _Field.values) {
      final v = int.tryParse(_values[f]!);
      if (v == null) continue;
      final (lo, hi) = _plausible[f]!;
      if (v < lo || v > hi) {
        final ok = await _confirmImplausible(v);
        if (ok != true) {
          setState(() => _active = f);
          return;
        }
      }
    }
    await _evaluate();
    if (mounted) setState(() => _step = 3);
  }

  Future<bool?> _confirmImplausible(int value) {
    final l = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VColors.surface,
        title: Text(l.measConfirmTitle('$value')),
        content: Text(l.measConfirmBody, style: const TextStyle(fontSize: VType.body, height: 1.5)),
        actionsOverflowButtonSpacing: Touch.gap,
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: Touch.minSize),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.measConfirmFix),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.measConfirmKeep)),
        ],
      ),
    );
  }

  // ---- repetir en 5 min ----
  void _startRepeat() {
    _timer?.cancel();
    setState(() => _remaining = _repeatDelay.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _remaining = 0);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.repeatDue)));
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _cancelRepeat() {
    _timer?.cancel();
    setState(() => _remaining = 0);
  }

  String _mmss(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // ---- guardar ----
  Future<void> _save() async {
    final state = AppScope.of(context);
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (_status != null && _status != VStatus.nominal) {
      await state.addToSummary(l.summaryEntry(
        _values[_Field.sys]!,
        _values[_Field.dia]!,
        l.status(_status!).toLowerCase(),
      ));
    }
    messenger.showSnackBar(SnackBar(
      content: Text(_status == VStatus.nominal ? l.savedOk : l.savedSummary),
    ));
  }

  // ---- UI ----
  String _stepTitle(AppLocalizations l, int i) =>
      [l.measStep1Title, l.measStep2Title, l.measStep3Title, l.measStep4Title][i];
  String _stepDetail(AppLocalizations l, int i) =>
      [l.measStep1Detail, l.measStep2Detail, l.measStep3Detail, l.measStep4Detail][i];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;

    final header = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.measStepCounter(_step + 1, _steps, _stepTitle(l, _step)), style: overline()),
      const SizedBox(height: VSpace.sm),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: (_step + 1) / _steps,
          minHeight: 6,
          backgroundColor: VColors.border,
          color: VColors.signal,
        ),
      ),
    ]);

    final body = switch (_step) {
      0 => _InfoStep(icon: Icons.self_improvement, title: _stepTitle(l, 0), detail: _stepDetail(l, 0)),
      1 => _InfoStep(icon: Icons.monitor_heart_outlined, title: _stepTitle(l, 1), detail: _stepDetail(l, 1)),
      2 => _entry(l, t),
      _ => _result(l, t),
    };

    final nav = Wrap(spacing: Touch.gapCritical, runSpacing: Touch.gapCritical, children: [
      if (_step > 0) OutlinedButton(onPressed: _back, child: Text(l.measBack)),
      if (_step < 3) FilledButton(onPressed: _next, child: Text(_step == 2 ? l.measSeeResult : l.measNext)),
    ]);

    final main = SectionCard(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        header,
        const SizedBox(height: VSpace.xl),
        body,
        const SizedBox(height: VSpace.xl),
        nav,
      ]),
    );

    final aside = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _HelpTile(title: l.helpWhatTitle, body: l.helpWhatBody),
      const SizedBox(height: Touch.gap),
      _HelpTile(title: l.helpWhyTitle, body: l.helpWhyBody),
      const SizedBox(height: Touch.gap),
      _HelpTile(title: l.helpTipTitle, body: l.helpTipBody),
    ]);

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 1000;
      return SingleChildScrollView(
        padding: EdgeInsets.all(c.maxWidth < 600 ? VSpace.lg : 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          widget.selector,
          const SizedBox(height: VSpace.lg),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: main),
              const SizedBox(width: 24),
              SizedBox(width: 320, child: aside),
            ])
          else ...[main, const SizedBox(height: 20), aside],
        ]),
      );
    });
  }

  Widget _entry(AppLocalizations l, TextTheme t) {
    String name(_Field f) => switch (f) { _Field.sys => l.measSys, _Field.dia => l.measDia, _Field.hr => l.measHr };
    String unit(_Field f) => f == _Field.hr ? 'lpm' : 'mmHg';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(l.measTitle, style: t.headlineMedium),
        if (_status != null) StatusChip(_status!),
        if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      ]),
      const SizedBox(height: VSpace.lg),
      Wrap(spacing: Touch.gapCritical, runSpacing: Touch.gapCritical, children: [
        for (final f in _Field.values)
          _FieldTile(
            label: name(f),
            unit: unit(f),
            value: _values[f]!,
            selected: f == _active,
            onTap: () => setState(() => _active = f),
          ),
      ]),
      const SizedBox(height: VSpace.lg),
      Text(l.measSource, style: overline(color: VColors.muted)),
      const SizedBox(height: VSpace.sm),
      Wrap(spacing: Touch.gap, runSpacing: Touch.gap, children: [
        for (final (id, label) in [
          ('manual', l.measSourceManual),
          ('wearable', l.measSourceWearable),
          ('ultrasound', l.measSourceUltrasound),
        ])
          ChoiceChip(
            label: Text(label, style: const TextStyle(fontSize: VType.body)),
            selected: _source == id,
            onSelected: (_) => setState(() => _source = id),
          ),
      ]),
      const SizedBox(height: VSpace.lg),
      _RangeMeter(value: _sysValue, low: _baseLow, high: _baseHigh, status: _status ?? VStatus.sinDato),
      const SizedBox(height: VSpace.lg),
      Center(
        child: NumericKeypad(
          onDigit: _press,
          onBackspace: _backspace,
          onNextField: _nextField,
          backspaceLabel: l.keypadBackspace,
          nextFieldLabel: l.keypadNextField,
        ),
      ),
    ]);
  }

  Widget _result(AppLocalizations l, TextTheme t) {
    final status = _status ?? VStatus.sinDato;
    final advice = switch (status) {
      VStatus.nominal => l.resultNominal,
      VStatus.atencion => l.resultAtencion,
      VStatus.critico => l.resultCritico,
      VStatus.sinDato => l.resultNoData,
    };
    final counting = _remaining > 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('${_values[_Field.sys]}/${_values[_Field.dia]}', style: mono(size: 40)),
        Text('mmHg', style: mono(size: 16, color: VColors.muted)),
        StatusChip(status),
      ]),
      const SizedBox(height: VSpace.lg),
      _RangeMeter(value: _sysValue, low: _baseLow, high: _baseHigh, status: status),
      const SizedBox(height: VSpace.xl),
      Text(l.panelActionTitle, style: overline()),
      const SizedBox(height: VSpace.sm),
      Text(advice, style: const TextStyle(fontSize: VType.bodyLarge, height: 1.5)),
      const SizedBox(height: VSpace.xl),
      Wrap(spacing: Touch.gapCritical, runSpacing: Touch.gapCritical, children: [
        FilledButton(onPressed: _save, child: Text(l.measSave)),
        OutlinedButton(
          onPressed: counting ? _cancelRepeat : _startRepeat,
          child: Text(counting ? '${l.repeatCountdown(_mmss(_remaining))} · ${l.repeatCancel}' : l.repeatIn5),
        ),
      ]),
    ]);
  }
}

class _InfoStep extends StatelessWidget {
  const _InfoStep({required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: VSpace.xl),
        child: Column(children: [
          Icon(icon, size: 72, color: VColors.signalSoft),
          const SizedBox(height: VSpace.lg),
          Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: VSpace.sm),
          Text(detail, style: const TextStyle(fontSize: VType.bodyLarge, color: VColors.muted), textAlign: TextAlign.center),
        ]),
      );
}

/// Campo numérico que se elige tocando (no abre el teclado del sistema).
class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.label, required this.unit, required this.value, required this.selected, required this.onTap});
  final String label;
  final String unit;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '$label, ${value.isEmpty ? '—' : value} $unit',
        excludeSemantics: true,
        child: Material(
          color: selected ? VColors.surface : VColors.surface2,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: 190,
              constraints: const BoxConstraints(minHeight: Touch.primary + 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? VColors.signal : VColors.borderStrong, width: selected ? 2 : 1),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: VType.label, color: VColors.muted)),
                const SizedBox(height: 2),
                Text.rich(TextSpan(children: [
                  TextSpan(text: value.isEmpty ? '—' : value, style: mono(size: 30)),
                  TextSpan(text: ' $unit', style: mono(size: 13, color: VColors.muted)),
                ])),
              ]),
            ),
          ),
        ),
      );
}

/// Medidor contra la línea base personal: banda del rango + marcador con forma (▼).
class _RangeMeter extends StatelessWidget {
  const _RangeMeter({
    required this.value,
    required this.low,
    required this.high,
    required this.status,
    this.min = 90,
    this.max = 160,
    this.decimals = 0,
    this.title,
  });
  final double? value;
  final double low;
  final double high;
  final VStatus status;
  final double min;
  final double max;
  final int decimals;
  final String? title;

  double get _min => min;
  double get _max => max;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    double frac(double v) => ((v - _min) / (_max - _min)).clamp(0.0, 1.0);
    final delta = value == null ? null : (value! > high ? value! - high : (value! < low ? value! - low : 0.0));
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(color: VColors.surface2, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(alignment: WrapAlignment.spaceBetween, spacing: 12, runSpacing: 4, children: [
          Text(title ?? l.rangeTitle, style: const TextStyle(fontSize: VType.body)),
          if (delta != null)
            Text(delta > 0 ? l.rangeOver(delta.toStringAsFixed(decimals)) : (delta < 0 ? l.rangeUnder(delta.abs().toStringAsFixed(decimals)) : l.rangeInside),
                style: mono(size: 14, color: statusColor(status))),
        ]),
        const SizedBox(height: VSpace.md),
        LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          return SizedBox(
            height: 44,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: Container(height: 14, decoration: BoxDecoration(color: VColors.border, borderRadius: BorderRadius.circular(7))),
              ),
              Positioned(
                top: 24,
                left: w * frac(low),
                width: w * (frac(high) - frac(low)),
                child: Container(height: 14, decoration: BoxDecoration(color: const Color(0xFF2B6B4F), borderRadius: BorderRadius.circular(7))),
              ),
              if (value != null)
                Positioned(
                  left: (w * frac(value!) - 12).clamp(-4.0, w - 20),
                  top: 0,
                  child: Icon(Icons.arrow_drop_down, size: 24, color: statusColor(status)),
                ),
            ]),
          );
        }),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_min.toStringAsFixed(decimals), style: mono(size: 12, color: VColors.muted)),
          Flexible(
            child: Text(l.rangeBase(low.toStringAsFixed(decimals), high.toStringAsFixed(decimals)),
                textAlign: TextAlign.center, style: mono(size: 12, color: VColors.muted)),
          ),
          Text(_max.toStringAsFixed(decimals), style: mono(size: 12, color: VColors.muted)),
        ]),
      ]),
    );
  }
}

/// Ayuda desplegable para no saturar la pantalla.
class _HelpTile extends StatelessWidget {
  const _HelpTile({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: VColors.surface,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                minTileHeight: Touch.primary,
                tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: Text(title, style: overline()),
                children: [Text(body, style: const TextStyle(fontSize: VType.body, height: 1.55))],
              ),
            ),
          ),
        ),
      );
}

/// Medición de una métrica del catálogo con un solo valor (FC, sueño, ánimo…).
/// Etiqueta, unidad, base y regla vienen de Python (`/trend/{metric}`).
class _GenericMeasurement extends StatefulWidget {
  const _GenericMeasurement({super.key, required this.metric, required this.selector});
  final String metric;
  final Widget selector;

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
    try {
      final s = await AppScope.of(context).api.evaluate(widget.metric, v);
      if (mounted && id == _request) setState(() => _status = s);
    } catch (_) {
      if (mounted && id == _request) setState(() => _status = VStatus.sinDato);
    }
  }

  Future<void> _save(Trend info) async {
    final state = AppScope.of(context);
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final flagged = _status == VStatus.atencion || _status == VStatus.critico;
    if (flagged) {
      await state.addToSummary(l.measGenericSummaryEntry(info.label, _value.text, info.unit, l.status(_status!).toLowerCase()));
    }
    messenger.showSnackBar(SnackBar(content: Text(flagged ? l.measSavedAdded : l.measSavedOk)));
  }

  Widget _form(BuildContext context, Trend info) {
    final l = context.l10n;
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
          Text(l.measNoBase, style: const TextStyle(fontSize: VType.body, height: 1.55)),
        ]),
      );
    }
    final span = info.baseHigh - info.baseLow;
    final decimals = span < 5 ? 1 : 0;
    return SectionCard(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(l.measTitle, style: t.headlineMedium),
          if (_status != null) StatusChip(_status!),
        ]),
        const SizedBox(height: 22),
        SizedBox(
          width: 280,
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
        _RangeMeter(
          title: l.measGenericRangeTitle(info.label),
          value: _parsed,
          low: info.baseLow,
          high: info.baseHigh,
          min: info.baseLow - span,
          max: info.baseHigh + span,
          decimals: decimals,
          status: _status ?? VStatus.sinDato,
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: () => _save(info), child: Text(l.measSave)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        widget.selector,
        const SizedBox(height: 20),
        AsyncView<Trend>(
          future: _info!,
          builder: (context, info) {
            final aside = _HelpTile(title: l.measRuleOrigin, body: [info.rule, if (info.source.isNotEmpty) info.source].join('\n\n'));
            return LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 1000;
              return wide
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _form(context, info)),
                      const SizedBox(width: 24),
                      SizedBox(width: 340, child: aside),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_form(context, info), const SizedBox(height: 20), aside]);
            });
          },
        ),
      ]),
    );
  }
}
