import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Fondo de toda la app: imagen de ondas azul marino (assets/images/app_bg.jpg,
/// 1080 px de ancho, ~50 KB). Se decodifica una sola vez al ancho de la
/// pantalla y queda en caché para todas las pantallas; el RepaintBoundary
/// evita repintarla al hacer scroll encima. Debajo, el marino liso por si la
/// imagen todavía no cargó.
class PrismBackground extends StatelessWidget {
  final Widget child;
  const PrismBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ColoredBox(
      color: AppColors.scorifyBg,
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
