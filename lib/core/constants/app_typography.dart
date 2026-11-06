import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tres roles tipográficos: Manrope negrita para números grandes de
/// marcador, Montserrat (la fuente del brand kit / la web) para todo el
/// texto de interfaz, y IBM Plex Mono con cifras tabulares para tablas de
/// estadísticas/rankings donde los dígitos necesitan alinear.
class AppTypography {
  static const String display = 'Manrope'; // números grandes: sans negrita (antes Teko, condensada)
  static const String body = 'Montserrat';
  static const String mono = 'IBM Plex Mono';

  static const TextStyle displayXl = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w700,
    fontSize: 40,
    height: 1.05,
    letterSpacing: -1,
    color: AppColors.scorifyText,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle displayLg = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 1.05,
    letterSpacing: -0.5,
    color: AppColors.scorifyText,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    height: 1.05,
    letterSpacing: -0.3,
    color: AppColors.scorifyText,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    color: AppColors.scorifyText,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: AppColors.scorifyText,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.scorifyText,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: AppColors.scorifyTextMuted,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    letterSpacing: 0.2,
    color: AppColors.scorifyTextFaint,
  );

  // Igual que los botones de la web: Montserrat seminegrita, 14 px.
  static const TextStyle button = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0,
    color: AppColors.scorifyText,
  );

  static const TextStyle mono14 = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    color: AppColors.scorifyText,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle monoStrong = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: AppColors.scorifyMint,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
