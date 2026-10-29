import 'package:flutter/material.dart';

/// Fondo de toda la app, sin imagen: degradado vertical de gris (arriba) que
/// se va oscureciendo hacia abajo. El RepaintBoundary evita repintarlo al
/// hacer scroll encima.
class PrismBackground extends StatelessWidget {
  final Widget child;
  const PrismBackground({super.key, required this.child});

  // Gris arriba que se va oscureciendo hacia abajo (sin llegar al negro ni
  // brillo de color).
  static const _gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF24282C), Color(0xFF1A1D20), Color(0xFF131518)],
    stops: [0, 0.5, 1],
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _gradient),
      child: RepaintBoundary(child: child),
    );
  }
}
