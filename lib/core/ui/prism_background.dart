import 'package:flutter/material.dart';

/// Fondo de toda la app: diagonal suave en verde esmeralda (el color del
/// jugador: entre el lima y el celeste de la marca). Entra desde arriba a la
/// izquierda, se desvanece al centro y termina con un brillo turquesa abajo.
/// Antes eran franjas verticales a los costados, que junto a los bordes de las
/// tarjetas se veían como muchas líneas verticales; y el centro no es negro
/// puro, así las tarjetas se despegan del fondo. Es un solo degradado: se
/// pinta una vez y no carga la navegación.
class PrismBackground extends StatelessWidget {
  final Widget child;
  const PrismBackground({super.key, required this.child});

  // 160° (como en la web): de arriba a la izquierda hacia abajo a la derecha.
  static const _diagonal = LinearGradient(
    begin: Alignment(-0.36, -1),
    end: Alignment(0.36, 1),
    colors: [
      Color(0x420E6E4A),
      Color(0x120E6E4A),
      Color(0x00060E12),
      Color(0x120096B2),
      Color(0x2E0096B2),
    ],
    stops: [0, 0.30, 0.55, 0.82, 1],
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF060E12), gradient: _diagonal),
      child: child,
    );
  }
}
