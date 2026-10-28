import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Fondo de toda la app: gris oscuro liso (AppColors.scorifyBg), sin imagen.
/// Las tarjetas (verde azulado oscuro con filete) se despegan solas encima y
/// no hay foto que decodificar. El RepaintBoundary evita repintar el fondo
/// al hacer scroll encima.
class PrismBackground extends StatelessWidget {
  final Widget child;
  const PrismBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.scorifyBg,
      child: RepaintBoundary(child: child),
    );
  }
}
