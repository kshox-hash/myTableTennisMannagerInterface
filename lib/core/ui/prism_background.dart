import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Fondo de la app: color liso del tema (estilo flat). [image] ya no hace
/// nada: antes ponía una imagen geométrica detrás del Inicio.
class PrismBackground extends StatelessWidget {
  final Widget child;
  final bool image;
  const PrismBackground({super.key, required this.child, this.image = false});

  static const color = AppColors.scorifyBg;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Flat: sin imagen de fondo en ninguna pantalla (image se ignora).
          RepaintBoundary(child: child),
        ],
      ),
    );
  }
}
