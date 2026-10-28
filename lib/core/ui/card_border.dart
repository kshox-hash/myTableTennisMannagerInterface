import "package:flutter/material.dart";
import "package:myttmi/core/ui/panel_style.dart";

/// Filete de las tarjetas (estilo panel): línea fina verde azulado oscuro
/// alrededor y una línea encendida de 1 px en el borde superior, pintadas
/// encima del borde (no cambian el tamaño de la tarjeta).
class CardBorder extends StatelessWidget {
  final Widget child;
  final double radius;
  /// Tarjeta destacada (la principal de la pantalla): filete más claro.
  final bool highlight;
  const CardBorder({super.key, required this.child, this.radius = Panel.radius, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: highlight ? Panel.edgeStrong : Panel.edge),
      ),
      // passthrough: la tarjeta recibe las mismas medidas que tendría sin el
      // Stack (con el "loose" por defecto se encogía al ancho de su
      // contenido y el relleno no llegaba al borde).
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          // Línea encendida arriba (dentro del filete, sin pisar las esquinas).
          Positioned(
            top: 0,
            left: radius / 2,
            right: radius / 2,
            child: IgnorePointer(child: Container(height: 1, color: Panel.topLine)),
          ),
        ],
      ),
    );
  }
}
