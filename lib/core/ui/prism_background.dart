import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Fondo de toda la app: negro plano — mismo lenguaje que se definió
/// para el home (sin la foto del estadio, que quedaba inconsistente con
/// las cards en degradé negro/mint del resto de las pantallas).
class PrismBackground extends StatelessWidget {
  final Widget child;
  const PrismBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Base oscura con un resplandor turquesa muy tenue arriba a la derecha
    // y un toque verde abajo a la izquierda (como la luz del Inicio).
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.scorifyBg,
        gradient: RadialGradient(
          center: Alignment(1.1, -1.1),
          radius: 1.3,
          colors: [Color(0x1A00B3D6), Color(0x0000B3D6)],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-1.2, 1.2),
            radius: 1.1,
            colors: [Color(0x0FA6D32D), Color(0x00A6D32D)],
          ),
        ),
        child: child,
      ),
    );
  }
}
