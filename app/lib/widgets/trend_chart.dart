import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Gráfica de tendencia con la banda del rango prevuelo personal.
///
/// - Puntos fuera de rango: triángulo (no solo color).
/// - Se toca en cualquier parte de la gráfica para elegir el punto más cercano.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.series,
    required this.firstDay,
    required this.baseLow,
    required this.baseHigh,
    required this.semanticsLabel,
    required this.baseLabel,
    this.selected,
    this.decimals = 0,
    this.onSelect,
  });

  final List<double> series;
  final int firstDay;
  final double baseLow;
  final double baseHigh;
  final String semanticsLabel;
  final String baseLabel;
  final int decimals;
  final int? selected;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticsLabel,
        child: LayoutBuilder(
          builder: (context, c) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: onSelect == null || series.isEmpty
                ? null
                : (d) => onSelect!(_TrendPainter.indexAt(d.localPosition.dx, c.maxWidth, series.length)),
            child: SizedBox(
              height: 300,
              child: CustomPaint(
                painter: _TrendPainter(series, firstDay, baseLow, baseHigh, baseLabel, selected, decimals),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      );
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.series, this.firstDay, this.baseLow, this.baseHigh, this.baseLabel, this.selected, this.decimals);
  final List<double> series;
  final int firstDay;
  final double baseLow;
  final double baseHigh;
  final String baseLabel;
  final int decimals;
  final int? selected;

  static const _left = 40.0;
  static const _bottom = 24.0;

  static double _x(int i, double width, int n) =>
      n < 2 ? _left + (width - _left) / 2 : _left + i * (width - _left) / (n - 1);

  static int indexAt(double dx, double width, int n) {
    if (n < 2) return 0;
    final step = (width - _left) / (n - 1);
    return ((dx - _left) / step).round().clamp(0, n - 1);
  }

  void _label(Canvas c, String s, Offset at, {Color color = VColors.muted}) {
    final tp = TextPainter(text: TextSpan(text: s, style: mono(size: 12, color: color)), textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    final lo = [...series, baseLow].reduce(math.min);
    final hi = [...series, baseHigh].reduce(math.max);
    final pad = math.max(2.0, (hi - lo) * 0.15);
    final minY = (lo - pad).floorToDouble();
    final maxY = (hi + pad).ceilToDouble();

    final h = size.height - _bottom;
    final n = series.length;
    double y(double v) => h - (v - minY) / (maxY - minY) * h;
    double x(int i) => _x(i, size.width, n);

    // Banda del rango personal.
    canvas.drawRect(
      Rect.fromLTRB(_left, y(baseHigh), size.width, y(baseLow)),
      Paint()..color = const Color(0xFF1B4D3A).withValues(alpha: 0.6),
    );
    _label(canvas, baseLabel, Offset(_left + 10, y(baseLow) - 20), color: const Color(0xFF7FD8AE));

    // Rejilla.
    final grid = Paint()..color = VColors.border;
    for (final v in [minY, (minY + maxY) / 2, maxY]) {
      canvas.drawLine(Offset(_left, y(v)), Offset(size.width, y(v)), grid);
      _label(canvas, v.toStringAsFixed(decimals), Offset(0, y(v) - 8));
    }

    // Guía del punto elegido.
    if (selected != null && selected! < n) {
      canvas.drawLine(
        Offset(x(selected!), 0),
        Offset(x(selected!), h),
        Paint()
          ..color = VColors.signalSoft.withValues(alpha: 0.5)
          ..strokeWidth = 1.5,
      );
    }

    // Línea.
    if (n > 1) {
      final path = Path()..moveTo(x(0), y(series[0]));
      for (var i = 1; i < n; i++) {
        path.lineTo(x(i), y(series[i]));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = VColors.signal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Puntos: círculo dentro de rango, triángulo fuera de rango.
    for (var i = 0; i < n; i++) {
      final v = series[i];
      final c = Offset(x(i), y(v));
      final out = v > baseHigh || v < baseLow;
      if (out) {
        const s = 8.0;
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - s)
            ..lineTo(c.dx + s, c.dy + s * 0.8)
            ..lineTo(c.dx - s, c.dy + s * 0.8)
            ..close(),
          Paint()..color = VColors.atencion,
        );
      } else {
        canvas.drawCircle(c, 4.5, Paint()..color = VColors.signal);
      }
      if (i == selected) {
        canvas.drawCircle(
          c,
          out ? 13 : 10,
          Paint()
            ..color = VColors.text
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }

    _label(canvas, 'D$firstDay', Offset(_left, h + 6));
    _label(canvas, 'D${firstDay + n - 1}', Offset(size.width - 34, h + 6));
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.series != series || old.selected != selected || old.baseLow != baseLow || old.baseHigh != baseHigh;
}
