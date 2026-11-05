import "package:flutter/material.dart";
import "package:myttmi/core/ui/panel_style.dart";

/// Antes pintaba el filete y la línea encendida de arriba de las tarjetas.
/// En el estilo flat las tarjetas no llevan borde: devuelve la tarjeta tal
/// cual (un widget menos que pintar en cada tarjeta). Se mantiene para no
/// tocar los call sites.
class CardBorder extends StatelessWidget {
  final Widget child;
  final double radius;
  final bool highlight;
  const CardBorder({super.key, required this.child, this.radius = Panel.radius, this.highlight = false});

  @override
  Widget build(BuildContext context) => child;
}
