import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/touch.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/hold_button.dart';

/// Modo autónomo: protocolo guiado con el CMO, decisión a bordo y mensaje diferido a Tierra.
///
/// El contenido del protocolo viene de Python (`/autonomous`). Los tiempos de la línea de
/// tiempo son valores de ejemplo (supuesto de diseño), no mediciones de NASA.
class AutonomousScreen extends StatefulWidget {
  const AutonomousScreen({super.key});

  @override
  State<AutonomousScreen> createState() => _AutonomousScreenState();
}

class _AutonomousScreenState extends State<AutonomousScreen> {
  /// Tiempo de ida a Tierra por entorno (ejemplo): Luna 4–12 s, Marte hasta 20 min.
  static Duration oneWay(MissionEnv env) => switch (env) {
        MissionEnv.iss => Duration.zero,
        MissionEnv.luna => const Duration(seconds: 8),
        MissionEnv.marte => const Duration(minutes: 14),
      };

  static const _demoSpeed = 60;

  Future<Map<String, dynamic>>? _future;
  MissionEnv? _loadedFor;

  int? _done; // pasos registrados; se inicializa con los que Python marca como hechos
  final List<String> _logged = [];

  bool _sent = false;
  Duration _elapsed = Duration.zero;
  bool _fast = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    if (_loadedFor != state.env) {
      _loadedFor = state.env;
      _future = state.api.autonomous(state.env);
      _resetSend();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reload() => setState(() {
        _future = AppScope.of(context).api.autonomous(AppScope.of(context).env);
        _done = null;
        _logged.clear();
      });

  void _resetSend() {
    _timer?.cancel();
    _sent = false;
    _elapsed = Duration.zero;
  }

  void _send() {
    final total = oneWay(AppScope.of(context).env) * 2;
    setState(() {
      _sent = true;
      _elapsed = Duration.zero;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _elapsed += Duration(seconds: _fast ? _demoSpeed : 1));
      if (_elapsed >= total) t.cancel();
    });
  }

  static String fmt(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds} s';
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${d.inMinutes}:$s min';
  }

  void _openGuide(Map<String, dynamic> step) {
    final l = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${step['title']}'),
        content: Text('${step['detail']}', style: const TextStyle(fontSize: VType.body, height: 1.5)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.autoGuideClose))],
      ),
    );
  }

  void _logStep(List<Map<String, dynamic>> steps, int done) {
    final l = context.l10n;
    setState(() {
      _logged.add('${steps[done]['title']}');
      _done = done + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.autoStepLogged)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = context.l10n;
    final t = Theme.of(context).textTheme;

    if (!state.env.autonomous) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VSpace.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SectionCard(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const StatusChip(VStatus.nominal),
                  const SizedBox(height: 16),
                  Text(l.autoRealtimeTitle, style: t.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(l.autoRealtimeBody,
                      textAlign: TextAlign.center, style: const TextStyle(color: VColors.muted, height: 1.5, fontSize: VType.body)),
                ]),
              ),
              const SizedBox(height: VSpace.lg),
              _Reminder(l.autoReminder, l.autoPrivacy),
            ]),
          ),
        ),
      );
    }

    return AsyncView<Map<String, dynamic>>(
      future: _future!,
      onRetry: _reload,
      builder: (context, d) {
        final steps = (d['steps'] as List).cast<Map<String, dynamic>>();
        final queue = (d['queue'] as List).cast<Map<String, dynamic>>();
        _done ??= steps.where((s) => s['state'] == 'done').length;
        final done = _done!.clamp(0, steps.length);
        final complete = done >= steps.length;
        final message = [
          '${d['message']}',
          for (final s in _logged) '✓ $s',
        ].join('\n');

        final protocol = SectionCard(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.autoProtocolOverline, style: overline()),
            const SizedBox(height: 6),
            Text('${d['title']}', style: t.headlineMedium),
            const SizedBox(height: VSpace.md),
            Text(l.autoProgress(math.min(done + 1, steps.length), steps.length), style: mono(size: 13, color: VColors.muted)),
            const SizedBox(height: VSpace.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: done / steps.length,
                minHeight: 6,
                backgroundColor: VColors.border,
                color: VColors.signal,
              ),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < steps.length; i++)
              _ProtocolStep(
                title: '${steps[i]['title']}',
                detail: '${steps[i]['detail']}',
                state: i < done ? _StepState.done : (i == done ? _StepState.current : _StepState.todo),
                onGuide: () => _openGuide(steps[i]),
                onLog: () => _logStep(steps, i),
              ),
            if (complete) ...[
              const SizedBox(height: VSpace.sm),
              AlertBanner(title: l.status(VStatus.nominal), body: l.autoAllDone, status: VStatus.nominal),
            ],
            const SizedBox(height: VSpace.sm),
            Text(l.autoNoWait, style: const TextStyle(fontSize: VType.label, color: VColors.muted, height: 1.5)),
          ]),
        );

        final one = oneWay(state.env);
        final side = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(l.autoMessageTitle, style: overline()),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: VColors.space,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VColors.border),
                ),
                child: Text(message, style: mono(size: 13).copyWith(height: 1.6)),
              ),
              const SizedBox(height: 10),
              Wrap(alignment: WrapAlignment.spaceBetween, spacing: 12, children: [
                Text(l.autoMessageMeta, style: const TextStyle(fontSize: VType.label, color: VColors.muted)),
                Text(l.autoDelayLabel(l.envDelay(state.env)), style: const TextStyle(fontSize: VType.label, color: VColors.muted)),
              ]),
              const SizedBox(height: Touch.gapCritical),
              if (_sent)
                Row(children: [
                  const StatusShape(VStatus.nominal, size: 14),
                  const SizedBox(width: 8),
                  Text(l.autoTlSent, style: const TextStyle(fontSize: VType.body)),
                ])
              else
                HoldToConfirmButton(label: l.autoHoldSend, icon: Icons.send, color: VColors.signal, onConfirmed: _send),
            ]),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(l.autoTimelineTitle, style: overline()),
              const SizedBox(height: 10),
              _TimelineRow(
                state: _TlState.done,
                text: l.autoTlDrafted,
              ),
              _TimelineRow(
                state: _sent ? _TlState.done : _TlState.pending,
                text: _sent ? l.autoTlSent : l.autoTlQueued,
              ),
              _TimelineRow(
                state: !_sent ? _TlState.pending : (_elapsed >= one ? _TlState.done : _TlState.current),
                text: _sent && _elapsed >= one ? l.autoTlArrived : l.autoTlArrival(fmt(_sent ? one - _elapsed : one)),
              ),
              _TimelineRow(
                state: _sent && _elapsed >= one * 2 ? _TlState.done : _TlState.pending,
                text: _sent && _elapsed >= one * 2 ? l.autoTlResponseIn : l.autoTlResponse(fmt(one * 2)),
                body: _sent && _elapsed >= one * 2 ? l.autoTlResponseBody : null,
              ),
              const SizedBox(height: VSpace.sm),
              Text(l.autoEtaAssumption(fmt(one)),
                  style: const TextStyle(fontSize: VType.label, color: VColors.muted, height: 1.5)),
              // Material propio: el ListTile no puede pintar sobre el fondo de la tarjeta.
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.autoSpeedUp, style: const TextStyle(fontSize: VType.body)),
                  value: _fast,
                  onChanged: (v) => setState(() => _fast = v),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(l.autoQueueTitle, style: overline()),
              const SizedBox(height: 10),
              for (final q in queue) _queueRow(l, q),
            ]),
          ),
        ]);

        final decision = _Decision(l);

        return LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 1000;
          final pad = c.maxWidth < 600 ? VSpace.lg : 28.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(pad),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _Reminder(l.autoReminder, l.autoPrivacy),
              const SizedBox(height: 20),
              if (wide)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [protocol, const SizedBox(height: 20), decision])),
                  const SizedBox(width: 24),
                  SizedBox(width: 400, child: side),
                ])
              else ...[protocol, const SizedBox(height: 20), side, const SizedBox(height: 20), decision],
            ]),
          );
        });
      },
    );
  }

  Widget _queueRow(AppLocalizations l, Map<String, dynamic> q) {
    final isThis = q['title'] == 'Este protocolo';
    final received = q['state'] == 'Recibido';
    final title = isThis ? l.autoQueueThisProtocol : '${q['title']}';
    final stateText = isThis ? (_sent ? l.autoQueueSent : l.autoQueueDraft) : (received ? l.autoQueueReceived : '${q['state']}');
    final ok = received || (isThis && _sent);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: VType.body))),
        if (ok) const Padding(padding: EdgeInsets.only(right: 6), child: StatusShape(VStatus.nominal, size: 12)),
        Text(stateText, style: TextStyle(fontSize: VType.body, color: ok ? VColors.nominal : VColors.muted)),
      ]),
    );
  }
}

/// Recordatorio permanente: la app no diagnostica y los datos son privados.
class _Reminder extends StatelessWidget {
  const _Reminder(this.text, this.privacy);
  final String text;
  final String privacy;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(VSpace.lg),
        decoration: BoxDecoration(
          color: VColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VColors.signal),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline, color: VColors.signal),
          const SizedBox(width: VSpace.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(text, style: const TextStyle(fontSize: VType.body, fontWeight: FontWeight.w600, height: 1.4)),
              const SizedBox(height: 4),
              Text(privacy, style: const TextStyle(fontSize: VType.label, color: VColors.muted, height: 1.4)),
            ]),
          ),
        ]),
      );
}

enum _StepState { done, current, todo }

class _ProtocolStep extends StatelessWidget {
  const _ProtocolStep({
    required this.title,
    required this.detail,
    required this.state,
    required this.onGuide,
    required this.onLog,
  });
  final String title;
  final String detail;
  final _StepState state;
  final VoidCallback onGuide;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final done = state == _StepState.done;
    final current = state == _StepState.current;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: done || current ? VColors.surface2 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: current ? VColors.signal : (done ? VColors.surface2 : VColors.border), width: current ? 2 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(done ? Icons.check_circle : (current ? Icons.radio_button_checked : Icons.radio_button_unchecked),
              color: done ? VColors.nominal : (current ? VColors.signal : VColors.borderStrong)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontSize: VType.body, fontWeight: FontWeight.w600, color: done || current ? VColors.text : VColors.muted)),
              Text(detail, style: const TextStyle(fontSize: VType.label, color: VColors.muted, height: 1.4)),
            ]),
          ),
        ]),
        if (current) ...[
          const SizedBox(height: VSpace.md),
          Wrap(spacing: Touch.gapCritical, runSpacing: Touch.gapCritical, children: [
            OutlinedButton(onPressed: onGuide, child: Text(l.autoOpenGuide)),
            FilledButton(onPressed: onLog, child: Text(l.autoLogContinue)),
          ]),
        ],
      ]),
    );
  }
}

enum _TlState { done, current, pending }

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.state, required this.text, this.body});
  final _TlState state;
  final String text;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (state) {
      _TlState.done => (Icons.check_circle, VColors.nominal),
      _TlState.current => (Icons.hourglass_top, VColors.atencion),
      _TlState.pending => (Icons.radio_button_unchecked, VColors.borderStrong),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: TextStyle(fontSize: VType.body, color: state == _TlState.pending ? VColors.muted : VColors.text)),
            if (body != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(body!, style: const TextStyle(fontSize: VType.label, color: VColors.muted, height: 1.5)),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// Opciones a bordo con pros y contras, más el inventario del botiquín (datos de ejemplo).
class _Decision extends StatelessWidget {
  const _Decision(this.l);
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final options = [
      (l.autoOpt1Title, l.autoOpt1Pros, l.autoOpt1Cons),
      (l.autoOpt2Title, l.autoOpt2Pros, l.autoOpt2Cons),
      (l.autoOpt3Title, l.autoOpt3Pros, l.autoOpt3Cons),
    ];
    final kit = [
      (l.autoMedkitItem1, l.autoMedkitItem1Qty),
      (l.autoMedkitItem2, l.autoMedkitItem2Qty),
      (l.autoMedkitItem3, l.autoMedkitItem3Qty),
    ];
    return SectionCard(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.autoDecisionTitle, style: overline()),
        const SizedBox(height: 6),
        Text(l.autoDecisionIntro, style: const TextStyle(fontSize: VType.body, color: VColors.muted, height: 1.5)),
        const SizedBox(height: VSpace.md),
        for (final o in options)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: VColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.$1, style: const TextStyle(fontSize: VType.body, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _Pro(label: l.autoPros, text: o.$2, icon: Icons.add_circle_outline, color: VColors.nominal),
              const SizedBox(height: 4),
              _Pro(label: l.autoCons, text: o.$3, icon: Icons.remove_circle_outline, color: VColors.atencion),
            ]),
          ),
        const SizedBox(height: VSpace.sm),
        Text(l.autoMedkitTitle, style: overline()),
        const SizedBox(height: 6),
        for (final k in kit)
          Container(
            constraints: const BoxConstraints(minHeight: Touch.min),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: VColors.border))),
            child: Row(children: [
              Expanded(child: Text(k.$1, style: const TextStyle(fontSize: VType.body))),
              Text(k.$2, style: mono(size: 14, color: VColors.muted)),
            ]),
          ),
        const SizedBox(height: VSpace.sm),
        Text(l.autoMedkitNote, style: const TextStyle(fontSize: VType.label, color: VColors.muted)),
      ]),
    );
  }
}

class _Pro extends StatelessWidget {
  const _Pro({required this.label, required this.text, required this.icon, required this.color});
  final String label;
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            TextSpan(text: text),
          ]), style: const TextStyle(fontSize: VType.label, height: 1.45)),
        ),
      ]);
}
