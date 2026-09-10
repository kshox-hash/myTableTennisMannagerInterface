import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

/// Timings compartidos por CyberPageRoute (push/pop entre pantallas) y por
/// el pulso de cambio de pestaña del shell (ver app_shell.dart), para que
/// las dos transiciones se sientan iguales.
class CyberTransition {
  /// Punto de corte: la pantalla que se va termina de desvanecerse ANTES
  /// de que empiece a aparecer la que entra — evita el "doble exposición"
  /// de dos pantallas completas cruzándose a la vez.
  static const double crossoverAt = 0.45;

  static Animation<double> fadeOut(Animation<double> parent) {
    final curved = CurvedAnimation(parent: parent, curve: Curves.easeInOutCubic);
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: (crossoverAt * 100)),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: ((1 - crossoverAt) * 100)),
    ]).animate(curved);
  }

  static Animation<double> fadeIn(Animation<double> parent) {
    final curved = CurvedAnimation(parent: parent, curve: Curves.easeInOutCubic);
    return TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: (crossoverAt * 100)),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: ((1 - crossoverAt) * 100)),
    ]).animate(curved);
  }

  static Animation<double> scaleOut(Animation<double> parent) {
    final curved = CurvedAnimation(parent: parent, curve: Curves.easeInOutCubic);
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.97), weight: (crossoverAt * 100)),
      TweenSequenceItem(tween: ConstantTween(0.97), weight: ((1 - crossoverAt) * 100)),
    ]).animate(curved);
  }

  static Animation<double> scaleIn(Animation<double> parent) {
    final curved = CurvedAnimation(parent: parent, curve: Curves.easeInOutCubic);
    return TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.97), weight: (crossoverAt * 100)),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: ((1 - crossoverAt) * 100)),
    ]).animate(curved);
  }

  /// Brillo mint que marca el "corte" entre una pantalla y la otra.
  static Animation<double> glow(Animation<double> parent) {
    final curved = CurvedAnimation(parent: parent, curve: Curves.easeInOutCubic);
    final at = (crossoverAt * 100);
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.22), weight: at),
      TweenSequenceItem(tween: Tween(begin: 0.22, end: 0.0), weight: 100 - at),
    ]).animate(curved);
  }

  /// Versión "un solo widget" de la transición, para cuando el contenido
  /// no son dos rutas distintas sino el mismo lugar en el árbol cambiando
  /// de contenido (p.ej. el IndexedStack del shell al cambiar de pestaña):
  /// una curva en V — se apaga, en el fondo (mitad del recorrido) se
  /// reemplaza el contenido, y se vuelve a encender.
  static Animation<double> contentOpacity(Animation<double> parent) {
    final curved = CurvedAnimation(parent: parent, curve: Curves.easeInOutCubic);
    final at = (crossoverAt * 100);
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: at),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 100 - at),
    ]).animate(curved);
  }

  static Animation<double> contentScale(Animation<double> parent) {
    final curved = CurvedAnimation(parent: parent, curve: Curves.easeInOutCubic);
    final at = (crossoverAt * 100);
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.97), weight: at),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: 100 - at),
    ]).animate(curved);
  }

  static Widget glowOverlay(Animation<double> glowAnim) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: glowAnim,
        builder: (context, _) => Opacity(
          opacity: glowAnim.value,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [AppColors.scorifyMint.withOpacity(0.55), Colors.transparent],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Transición "cyberpunk" de navegación: la pantalla de origen se apaga y
/// se encoge del todo ANTES de que la nueva empiece a aparecer (no se
/// cruzan/superponen) agrandándose desde el centro con un flash de brillo
/// mint en el corte. Se usa en TODAS las rutas con nombre (ver
/// app_routes.dart) en vez de tener que envolver cada card con un Hero.
class CyberPageRoute<T> extends PageRouteBuilder<T> {
  CyberPageRoute({required WidgetBuilder builder, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 560),
          reverseTransitionDuration: const Duration(milliseconds: 480),
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final outgoingFade = CyberTransition.fadeOut(secondaryAnimation);
            final outgoingScale = CyberTransition.scaleOut(secondaryAnimation);
            final incomingFade = CyberTransition.fadeIn(animation);
            final incomingScale = CyberTransition.scaleIn(animation);
            final glow = CyberTransition.glow(animation);

            return FadeTransition(
              opacity: outgoingFade,
              child: ScaleTransition(
                scale: outgoingScale,
                child: FadeTransition(
                  opacity: incomingFade,
                  child: ScaleTransition(
                    scale: incomingScale,
                    child: Stack(
                      children: [child, CyberTransition.glowOverlay(glow)],
                    ),
                  ),
                ),
              ),
            );
          },
        );
}
