import 'package:flutter/material.dart';

/// Paleta oficial MYTTM = la misma de la web (myttmi-web/src/index.css,
/// tokens --color-app-*): marino verdoso casi negro, tarjetas gris azulado,
/// celeste de marca y verde lima. Antes la app tenía su propia paleta azul
/// y, sobre el fondo de imagen azul, los componentes se perdían; con estas
/// tarjetas casi opacas y de otro tono se despegan del fondo.
///
/// Los NOMBRES de los campos NO cambian (scorifyBg, scorifyMint, etc. se
/// usan en toda la app) — solo cambian los valores. `scorifyMint` es el
/// celeste de marca.
class AppColors {
  static const Color scorifyBg = Color(0xFF191919); // fondo base: gris oscuro liso, el mismo de la imagen del Inicio
  static const Color scorifyDeep = Color(0xFF11232B); // web --color-app-surface (hojas, diálogos)
  static const Color scorifyNavbar = Color(0xFF020304); // web --color-app-primary
  static const Color scorifySurface2 = Color(0xFF193139); // web --color-app-surface2 (bloques internos)

  // Acento principal: celeste de marca (web --color-app-electric). Botones,
  // enlaces, pestaña activa. Texto oscuro encima (scorifyOnMint).
  static const Color scorifyMint = Color(0xFF00B3D6);
  static const Color scorifyMintDark = Color(0xFF007A94); // web --color-app-accent
  static const Color scorifyCyan = Color(0xFF7FE0F5); // web --color-app-advance

  // Bordes de tarjeta (web --color-app-border); el de la tarjeta principal
  // en celeste de marca.
  static const Color scorifyCardBorder = Color(0xFF21404C);
  static const Color scorifyCardBorderStrong = Color(0xB300B3D6);

  // Jerarquía de color (cada color significa UNA cosa en toda la app):
  //   celeste (scorifyMint) = lo que se toca: botones, enlaces, pestaña activa
  //   celeste claro (scorifyLive) = está pasando ahora: en mesa, en vivo
  //   lima (scorifyButterfly) = victoria / partido ganado
  //   ámbar (scorifyPending) = pendiente / esperando
  //   rojo (scorifyNegative) = derrota / error
  static const Color scorifyLive = Color(0xFF7FE0F5); // web --color-app-advance
  static const Color scorifyOnLive = Color(0xFF04303B); // web --color-app-on-advance

  // Acento de PARTIDOS / victorias: lima de marca (web --color-app-butterfly).
  static const Color scorifyButterfly = Color(0xFFA6D32D);
  static const Color scorifyOnButterfly = Color(0xFF16210A);

  static const Color scorifyText = Color(0xFFEEF4F7); // web --color-app-text
  static const Color scorifyTextMuted = Color(0xFF98A4B2); // web --color-app-text-muted
  static const Color scorifyTextFaint = Color(0xFF6B7A88); // labels, timestamps
  static const Color scorifyOnMint = Color(0xFF041016); // web --color-app-on-accent (texto sobre celeste)
  static const Color scorifyNegative = Color(0xFFFF5C5C); // web --color-app-danger
  static const Color scorifyPending = Color(0xFFEAB308); // web --color-app-warning
  static const Color scorifyBadge = Color(0xFFFF4D5E); // contador de notifs
  static const Color scorifyCardFill = Color(0xF20F2529); // tarjeta lisa: el medio del degradado de panel
  static const Color scorifyInput = Color(0xFF1A1D1D); // campos de texto: gris casi negro (estilo panel)

  // Fondo de las tarjetas (estilo panel, ver core/ui/panel_style.dart):
  // verde azulado casi negro arriba, apenas más claro abajo. Casi opaco
  // (95%) para que los componentes no se pierdan sobre el fondo de imagen.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xF20E1D20), Color(0xF2102E33)],
  );

  /// Tarjeta principal (próximo partido, el campeonato en su detalle): un
  /// paso más clara + filete más claro.
  static const LinearGradient featuredGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xF2132A2F), Color(0xF2163A40)],
  );
}
