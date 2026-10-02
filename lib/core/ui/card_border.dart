import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";

/// Filete sutil en degradado para las tarjetas principales: celeste tenue
/// arriba a la izquierda, casi invisible al medio y un toque verde abajo a
/// la derecha. Se pinta encima del borde de la tarjeta (no cambia su tamaño).
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
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.scorifyMint.withValues(alpha: 0.30),
          Colors.white.withValues(alpha: 0.05),
          AppColors.scorifyButterfly.withValues(alpha: 0.18),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(radius - 0.5)), paint);
  }

  @override
  bool shouldRepaint(_CardBorderPainter old) => old.radius != radius;
}
