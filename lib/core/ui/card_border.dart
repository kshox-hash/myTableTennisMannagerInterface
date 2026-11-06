import "package:flutter/material.dart";
import "package:myttmi/core/ui/panel_style.dart";

/// Filo iluminado de las tarjetas (estilo "premium" que eligió el usuario):
/// un trazo fino verde-menta que brilla en la esquina de arriba-izquierda y
/// en la de abajo-derecha y se apaga hacia el medio. La tarjeta destacada
/// ([highlight], p. ej. la principal del Inicio) suma un halo suave.
///
/// Se pinta encima de la tarjeta (no cambia su tamaño) y es estático: se
/// dibuja una sola vez, sin animaciones, así que no pesa en el celular.
class CardBorder extends StatelessWidget {
  final Widget child;
  final double radius;
  /// Tarjeta destacada: filo más intenso y con halo.
  final bool highlight;
  const CardBorder({super.key, required this.child, this.radius = Panel.radius, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: GlowEdgePainter(radius: radius, strong: highlight),
      child: child,
    );
  }
}

/// Color de la luz de los bordes (medido de la referencia: #4CF1AC).
const Color kEdgeGlow = Color(0xFF4CF1AC);

class GlowEdgePainter extends CustomPainter {
  final double radius;
  final bool strong;
  const GlowEdgePainter({required this.radius, this.strong = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(0.6), Radius.circular(radius));

    // Brilla en dos esquinas opuestas y se apaga en el medio.
    Shader shader(double a1, double a2) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, 0.3, 0.7, 1],
          colors: [
            kEdgeGlow.withValues(alpha: a1),
            kEdgeGlow.withValues(alpha: 0),
            kEdgeGlow.withValues(alpha: 0),
            kEdgeGlow.withValues(alpha: a2),
          ],
        ).createShader(rect);

    if (strong) {
      // Halo: el mismo trazo, ancho y difuminado.
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
          ..shader = shader(0.45, 0.3),
      );
    }
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strong ? 1.4 : 1.1
        ..shader = shader(strong ? 0.95 : 0.7, strong ? 0.75 : 0.5),
    );
  }

  @override
  bool shouldRepaint(GlowEdgePainter old) => old.radius != radius || old.strong != strong;
}
