import 'package:flutter/material.dart';

/// Fondo de toda la app: hexágonos en líneas grises con semitono arriba y
/// abajo (assets/images/app_bg.jpg, 1080 px). Se decodifica una sola vez al
/// ancho de la pantalla y queda en caché; el RepaintBoundary evita
/// repintarlo al hacer scroll encima. Debajo, el degradado gris por si la
/// imagen todavía no cargó.
class PrismBackground extends StatelessWidget {
  final Widget child;
  const PrismBackground({super.key, required this.child});

  static const _gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF24282C), Color(0xFF1A1D20), Color(0xFF131518)],
    stops: [0, 0.5, 1],
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _gradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: Image(
              image: ResizeImage(const AssetImage("assets/images/app_bg.jpg"), width: (size.width * dpr).round().clamp(360, 1080)),
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
          RepaintBoundary(child: child),
        ],
      ),
    );
  }
}
