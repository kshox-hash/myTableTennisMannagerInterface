import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Paleta MYTTM con modo oscuro (por defecto) y claro (el de la web:
/// `:root[data-theme="light"]` en myttmi-web/src/index.css).
///
/// Los NOMBRES no cambian (scorifyBg, scorifyMint, etc. se usan en toda la
/// app): cada color es un getter que devuelve el valor del modo activo. Por
/// eso ya no son `const` — no usarlos dentro de expresiones const.
///
/// Jerarquía de color (cada color significa UNA cosa en toda la app):
///   celeste (scorifyMint) = lo que se toca: botones, enlaces, pestaña activa
///   coral (scorifyLive) = está pasando ahora: en mesa, en vivo
///   lima (scorifyButterfly) = victoria / partido ganado
///   ámbar (scorifyPending) = pendiente / esperando
///   rojo (scorifyNegative) = derrota / error
class AppColors {
  /// Modo claro activo. Cambiarlo con [setLight] (lo guarda y redibuja la app).
  static final ValueNotifier<bool> light = ValueNotifier<bool>(false);
  static bool get isLight => light.value;
  static const _prefKey = "myttm:theme_light";

  /// Lee el modo guardado (llamar antes de runApp).
  static Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      light.value = prefs.getBool(_prefKey) ?? false;
    } catch (_) {}
  }

  static Future<void> setLight(bool value) async {
    light.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }

  static Color _p(int dark, int light) => Color(isLight ? light : dark);

  static Color get scorifyBg => _p(0xFF060E12, 0xFFF7F7F8); // fondo base (mismos colores que la web)
  static Color get scorifyDeep => _p(0xFF11232B, 0xFFFFFFFF); // hojas, diálogos (opaco)
  static Color get scorifyNavbar => _p(0xFF020304, 0xFFFFFFFF); // barra inferior
  static Color get scorifySurface2 => _p(0x0FFFFFFF, 0x0F000000); // bloques internos: velo

  // Acento principal: celeste de marca. Texto encima: scorifyOnMint.
  static Color get scorifyMint => _p(0xFF00B3D6, 0xFF0088A6);
  static Color get scorifyMintDark => _p(0xFF007A94, 0xFF006F88);
  static Color get scorifyCyan => _p(0xFF7FE0F5, 0xFF0AA2C4);

  // Bordes: casi invisibles, solo para separar cuando hace falta.
  static Color get scorifyCardBorder => _p(0xFF21404C, 0xFFE2E2E5);
  static Color get scorifyCardBorderStrong => _p(0xFF2E5263, 0xFFD4D4D8);

  static Color get scorifyLive => _p(0xFFFF7A4D, 0xFFE0592A);
  static Color get scorifyOnLive => _p(0xFF2A0E04, 0xFFFFFFFF);

  static Color get scorifyButterfly => _p(0xFFA6D32D, 0xFF5F9411);
  static Color get scorifyOnButterfly => _p(0xFF16210A, 0xFFFFFFFF);

  static Color get scorifyText => _p(0xFFEEF4F7, 0xFF18181B);
  /// Texto más fuerte (títulos, cifras): blanco en oscuro, casi negro en claro.
  static Color get scorifyInk => _p(0xFFFFFFFF, 0xFF0B0B0D);
  static Color get scorifyTextMuted => _p(0xFF98A4B2, 0xFF5E5E66);
  static Color get scorifyTextFaint => _p(0xFF7D8B93, 0xFF8A8A93); // labels, timestamps
  static Color get scorifyOnMint => _p(0xFF03121B, 0xFFFFFFFF); // texto sobre el azul de marca
  static Color get scorifyNegative => _p(0xFFFF5C5C, 0xFFD33A3A);
  static Color get scorifyPending => _p(0xFFEAB308, 0xFFB8860B);
  static Color get scorifyBadge => _p(0xFFFF4D5E, 0xFFE5334A); // contador de notifs
  static Color get scorifyCardFill => _p(0xFF11232B, 0xFFFFFFFF); // tarjeta sólida
  static Color get scorifyInput => _p(0xFF193139, 0xFFECECEE); // campos de texto
  /// Títulos de sección ("MIS INSCRIPCIONES", "CATEGORÍAS"…).
  static Color get scorifySection => _p(0xFF00B3D6, 0xFF0088A6);
  /// Separadores y filetes finos dentro de tarjetas.
  static Color get scorifyHairline => _p(0xFF21404C, 0xFFE4E4E7);
  /// Velo de "elegido" (fila o pestaña activa).
  static Color get scorifySelected => _p(0xFF193139, 0x0F0088A6);

  // Fondo de las tarjetas: liso (se deja como "degradado" de un solo color
  // porque muchas pantallas lo pasan donde se espera un Gradient).
  static LinearGradient get cardGradient => LinearGradient(colors: [scorifyCardFill, scorifyCardFill]);

  /// Tarjeta principal (próximo partido): un paso más clara (o celeste muy suave en claro).
  static LinearGradient get featuredGradient {
    final c = _p(0xFF193139, 0xFFF1F8FA);
    return LinearGradient(colors: [c, c]);
  }

  /// Fondo de la app (degradado diagonal).
  static LinearGradient get appBackground => isLight
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.35, 0.7],
          colors: [Color(0xFFDFF2FB), Color(0xFFF3FAFD), Color(0xFFFFFFFF)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 0.3, 0.55, 0.82, 1],
          colors: [Color(0xFF08271F), Color(0xFF071516), Color(0xFF060E12), Color(0xFF06181D), Color(0xFF05272F)],
        );

  /// Login (portada): siempre oscuro, va sobre la foto del jugador.
  static const Color loginAccent = Color(0xFF00B3D6);
  static const Color loginOnAccent = Color(0xFF03121B);
  static const LinearGradient loginButton = LinearGradient(colors: [loginAccent, loginAccent]);

  /// Botón principal: el mismo degradado que la web — lima → celeste en
  /// oscuro, celeste fuerte → celeste claro en claro.
  static LinearGradient get primaryButton => isLight
      ? const LinearGradient(colors: [Color(0xFF0B8FD0), Color(0xFF45B8EC)])
      : const LinearGradient(colors: [Color(0xFFA6D32D), Color(0xFF00B3D6)]);
}
