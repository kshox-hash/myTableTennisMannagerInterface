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
    return ColoredBox(
      color: AppColors.scorifyBg,
      child: child,
    );
  }
}
