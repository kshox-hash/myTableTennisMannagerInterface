import 'package:flutter/material.dart';

/// Paleta oficial MYTTM — azul eléctrico + cyan sobre azul marino profundo,
/// con verde para victorias (rediseño 2026-10, mockup "MyTTM" oscuro:
/// tarjetas marino con filete azul, botones en degradado azul → cyan).
///
/// Los NOMBRES de los campos NO cambian (scorifyBg, scorifyMint, etc. siguen
/// usándose en las ~43 pantallas/widgets) — solo cambian los valores. El
/// prefijo "scorify"/"mint" quedó como nombre histórico; el valor real de
/// `scorifyMint` ahora es el azul eléctrico de marca.
class AppColors {
  // Fondo base — azul marino casi negro.
  static const Color scorifyBg = Color(0xFF050A14);
  // Relleno de cards / paneles.
  static const Color scorifyDeep = Color(0xFF0B1528);
  // Navbar / superficie más oscura.
  static const Color scorifyNavbar = Color(0xFF070E1C);
  // Input / superficie un paso más clara que la tarjeta.
  static const Color scorifySurface2 = Color(0xFF111E36);

  // Acento principal: azul eléctrico. Botones, nav activo, foco, chips
  // primarios, categorías/torneos.
  static const Color scorifyMint = Color(0xFF2D8CFF);
  // Acento oscuro para gradientes / statusbar.
  static const Color scorifyMintDark = Color(0xFF0B5BD6);
  // Cyan: el otro extremo de los degradados (botones, anillos, gráficos).
  static const Color scorifyCyan = Color(0xFF00C8FF);
  // Filete azul tenue de las tarjetas (ver CardBorder).
  static const Color scorifyCardBorder = Color(0x3D3B82F6);

  // Acento de PARTIDOS / victorias: verde. Texto oscuro encima.
  static const Color scorifyButterfly = Color(0xFF2FD67B);
  static const Color scorifyOnButterfly = Color(0xFF04140B);

  static const Color scorifyText = Color(0xFFF2F6FF); // texto principal
  static const Color scorifyTextMuted = Color(0xFF8D9BB8); // secundario
  static const Color scorifyTextFaint = Color(0xFF61708E); // labels, timestamps
  static const Color scorifyOnMint = Color(0xFFFFFFFF); // texto sobre azul
  static const Color scorifyNegative = Color(0xFFFF5470); // perdiste/error
  static const Color scorifyPending = Color(0xFFFFB547); // esperando rival/mesa
  static const Color scorifyBadge = Color(0xFFFF4D6A); // contador de notifs
  static const Color scorifyCardFill = Color(0xFF0B1528); // relleno sólido de tarjeta
  // Relleno de los campos de texto/selección: un paso más claro que la
  // tarjeta, así el campo se distingue sin depender del borde.
  static const Color scorifyInput = Color(0xFF13213B);

  // Fondo de las tarjetas — vive acá para que cualquier Container que
  // necesite el mismo fondo de card lo comparta. Color SÓLIDO (los dos
  // extremos iguales, sin degradado): se mantiene como "gradiente" solo
  // para no tocar a las ~20 pantallas que lo usan.
  /// Todas las tarjetas: marino liso.
  static const LinearGradient cardGradient = LinearGradient(colors: [Color(0xFF0B1528), Color(0xFF0B1528)]);

  /// Tarjeta destacada (mi temporada / próximo partido): un marino con más
  /// azul, para que resalte sobre las demás — también liso.
  static const LinearGradient featuredGradient = LinearGradient(colors: [Color(0xFF102447), Color(0xFF102447)]);
}
