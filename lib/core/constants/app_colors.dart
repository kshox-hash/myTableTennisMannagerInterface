import 'package:flutter/material.dart';

/// Paleta oficial MYTTM — celeste + verde lima sobre azul marino, según el
/// brand kit (isotipo + paleta + Montserrat). Es la MISMA paleta que la web
/// (myttmi-web, tokens --color-app-*): antes esta app tenía la variante
/// "Marcador" negro/mint y quedó divergida — acá se realinea.
///
/// Los NOMBRES de los campos NO cambian (scorifyBg, scorifyMint, etc. siguen
/// usándose en las ~43 pantallas/widgets) — solo cambian los valores. El
/// prefijo "scorify"/"mint" quedó como nombre histórico; el valor real de
/// `scorifyMint` ahora es el celeste de marca.
class AppColors {
  // Fondo base — el marino EXACTO del brand kit (web --color-app-dark).
  static const Color scorifyBg = Color(0xFF060E12);
  // Relleno de cards / paneles (web --color-app-surface).
  static const Color scorifyDeep = Color(0xFF0F1E25);
  // Navbar / superficie más oscura (web --color-app-primary).
  static const Color scorifyNavbar = Color(0xFF020304);
  // Input / superficie un paso más clara (web --color-app-surface2).
  static const Color scorifySurface2 = Color(0xFF14262E);

  // Acento principal: celeste de marca (web --color-app-electric).
  // Botones, nav activo, foco, chips primarios, categorías/torneos.
  static const Color scorifyMint = Color(0xFF00B3D6);
  // Acento oscuro para gradientes / statusbar (web --color-app-accent).
  static const Color scorifyMintDark = Color(0xFF007A94);
  // Antes un borde "glass" celeste tenue. Ahora, como el landing, los
  // componentes NO tienen borde: la separación la da el salto de color
  // entre el fondo y la tarjeta. Transparente en vez de borrar el campo
  // para no tocar las ~40 pantallas que lo usan.
  static const Color scorifyCardBorder = Color(0x00000000);

  // Acento de PARTIDOS: verde lima de marca (web --color-app-butterfly) —
  // un partido se distingue de una categoría/torneo a simple vista sin
  // salir de la paleta. Texto oscuro encima porque el lima es claro.
  static const Color scorifyButterfly = Color(0xFFA6D32D);
  static const Color scorifyOnButterfly = Color(0xFF16210A);

  static const Color scorifyText = Color(0xFFF5F7F8); // texto principal (landing)
  static const Color scorifyTextMuted = Color(0xFF86939B); // secundario (gris del landing)
  static const Color scorifyTextFaint = Color(0xFF6B7A88); // labels, timestamps
  static const Color scorifyOnMint = Color(0xFF041016); // texto sobre celeste
  static const Color scorifyNegative = Color(0xFFFF5C5C); // perdiste/error
  static const Color scorifyPending = Color(0xFFEAB308); // esperando rival/mesa
  static const Color scorifyBadge = Color(0xFFFF4D5E); // contador de notifs
  static const Color scorifyCardFill = Color(0xFF0F1E25); // relleno sólido de tarjeta
  // Relleno de los campos de texto/selección: un paso más claro que la
  // tarjeta. Sin bordes (estilo landing), el campo se distingue solo por
  // este salto de color — con el mismo color que la tarjeta desaparecía.
  static const Color scorifyInput = Color(0xFF1C3440);

  // Degradé diagonal (marino claro → marino profundo) que usa GlassCard —
  // vive acá para que cualquier Container que necesite el mismo fondo de
  // card lo comparta en vez de redefinirlo con sus propios valores.
  //
  // Ahora es un color SÓLIDO (los dos extremos iguales), como las tarjetas
  // del landing: se mantiene como "gradiente" solo para no tocar a quien
  // lo usa.
  /// Todas las tarjetas: turquesa tenue arriba a la izquierda que se funde
  /// con el fondo de tarjeta.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E2A32), Color(0xFF0F1E25)],
    stops: [0, 0.7],
  );

  /// Tarjeta destacada (próximo partido): el mismo turquesa pero más
  /// intenso y que llega más lejos, para que resalte sobre las demás.
  static const LinearGradient featuredGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F4652), Color(0xFF0F1E25)],
    stops: [0, 0.9],
  );
}
