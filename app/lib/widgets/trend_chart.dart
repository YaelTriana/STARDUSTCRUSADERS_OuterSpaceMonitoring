import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';

/// Gráfica de tendencia con la banda del rango prevuelo personal.
/// La escala se ajusta sola a la serie y a la base de cada métrica.
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.trend});
  final Trend trend;

  @override
  Widget build(BuildContext context) {
    final t = trend;
    return Semantics(
      label: '${t.label} de los últimos ${t.series.length} días: de '
          '${t.fmt(t.series.first)} a ${t.fmt(t.series.last)} ${t.unit}; '
          'rango prevuelo ${t.fmt(t.baseLow)} a ${t.fmt(t.baseHigh)}',
      child: SizedBox(height: 300, child: CustomPaint(painter: _TrendPainter(t), size: Size.infinite)),
    );
  }
}

/// Límites del eje Y con margen, incluyendo serie y base.
(double, double) chartRange(Trend t) {
  final values = [...t.series, t.baseLow, t.baseHigh];
  var lo = values.reduce(math.min);
  var hi = values.reduce(math.max);
  final pad = math.max((hi - lo) * 0.15, hi.abs() * 0.02 + 0.5);
  lo -= pad;
  hi += pad;
  return (lo, hi);
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.t);
  final Trend t;

  static const _left = 44.0;
  static const _bottom = 24.0;

  void _label(Canvas c, String s, Offset at, {Color color = VColors.muted}) {
    final tp = TextPainter(text: TextSpan(text: s, style: mono(size: 12, color: color)), textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final (minY, maxY) = chartRange(t);
    final w = size.width - _left;
    final h = size.height - _bottom;
    double y(double v) => h - (v - minY) / (maxY - minY) * h;
    final n = t.series.length;
    double x(int i) => n == 1 ? _left + w / 2 : _left + i * w / (n - 1);

    // Banda del rango personal.
    canvas.drawRect(
      Rect.fromLTRB(_left, y(t.baseHigh), size.width, y(t.baseLow)),
      Paint()..color = const Color(0xFF1B4D3A).withValues(alpha: 0.6),
    );
    _label(canvas, 'Tu rango prevuelo ${t.fmt(t.baseLow)}–${t.fmt(t.baseHigh)}',
        Offset(_left + 10, y(t.baseLow) - 20), color: const Color(0xFF7FD8AE));

    // Rejilla.
    final grid = Paint()..color = VColors.border;
    for (final v in [minY, (minY + maxY) / 2, maxY]) {
      canvas.drawLine(Offset(_left, y(v)), Offset(size.width, y(v)), grid);
      _label(canvas, v.toStringAsFixed(t.decimals), Offset(0, y(v) - 8));
    }

    // Línea.
    final path = Path()..moveTo(x(0), y(t.series[0]));
    for (var i = 1; i < n; i++) {
      path.lineTo(x(i), y(t.series[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = VColors.signal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );

    // Puntos de la racha fuera de la base, en la dirección que preocupa.
    for (var i = math.max(0, n - t.sustainedStreak); i < n; i++) {
      canvas.drawCircle(Offset(x(i), y(t.series[i])), 6, Paint()..color = VColors.atencion);
    }

    _label(canvas, 'D${t.firstDay}', Offset(_left, h + 6));
    _label(canvas, 'D${t.firstDay + n - 1}', Offset(size.width - 34, h + 6));
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.t != t;
}
