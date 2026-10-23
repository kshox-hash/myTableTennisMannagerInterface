import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";

/// Filete de las tarjetas: una línea fina azul de un solo color, pintada
/// encima del borde (no cambia el tamaño de la tarjeta). Sin degradado ni
/// sombra — antes era un CustomPaint con un shader por tarjeta.
class CardBorder extends StatelessWidget {
  final Widget child;
  final double radius;
  /// Tarjeta destacada (la principal de la pantalla): filete azul brillante.
  final bool highlight;
  const CardBorder({super.key, required this.child, this.radius = 14, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: highlight ? AppColors.scorifyCardBorderStrong : AppColors.scorifyCardBorder,
          width: highlight ? 1.3 : 1,
        ),
      ),
      child: child,
    );
  }
}
