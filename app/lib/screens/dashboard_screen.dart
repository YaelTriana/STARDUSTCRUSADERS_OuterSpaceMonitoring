import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api.dart';
import '../app_state.dart';
import '../core/touch.dart';
import '../data/models.dart';
import '../l10n/labels.dart';
import '../theme.dart';
import '../widgets/body_figure.dart';
import '../widgets/common.dart';

/// Panel principal: resumen de atención + figura corporal + detalle del sistema.
///
/// Objetivo: que el astronauta sepa en 3 s si algo requiere atención y qué hacer primero.
///
/// Se refresca solo cada [refreshEvery]: los estados los calcula Python desde el
/// catálogo (datos de ejemplo o PostgreSQL), así que cambian sin que el tripulante
/// toque nada. Un refresco que falla no borra el último dato bueno.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onGoTo, this.refreshEvery = dashboardRefresh});
  final ValueChanged<int> onGoTo;
  final Duration refreshEvery;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Dashboard? _data;
  Object? _error; // solo manda mientras no haya ningún dato que mostrar
  bool _offline = false;
  DateTime? _updatedAt;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null) {
      _timer = Timer.periodic(widget.refreshEvery, (_) => _load());
      _load();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // al salir de la pantalla se deja de preguntar
    super.dispose();
  }

  Future<void> _load() async {
    final api = AppScope.of(context).api;
    try {
      final dashboard = await api.dashboard();
      if (!mounted) return;
      setState(() {
        _data = dashboard;
        _error = null;
        _offline = false;
        _updatedAt = DateTime.now();
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        if (_data == null) {
          _error = err;
        } else {
          _offline = true; // se conserva lo último conocido
        }
      });
    }
  }

  void _retry() => _load();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = context.l10n;
    if (_data == null) {
      if (_error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(VSpace.xxl),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l.errorEngine,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: VColors.critico, fontSize: VType.body)),
              const SizedBox(height: VSpace.sm),
              Text('$_error', textAlign: TextAlign.center, style: mono(size: 12, color: VColors.muted)),
              const SizedBox(height: VSpace.lg),
              OutlinedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: Text(l.retry),
              ),
            ]),
          ),
        );
      }
      return Semantics(label: l.loading, liveRegion: true, child: const _DashboardSkeleton());
    }
    final d = _data!;
    final current = d.system(state.selectedSystem);
    final bodyCard = SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // La marca de frescura va junto al título: es la señal de que el panel está vivo.
        Wrap(spacing: VSpace.md, runSpacing: VSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(l.panelBodyTitle, style: overline(color: VColors.muted)),
          _RefreshMark(updatedAt: _updatedAt, offline: _offline),
        ]),
        const SizedBox(height: VSpace.md),
        BodyFigure(systems: d.systems, selected: state.selectedSystem, onSelect: state.selectSystem),
        const SizedBox(height: VSpace.lg),
        const _Legend(),
      ]),
    );
    final detail = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SystemDetail(system: current, onMeasure: () => widget.onGoTo(current.id == 'ojos' ? 3 : 1)),
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
  }
}

/// Marca de frescura: cuándo se leyó por última vez y si la última lectura falló.
class _RefreshMark extends StatelessWidget {
  const _RefreshMark({required this.updatedAt, required this.offline});
  final DateTime? updatedAt;
  final bool offline;

  static String _hora(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final hora = updatedAt == null ? '—' : _hora(updatedAt!);
    if (!offline) {
      return Text('Actualizado $hora', style: mono(size: 11, color: VColors.muted));
    }
    return Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
      const StatusShape(VStatus.atencion, size: 9),
      Text('Sin conexión · último dato $hora', style: mono(size: 11, color: VColors.atencion)),
    ]);
  }
}

/// Esqueleto mientras el motor de Python responde.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
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
    final l = context.l10n;
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
    final l = context.l10n;
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
    final l = context.l10n;
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
    final l = context.l10n;
    // Atención/crítico: fondo surface2 y barra de 4 dp del color del estado.
    // Nominal (y sin dato): fondo surface y borde de 1 px (SectionCard).
    final alert = system.status == VStatus.atencion || system.status == VStatus.critico;
    const pad = EdgeInsets.fromLTRB(28, 24, 28, 24);
    final content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(system.name, style: t.headlineMedium),
        StatusChip(system.status),
      ]),
      const SizedBox(height: 18),
      if (system.status == VStatus.sinDato && system.indicators.isEmpty)
        OutlinedButton.icon(onPressed: onMeasure, icon: const Icon(Icons.straighten), label: Text(l.noDataMeasure))
      else
        _MetricRow(indicators: system.indicators),
      const SizedBox(height: 20),
      Wrap(spacing: 24, runSpacing: 16, children: [
        _Explain(title: l.panelWhyTitle, body: system.why),
        // "Qué hacer ahora" siempre resalta con la barra del color del estado,
        // nominal incluido: es la acción a tomar, no solo información.
        _Explain(title: l.panelActionTitle, body: system.action, barColor: statusColor(system.status)),
      ]),
      const SizedBox(height: VSpace.lg),
      ActionChip(
        avatar: const Icon(Icons.info_outline, size: 18, color: VColors.signalSoft),
        label: Text(l.sourceChip),
        side: const BorderSide(color: VColors.borderStrong),
        backgroundColor: VColors.surface2,
        onPressed: () => _showSource(context),
      ),
    ]);
    return alert
        ? StatusSideCard(color: statusColor(system.status), padding: pad, child: content)
        : SectionCard(padding: pad, child: content);
  }
}

/// "Ejercicio" como anillo de progreso (decorativo); el texto con el valor
/// (arriba) sigue siendo la fuente accesible, no el dibujo.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value});
  final double value;
  static const _size = 56.0;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: _size,
          height: _size,
          child: CustomPaint(
            painter: _RingPainter(value.clamp(0.0, 1.0)),
            child: Center(child: Text('${(value.clamp(0.0, 1.0) * 100).round()}%', style: mono(size: 13, weight: FontWeight.w600))),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    canvas.drawCircle(center, radius, Paint()..color = VColors.border..style = PaintingStyle.stroke..strokeWidth = 6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..color = VColors.nominal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

/// Las mediciones del sistema en una sola tarjeta, divididas en celdas por
/// líneas finas (no tarjetas sueltas): cifra grande + unidad + base con la
/// forma y la palabra del estado. En angosto (<700) pasa a columna.
class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.indicators});
  final List<Indicator> indicators;

  Widget _cell(Indicator i) {
    final valueColor = i.status == VStatus.nominal ? VColors.text : statusColor(i.status);
    final noteColor = i.status == VStatus.nominal ? VColors.muted : statusColor(i.status);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(i.label, style: const TextStyle(fontSize: VType.label, color: VColors.muted)),
        const SizedBox(height: 8),
        Text.rich(TextSpan(children: [
          TextSpan(text: i.value, style: mono(size: 44, color: valueColor, weight: FontWeight.w500)),
          if (i.unit.isNotEmpty) TextSpan(text: ' ${i.unit}', style: mono(size: 16, color: VColors.muted)),
        ])),
        const SizedBox(height: 10),
        Row(mainAxisSize: MainAxisSize.min, children: [
          StatusShape(i.status, size: 14, color: noteColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(i.note, style: TextStyle(fontSize: VType.label, color: noteColor), overflow: TextOverflow.ellipsis),
          ),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final narrow = c.maxWidth < 700;
        final cells = [for (final i in indicators) _cell(i)];
        return Container(
          decoration: BoxDecoration(
            color: VColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VColors.border),
          ),
          child: narrow
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (var j = 0; j < cells.length; j++) ...[
                    if (j > 0) const Divider(height: 1, color: VColors.border),
                    cells[j],
                  ],
                ])
              : IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (var j = 0; j < cells.length; j++) ...[
                      if (j > 0) const VerticalDivider(width: 1, color: VColors.border),
                      Expanded(child: cells[j]),
                    ],
                  ]),
                ),
        );
      });
}

class _Explain extends StatelessWidget {
  const _Explain({required this.title, required this.body, this.barColor});
  final String title;
  final String body;

  /// Si no es null, el texto va dentro de una StatusSideCard con esta barra.
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: overline()),
      const SizedBox(height: 8),
      Text(body, style: const TextStyle(fontSize: VType.body, height: 1.55)),
    ]);
    final color = barColor;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: color == null ? text : StatusSideCard(color: color, padding: const EdgeInsets.all(14), child: text),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.dashboard, required this.onMeasure});
  final Dashboard dashboard;
  final VoidCallback onMeasure;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
                  Text(l.taskPending('${pending['time']}'), style: mono(size: 13, color: VColors.onStatus)),
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
      card(Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        _ProgressRing(value: ratio),
        const SizedBox(width: 12),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.exerciseLabel, style: mono(size: 12, color: VColors.muted)),
            const SizedBox(height: 4),
            // Texto del valor conservado para accesibilidad (el anillo es decorativo).
            Text(l.exerciseProgress(dashboard.exerciseDone ~/ 60, dashboard.exerciseDone % 60),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: VType.body)),
          ]),
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
