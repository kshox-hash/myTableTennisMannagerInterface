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
  static const Color scorifyBg = Color(0xFF0D1B23);
  // Relleno de cards / paneles (web --color-app-surface).
  static const Color scorifyDeep = Color(0xFF14242D);
  // Navbar / superficie más oscura (web --color-app-primary).
  static const Color scorifyNavbar = Color(0xFF060D12);
  // Input / superficie un paso más clara (web --color-app-surface2).
  static const Color scorifySurface2 = Color(0xFF1A2E39);

  // Acento principal: celeste de marca (web --color-app-electric).
  // Botones, nav activo, foco, chips primarios, categorías/torneos.
  static const Color scorifyMint = Color(0xFF00B3D6);
  // Acento oscuro para gradientes / statusbar (web --color-app-accent).
  static const Color scorifyMintDark = Color(0xFF007A94);
  // Borde "glass" celeste tenue (electric al 20%).
  static const Color scorifyCardBorder = Color(0x3300B3D6);

  // Acento de PARTIDOS: verde lima de marca (web --color-app-butterfly) —
  // un partido se distingue de una categoría/torneo a simple vista sin
  // salir de la paleta. Texto oscuro encima porque el lima es claro.
  static const Color scorifyButterfly = Color(0xFFA6D32D);
  static const Color scorifyOnButterfly = Color(0xFF16210A);

  static const Color scorifyText = Color(0xFFEEF4F7); // texto principal
  static const Color scorifyTextMuted = Color(0xFF98A4B2); // secundario/meta
  static const Color scorifyTextFaint = Color(0xFF6B7A88); // labels, timestamps
  static const Color scorifyOnMint = Color(0xFF041016); // texto sobre celeste
  static const Color scorifyNegative = Color(0xFFFF5C5C); // perdiste/error
  static const Color scorifyPending = Color(0xFFEAB308); // esperando rival/mesa
  static const Color scorifyBadge = Color(0xFFFF4D5E); // contador de notifs
  static const Color scorifyCardFill = Color(0x8C14242D); // relleno GlassCard

  // Degradé diagonal (marino claro → marino profundo) que usa GlassCard —
  // vive acá para que cualquier Container que necesite el mismo fondo de
  // card lo comparta en vez de redefinirlo con sus propios valores.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B2E38), Color(0xFF0A141A)],
  );
}
