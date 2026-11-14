import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tirelus/theme.dart';

/// Razón de contraste WCAG 2.x entre dos colores opacos.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const backgrounds = {
    'space': VColors.space,
    'surface': VColors.surface,
    'surface2': VColors.surface2,
    'warnBg': VColors.warnBg,
  };

  group('texto ≥ 4.5:1 sobre todos los fondos (WCAG AA)', () {
    const textColors = {
      'text': VColors.text,
      'muted': VColors.muted,
      'signal': VColors.signal,
      'signalSoft': VColors.signalSoft,
      'nominal': VColors.nominal,
      'atencion': VColors.atencion,
      'critico': VColors.critico,
    };
    for (final fg in textColors.entries) {
      for (final bg in backgrounds.entries) {
        test('${fg.key} sobre ${bg.key}', () {
          expect(contrast(fg.value, bg.value), greaterThanOrEqualTo(4.5));
        });
      }
    }
  });

  group('texto oscuro sobre píldoras de estado y botones ≥ 4.5:1', () {
    for (final c in const {
      'signal': VColors.signal,
      'nominal': VColors.nominal,
      'atencion': VColors.atencion,
      'critico': VColors.critico,
    }.entries) {
      test('onStatus sobre ${c.key}', () {
        expect(contrast(VColors.onStatus, c.value), greaterThanOrEqualTo(4.5));
      });
    }
  });

  group('bordes de controles ≥ 3:1 (WCAG 1.4.11)', () {
    for (final bg in backgrounds.entries) {
      test('borderStrong sobre ${bg.key}', () {
        expect(contrast(VColors.borderStrong, bg.value), greaterThanOrEqualTo(3.0));
      });
    }
  });
}
