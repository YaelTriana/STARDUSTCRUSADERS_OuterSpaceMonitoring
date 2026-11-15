import 'package:flutter/widgets.dart';

/// Política táctil de TIRELUS (ver planning/PLAN-UX-UI-TIRELUS.md, sección 4).
///
/// Son supuestos de diseño razonados, no un estándar oficial de la ISS:
/// medir en la pantalla real antes de darlos por buenos (1 dp ≈ 0.16 mm solo
/// de forma aproximada).
class Touch {
  Touch._();

  /// Mínimo para cualquier elemento tocable.
  static const double min = 48;

  /// Botón principal de cada pantalla y teclas numéricas.
  static const double primary = 64;

  /// Con guantes (~20 mm): variante de mano y botones críticos del visor.
  static const double glove = 120;

  /// Separación entre objetivos vecinos.
  static const double gap = 8;

  /// Separación en acciones destructivas o críticas.
  static const double gapCritical = 12;

  /// Tiempo de "mantener presionado" para acciones críticas.
  static const Duration holdToConfirm = Duration(seconds: 1);

  /// Tiempo que dura el aviso con "Deshacer".
  static const Duration undoWindow = Duration(seconds: 6);

  static const Size minSize = Size(min, min);
  static const Size primarySize = Size(min, primary);
  static const Size gloveSize = Size(glove, glove);
}

/// Amplía el área táctil de un widget visualmente pequeño (puntos de la figura
/// corporal, marcadores de la gráfica) sin cambiar cómo se ve.
class TouchTarget extends StatelessWidget {
  const TouchTarget({super.key, required this.child, this.size = Touch.min, this.onTap, this.semanticLabel});
  final Widget child;
  final double size;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Center(child: child)),
        ),
      );
}
