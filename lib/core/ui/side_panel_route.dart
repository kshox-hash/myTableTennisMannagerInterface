import "package:flutter/material.dart";

/// Abre [child] a pantalla completa deslizándose desde la derecha, como un
/// panel lateral (se cierra con la X o el botón atrás).
class SidePanelRoute<T> extends PageRouteBuilder<T> {
  SidePanelRoute({required Widget child})
      : super(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          barrierLabel: "Cerrar",
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          // Cubre la pantalla completa; solo la entrada es lateral.
          pageBuilder: (context, _, __) => child,
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic)),
            child: child,
          ),
        );
}
