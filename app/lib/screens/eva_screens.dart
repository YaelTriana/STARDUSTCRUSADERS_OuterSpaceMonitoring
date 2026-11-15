import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Carga la telemetría de caminata espacial una sola vez.
mixin _EvaData<T extends StatefulWidget> on State<T> {
  Future<Map<String, dynamic>>? future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    future ??= AppScope.of(context).api.eva();
  }
}

/// Visor de casco: CONCEPTO A FUTURO (formato tipo Joint AR / NASA SUITS).
class VisorScreen extends StatefulWidget {
  const VisorScreen({super.key});

  @override
  State<VisorScreen> createState() => _VisorScreenState();
}

class _VisorScreenState extends State<VisorScreen> with _EvaData {
  @override
  Widget build(BuildContext context) => AsyncView<Map<String, dynamic>>(
        future: future!,
        builder: (context, e) => Padding(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LayoutBuilder(builder: (context, c) {
                  final s = c.maxWidth / 1280; // escala respecto al diseño de 1280×720
                  Widget at(double l, double t, Widget child, {double? w}) =>
                      Positioned(left: l * s, top: t * s, width: w == null ? null : w * s, child: child);
                  TextStyle m(double size, [Color color = VColors.text]) => mono(size: size * s, color: color);
                  return Stack(children: [
                    Positioned.fill(child: CustomPaint(painter: _VisorPainter())),
                    at(24, 20, Text('CONCEPTO A FUTURO · PANTALLA EN CASCO TIPO JOINT AR / SUITS', style: m(12, VColors.muted))),
                    at(300, 110, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('O₂ DEL TRAJE', style: m(12, VColors.muted)),
                      Text('${e['o2_left']} h', style: m(34)),
                    ])),
                    at(790, 110, w: 200, Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('EVA', style: m(12, VColors.muted)),
                      Text('${e['elapsed']}', style: m(34)),
                      Text('regreso al rover en ${e['return_in_min']} min', style: TextStyle(fontSize: 13 * s, color: VColors.muted)),
                    ])),
                    at(520, 72, w: 240, Text('Di «TIRELUS, estado»', textAlign: TextAlign.center, style: TextStyle(fontSize: 12 * s, color: VColors.muted))),
                    at(250, 500, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'FC  ', style: m(12, VColors.muted)),
                        TextSpan(text: '${e['hr']}', style: m(30, VColors.atencion)),
                        TextSpan(text: ' lpm ▲', style: TextStyle(fontSize: 13 * s, color: VColors.muted)),
                      ])),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'SpO₂  ', style: m(12, VColors.muted)),
                        TextSpan(text: '${e['spo2']} %', style: m(22)),
                      ])),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'TEMP  ', style: m(12, VColors.muted)),
                        TextSpan(text: '${e['temp']} °C', style: m(22)),
                      ])),
                    ])),
                    at(830, 500, w: 200, Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'CO₂ TRAJE  ', style: m(12, VColors.muted)),
                        TextSpan(text: '${e['co2']}', style: m(22)),
                      ])),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'ESFUERZO  ', style: m(12, VColors.muted)),
                        TextSpan(text: '${e['effort']}', style: m(22, VColors.atencion)),
                      ])),
                    ])),
                    at(430, 596, w: 420, Container(
                      padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 10 * s),
                      decoration: BoxDecoration(
                        color: VColors.warnBg.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: VColors.atencion, width: 2),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        StatusShape(VStatus.atencion, size: 16 * s),
                        SizedBox(width: 10 * s),
                        Flexible(child: Text('${e['alert']}', style: TextStyle(fontSize: 16 * s, fontWeight: FontWeight.w600))),
                      ]),
                    )),
                  ]);
                }),
              ),
            ),
          ),
        ),
      );
}

class _VisorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 1280, size.height / 720);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1280, 720), Paint()..color = const Color(0xFF02040A));
    final star = Paint()..color = VColors.muted;
    for (final o in const [Offset(220, 140), Offset(420, 90), Offset(700, 160), Offset(960, 110), Offset(1080, 200), Offset(560, 230)]) {
      canvas.drawCircle(o, 1.5, star);
    }
    canvas.drawPath(
      Path()
        ..moveTo(0, 470)
        ..lineTo(160, 430)
        ..lineTo(300, 450)
        ..lineTo(470, 400)
        ..lineTo(640, 440)
        ..lineTo(820, 415)
        ..lineTo(1000, 450)
        ..lineTo(1150, 425)
        ..lineTo(1280, 445)
        ..lineTo(1280, 720)
        ..lineTo(0, 720)
        ..close(),
      Paint()..color = const Color(0xFF2B303B),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 560)
        ..lineTo(240, 520)
        ..lineTo(520, 545)
        ..lineTo(760, 515)
        ..lineTo(1040, 550)
        ..lineTo(1280, 530)
        ..lineTo(1280, 720)
        ..lineTo(0, 720)
        ..close(),
      Paint()..color = const Color(0xFF3A404C),
    );
    const visor = Rect.fromLTWH(40, 50, 1200, 660);
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(const Rect.fromLTWH(0, 0, 1280, 720))
      ..addOval(visor);
    canvas.drawPath(mask, Paint()..color = Colors.black.withValues(alpha: 0.92));
    canvas.drawOval(
        visor,
        Paint()
          ..color = VColors.borderStrong
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Variante de mano: misma información, botones grandes para guantes.
class HandheldScreen extends StatefulWidget {
  const HandheldScreen({super.key});

  @override
  State<HandheldScreen> createState() => _HandheldScreenState();
}

class _HandheldScreenState extends State<HandheldScreen> with _EvaData {
  @override
  Widget build(BuildContext context) => AsyncView<Map<String, dynamic>>(
        future: future!,
        builder: (context, e) => SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: VColors.space,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: VColors.borderStrong, width: 2),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('EVA ${e['elapsed']} · TRIPULANTE B', style: mono(size: 13, color: VColors.muted)),
                  Text('O₂ ${e['o2_left']} h', style: mono(size: 13, color: VColors.muted)),
                ]),
                const SizedBox(height: 16),
                const AlertBanner(title: 'Esfuerzo alto', body: '4 min sobre tu zona. Baja el ritmo o pausa 2 min.'),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    MetricTile(label: 'FC', value: '${e['hr']}', unit: 'lpm', valueSize: 38, valueColor: VColors.atencion),
                    MetricTile(label: 'SpO₂', value: '${e['spo2']}', unit: '%', valueSize: 38),
                    MetricTile(label: 'Temperatura', value: '${e['temp']}', unit: '°C', valueSize: 30),
                    MetricTile(label: 'CO₂ del traje', value: '${e['co2']}', valueSize: 24, valueColor: VColors.nominal),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pausa de 2 min iniciada.'))),
                  child: const Text('Pausa de 2 min', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(60)),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Llamando al CMO…'))),
                  child: const Text('Llamar al CMO', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Botones grandes para guantes presurizados. La misma información que el visor, por si el traje no tiene pantalla en el casco.',
                  style: TextStyle(fontSize: 13, color: VColors.muted, height: 1.5),
                ),
              ]),
            ),
          ),
        ),
      );
}
