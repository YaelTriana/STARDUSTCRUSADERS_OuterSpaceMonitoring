import 'package:flutter/material.dart';

import 'api.dart';
import 'app_state.dart';
import 'data/models.dart';
import 'screens/autonomous_screen.dart';
import 'screens/base_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/eva_screens.dart';
import 'screens/measurement_screen.dart';
import 'screens/sans_screen.dart';
import 'screens/trend_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/env_selector.dart';

void main() {
  final api = TirelusApi();
  runApp(TirelusApp(state: AppState(api)));
}

class TirelusApp extends StatelessWidget {
  const TirelusApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
        state: state,
        child: MaterialApp(
          title: 'TIRELUS',
          debugShowCheckedModeBanner: false,
          theme: tirelusTheme(),
          home: const BootScreen(),
        ),
      );
}

/// Arranca el Python embebido y espera a que la API local responda.
class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  Future<void>? _boot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _boot ??= PythonRuntime.start(AppScope.of(context).api);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _boot,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.done && !snap.hasError) return const Shell();
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const TirelusMark(size: 64),
                  const SizedBox(height: 20),
                  Text('TIRELUS', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 16),
                  if (snap.hasError) ...[
                    Text('No se pudo iniciar el motor en Python.\n${snap.error}',
                        textAlign: TextAlign.center, style: const TextStyle(color: VColors.critico)),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => setState(() => _boot = PythonRuntime.start(AppScope.of(context).api)),
                      child: const Text('Reintentar'),
                    ),
                  ] else ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text('Iniciando el motor en Python…', style: TextStyle(color: VColors.muted)),
                  ],
                ]),
              ),
            ),
          );
        },
      );
}

class _Dest {
  const _Dest(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _dests = [
  _Dest('Panel', Icons.monitor_heart_outlined),
  _Dest('Medición', Icons.straighten),
  _Dest('Tendencia', Icons.show_chart),
  _Dest('Ojos', Icons.remove_red_eye_outlined),
  _Dest('Autónomo', Icons.satellite_alt_outlined),
  _Dest('Base', Icons.home_work_outlined),
  _Dest('Visor', Icons.visibility_outlined),
  _Dest('De mano', Icons.smartphone),
];

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  Widget _screen() => switch (_index) {
        0 => DashboardScreen(onGoTo: (i) => setState(() => _index = i)),
        1 => const MeasurementScreen(),
        2 => const TrendScreen(),
        3 => const SansScreen(),
        4 => const AutonomousScreen(),
        5 => const BaseScreen(),
        6 => const VisorScreen(),
        _ => const HandheldScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final rail = NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      labelType: NavigationRailLabelType.all,
      destinations: [
        for (final d in _dests) NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)),
      ],
    );
    return Scaffold(
      appBar: const _TopBar(),
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: VColors.space,
              child: ListView(children: [
                for (var i = 0; i < _dests.length; i++)
                  ListTile(
                    leading: Icon(_dests[i].icon),
                    title: Text(_dests[i].label),
                    selected: i == _index,
                    onTap: () {
                      setState(() => _index = i);
                      Navigator.pop(context);
                    },
                  ),
              ]),
            ),
      // stretch: las pantallas cortas empiezan arriba en vez de quedar centradas.
      body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (wide) ...[rail, const VerticalDivider(width: 1)],
        Expanded(child: KeyedSubtree(key: ValueKey(_index), child: _screen())),
      ]),
    );
  }
}

class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  const _TopBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final compact = MediaQuery.sizeOf(context).width < 900;
    return AppBar(
      backgroundColor: VColors.space,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 64,
      shape: const Border(bottom: BorderSide(color: VColors.border)),
      titleSpacing: 16,
      title: Row(children: [
        const TirelusMark(size: 30),
        const SizedBox(width: 12),
        Flexible(
          child: Text('TIRELUS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ),
        if (!compact) ...[
          const SizedBox(width: 16),
          Text('DÍA DE MISIÓN 047 · ${state.env.label.toUpperCase()}', style: mono(size: 13, color: VColors.muted)),
        ],
      ]),
      actions: [
        Center(child: EnvSelector(value: state.env, onChanged: state.setEnv)),
        if (!compact) ...[
          const SizedBox(width: 16),
          StatusShape(state.env.autonomous ? VStatus.critico : VStatus.nominal, size: 10),
          const SizedBox(width: 8),
          Text(state.env.autonomous ? 'Modo autónomo · ${state.env.delay}' : 'Enlace: tiempo real',
              style: const TextStyle(color: VColors.muted, fontSize: 14)),
          const SizedBox(width: 16),
          const SampleTag(),
        ],
        const SizedBox(width: 16),
      ],
    );
  }
}

/// Símbolo propio de TIRELUS (nunca la insignia de NASA).
class TirelusMark extends StatelessWidget {
  const TirelusMark({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _MarkPainter());
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 56);
    canvas.drawCircle(
        const Offset(28, 28),
        22,
        Paint()
          ..color = VColors.signal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    canvas.drawPath(
      Path()
        ..moveTo(14, 29)
        ..lineTo(22, 29)
        ..lineTo(25, 22)
        ..lineTo(30, 35)
        ..lineTo(33, 29)
        ..lineTo(42, 29),
      Paint()
        ..color = VColors.nominal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
