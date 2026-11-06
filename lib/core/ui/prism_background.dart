import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Fondo de la app: degradado verde esmeralda → marino (AppColors.appBackground)
/// con vetas de luz en diagonal, como la referencia que eligió el usuario.
/// Todo dibujado por código (sin imagen) y estático: se pinta una vez y el
/// RepaintBoundary lo aísla del scroll, así que no pesa. [image] ya no hace
/// nada: antes ponía una imagen geométrica detrás del Inicio.
class PrismBackground extends StatelessWidget {
  final Widget child;
  final bool image;
  const PrismBackground({super.key, required this.child, this.image = false});

  static const color = AppColors.scorifyBg;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: color, gradient: AppColors.appBackground),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: CustomPaint(painter: LightStreaksPainter())),
          RepaintBoundary(child: child),
        ],
      ),
    );
  }
}

/// Vetas de luz esmeralda en diagonal (suben de izquierda a derecha): unas
/// anchas y difusas, otras finas y más brillantes. Arriba a la izquierda y
/// abajo, como en la referencia; el centro queda limpio para el contenido.
class LightStreaksPainter extends CustomPainter {
  const LightStreaksPainter();

  static const _glow = Color(0xFF31E38B);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final diag = math.sqrt(w * w + h * h);
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 3.4); // ~53°: suben de abajo-izquierda a arriba-derecha

    // (posición a lo ancho de la pantalla girada, ancho de la veta, intensidad)
    const streaks = <(double, double, double)>[
      (-0.46, 70, 0.10), // ancha, arriba a la izquierda
      (-0.40, 2.5, 0.45), // fina y brillante
      (-0.33, 26, 0.08),
      (0.40, 90, 0.08), // ancha, abajo
      (0.47, 2, 0.40), // fina
      (0.55, 34, 0.07),
    ];
    for (final (pos, width, alpha) in streaks) {
      final x = pos * diag;
      final r = Rect.fromLTWH(x - width / 2, -diag / 2, width, diag);
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [_glow.withValues(alpha: 0), _glow.withValues(alpha: alpha), _glow.withValues(alpha: 0)],
        ).createShader(r);
      if (width > 10) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, width / 4);
      canvas.drawRect(r, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LightStreaksPainter oldDelegate) => false;
}
