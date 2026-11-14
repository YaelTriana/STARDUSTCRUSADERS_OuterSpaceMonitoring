import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';

/// Gráfica de tendencia con la banda del rango prevuelo personal.
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.trend, this.minY = 100, this.maxY = 140});
  final Trend trend;
  final double minY;
  final double maxY;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Presión sistólica de los últimos ${trend.series.length} días: de '
            '${trend.series.first.toStringAsFixed(0)} a ${trend.series.last.toStringAsFixed(0)}; '
            'rango prevuelo ${trend.baseLow.toStringAsFixed(0)} a ${trend.baseHigh.toStringAsFixed(0)}',
        child: SizedBox(height: 300, child: CustomPaint(painter: _TrendPainter(trend, minY, maxY), size: Size.infinite)),
      );
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.t, this.minY, this.maxY);
  final Trend t;
  final double minY;
  final double maxY;

  static const _left = 40.0;
  static const _bottom = 24.0;

  void _label(Canvas c, String s, Offset at, {Color color = VColors.muted}) {
    final tp = TextPainter(text: TextSpan(text: s, style: mono(size: 12, color: color)), textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - _left;
    final h = size.height - _bottom;
    double y(double v) => h - (v - minY) / (maxY - minY) * h;
    double x(int i) => _left + i * w / (t.series.length - 1);

    // Banda del rango personal.
    canvas.drawRect(
      Rect.fromLTRB(_left, y(t.baseHigh), size.width, y(t.baseLow)),
      Paint()..color = const Color(0xFF1B4D3A).withValues(alpha: 0.6),
    );
    _label(canvas, 'Tu rango prevuelo ${t.baseLow.toStringAsFixed(0)}–${t.baseHigh.toStringAsFixed(0)}',
        Offset(_left + 10, y(t.baseLow) - 20), color: const Color(0xFF7FD8AE));

    // Rejilla.
    final grid = Paint()..color = VColors.border;
    for (final v in [minY, (minY + maxY) / 2, maxY]) {
      canvas.drawLine(Offset(_left, y(v)), Offset(size.width, y(v)), grid);
      _label(canvas, v.toStringAsFixed(0), Offset(0, y(v) - 8));
    }

    // Línea.
    final path = Path()..moveTo(x(0), y(t.series[0]));
    for (var i = 1; i < t.series.length; i++) {
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

    // Puntos de la racha fuera de la base.
    for (var i = t.series.length - t.consecutiveAbove; i < t.series.length; i++) {
      canvas.drawCircle(Offset(x(i), y(t.series[i])), 6, Paint()..color = VColors.atencion);
    }

    _label(canvas, 'D${t.firstDay}', Offset(_left, h + 6));
    _label(canvas, 'D${t.firstDay + t.series.length - 1}', Offset(size.width - 34, h + 6));
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.t != t;
}
