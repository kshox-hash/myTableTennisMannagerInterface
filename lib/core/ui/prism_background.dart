import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Fondo de la app: oscuro profundo con una luz azul suave arriba (sin
/// cenizas: ensuciaban el diseño; quedan solo en el login).
/// Los parámetros se mantienen para no tocar las 28 pantallas que lo usan;
/// ya no cambian nada.
class PrismBackground extends StatelessWidget {
  final Widget child;
  final bool image;
  final String? asset;
  final List<Color>? scrim;
  final bool bright;
  final bool gradientOnly;

  const PrismBackground({
    super.key,
    required this.child,
    this.image = false,
    this.asset,
    this.scrim,
    this.bright = false,
    this.gradientOnly = false,
  });

  const PrismBackground.login({super.key, required this.child})
      : image = false,
        asset = null,
        scrim = null,
        bright = false,
        gradientOnly = false;

  static Color get color => AppColors.scorifyBg;

  /// Se conserva por compatibilidad (el Inicio lo pasa): ya no hay imagen.
  static const homeAsset = 'home';

  /// Antes precargaba las fotos de fondo; ya no hay nada que precargar.
  static Future<void> precache(BuildContext context) => Future.value();

  @override
  Widget build(BuildContext context) {
    // Atmósfera del login, más tenue: oscuro profundo, luz azul de estadio
    // arriba y cenizas blancas suaves flotando (los datos encima se leen igual).
    return ColoredBox(
      color: color,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.isLight
                    ? const [Color(0xFFEFF5F8), Color(0xFFF7F7F8), Color(0xFFF4F4F6)]
                    : const [Color(0xFF0A0F18), Color(0xFF07090D), Color(0xFF040508)],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1.15),
                radius: 1.0,
                colors: AppColors.isLight
                    ? const [Color(0x140088A6), Color(0x000088A6)]
                    : const [Color(0x1A2A6BFF), Color(0x002A6BFF)],
              ),
            ),
          ),
          RepaintBoundary(child: child),
        ],
      ),
    );
  }
}
