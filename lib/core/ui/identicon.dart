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

  // (claro, oscuro): tonos verdes de la paleta de la app (2026-11-07).
  static const _tones = <(Color, Color)>[
    (Color(0xFF1FA67A), Color(0xFF0E5C47)), // esmeralda
    (Color(0xFF2E9E5B), Color(0xFF14522F)), // bosque
    (Color(0xFF5FA830), Color(0xFF2F5A17)), // lima oscuro
    (Color(0xFF3F8F6A), Color(0xFF1E4A36)), // musgo
    (Color(0xFF2E9E8E), Color(0xFF14544B)), // verde agua
    (Color(0xFF6A8F3A), Color(0xFF35491C)), // oliva
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
