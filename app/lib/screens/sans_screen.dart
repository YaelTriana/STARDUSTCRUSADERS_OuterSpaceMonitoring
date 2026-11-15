import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../l10n/labels.dart';
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

  void _reload() => setState(() => _trend = AppScope.of(context).api.sansTrend());

  Future<void> _evaluate() async {
    final v = _value;
    final id = ++_request;
    if (v == null) {
      setState(() => _status = null);
      return;
    }
    try {
      final s = await AppScope.of(context).api.evaluateSans(v);
      // Ignora respuestas viejas si se siguió escribiendo.
      if (mounted && id == _request) setState(() => _status = s);
    } catch (_) {
      if (mounted && id == _request) setState(() => _status = VStatus.sinDato);
    }
  }

  Future<void> _addToSummary() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final status = _status;
    if (status == null) return;
    final ok = await AppScope.of(context).addToSummary(l.sansSummaryEntry(_delta.text, l.status(status).toLowerCase()));
    messenger.showSnackBar(SnackBar(content: Text(ok ? l.sansAdded : l.summaryOffline)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final flagged = _status == VStatus.atencion || _status == VStatus.critico;

    final form = SectionCard(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(l.sansTitle, style: t.headlineMedium),
          if (_status != null) StatusChip(_status!),
        ]),
        const SizedBox(height: 8),
        Text(l.sansIntro, style: const TextStyle(fontSize: VType.body, color: VColors.muted, height: 1.5)),
        const SizedBox(height: 22),
        SizedBox(
          width: 320,
          child: TextField(
            key: const Key('sans-input'),
            controller: _delta,
            onChanged: (_) => _evaluate(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: mono(size: 30),
            decoration: InputDecoration(labelText: l.sansFieldLabel, hintText: l.sansFieldHint),
          ),
        ),
        const SizedBox(height: 22),
        _ThresholdBar(value: _value, status: _status ?? VStatus.sinDato),
        const SizedBox(height: 10),
        Text(l.sansPublished, style: const TextStyle(fontSize: VType.label, color: VColors.muted, height: 1.5)),
        if (flagged) ...[
          const SizedBox(height: 20),
          AlertBanner(
            title: _status == VStatus.critico ? l.sansAlertCriticalTitle : l.sansAlertAttentionTitle,
            body: _status == VStatus.critico ? l.sansAlertCriticalBody : l.sansAlertAttentionBody,
            status: _status!,
          ),
          const SizedBox(height: 16),
          Wrap(children: [FilledButton(onPressed: _addToSummary, child: Text(l.sansAddSummary))]),
        ],
      ]),
    );

    final history = AsyncView<Map<String, dynamic>>(
      future: _trend!,
      onRetry: _reload,
      builder: (context, body) {
        final series = [for (final v in body['series'] as List) (v as num).toDouble()];
        final days = [for (final d in body['days'] as List) d as int];
        return SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(l.sansHistoryTitle, style: overline()),
              StatusChip(statusFromApi(body['status'] as String?)),
            ]),
            const SizedBox(height: 12),
            if (series.isEmpty)
              Text(l.sansHistoryEmpty, style: const TextStyle(fontSize: VType.body, height: 1.5))
            else
              for (var i = 0; i < series.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(l.sansHistoryRow(i < days.length ? '${days[i]}' : '?', series[i].toStringAsFixed(0)),
                      style: mono(size: 15)),
                ),
            const SizedBox(height: 12),
            Text(body['source'] as String? ?? '', style: const TextStyle(fontSize: VType.label, color: VColors.muted, height: 1.5)),
          ]),
        );
      },
    );

    final info = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _InfoCard(title: l.sansWhatTitle, body: l.sansWhatBody),
      const SizedBox(height: 16),
      _InfoCard(title: l.sansWhyTitle, body: l.sansWhyBody),
      const SizedBox(height: 16),
      _InfoCard(title: l.sansDoTitle, body: l.sansDoBody),
    ]);

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 1000;
      return SingleChildScrollView(
        padding: EdgeInsets.all(c.maxWidth < 600 ? VSpace.lg : 28),
        child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [form, const SizedBox(height: 20), history])),
                const SizedBox(width: 24),
                SizedBox(width: 340, child: info),
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
/// El valor se marca con un triángulo (▼) y se escribe con su estado: no depende solo del color.
class _ThresholdBar extends StatelessWidget {
  const _ThresholdBar({required this.value, required this.status});
  final double? value;
  final VStatus status;

  static const _max = 70.0;
  static const _attention = 20.0;
  static const _critical = 55.0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    double frac(double v) => (v / _max).clamp(0.0, 1.0);
    final v = value;
    return Semantics(
      label: l.sansBarSemantics + (v == null ? '' : l.sansBarValue(v.toStringAsFixed(0))),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(color: VColors.surface2, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (v != null) ...[
            Text(l.sansYourValue(v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1), l.status(status)),
                style: mono(size: 15, color: statusColor(status))),
            const SizedBox(height: 6),
          ],
          LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            Widget band(double from, double to, Color color) => Positioned(
                  top: 24,
                  left: w * frac(from),
                  width: w * (frac(to) - frac(from)),
                  child: Container(height: 14, color: color),
                );
            Widget tick(double at) => Positioned(
                  top: 20,
                  left: w * frac(at) - 1,
                  child: Container(width: 2, height: 22, color: VColors.text),
                );
            return SizedBox(
              height: 44,
              child: Stack(clipBehavior: Clip.none, children: [
                band(0, _attention, const Color(0xFF2B6B4F)),
                band(_attention, _critical, const Color(0xFF7A5A1E)),
                band(_critical, _max, const Color(0xFF7A2E28)),
                tick(_attention),
                tick(_critical),
                if (v != null)
                  Positioned(
                    left: (w * frac(v) - 12).clamp(-4.0, w - 20),
                    top: 0,
                    child: Icon(Icons.arrow_drop_down, size: 24, color: statusColor(status)),
                  ),
              ]),
            );
          }),
          const SizedBox(height: 10),
          Wrap(spacing: 18, runSpacing: 6, children: [
            Text(l.sansMarkNone, style: mono(size: 12, color: VColors.muted)),
            Text(l.sansMarkAttention, style: mono(size: 12, color: VColors.muted)),
            Text(l.sansMarkCritical, style: mono(size: 12, color: VColors.muted)),
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
          Text(body, style: const TextStyle(fontSize: VType.body, height: 1.55)),
        ]),
      );
}
