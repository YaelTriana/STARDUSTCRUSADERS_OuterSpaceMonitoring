import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/touch.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../theme.dart';
import '../widgets/body_figure.dart';
import '../widgets/common.dart';

/// Panel principal: resumen de atención + figura corporal + detalle del sistema.
///
/// Objetivo: que el astronauta sepa en 3 s si algo requiere atención y qué hacer primero.
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

  void _retry() => setState(() => _future = AppScope.of(context).api.dashboard());

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = AppLocalizations.of(context);
    return AsyncView<Dashboard>(
      future: _future!,
      onRetry: _retry,
      loading: const _DashboardSkeleton(),
      builder: (context, d) {
        final current = d.system(state.selectedSystem);
        final bodyCard = SectionCard(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.panelBodyTitle, style: overline(color: VColors.muted)),
            const SizedBox(height: VSpace.md),
            BodyFigure(systems: d.systems, selected: state.selectedSystem, onSelect: state.selectSystem),
            const SizedBox(height: VSpace.lg),
            const _Legend(),
          ]),
        );
        final detail = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SystemDetail(system: current, onMeasure: () => widget.onGoTo(1)),
          const SizedBox(height: 20),
          _TaskRow(dashboard: d, onMeasure: () => widget.onGoTo(1)),
        ]);
        return LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 1000;
          return SingleChildScrollView(
            padding: EdgeInsets.all(c.maxWidth < 600 ? VSpace.lg : 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _SummaryStrip(dashboard: d, onSelect: state.selectSystem, onMeasure: () => widget.onGoTo(1)),
              const SizedBox(height: 20),
              if (wide)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 400, child: bodyCard),
                  const SizedBox(width: 24),
                  Expanded(child: detail),
                ])
              else ...[bodyCard, const SizedBox(height: 20), detail],
            ]),
          );
        });
      },
    );
  }
}

/// Esqueleto mientras el motor de Python responde.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SkeletonBox(height: 88),
          SizedBox(height: 20),
          SkeletonBox(height: 320),
          SizedBox(height: 20),
          SkeletonBox(height: 120),
        ]),
      );
}

/// Franja superior: cuántos sistemas requieren atención y la tarea más urgente.
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.dashboard, required this.onSelect, required this.onMeasure});
  final Dashboard dashboard;
  final ValueChanged<String> onSelect;
  final VoidCallback onMeasure;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Críticos primero, luego atención.
    final attention = [
      for (final s in dashboard.systems)
        if (s.status == VStatus.critico || s.status == VStatus.atencion) s,
    ]..sort((a, b) => a.status == b.status ? 0 : (a.status == VStatus.critico ? -1 : 1));
    final worst = attention.isEmpty ? VStatus.nominal : attention.first.status;
    final urgent = dashboard.tasks.isEmpty ? null : dashboard.tasks.first;

    final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        StatusShape(worst, size: 20),
        const SizedBox(width: VSpace.md),
        Expanded(
          child: Text(
            attention.isEmpty ? l.summaryAllClear : l.summaryAttention(attention.length),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ]),
      if (attention.isNotEmpty) ...[
        const SizedBox(height: VSpace.md),
        Wrap(spacing: Touch.gap, runSpacing: Touch.gap, children: [
          for (final s in attention)
            ActionChip(
              avatar: StatusShape(s.status, size: 12),
              label: Text(s.name, style: const TextStyle(fontSize: VType.body)),
              side: const BorderSide(color: VColors.borderStrong),
              backgroundColor: VColors.surface2,
              onPressed: () => onSelect(s.id),
            ),
        ]),
      ],
    ]);

    final cta = urgent == null
        ? null
        : FilledButton(onPressed: onMeasure, child: Text('${urgent['title']}'));

    return SectionCard(
      highlight: attention.isNotEmpty,
      padding: const EdgeInsets.all(VSpace.xl - 4),
      child: LayoutBuilder(builder: (context, c) {
        if (cta == null) return info;
        if (c.maxWidth >= 640) {
          return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: info),
            const SizedBox(width: VSpace.xl),
            cta,
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          info,
          const SizedBox(height: VSpace.lg),
          cta,
        ]);
      }),
    );
  }
}

/// Leyenda: cada estado con su forma, su color y su palabra.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Wrap(spacing: VSpace.lg, runSpacing: VSpace.sm, children: [
      for (final s in VStatus.values)
        Row(mainAxisSize: MainAxisSize.min, children: [
          StatusShape(s, size: 12),
          const SizedBox(width: 6),
          Text(l.status(s), style: const TextStyle(fontSize: VType.label, color: VColors.muted)),
        ]),
    ]);
  }
}

class _SystemDetail extends StatelessWidget {
  const _SystemDetail({required this.system, required this.onMeasure});
  final BodySystem system;
  final VoidCallback onMeasure;

  void _showSource(BuildContext context) {
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VColors.surface,
        title: Text(l.sourceNoteTitle),
        content: Text(l.sourceNoteBody, style: const TextStyle(fontSize: VType.body, height: 1.5)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(system.name, style: t.headlineMedium),
          StatusChip(system.status),
        ]),
        const SizedBox(height: 18),
        if (system.status == VStatus.sinDato && system.indicators.isEmpty)
          OutlinedButton.icon(onPressed: onMeasure, icon: const Icon(Icons.straighten), label: Text(l.noDataMeasure))
        else
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
          _Explain(title: l.panelWhyTitle, body: system.why),
          _Explain(title: l.panelActionTitle, body: system.action),
        ]),
        const SizedBox(height: VSpace.lg),
        ActionChip(
          avatar: const Icon(Icons.info_outline, size: 18, color: VColors.signalSoft),
          label: Text(l.sourceChip),
          side: const BorderSide(color: VColors.borderStrong),
          backgroundColor: VColors.surface2,
          onPressed: () => _showSource(context),
        ),
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
          Text(body, style: const TextStyle(fontSize: VType.body, height: 1.55)),
        ]),
      );
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.dashboard, required this.onMeasure});
  final Dashboard dashboard;
  final VoidCallback onMeasure;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pending = dashboard.tasks.isEmpty ? null : dashboard.tasks.first;
    final other = dashboard.tasks.length > 1 ? dashboard.tasks[1] : null;
    final ratio = (dashboard.exerciseDone / dashboard.exerciseGoal).clamp(0.0, 1.0);
    Widget card(Widget child) => SizedBox(width: 220, child: SectionCard(padding: const EdgeInsets.all(16), child: child));
    return Wrap(spacing: 14, runSpacing: 14, children: [
      if (pending != null)
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
                  Text(l.taskPending('${pending['time']}'), style: mono(size: 12, color: VColors.onStatus)),
                  const SizedBox(height: 4),
                  Text('${pending['title']}',
                      style: const TextStyle(color: VColors.onStatus, fontWeight: FontWeight.w600, fontSize: VType.body)),
                  Text('${pending['detail']}', style: const TextStyle(color: VColors.onStatus, fontSize: VType.label)),
                ]),
              ),
            ),
          ),
        ),
      if (other != null)
        card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.taskToday('${other['time']}'), style: mono(size: 12, color: VColors.muted)),
          const SizedBox(height: 4),
          Text('${other['title']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: VType.body)),
          Text('${other['detail']}', style: const TextStyle(fontSize: VType.label, color: VColors.muted)),
        ])),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.exerciseLabel, style: mono(size: 12, color: VColors.muted)),
        const SizedBox(height: 4),
        Text(l.exerciseProgress(dashboard.exerciseDone ~/ 60, dashboard.exerciseDone % 60),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: VType.body)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: ratio, minHeight: 6, backgroundColor: VColors.border, color: VColors.nominal),
        ),
      ])),
      // Racha amable: premia la constancia, nunca castiga.
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.streakLabel, style: mono(size: 12, color: VColors.muted)),
        Text.rich(TextSpan(children: [
          TextSpan(text: '${dashboard.streakDays}', style: mono(size: 26)),
          TextSpan(text: ' ${l.streakDays}', style: mono(size: 14, color: VColors.muted)),
        ])),
        Text(l.streakBadge, style: const TextStyle(fontSize: VType.label, color: VColors.muted)),
      ])),
    ]);
  }
}
