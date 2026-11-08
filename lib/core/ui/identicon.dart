import "package:flutter/material.dart";

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
    (Color(0xFF55705F), Color(0xFF28362E)), // salvia
    (Color(0xFF5B6878), Color(0xFF2C333C)), // pizarra
    (Color(0xFF6E6457), Color(0xFF36312A)), // piedra
    (Color(0xFF4F6C74), Color(0xFF26353A)), // acero
    (Color(0xFF6A6076), Color(0xFF342F3B)), // malva gris
    (Color(0xFF627252), Color(0xFF303828)), // oliva gris
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
    final (light, dark) = _tones[_hash(seed) % _tones.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, dark]),
      ),
      clipBehavior: Clip.antiAlias,
      // La silueta un poco más abajo del centro, "apoyada" en el borde
      // inferior como en los avatares por defecto habituales.
      child: Align(
        alignment: const Alignment(0, 0.55),
        child: Icon(Icons.person_rounded, size: size * 0.86, color: Colors.white.withValues(alpha: 0.88)),
      ),
    );
  }
}
