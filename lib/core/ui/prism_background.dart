import 'package:flutter/material.dart';

/// Fondo de la app: degradado gris. Con [image] (solo el Inicio) encima va
/// la imagen geométrica (assets/images/app_bg.jpg, 1080 px); en las demás
/// páginas se veía recargada. Se decodifica una sola vez al ancho de la
/// pantalla y queda en caché; el RepaintBoundary evita repintarla al hacer
/// scroll encima.
class PrismBackground extends StatelessWidget {
  final Widget child;
  final bool image;
  const PrismBackground({super.key, required this.child, this.image = false});

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
          if (image)
            RepaintBoundary(
              child: Image(
                image: ResizeImage(
                  const AssetImage("assets/images/app_bg.jpg"),
                  width: (size.width * dpr).round().clamp(360, 1080),
                ),
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
