import "package:myttmi/core/constants/app_colors.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/ui/avatar_cache.dart";

/// Avatar por defecto de alguien sin foto: círculo con un degradado suave y
/// la silueta de una persona en blanco (como el avatar por defecto de las
/// apps conocidas). Cada persona recibe uno de varios tonos sobrios de la
/// paleta, siempre el mismo para el mismo [seed] (su id), para que no se vean
/// todos iguales.
///
/// Antes era un "identicon" (grilla 5×5 de cuadritos celeste/azul): se veía
/// como la bandera de Croacia y poco profesional. Se mantiene el nombre de la
/// clase para no tocar los lugares donde se usa.
class Identicon extends StatelessWidget {
  final String seed;
  final double size;

  const Identicon({super.key, required this.seed, this.size = 40});

  // (claro, oscuro): tonos neutros apagados (2026-11-07). Antes eran todos
  // verdes y, con la app entera en verde, cinco avatares seguidos sumaban
  // más verde a la pantalla sin aportar nada: el verde queda para acciones.
  static const _tones = <(Color, Color)>[
    (Color(0xFF3B5B8C), Color(0xFF1C2D4A)), // cobalto
    (Color(0xFF4A6378), Color(0xFF23313D)), // acero
    (Color(0xFF3E6F7E), Color(0xFF1D363E)), // petróleo
    (Color(0xFF5A5F86), Color(0xFF2A2D44)), // índigo gris
    (Color(0xFF51677F), Color(0xFF263241)), // pizarra azul
    (Color(0xFF3D6A8E), Color(0xFF1C3347)), // azul marino
  ];

  /// Modo claro: los mismos tonos en pastel (fondo) con la inicial en el
  /// tono oscuro (como los avatares de la web clara). (fondo claro, fondo, texto)
  static const _tonesLight = <(Color, Color, Color)>[
    (Color(0xFFE3ECF8), Color(0xFFD3E0F2), Color(0xFF2B4A7A)), // cobalto
    (Color(0xFFE5ECF1), Color(0xFFD6E0E8), Color(0xFF3A5266)), // acero
    (Color(0xFFE0EEF1), Color(0xFFCFE4E9), Color(0xFF2C5A66)), // petróleo
    (Color(0xFFE7E8F3), Color(0xFFD9DBEC), Color(0xFF474C75)), // índigo gris
    (Color(0xFFE5EAF0), Color(0xFFD5DEE8), Color(0xFF3E5470)), // pizarra azul
    (Color(0xFFE1ECF5), Color(0xFFD0E2EF), Color(0xFF2C5678)), // azul marino
  ];

  static int _hash(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = (hash * 31 + input.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  @override
  Widget build(BuildContext context) {
    final i = _hash(seed) % _tones.length;
    final isLightMode = AppColors.isLight;
    final (light, dark) = isLightMode ? (_tonesLight[i].$1, _tonesLight[i].$2) : _tones[i];
    final fg = isLightMode ? _tonesLight[i].$3 : Colors.white;
    final name = AvatarCache.nameFor(seed);
    final parts = (name ?? "").split(RegExp(r"\s+")).where((w) => w.isNotEmpty).toList();
    final initials = parts.isEmpty ? null : (parts.first[0] + (parts.length > 1 ? parts[1][0] : "")).toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, dark]),
      ),
      clipBehavior: Clip.antiAlias,
      // Con el nombre conocido: sus iniciales (más personal que la silueta
      // gris repetida). Si no, la silueta de siempre.
      child: initials != null
          ? Center(
              child: Text(initials,
                  style: TextStyle(
                    fontFamily: "Manrope",
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: fg.withValues(alpha: 0.95),
                  )),
            )
          : Align(
        alignment: const Alignment(0, 0.55),
        child: Icon(Icons.person_rounded, size: size * 0.86, color: fg.withValues(alpha: isLightMode ? 0.55 : 0.88)),
      ),
    );
  }
}
