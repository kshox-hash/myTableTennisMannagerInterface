import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";

/// Filete de las tarjetas: una línea fina azul de un solo color, pintada
/// encima del borde (no cambia el tamaño de la tarjeta). Sin degradado ni
/// sombra — antes era un CustomPaint con un shader por tarjeta.
class CardBorder extends StatelessWidget {
  final Widget child;
  final double radius;
  const CardBorder({super.key, required this.child, this.radius = 14});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.scorifyCardBorder),
      ),
      child: child,
    );
  }
}
