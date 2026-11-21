import "package:myttmi/core/constants/app_colors.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/ui/ash_particles.dart";

/// Fondo del login (igual que la portada de la web), en capas: el estadio,
/// cenizas detrás, el jugador recortado (oscuro) o la jugadora (claro), más
/// cenizas por delante y un degradado abajo para que el formulario se lea.
class LoginBackground extends StatelessWidget {
  final Widget child;
  const LoginBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final light = AppColors.isLight;
    // Cenizas blancas en oscuro; naranjas intensas (más grandes y opacas) en claro.
    final ash = light ? const Color(0xFFFF6A00) : Colors.white;
    return ColoredBox(
      color: light ? const Color(0xFFDCEBFA) : Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: AssetImage(light ? "assets/images/login_bg_light.webp" : "assets/images/login_bg_dark.webp"),
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
          AshParticles(color: ash, count: 45, strong: light, seed: 7),
          // El jugador de cuerpo entero, apoyado abajo; arriba queda espacio
          // para el logo (la cabeza va justo debajo de la bajada).
          LayoutBuilder(
            builder: (context, c) => Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: c.maxHeight * 0.8,
                child: Image(
                  image: AssetImage(light ? "assets/images/login_player_light.webp" : "assets/images/login_player_dark.webp"),
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
          AshParticles(color: ash, count: 30, strong: light, seed: 23),
          // Limpio arriba, más denso abajo (donde va el formulario).
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.35, 0.62, 1],
                colors: light
                    ? const [Color(0x33FFFFFF), Color(0x00FFFFFF), Color(0x8CFFFFFF), Color(0xF2FFFFFF)]
                    : const [Color(0x40000000), Color(0x00000000), Color(0x8C000000), Color(0xE6000000)],
              ),
            ),
          ),
          RepaintBoundary(child: child),
        ],
      ),
    );
  }
}
