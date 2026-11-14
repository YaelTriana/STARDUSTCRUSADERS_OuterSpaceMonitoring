import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/body_figure.dart';
import '../widgets/common.dart';

/// Panel principal: figura corporal + detalle del sistema seleccionado.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onGoTo});
  final ValueChanged<int> onGoTo;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<Dashboard>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).api.dashboard();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AsyncView<Dashboard>(
      future: _future!,
      builder: (context, d) {
        final current = d.system(state.selectedSystem);
        final bodyCard = SectionCard(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ESTADO POR SISTEMA · TOCA UNA ZONA', style: overline(color: VColors.muted)),
            const SizedBox(height: 12),
            BodyFigure(systems: d.systems, selected: state.selectedSystem, onSelect: state.selectSystem),
          ]),
        );
        final detail = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SystemDetail(system: current),
          const SizedBox(height: 20),
          _TaskRow(dashboard: d, onMeasure: () => widget.onGoTo(1)),
        ]);
        return LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 1000;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 400, child: bodyCard),
                    const SizedBox(width: 24),
                    Expanded(child: detail),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [bodyCard, const SizedBox(height: 20), detail]),
          );
        });
      },
    );
  }
}

class _SystemDetail extends StatelessWidget {
  const _SystemDetail({required this.system});
  final BodySystem system;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(system.name, style: t.headlineMedium),
          StatusChip(system.status),
        ]),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 600 ? 3 : 1;
          return Wrap(spacing: 14, runSpacing: 14, children: [
            for (final i in system.indicators)
              SizedBox(
                width: (c.maxWidth - 14 * (cols - 1)) / cols,
                child: MetricTile(
                  label: i.label,
                  value: i.value,
                  unit: i.unit,
                  note: i.note,
                  noteColor: i.status == VStatus.nominal ? VColors.muted : statusColor(i.status),
                ),
              ),
          ]);
        }),
        const SizedBox(height: 20),
        Wrap(spacing: 24, runSpacing: 16, children: [
          _Explain(title: 'POR QUÉ CAMBIA EN EL ESPACIO', body: system.why),
          _Explain(title: 'QUÉ HACER AHORA', body: system.action),
        ]),
      ]),
    );
  }
}

class _Explain extends StatelessWidget {
  const _Explain({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: overline()),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 15, height: 1.55)),
        ]),
      );
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.dashboard, required this.onMeasure});
  final Dashboard dashboard;
  final VoidCallback onMeasure;

  @override
  Widget build(BuildContext context) {
    final pending = dashboard.tasks.first;
    final other = dashboard.tasks.length > 1 ? dashboard.tasks[1] : null;
    final ratio = dashboard.exerciseDone / dashboard.exerciseGoal;
    Widget card(Widget child) => SizedBox(width: 220, child: SectionCard(padding: const EdgeInsets.all(16), child: child));
    return Wrap(spacing: 14, runSpacing: 14, children: [
      SizedBox(
        width: 220,
        child: Material(
          color: VColors.signal,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onMeasure,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PENDIENTE · ${pending['time']}', style: mono(size: 12, color: VColors.onStatus)),
                const SizedBox(height: 4),
                Text('${pending['title']}',
                    style: const TextStyle(color: VColors.onStatus, fontWeight: FontWeight.w600, fontSize: 16)),
                Text('${pending['detail']}', style: const TextStyle(color: VColors.onStatus, fontSize: 13)),
              ]),
            ),
          ),
        ),
      ),
      if (other != null)
        card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('HOY · ${other['time']}', style: mono(size: 12, color: VColors.muted)),
          const SizedBox(height: 4),
          Text('${other['title']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          Text('${other['detail']}', style: const TextStyle(fontSize: 13, color: VColors.muted)),
        ])),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EJERCICIO', style: mono(size: 12, color: VColors.muted)),
        const SizedBox(height: 4),
        Text('${dashboard.exerciseDone ~/ 60} h ${dashboard.exerciseDone % 60} min de ~2 h',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
              value: ratio, minHeight: 6, backgroundColor: VColors.border, color: VColors.nominal),
        ),
      ])),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RACHA DE REGISTRO', style: mono(size: 12, color: VColors.muted)),
        Text.rich(TextSpan(children: [
          TextSpan(text: '${dashboard.streakDays}', style: mono(size: 26)),
          TextSpan(text: ' días', style: mono(size: 14, color: VColors.muted)),
        ])),
        const Text('Insignia «Constancia orbital»', style: TextStyle(fontSize: 13, color: VColors.muted)),
      ])),
    ]);
  }
}
