import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/src/google_fonts_base.dart';
import 'package:google_fonts/src/google_fonts_family_with_variant.dart';
import 'package:google_fonts/src/google_fonts_variant.dart';

/// Los únicos pesos que theme.dart pide de verdad (ver lib/theme.dart):
/// Inter solo en w700/w800 (headlines y titleLarge), Public Sans en
/// w400/w500/w600 (publicSansTextTheme + overrides), DM Mono solo en w400
/// (mono()/overline(), ningún llamado pasa weight).
const _neededVariants = [
  GoogleFontsFamilyWithVariant(
    family: 'Inter',
    googleFontsVariant: GoogleFontsVariant(fontWeight: FontWeight.w700, fontStyle: FontStyle.normal),
  ),
  GoogleFontsFamilyWithVariant(
    family: 'Inter',
    googleFontsVariant: GoogleFontsVariant(fontWeight: FontWeight.w800, fontStyle: FontStyle.normal),
  ),
  GoogleFontsFamilyWithVariant(
    family: 'PublicSans',
    googleFontsVariant: GoogleFontsVariant(fontWeight: FontWeight.w400, fontStyle: FontStyle.normal),
  ),
  GoogleFontsFamilyWithVariant(
    family: 'PublicSans',
    googleFontsVariant: GoogleFontsVariant(fontWeight: FontWeight.w500, fontStyle: FontStyle.normal),
  ),
  GoogleFontsFamilyWithVariant(
    family: 'PublicSans',
    googleFontsVariant: GoogleFontsVariant(fontWeight: FontWeight.w600, fontStyle: FontStyle.normal),
  ),
  GoogleFontsFamilyWithVariant(
    family: 'DMMono',
    googleFontsVariant: GoogleFontsVariant(fontWeight: FontWeight.w400, fontStyle: FontStyle.normal),
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cada peso que usa theme.dart está en assets/google_fonts/: nunca se intenta descargar', () async {
    // findFamilyWithVariantAssetPath es exactamente lo que google_fonts usa
    // en tiempo de ejecución (loadFontIfNecessary) para decidir si hay que
    // ir a la red. Si devuelve una ruta para los seis, nunca llega a esa
    // rama de descarga — sin necesidad de apagar el Wi-Fi para probarlo.
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();

    for (final variant in _neededVariants) {
      final path = findFamilyWithVariantAssetPath(variant, assets);
      expect(
        path,
        isNotNull,
        reason: '${variant.toApiFilenamePrefix()}.ttf no está en assets/google_fonts/ (o falta en pubspec.yaml)',
      );
      expect(path, contains('assets/google_fonts/'));
    }
  });
}
