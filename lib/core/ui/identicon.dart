import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";

/// Avatar tipo identicon (grilla 5x5 simétrica: mitad izquierda al azar,
/// reflejada a la derecha) — mismo seed siempre da el mismo patrón, sin
/// subir ni guardar ninguna imagen. Mismo concepto que el panel admin
/// (IdenticonAvatar.tsx) — le da personalidad real a cada jugador en vez
/// del círculo gris con un ícono/inicial genérica que había antes.
class Identicon extends StatelessWidget {
  final String seed;
  final double size;

  const Identicon({super.key, required this.seed, this.size = 40});

  static const _gridSize = 5;
  static const _half = 3;
  static const _palette = [AppColors.scorifyMint, Color(0xFF35A7F2)];

  static int _hash(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = (hash * 31 + input.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  @override
  Widget build(BuildContext context) {
    final safeSeed = seed.trim().isEmpty ? "jugador" : seed;
    final radius = size * 0.22;

    final grid = List.generate(_gridSize, (row) {
      final left = List.generate(_half, (col) {
        final on = _hash("$safeSeed-$row-$col") % 2 == 0;
        final color =
            _palette[_hash("$safeSeed-$row-$col-c") % _palette.length];
        return (on: on, color: color);
      });
      return [...left, left[1], left[0]];
    });

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: AppColors.scorifyDeep,
        child: Column(
          children: [
            for (final row in grid)
              Expanded(
                child: Row(
                  children: [
                    for (final cell in row)
                      Expanded(
                        child: Container(
                          color: cell.on
                              ? cell.color.withOpacity(0.85)
                              : Colors.transparent,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
