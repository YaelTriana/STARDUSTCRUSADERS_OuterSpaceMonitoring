import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../theme.dart';

Color statusColor(VStatus s) => switch (s) {
      VStatus.nominal => VColors.nominal,
      VStatus.atencion => VColors.atencion,
      VStatus.critico => VColors.critico,
      VStatus.sinDato => VColors.muted,
    };

/// Forma del estado (círculo, triángulo, octágono): el color nunca va solo.
class StatusShape extends StatelessWidget {
  const StatusShape(this.status, {super.key, this.size = 14, this.color});
  final VStatus status;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _ShapePainter(status, color ?? statusColor(status)),
      );
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.status, this.color);
  final VStatus status;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final w = size.width;
    switch (status) {
      case VStatus.atencion:
        canvas.drawPath(Path()
          ..moveTo(w / 2, 0)
          ..lineTo(w, w)
          ..lineTo(0, w)
          ..close(), p);
      case VStatus.critico:
        final path = Path();
        for (var i = 0; i < 8; i++) {
          final a = math.pi / 8 + i * math.pi / 4;
          final o = Offset(w / 2 + w / 2 * math.cos(a), w / 2 + w / 2 * math.sin(a));
          i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(path..close(), p);
      case VStatus.sinDato:
        canvas.drawCircle(Offset(w / 2, w / 2), w / 2 - 1, p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      case VStatus.nominal:
        canvas.drawCircle(Offset(w / 2, w / 2), w / 2, p);
    }
  }

  @override
  bool shouldRepaint(_ShapePainter old) => old.status != status || old.color != color;
}

/// Píldora de estado: color + forma + palabra.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final VStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
        label: l.statusSemantics(l.status(status)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: statusColor(status), borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            StatusShape(status, color: VColors.onStatus),
            const SizedBox(width: 8),
            Text(l.status(status),
                style: const TextStyle(color: VColors.onStatus, fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(22), this.highlight = false});
  final Widget child;
  final EdgeInsets padding;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: VColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: highlight ? VColors.signal : VColors.border, width: highlight ? 2 : 1),
        ),
        child: child,
      );
}

/// Etiqueta "Datos de ejemplo" obligatoria en la demo.
class SampleTag extends StatelessWidget {
  const SampleTag({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: VColors.borderStrong),
        ),
        child: Text(AppLocalizations.of(context).sampleData,
            style: const TextStyle(color: VColors.muted, fontSize: 12)),
      );
}

/// Aviso amarillo o rojo con forma + texto.
class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key, required this.title, required this.body, this.status = VStatus.atencion, this.action});
  final String title;
  final String body;
  final VStatus status;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VColors.warnBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c, width: 2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 3), child: StatusShape(status, size: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: VType.body, height: 1.5)),
          ]),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ]),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, this.unit = '', this.note, this.noteColor, this.valueColor, this.valueSize = 28});
  final String label;
  final String value;
  final String unit;
  final String? note;
  final Color? noteColor;
  final Color? valueColor;
  final double valueSize;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: VColors.surface2, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: VType.label, color: VColors.muted)),
          const SizedBox(height: 6),
          Text.rich(TextSpan(children: [
            TextSpan(text: value, style: mono(size: valueSize, color: valueColor ?? VColors.text)),
            if (unit.isNotEmpty) TextSpan(text: ' $unit', style: mono(size: 13, color: VColors.muted)),
          ])),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(note!, style: mono(size: 12, color: noteColor ?? VColors.muted)),
          ],
        ]),
      );
}

/// Carga asíncrona con estados de espera y error.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.future, required this.builder});
  final Future<T> future;
  final Widget Function(BuildContext, T) builder;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No se pudo leer el servidor Python local.\n${snap.error}',
                    textAlign: TextAlign.center, style: const TextStyle(color: VColors.critico)),
              ),
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return builder(context, snap.data as T);
        },
      );
}
