import 'package:flutter/material.dart';

import '../core/touch.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../theme.dart';
import 'common.dart';

/// Figura corporal abstracta con zonas tocables por sistema.
///
/// En ancho suficiente, los botones van al lado de la figura. En angosto
/// (móvil o ventana estrecha) pasan a una columna debajo, para que ninguna
/// etiqueta se corte.
class BodyFigure extends StatelessWidget {
  const BodyFigure({super.key, required this.systems, required this.selected, required this.onSelect});

  final List<BodySystem> systems;
  final String selected;
  final ValueChanged<String> onSelect;

  /// Debajo de este ancho se usa la disposición en columna.
  static const _narrowBelow = 420.0;

  // Posición vertical de cada botón (dp dentro de la figura de 480 de alto)
  // y punto que marca la zona en el cuerpo (coordenadas del lienzo 160×520).
  static const _layout = <String, (double, Offset)>{
    'mente': (10, Offset(80, 30)),
    'ojos': (82, Offset(80, 52)),
    'cardio': (154, Offset(96, 140)),
    'inmune': (226, Offset(70, 200)),
    'hueso': (360, Offset(104, 380)),
  };

  Map<Offset, Color> get _dots => {
        for (final s in systems)
          if (_layout.containsKey(s.id)) _layout[s.id]!.$2: statusColor(s.status),
      };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) =>
            box.maxWidth < _narrowBelow ? _narrow(context) : _wide(),
      );

  Widget _wide() => SizedBox(
        height: 500,
        child: Stack(children: [
          Positioned(
            left: 20,
            top: 10,
            child: CustomPaint(size: const Size(150, 480), painter: _BodyPainter(_dots)),
          ),
          for (final s in systems)
            if (_layout.containsKey(s.id))
              Positioned(
                left: 170,
                right: 0,
                top: _layout[s.id]!.$1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _ZoneButton(system: s, selected: s.id == selected, onTap: () => onSelect(s.id)),
                ),
              ),
        ]),
      );

  Widget _narrow(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        CustomPaint(size: const Size(110, 352), painter: _BodyPainter(_dots)),
        const SizedBox(height: VSpace.lg),
        Wrap(
          spacing: Touch.gap,
          runSpacing: Touch.gap,
          children: [
            for (final s in systems)
              if (_layout.containsKey(s.id))
                _ZoneButton(system: s, selected: s.id == selected, onTap: () => onSelect(s.id)),
          ],
        ),
      ]);
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
        label: '${system.name}, ${AppLocalizations.of(context).status(system.status)}',
        child: Material(
          color: VColors.surface2,
          shape: StadiumBorder(
            side: BorderSide(color: selected ? VColors.signal : VColors.border, width: selected ? 2 : 1),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Touch.min),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  StatusShape(system.status, size: 12),
                  const SizedBox(width: 8),
                  Flexible(child: Text(system.name, maxLines: 2, style: const TextStyle(fontSize: VType.body))),
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
