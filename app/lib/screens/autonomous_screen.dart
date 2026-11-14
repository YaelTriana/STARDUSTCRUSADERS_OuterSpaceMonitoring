import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Modo autónomo: protocolo guiado con el CMO y mensaje diferido a Tierra.
class AutonomousScreen extends StatefulWidget {
  const AutonomousScreen({super.key});

  @override
  State<AutonomousScreen> createState() => _AutonomousScreenState();
}

class _AutonomousScreenState extends State<AutonomousScreen> {
  Future<Map<String, dynamic>>? _future;
  MissionEnv? _loadedFor;
  bool _queued = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    if (_loadedFor != state.env) {
      _loadedFor = state.env;
      _future = state.api.autonomous(state.env);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context).textTheme;

    if (!state.env.autonomous) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: SectionCard(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const StatusChip(VStatus.nominal),
              const SizedBox(height: 16),
              Text('Enlace con Tierra en tiempo real', style: t.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'En la ISS consultas al flight surgeon directamente.\nCambia el entorno a Luna o Marte para ver el modo autónomo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: VColors.muted, height: 1.5),
              ),
            ]),
          ),
        ),
      );
    }

    return AsyncView<Map<String, dynamic>>(
      future: _future!,
      builder: (context, d) {
        final steps = (d['steps'] as List).cast<Map<String, dynamic>>();
        final queue = (d['queue'] as List).cast<Map<String, dynamic>>();
        final protocol = SectionCard(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('PROTOCOLO GUIADO · CON EL CMO', style: overline()),
            const SizedBox(height: 6),
            Text('${d['title']}', style: t.headlineMedium),
            const SizedBox(height: 18),
            for (final s in steps) _ProtocolStep(step: s),
            const SizedBox(height: 8),
            const Text(
              'Las decisiones no esperan la respuesta de Tierra. TIRELUS guía, registra cada paso y lo envía en diferido.',
              style: TextStyle(fontSize: 13, color: VColors.muted, height: 1.5),
            ),
          ]),
        );

        final side = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('MENSAJE DIFERIDO AL FLIGHT SURGEON', style: overline()),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: VColors.space,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VColors.border),
                ),
                child: Text('${d['message']}', style: mono(size: 13).copyWith(height: 1.6)),
              ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Texto comprimido · sin video', style: TextStyle(fontSize: 13, color: VColors.muted)),
                Text('Retraso ${state.env.delay}', style: const TextStyle(fontSize: 13, color: VColors.muted)),
              ]),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _queued ? null : () => setState(() => _queued = true),
                child: Text(_queued ? 'En cola de envío' : 'Poner en cola de envío'),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('COLA DE COMUNICACIÓN', style: overline()),
              const SizedBox(height: 10),
              for (final q in queue)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: Text('${q['title']}', style: const TextStyle(fontSize: 14))),
                    Text(
                      q['title'] == 'Este protocolo' && _queued ? 'En cola' : '${q['state']}',
                      style: TextStyle(fontSize: 14, color: q['state'] == 'Recibido' ? VColors.nominal : VColors.muted),
                    ),
                  ]),
                ),
            ]),
          ),
        ]);

        return LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 1000;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: protocol),
                    const SizedBox(width: 24),
                    SizedBox(width: 400, child: side),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [protocol, const SizedBox(height: 20), side]),
          );
        });
      },
    );
  }
}

class _ProtocolStep extends StatelessWidget {
  const _ProtocolStep({required this.step});
  final Map<String, dynamic> step;

  @override
  Widget build(BuildContext context) {
    final state = step['state'] as String;
    final done = state == 'done';
    final current = state == 'current';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: done || current ? VColors.surface2 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: current ? VColors.signal : (done ? VColors.surface2 : VColors.border), width: current ? 2 : 1),
      ),
      child: Row(children: [
        Icon(done ? Icons.check_circle : (current ? Icons.radio_button_checked : Icons.radio_button_unchecked),
            color: done ? VColors.nominal : (current ? VColors.signal : VColors.borderStrong)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${step['title']}',
                style: TextStyle(fontWeight: FontWeight.w600, color: done || current ? VColors.text : VColors.muted)),
            Text('${step['detail']}', style: const TextStyle(fontSize: 13, color: VColors.muted)),
          ]),
        ),
        if (current) FilledButton(onPressed: () {}, child: const Text('Abrir guía')),
      ]),
    );
  }
}
