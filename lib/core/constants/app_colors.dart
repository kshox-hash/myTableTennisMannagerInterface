import 'package:flutter/material.dart';

/// Paleta MYTTM, estilo flat (rediseño 2026-11): fondo en degradado
/// petróleo → marino casi negro (ver [appBackground]), tarjetas azul petróleo
/// oscuro semitransparentes (el degradado se asoma apenas), sin filete ni
/// brillo, y los acentos de marca (celeste, lima) solo donde algo se toca o
/// significa algo.
///
/// Los NOMBRES de los campos NO cambian (scorifyBg, scorifyMint, etc. se
/// usan en toda la app) — solo cambian los valores. 2026-11-08: la paleta
/// pasó al AZUL del fondo (franjas azules sobre negro): `scorifyMint` es el
/// azul de marca, superficies azul marino casi negro, "en vivo" coral (antes
/// celeste, se confundía con el acento). El login conserva el verde (ver
/// [loginAccent]). Antes, 2026-11-07: la paleta
/// pasó a la gama verde del fondo (imagen verde oscuro): `scorifyMint` es
/// ahora el VERDE de marca (el de "TTM" del logo), fondos y tarjetas verde
/// casi negro. "En vivo" sigue celeste y las victorias lima, para no
/// confundirse con el acento.
class AppColors {
  static const Color scorifyBg = Color(0xFF02070B); // fondo base (debajo del degradado y en transiciones)
  static const Color scorifyDeep = Color(0xFF07141C); // hojas, diálogos (opaco)
  static const Color scorifyNavbar = Color(0xFF040B10); // barra inferior
  static const Color scorifySurface2 = Color(0x1FFFFFFF); // bloques internos: velo blanco (sirve sobre cualquier tono)

  // Acento principal: celeste de marca. Botones, enlaces, pestaña activa.
  // Texto oscuro encima (scorifyOnMint).
  static const Color scorifyMint = Color(0xFF2EA8E0);
  static const Color scorifyMintDark = Color(0xFF1A6F96);
  static const Color scorifyCyan = Color(0xFF7FE0F5);

  // Bordes: casi invisibles, solo para separar cuando hace falta.
  static const Color scorifyCardBorder = Color(0x1AFFFFFF);
  static const Color scorifyCardBorderStrong = Color(0x33FFFFFF);

  // Jerarquía de color (cada color significa UNA cosa en toda la app):
  //   celeste (scorifyMint) = lo que se toca: botones, enlaces, pestaña activa
  //   celeste claro (scorifyLive) = está pasando ahora: en mesa, en vivo
  //   lima (scorifyButterfly) = victoria / partido ganado
  //   ámbar (scorifyPending) = pendiente / esperando
  //   rojo (scorifyNegative) = derrota / error
  static const Color scorifyLive = Color(0xFFFF7A4D);
  static const Color scorifyOnLive = Color(0xFF2A0E04);

  // Acento de PARTIDOS / victorias: lima de marca.
  static const Color scorifyButterfly = Color(0xFFA6D32D);
  static const Color scorifyOnButterfly = Color(0xFF16210A);

  static const Color scorifyText = Color(0xFFF2F2F4);
  // Grises fríos, un paso más claros: sobre el petróleo los grises neutros
  // anteriores quedaban justos de legibilidad (contraste AA o mejor).
  static const Color scorifyTextMuted = Color(0xFFA9B6BD);
  static const Color scorifyTextFaint = Color(0xFF7D8B93); // labels, timestamps
  static const Color scorifyOnMint = Color(0xFF03121B); // texto sobre el azul de marca
  static const Color scorifyNegative = Color(0xFFFF5C5C);
  static const Color scorifyPending = Color(0xFFEAB308);
  static const Color scorifyBadge = Color(0xFFFF4D5E); // contador de notifs
  static const Color scorifyCardFill = Color(0xF20E1C26); // tarjeta: verde grisáceo al 95 %, un paso más claro que el fondo para que se despegue
  static const Color scorifyInput = Color(0x1FFFFFFF); // campos de texto: velo blanco

  // Fondo de las tarjetas: gris liso (se deja como "degradado" de un solo
  // color porque muchas pantallas lo pasan donde se espera un Gradient).
  static const LinearGradient cardGradient = LinearGradient(
    colors: [scorifyCardFill, scorifyCardFill],
  );

  /// Tarjeta principal (próximo partido, el campeonato en su detalle): un
  /// paso más clara, también lisa.
  static const LinearGradient featuredGradient = LinearGradient(
    colors: [Color(0xF2132A39), Color(0xF2132A39)],
  );

  /// Fondo de la app: degradado en diagonal, verde esmeralda arriba a la
  /// izquierda → marino casi negro abajo a la derecha (colores medidos de la
  /// referencia que eligió el usuario). Encima van las vetas de luz
  /// (PrismBackground). Se pinta una sola vez por pantalla.
  static const LinearGradient appBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0, 0.35, 0.7, 1],
    colors: [Color(0xFF0B3A55), Color(0xFF06223A), Color(0xFF03101A), Color(0xFF02070B)],
  );

  /// Login (portada). 2026-11-08: pasó al azul de la app (fondo y logo
  /// azules); se dejan aparte por si la portada vuelve a tener su color.
  static const Color loginAccent = scorifyMint;
  static const Color loginOnAccent = scorifyOnMint;
  static const LinearGradient loginButton = primaryButton;

  /// Botón principal.
  static const LinearGradient primaryButton = LinearGradient(
    colors: [Color(0xFF6CD3F7), Color(0xFF1E8FCB)],
  );
}
