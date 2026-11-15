import 'package:flutter/material.dart';

import '../core/touch.dart';
import '../theme.dart';

/// Botón para acciones críticas: hay que mantenerlo presionado ~1 s.
/// Un toque accidental no hace nada; al soltar antes de tiempo se reinicia.
///
/// Para lectores de pantalla expone la acción de pulsación larga.
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.icon = Icons.notifications_active_outlined,
    this.color = VColors.critico,
    this.duration = Touch.holdToConfirm,
  });

  final String label;
  final VoidCallback onConfirmed;
  final IconData icon;
  final Color color;
  final Duration duration;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        widget.onConfirmed();
        _c.reset();
      }
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.label,
        onLongPress: widget.onConfirmed,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _c.forward(),
          onTapUp: (_) => _c.reverse(),
          onTapCancel: () => _c.reverse(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Container(
                height: Touch.primary,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.color, width: 2),
                ),
                child: Stack(children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _c.value,
                        child: ColoredBox(color: widget.color.withValues(alpha: 0.35), child: const SizedBox.expand()),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(widget.icon, color: widget.color),
                        const SizedBox(width: 10),
                        Flexible(child: Text(widget.label, style: const TextStyle(fontSize: VType.body, fontWeight: FontWeight.w600))),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
