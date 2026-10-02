import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";

/// Filete sutil para las tarjetas principales: un solo tono turquesa
/// apagado, un poco más claro arriba y que se desvanece hacia abajo (sin
/// mezclar colores, para que no se vea recargado). Se pinta encima del borde de la tarjeta (no cambia su tamaño).
/// Solo para tarjetas grandes; los elementos de adentro (chips, filas,
/// casillas) van sin borde para no recargar.
class CardBorder extends StatelessWidget {
  final Widget child;
  final double radius;
  const CardBorder({super.key, required this.child, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(foregroundPainter: _CardBorderPainter(radius), child: child);
  }
}

class _CardBorderPainter extends CustomPainter {
  final double radius;
  _CardBorderPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.scorifyMint.withValues(alpha: 0.32),
          AppColors.scorifyMint.withValues(alpha: 0.10),
        ],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(0.7), Radius.circular(radius - 0.7)), paint);
  }

  @override
  bool shouldRepaint(_CardBorderPainter old) => old.radius != radius;
}
