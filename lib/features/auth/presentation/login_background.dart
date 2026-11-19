import "package:flutter/material.dart";

/// Fondo del login: la foto del jugador (sin parallax) y un degradado oscuro
/// abajo para que el formulario se lea.
class LoginBackground extends StatelessWidget {
  final Widget child;
  const LoginBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Jugador más cerca: la foto agrandada (como estaba en el Inicio),
          // centrada en el jugador (cara y torso), sin parallax.
          RepaintBoundary(
            // Corrido 40 px hacia abajo: la cabeza no toca el subtítulo del logo.
            child: Transform.translate(
              offset: const Offset(0, 40),
              child: Transform.scale(
              scale: 1.3,
              alignment: Alignment.bottomCenter,
              child: const Image(
                image: AssetImage("assets/images/login_player.jpg"),
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
            ),
            ),
          ),
          // Oscuro abajo (donde va el formulario), la foto limpia arriba.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.35, 0.62, 1],
                colors: [Color(0x40000000), Color(0x00000000), Color(0x8C000000), Color(0xE6000000)],
              ),
            ),
          ),
          RepaintBoundary(child: child),
        ],
      ),
    );
  }
}

