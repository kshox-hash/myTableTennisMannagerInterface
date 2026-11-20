import "package:myttmi/core/constants/app_colors.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/ui/ash_particles.dart";

/// Fondo del login: la foto del jugador (sin parallax) y un degradado oscuro
/// abajo para que el formulario se lea.
class LoginBackground extends StatelessWidget {
  final Widget child;
  const LoginBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // En claro, el color del borde de arriba de la foto (al bajarla no se nota el corte).
      color: AppColors.isLight ? const Color(0xFFE7F0FA) : Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Jugador más cerca: la foto agrandada (como estaba en el Inicio),
          // centrada en el jugador (cara y torso), sin parallax.
          RepaintBoundary(
            // Corrido 40 px hacia abajo y zoom 1.15: en la foto con el logo
            // nuevo el jugador viene más arriba; así la cabeza queda bajo
            // "GESTIÓN DE TORNEOS Y CLUBES" y no detrás del logo.
            child: Transform.translate(
              // En claro la jugadora viene más arriba en la foto: se baja más
              // para que la cabeza no quede detrás del logo.
              offset: Offset(0, AppColors.isLight ? 150 : 40),
              child: Transform.scale(
              scale: 1.15,
              alignment: Alignment.bottomCenter,
              child: Image(
                // Modo claro: la jugadora en la arena luminosa (misma pose y tamaño).
                image: AssetImage(AppColors.isLight ? "assets/images/login_player_light.jpg" : "assets/images/login_player.jpg"),
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
            ),
            ),
          ),
          // Oscuro abajo (donde va el formulario), la foto limpia arriba.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.35, 0.62, 1],
                colors: AppColors.isLight
                    ? const [Color(0x33FFFFFF), Color(0x00FFFFFF), Color(0x8CFFFFFF), Color(0xF2FFFFFF)]
                    : const [Color(0x40000000), Color(0x00000000), Color(0x8C000000), Color(0xE6000000)],
              ),
            ),
          ),
          // Cenizas blancas: puntos chicos, sin brillo, que suben lento.
          // Cenizas: blancas en oscuro; azul pizarra en claro (si no, no se ven).
          AshParticles(color: AppColors.isLight ? const Color(0xFF1E4A60) : Colors.white),
          RepaintBoundary(child: child),
        ],
      ),
    );
  }
}

