import 'package:flutter/material.dart';

import '../data/models.dart';
import '../l10n/labels.dart';
import '../theme.dart';
import 'common.dart';

/// Figura corporal abstracta (compacta, máx. ~220 dp de alto) con marcadores
/// tocables por sistema, y debajo los 5 sistemas como filas completas.
class BodyFigure extends StatelessWidget {
  const BodyFigure({super.key, required this.systems, required this.selected, required this.onSelect});

  final List<BodySystem> systems;
  final String selected;
  final ValueChanged<String> onSelect;

  // Punto que marca cada sistema en el lienzo 160×520 de la silueta.
  static const _dotAt = <String, Offset>{
    'mente': Offset(80, 30),
    'ojos': Offset(80, 52),
    'cardio': Offset(96, 140),
    'inmune': Offset(70, 200),
    'hueso': Offset(104, 380),
  };

  static const _figureSize = Size(68, 220);

  @override
  Widget build(BuildContext context) {
    final sx = _figureSize.width / 160;
    final sy = _figureSize.height / 520;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Center(
        child: SizedBox(
          width: _figureSize.width,
          height: _figureSize.height,
          child: Stack(children: [
            CustomPaint(size: _figureSize, painter: const _BodyPainter()),
            for (final s in systems)
              if (_dotAt.containsKey(s.id))
                Positioned(
                  left: _dotAt[s.id]!.dx * sx - 24,
                  top: _dotAt[s.id]!.dy * sy - 24,
                  width: 48,
                  height: 48,
                  child: Semantics(
                    button: true,
                    selected: s.id == selected,
                    label: '${s.name}, ${context.l10n.status(s.status)}',
                    excludeSemantics: true,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onSelect(s.id),
                        child: Center(
                          child: Stack(alignment: Alignment.center, children: [
                            // Aro exterior suave del color del estado.
                            Container(
                              width: 40,
                              height: 40,
                              decoration:
                                  BoxDecoration(shape: BoxShape.circle, color: statusColor(s.status).withValues(alpha: 0.22)),
                            ),
                            // Marcador: color + forma (StatusShape), 24 dp visual.
                            StatusShape(s.status, size: 24),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
          ]),
        ),
      ),
      const SizedBox(height: VSpace.lg),
      for (final s in systems)
        Padding(
          padding: const EdgeInsets.only(bottom: VSpace.sm),
          child: _SystemRow(system: s, selected: s.id == selected, onTap: () => onSelect(s.id)),
        ),
    ]);
  }
}

/// Fila completa por sistema: ícono de estado + nombre + palabra del estado.
class _SystemRow extends StatelessWidget {
  const _SystemRow({required this.system, required this.selected, required this.onTap});
  final BodySystem system;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      button: true,
      selected: selected,
      label: '${system.name}, ${l.status(system.status)}',
      excludeSemantics: true,
      child: Material(
        color: selected ? VColors.surface2 : VColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? VColors.signal : VColors.border, width: selected ? 2 : 1),
            ),
            child: Row(children: [
              StatusShape(system.status, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(system.name,
                    style: TextStyle(fontSize: VType.body, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
              ),
              Text(l.status(system.status),
                  style: TextStyle(fontSize: VType.label, color: statusColor(system.status), fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Solo la silueta: relleno surface2, contorno signal de baja opacidad.
/// Los marcadores por sistema se pintan como widgets reales encima (no en
/// el canvas), para que su tamaño no dependa de la escala de la figura.
class _BodyPainter extends CustomPainter {
  const _BodyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 160, size.height / 520);
    final fill = Paint()..color = VColors.surface2;
    final stroke = Paint()
      ..color = VColors.signal.withValues(alpha: 0.35)
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
  }

  @override
  bool shouldRepaint(_BodyPainter old) => false;
}
