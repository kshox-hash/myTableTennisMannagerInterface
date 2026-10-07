import 'package:flutter/material.dart';

/// Fondo de toda la app (menos Inicio, que tiene la foto). Son solo
/// degradados que se pintan una vez (sin imágenes ni blur, para no cargar
/// la navegación), en 4 capas:
///  1. negro puro al centro y turquesa de marca hacia los costados, con
///     muchos pasos para que la transición no tenga cortes;
///  2. viñeta arriba y abajo (profundidad; encabezado y pie se leen mejor);
///  3. luz de escenario celeste muy tenue arriba al centro;
///  4. toque lima apenas visible abajo a la izquierda (los dos colores de marca).
class PrismBackground extends StatelessWidget {
  final Widget child;
  const PrismBackground({super.key, required this.child});

  static const _sides = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF06505E), Color(0xFF054653), Color(0xFF04343D), Color(0xFF03222A), Color(0xFF011014),
      Colors.black, Colors.black,
      Color(0xFF011014), Color(0xFF03222A), Color(0xFF04343D), Color(0xFF054653), Color(0xFF06505E),
    ],
    stops: [0, 0.08, 0.17, 0.27, 0.37, 0.46, 0.54, 0.63, 0.73, 0.83, 0.92, 1],
  );

  static const _vignette = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x8C000000), Color(0x00000000), Color(0x00000000), Color(0xA6000000)],
    stops: [0, 0.14, 0.80, 1],
  );

  static const _stageLight = RadialGradient(
    center: Alignment(0, -1.08),
    radius: 0.75,
    colors: [Color(0x2900B3D6), Color(0x0000B3D6)],
    transform: _Stretch(Alignment(0, -1.08), 2.6, 0.75),
  );

  static const _limeTouch = RadialGradient(
    center: Alignment(-1, 1),
    radius: 0.7,
    colors: [Color(0x1AA6D32D), Color(0x00A6D32D)],
    transform: _Stretch(Alignment(-1, 1), 1.3, 0.85),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black, gradient: _sides),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: _vignette),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: _stageLight),
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: _limeTouch),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Estira un RadialGradient en elipse (ancho × sx, alto × sy) alrededor de
/// su propio centro [at] — Flutter solo dibuja círculos.
class _Stretch extends GradientTransform {
  final Alignment at;
  final double sx;
  final double sy;
  const _Stretch(this.at, this.sx, this.sy);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final c = at.withinRect(bounds);
    return Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(sx, sy, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
  }
}
