import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Consola de base: vista COMPARTIDA, sin datos clínicos por tripulante.
class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).api.habitat();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AsyncView<Map<String, dynamic>>(
      future: _future!,
      builder: (context, h) {
        final env = (h['environment'] as List).cast<Map<String, dynamic>>();
        final crew = (h['crew'] as List).cast<Map<String, dynamic>>();
        final agenda = (h['agenda'] as List).cast<Map<String, dynamic>>();
        final challenge = h['team_challenge'] as Map<String, dynamic>;

        final environment = SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('AMBIENTE DEL HÁBITAT', style: overline()),
            const SizedBox(height: 14),
            Wrap(spacing: 12, runSpacing: 12, children: [
              for (final e in env)
                SizedBox(
                  width: 135,
                  child: MetricTile(
                    label: '${e['label']}',
                    value: '${e['value']}',
                    unit: '${e['unit']}',
                    valueSize: 22,
                    valueColor: statusFromApi(e['status'] as String?) == VStatus.nominal ? null : VColors.atencion,
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            const Text('Dosis acumulada de radiación de cada quien: solo en su vista personal.',
                style: TextStyle(fontSize: 13, color: VColors.muted)),
          ]),
        );

        final crewSection = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, children: [
            Text('Tripulación', style: t.headlineSmall),
            const Text('Sin datos clínicos en pantallas compartidas', style: TextStyle(fontSize: 13, color: VColors.muted)),
          ]),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 560 ? 2 : 1;
            return Wrap(spacing: 14, runSpacing: 14, children: [
              for (final m in crew)
                SizedBox(
                  width: (c.maxWidth - 14 * (cols - 1)) / cols,
                  child: SectionCard(
                    padding: const EdgeInsets.all(18),
                    highlight: m['highlight'] == true,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        Expanded(child: Text('${m['name']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17))),
                        Text('${m['location']}',
                            style: mono(size: 12, color: m['highlight'] == true ? VColors.signalSoft : VColors.muted)),
                      ]),
                      const SizedBox(height: 6),
                      Text('${m['detail']}', style: const TextStyle(fontSize: 14, color: VColors.muted)),
                      if (m['progress'] != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (m['progress'] as num).toDouble(),
                            minHeight: 6,
                            backgroundColor: VColors.border,
                            color: (m['progress'] as num) >= 1 ? VColors.nominal : VColors.signal,
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
            ]);
          }),
          const SizedBox(height: 14),
          SectionCard(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              const Icon(Icons.emoji_events_outlined, color: VColors.nominal),
              const SizedBox(width: 14),
              Expanded(child: Text('${challenge['title']}', style: const TextStyle(fontWeight: FontWeight.w700))),
              Text('${challenge['done']}/${challenge['total']}', style: mono(size: 22)),
            ]),
          ),
        ]);

        final agendaCard = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AGENDA MÉDICA DE HOY', style: overline()),
              const SizedBox(height: 12),
              for (final a in agenda)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    SizedBox(width: 56, child: Text('${a['time']}', style: mono(size: 14, color: VColors.muted))),
                    Expanded(child: Text('${a['title']}', style: const TextStyle(fontSize: 14))),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('La vista CMO requiere identificación (no incluida en el mockup).'))),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Vista CMO · identificarse'),
          ),
        ]);

        return LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 1150;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Wrap(spacing: 18, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text('BASE LUNAR · DÍA ${h['day']}', style: mono(size: 13, color: VColors.muted)),
                Text('Gravedad ${h['gravity']}', style: mono(size: 13, color: VColors.muted)),
                Text('Enlace con Tierra ${h['link']}', style: mono(size: 13, color: VColors.muted)),
                const SampleTag(),
              ]),
              const SizedBox(height: 16),
              AlertBanner(title: 'Clima espacial', body: '${h['alert']}'),
              const SizedBox(height: 20),
              if (wide)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 330, child: environment),
                  const SizedBox(width: 20),
                  Expanded(child: crewSection),
                  const SizedBox(width: 20),
                  SizedBox(width: 340, child: agendaCard),
                ])
              else ...[
                environment,
                const SizedBox(height: 20),
                crewSection,
                const SizedBox(height: 20),
                agendaCard,
              ],
            ]),
          );
        });
      },
    );
  }
}
