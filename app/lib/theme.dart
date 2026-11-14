import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/touch.dart';

/// Paleta de TIRELUS (ver propuesta visual). Tema oscuro de cabina.
class VColors {
  static const space = Color(0xFF060B18);
  static const surface = Color(0xFF0E1830);
  static const surface2 = Color(0xFF15223F);
  static const border = Color(0xFF24345A);
  /// Bordes de controles (campos, botones con contorno, pasos pendientes):
  /// ≥ 3:1 sobre space, surface y surface2 (WCAG 1.4.11).
  static const borderStrong = Color(0xFF5B6F9E);
  static const signal = Color(0xFF4D8DFF);
  static const signalSoft = Color(0xFF7FB0FF);
  static const text = Color(0xFFE8EEF9);
  static const muted = Color(0xFF9AA8C4);
  static const nominal = Color(0xFF3DD68C);
  static const atencion = Color(0xFFF7B23B);
  static const critico = Color(0xFFFF6B5E);
  static const onStatus = Color(0xFF06121F);
  static const warnBg = Color(0xFF2A2310);
}

/// Escala de espaciado (dp). Usar estas constantes en vez de números sueltos.
class VSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Escala tipográfica (sp). Cuerpo ≥ 16; las etiquetas pequeñas no llevan
/// información crítica.
class VType {
  static const double label = 13;
  static const double body = 16;
  static const double bodyLarge = 18;
  static const double title = 20;
  static const double figure = 28;
  static const double evaMin = 28; // visor de casco: texto ≥ 28 sp
}

/// Cifras y etiquetas técnicas en DM Mono.
TextStyle mono({double size = 14, Color color = VColors.text, FontWeight? weight}) =>
    GoogleFonts.dmMono(fontSize: size, color: color, fontWeight: weight);

/// Etiqueta de sección en mayúsculas (estilo HDS).
TextStyle overline({Color color = VColors.signalSoft}) =>
    GoogleFonts.dmMono(fontSize: 12, letterSpacing: 1.2, color: color);

ThemeData tirelusTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  final body = GoogleFonts.publicSansTextTheme(base.textTheme).apply(
    bodyColor: VColors.text,
    displayColor: VColors.text,
  );
  TextStyle inter(double size, [FontWeight w = FontWeight.w800]) =>
      GoogleFonts.inter(fontSize: size, fontWeight: w, color: VColors.text, letterSpacing: -0.4);

  return base.copyWith(
    materialTapTargetSize: MaterialTapTargetSize.padded,
    scaffoldBackgroundColor: VColors.space,
    colorScheme: const ColorScheme.dark(
      primary: VColors.signal,
      onPrimary: VColors.onStatus,
      secondary: VColors.nominal,
      surface: VColors.surface,
      onSurface: VColors.text,
      error: VColors.critico,
      outline: VColors.border,
    ),
    textTheme: body.copyWith(
      headlineLarge: inter(32),
      headlineMedium: inter(28),
      headlineSmall: inter(22),
      titleLarge: inter(20, FontWeight.w700),
      titleMedium: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.w600, color: VColors.text),
    ),
    cardTheme: CardThemeData(
      color: VColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: VColors.border),
      ),
    ),
    dividerColor: VColors.border,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: VColors.signal,
        foregroundColor: VColors.onStatus,
        minimumSize: Touch.primarySize,
        padding: const EdgeInsets.symmetric(horizontal: VSpace.xl, vertical: VSpace.lg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.publicSans(fontSize: VType.body, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: VColors.text,
        minimumSize: const Size(Touch.min, 52),
        padding: const EdgeInsets.symmetric(horizontal: VSpace.xl, vertical: VSpace.lg),
        side: const BorderSide(color: VColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.publicSans(fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VColors.space,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: VColors.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: VColors.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: VColors.signal, width: 2),
      ),
      labelStyle: const TextStyle(color: VColors.muted),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: VColors.space,
      indicatorColor: VColors.surface2,
      selectedIconTheme: IconThemeData(color: VColors.signal),
      unselectedIconTheme: IconThemeData(color: VColors.muted),
    ),
  );
}
