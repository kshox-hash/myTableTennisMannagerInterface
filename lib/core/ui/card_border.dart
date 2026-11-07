import "package:flutter/material.dart";
import "package:myttmi/core/ui/panel_style.dart";

/// Antes pintaba un filo iluminado verde-menta (y un halo en la tarjeta
/// destacada). El usuario lo sacó: las tarjetas van planas, sin borde ni
/// brillo, y se distinguen solo por el relleno. Se deja el widget para no
/// tocar los call sites.
class CardBorder extends StatelessWidget {
  final Widget child;
  final double radius;
  final bool highlight;
  const CardBorder({super.key, required this.child, this.radius = Panel.radius, this.highlight = false});

  @override
  Widget build(BuildContext context) => child;
}
