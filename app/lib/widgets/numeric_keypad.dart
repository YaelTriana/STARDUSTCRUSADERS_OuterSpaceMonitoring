import 'package:flutter/material.dart';

import '../core/touch.dart';
import '../theme.dart';

/// Teclado numérico propio: teclas de 64 dp, sin teclado del sistema.
///
/// Disposición 3×4: 1-9, borrar, 0 y "siguiente campo".
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onNextField,
    required this.backspaceLabel,
    required this.nextFieldLabel,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onNextField;
  final String backspaceLabel;
  final String nextFieldLabel;

  @override
  Widget build(BuildContext context) {
    Widget digit(String d) => _Key(
          key: ValueKey('key-$d'),
          semantics: d,
          onTap: () => onDigit(d),
          child: Text(d, style: mono(size: 28)),
        );
    Widget row(List<Widget> keys) => Padding(
          padding: const EdgeInsets.only(bottom: Touch.gap),
          child: Row(children: [
            for (var i = 0; i < keys.length; i++) ...[
              if (i > 0) const SizedBox(width: Touch.gap),
              Expanded(child: keys[i]),
            ],
          ]),
        );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        row([digit('1'), digit('2'), digit('3')]),
        row([digit('4'), digit('5'), digit('6')]),
        row([digit('7'), digit('8'), digit('9')]),
        row([
          _Key(
            key: const ValueKey('key-backspace'),
            semantics: backspaceLabel,
            onTap: onBackspace,
            child: const Icon(Icons.backspace_outlined),
          ),
          digit('0'),
          _Key(
            key: const ValueKey('key-next'),
            semantics: nextFieldLabel,
            onTap: onNextField,
            child: const Icon(Icons.keyboard_tab),
          ),
        ]),
      ]),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({super.key, required this.child, required this.onTap, required this.semantics});
  final Widget child;
  final VoidCallback onTap;
  final String semantics;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semantics,
        excludeSemantics: true,
        child: Material(
          color: VColors.surface2,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(height: Touch.primary, child: Center(child: child)),
          ),
        ),
      );
}
