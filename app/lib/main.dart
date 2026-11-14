import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'api.dart';
import 'app_state.dart';
import 'core/touch.dart';
import 'data/models.dart';
import 'l10n/app_localizations.dart';
import 'l10n/labels.dart';
import 'screens/autonomous_screen.dart';
import 'screens/base_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/eva_screens.dart';
import 'screens/measurement_screen.dart';
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
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) => MaterialApp(
            title: 'TIRELUS',
            debugShowCheckedModeBanner: false,
            theme: tirelusTheme(),
            locale: state.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const BootScreen(),
          ),
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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<void>(
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
                    Text('${l.bootError}\n${snap.error}',
                        textAlign: TextAlign.center, style: const TextStyle(color: VColors.critico)),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => setState(() => _boot = PythonRuntime.start(AppScope.of(context).api)),
                      child: Text(l.retry),
                    ),
                  ] else ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(l.bootStarting, style: const TextStyle(color: VColors.muted)),
                  ],
                ]),
              ),
            ),
          );
        },
      );
  }
}

class _Dest {
  const _Dest(this.label, this.icon);
  final String Function(AppLocalizations) label;
  final IconData icon;
}

final _dests = <_Dest>[
  _Dest((l) => l.navPanel, Icons.monitor_heart_outlined),
  _Dest((l) => l.navMeasurement, Icons.straighten),
  _Dest((l) => l.navTrend, Icons.show_chart),
  _Dest((l) => l.navAutonomous, Icons.satellite_alt_outlined),
  _Dest((l) => l.navBase, Icons.home_work_outlined),
  _Dest((l) => l.navVisor, Icons.visibility_outlined),
  _Dest((l) => l.navHandheld, Icons.smartphone),
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
        3 => const AutonomousScreen(),
        4 => const BaseScreen(),
        5 => const VisorScreen(),
        _ => const HandheldScreen(),
      };

  void _showMore() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: VColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 4; i < _dests.length; i++)
            ListTile(
              minTileHeight: Touch.primary,
              leading: Icon(_dests[i].icon),
              title: Text(_dests[i].label(AppLocalizations.of(context))),
              selected: i == _index,
              onTap: () {
                setState(() => _index = i);
                Navigator.pop(ctx);
              },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 760;
    final topBar = _TopBar(compact: width < 900);
    final body = KeyedSubtree(
      // El idioma entra en la llave para que cada pantalla vuelva a pedir sus datos a Python.
      key: ValueKey('$_index-${AppScope.of(context).locale.languageCode}'),
      child: _screen(),
    );

    // Tablet horizontal / escritorio: riel lateral.
    if (wide) {
      return Scaffold(
        appBar: topBar,
        body: Row(children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final d in _dests) NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label(l))),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ]),
      );
    }

    // Vertical y móvil: barra inferior con 4 destinos + "Más".
    const main = 4;
    return Scaffold(
      appBar: topBar,
      body: body,
      bottomNavigationBar: NavigationBar(
        backgroundColor: VColors.space,
        indicatorColor: VColors.surface2,
        selectedIndex: _index < main ? _index : main,
        onDestinationSelected: (i) => i == main ? _showMore() : setState(() => _index = i),
        destinations: [
          for (var i = 0; i < main; i++) NavigationDestination(icon: Icon(_dests[i].icon), label: _dests[i].label(l)),
          NavigationDestination(icon: const Icon(Icons.more_horiz), label: l.navMore),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  const _TopBar({required this.compact});

  /// En compacto, el estado del enlace baja a una segunda fila (siempre visible).
  final bool compact;

  @override
  Size get preferredSize => Size.fromHeight(compact ? 64 + 32 : 64);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = AppLocalizations.of(context);
    return AppBar(
      backgroundColor: VColors.space,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 64,
      shape: const Border(bottom: BorderSide(color: VColors.border)),
      titleSpacing: 16,
      bottom: compact
          ? PreferredSize(
              preferredSize: const Size.fromHeight(32),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(children: [
                    StatusShape(state.env.autonomous ? VStatus.critico : VStatus.nominal, size: 10),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                          state.env.autonomous ? l.linkAutonomous(l.envDelay(state.env)) : l.linkRealtime,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: VColors.muted, fontSize: VType.label)),
                    ),
                    const SizedBox(width: 12),
                    const SampleTag(),
                  ]),
                ),
              ),
            )
          : null,
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
          Text(l.missionDayLabel('047', l.envLabel(state.env).toUpperCase()), style: mono(size: 13, color: VColors.muted)),
        ],
      ]),
      actions: [
        Center(child: EnvSelector(value: state.env, onChanged: state.setEnv)),
        const SizedBox(width: 8),
        Tooltip(
          message: l.languageSwitchTooltip,
          child: TextButton(
            style: TextButton.styleFrom(minimumSize: Touch.minSize, foregroundColor: VColors.signalSoft),
            onPressed: state.toggleLocale,
            child: Text(state.locale.languageCode == 'es' ? 'EN' : 'ES', style: mono(size: 14, color: VColors.signalSoft)),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 16),
          StatusShape(state.env.autonomous ? VStatus.critico : VStatus.nominal, size: 10),
          const SizedBox(width: 8),
          Text(state.env.autonomous ? l.linkAutonomous(l.envDelay(state.env)) : l.linkRealtime,
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
