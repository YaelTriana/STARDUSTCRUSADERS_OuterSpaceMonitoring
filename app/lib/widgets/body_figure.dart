import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';
import 'common.dart';

/// Figura corporal abstracta con zonas tocables por sistema.
class BodyFigure extends StatelessWidget {
  const BodyFigure({super.key, required this.systems, required this.selected, required this.onSelect});

  final List<BodySystem> systems;
  final String selected;
  final ValueChanged<String> onSelect;

  // Posición vertical de cada botón (px dentro de la figura de 480 de alto)
  // y punto que marca la zona en el cuerpo (coordenadas del lienzo 160×520).
  static const _layout = <String, (double, Offset)>{
    'mente': (18, Offset(80, 30)),
    'ojos': (72, Offset(80, 52)),
    'cardio': (140, Offset(96, 140)),
    'inmune': (206, Offset(70, 200)),
    'hueso': (360, Offset(104, 380)),
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Stack(children: [
        Positioned(
          left: 20,
          top: 10,
          child: CustomPaint(
            size: const Size(150, 480),
            painter: _BodyPainter({
              for (final s in systems)
                if (_layout.containsKey(s.id)) _layout[s.id]!.$2: statusColor(s.status),
            }),
          ),
        ),
        for (final s in systems)
          if (_layout.containsKey(s.id))
            Positioned(
              left: 170,
              top: _layout[s.id]!.$1,
              child: _ZoneButton(system: s, selected: s.id == selected, onTap: () => onSelect(s.id)),
            ),
      ]),
    );
  }
}

class _ZoneButton extends StatelessWidget {
  const _ZoneButton({required this.system, required this.selected, required this.onTap});
  final BodySystem system;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '${system.name}, ${system.status.label}',
        child: Material(
          color: VColors.surface2,
          shape: StadiumBorder(
            side: BorderSide(color: selected ? VColors.signal : VColors.border, width: selected ? 2 : 1),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  StatusShape(system.status, size: 12),
                  const SizedBox(width: 8),
                  Text(system.name, style: const TextStyle(fontSize: 14)),
                ]),
              ),
            ),
          ),
        ),
      );
}

class _BodyPainter extends CustomPainter {
  _BodyPainter(this.dots);
  final Map<Offset, Color> dots;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 160, size.height / 520);
    final fill = Paint()..color = VColors.surface2;
    final stroke = Paint()
      ..color = VColors.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    void shape(RRect r) {
      canvas.drawRRect(r, fill);
      canvas.drawRRect(r, stroke);
    }

    canvas.drawCircle(const Offset(80, 45), 32, fill);
    canvas.drawCircle(const Offset(80, 45), 32, stroke);
    shape(RRect.fromLTRBR(70, 76, 90, 94, Radius.zero));
    shape(RRect.fromLTRBR(30, 92, 130, 272, const Radius.circular(40)));
    shape(RRect.fromLTRBR(4, 100, 26, 270, const Radius.circular(11)));
    shape(RRect.fromLTRBR(134, 100, 156, 270, const Radius.circular(11)));
    shape(RRect.fromLTRBR(38, 262, 74, 502, const Radius.circular(18)));
    shape(RRect.fromLTRBR(86, 262, 122, 502, const Radius.circular(18)));
    dots.forEach((o, c) => canvas.drawCircle(o, 7, Paint()..color = c));
  }

  @override
  bool shouldRepaint(_BodyPainter old) => old.dots != dots;
}
