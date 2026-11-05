import 'package:flutter/material.dart';

/// Paleta MYTTM, estilo flat (rediseño 2026-11): fondo gris neutro casi
/// negro, tarjetas gris oscuro lisas sin filete ni brillo, y los acentos de
/// marca (celeste, lima) solo donde algo se toca o significa algo.
///
/// Los NOMBRES de los campos NO cambian (scorifyBg, scorifyMint, etc. se
/// usan en toda la app) — solo cambian los valores. `scorifyMint` es el
/// celeste de marca.
class AppColors {
  static const Color scorifyBg = Color(0xFF0F0F11); // fondo base: gris casi negro, liso
  static const Color scorifyDeep = Color(0xFF1C1C1F); // hojas, diálogos (= tarjeta)
  static const Color scorifyNavbar = Color(0xFF161618); // barra inferior
  static const Color scorifySurface2 = Color(0xFF26262A); // bloques internos de una tarjeta

  // Acento principal: celeste de marca. Botones, enlaces, pestaña activa.
  // Texto oscuro encima (scorifyOnMint).
  static const Color scorifyMint = Color(0xFF00B3D6);
  static const Color scorifyMintDark = Color(0xFF007A94);
  static const Color scorifyCyan = Color(0xFF7FE0F5);

  // Bordes: casi invisibles, solo para separar cuando hace falta.
  static const Color scorifyCardBorder = Color(0xFF2A2A2E);
  static const Color scorifyCardBorderStrong = Color(0xFF3A3A40);

  // Jerarquía de color (cada color significa UNA cosa en toda la app):
  //   celeste (scorifyMint) = lo que se toca: botones, enlaces, pestaña activa
  //   celeste claro (scorifyLive) = está pasando ahora: en mesa, en vivo
  //   lima (scorifyButterfly) = victoria / partido ganado
  //   ámbar (scorifyPending) = pendiente / esperando
  //   rojo (scorifyNegative) = derrota / error
  static const Color scorifyLive = Color(0xFF7FE0F5);
  static const Color scorifyOnLive = Color(0xFF04303B);

  // Acento de PARTIDOS / victorias: lima de marca.
  static const Color scorifyButterfly = Color(0xFFA6D32D);
  static const Color scorifyOnButterfly = Color(0xFF16210A);

  static const Color scorifyText = Color(0xFFF2F2F4);
  static const Color scorifyTextMuted = Color(0xFF9B9BA3);
  static const Color scorifyTextFaint = Color(0xFF6C6C74); // labels, timestamps
  static const Color scorifyOnMint = Color(0xFF041016); // texto sobre celeste
  static const Color scorifyNegative = Color(0xFFFF5C5C);
  static const Color scorifyPending = Color(0xFFEAB308);
  static const Color scorifyBadge = Color(0xFFFF4D5E); // contador de notifs
  static const Color scorifyCardFill = Color(0xFF1C1C1F); // tarjeta lisa
  static const Color scorifyInput = Color(0xFF26262A); // campos de texto

  // Fondo de las tarjetas: gris liso (se deja como "degradado" de un solo
  // color porque muchas pantallas lo pasan donde se espera un Gradient).
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C1C1F), Color(0xFF1C1C1F)],
  );

  /// Tarjeta principal (próximo partido, el campeonato en su detalle): un
  /// paso más clara, también lisa.
  static const LinearGradient featuredGradient = LinearGradient(
    colors: [Color(0xFF232327), Color(0xFF232327)],
  );
}
