import 'package:flutter/material.dart';

import '../data/models.dart';
import '../l10n/labels.dart';
import '../theme.dart';
import 'common.dart';

/// Holograma del cuerpo (imagen) con marcadores tocables por sistema, y
/// debajo los 5 sistemas como filas completas.
class BodyFigure extends StatelessWidget {
  const BodyFigure({super.key, required this.systems, required this.selected, required this.onSelect});

  final List<BodySystem> systems;
  final String selected;
  final ValueChanged<String> onSelect;

  // Fracciones (x, y) del tamaño de la imagen, desde la esquina superior izquierda.
  static const _dotAt = <String, Offset>{
    'ojos': Offset(0.50, 0.075),
    // "Sueño y ánimo" se desplaza para no encimarse con "ojos" (están muy
    // cerca en la silueta); queda unido a su punto real con una guía corta.
    'mente': Offset(0.82, 0.035),
    'cardio': Offset(0.54, 0.25),
    'inmune': Offset(0.47, 0.40),
    'hueso': Offset(0.40, 0.68),
  };

  static const _menteAnchor = Offset(0.62, 0.035);

  // Proporción real del PNG (ancho/alto). Si el contenedor es más angosto
  // que esto a 260 dp de alto, el holograma se reduce sin cortarse.
  static const _imageAspect = 1024 / 1536;
  static const _maxHeight = 260.0;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        LayoutBuilder(builder: (context, c) {
          var h = _maxHeight;
          var w = h * _imageAspect;
          if (c.maxWidth.isFinite && w > c.maxWidth) {
            w = c.maxWidth;
            h = w / _imageAspect;
          }
          Offset at(Offset frac) => Offset(frac.dx * w, frac.dy * h);
          return Center(
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(children: [
                Image.asset(
                  'assets/brand/holograma-tirelus.png',
                  width: w,
                  height: h,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  gaplessPlayback: true,
                ),
                // Guía corta entre el punto real de "mente" y su marcador desplazado.
                CustomPaint(size: Size(w, h), painter: _GuideLine(at(_menteAnchor), at(_dotAt['mente']!))),
                for (final s in systems)
                  if (_dotAt.containsKey(s.id))
                    Positioned(
                      left: at(_dotAt[s.id]!).dx - 24,
                      top: at(_dotAt[s.id]!).dy - 24,
                      width: 48,
                      height: 48,
                      child: _Marker(system: s, selected: s.id == selected, onTap: () => onSelect(s.id)),
                    ),
              ]),
            ),
          );
        }),
        const SizedBox(height: VSpace.lg),
        for (final s in systems)
          Padding(
            padding: const EdgeInsets.only(bottom: VSpace.sm),
            child: _SystemRow(system: s, selected: s.id == selected, onTap: () => onSelect(s.id)),
          ),
      ]);
}

/// Marcador tocable: aro exterior suave del color del estado + forma (color
/// + forma, StatusShape); el seleccionado lleva borde signal.
class _Marker extends StatelessWidget {
  const _Marker({required this.system, required this.selected, required this.onTap});
  final BodySystem system;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '${system.name}, ${context.l10n.status(system.status)}',
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor(system.status).withValues(alpha: 0.22),
                    border: selected ? Border.all(color: VColors.signal, width: 2) : null,
                  ),
                ),
                StatusShape(system.status, size: 24),
              ]),
            ),
          ),
        ),
      );
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

class _GuideLine extends CustomPainter {
  _GuideLine(this.from, this.to);
  final Offset from;
  final Offset to;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = VColors.borderStrong
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_GuideLine old) => old.from != from || old.to != to;
}
