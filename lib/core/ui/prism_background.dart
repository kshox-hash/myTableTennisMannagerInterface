import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/ui/ash_field.dart';

/// Fondo de la app: la atmósfera del login (oscuro profundo, luz azul arriba
/// y cenizas blancas tenues) en todas las pantallas.
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

  static const color = AppColors.scorifyBg;

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
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0E1726), Color(0xFF0B1017), Color(0xFF070A0F)],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -1.15),
                radius: 1.0,
                colors: [Color(0x332A6BFF), Color(0x002A6BFF)],
              ),
            ),
          ),
          // Cenizas como en el login (misma cantidad e intensidad): una sola capa,
          // su costo no depende de cuántas tarjetas haya encima.
          const IgnorePointer(child: RepaintBoundary(child: AshField(count: 30, near: false))),
          const IgnorePointer(child: RepaintBoundary(child: AshField(count: 6, near: true))),
          RepaintBoundary(child: child),
        ],
      ),
    );
  }
}
