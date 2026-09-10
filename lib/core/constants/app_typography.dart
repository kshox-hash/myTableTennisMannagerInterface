import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tres roles tipográficos: Teko (condensada) para números grandes de
/// marcador, Montserrat (la fuente del brand kit / la web) para todo el
/// texto de interfaz, y IBM Plex Mono con cifras tabulares para tablas de
/// estadísticas/rankings donde los dígitos necesitan alinear.
class AppTypography {
  static const String display = 'Teko';
  static const String body = 'Montserrat';
  static const String mono = 'IBM Plex Mono';

  static const TextStyle displayXl = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w600,
    fontSize: 56,
    height: 0.95,
    color: AppColors.scorifyText,
  );

  static const TextStyle displayLg = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w600,
    fontSize: 34,
    height: 0.95,
    color: AppColors.scorifyText,
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    height: 1.0,
    color: AppColors.scorifyText,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w800,
    fontSize: 20,
    color: AppColors.scorifyText,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w800,
    fontSize: 15,
    color: AppColors.scorifyText,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: AppColors.scorifyText,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w600,
    fontSize: 12.5,
    color: AppColors.scorifyTextMuted,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w800,
    fontSize: 11,
    letterSpacing: 1.1,
    color: AppColors.scorifyTextFaint,
  );

  static const TextStyle button = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w900,
    fontSize: 11,
    letterSpacing: 0.4,
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
