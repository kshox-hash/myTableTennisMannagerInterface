import 'package:flutter/material.dart';
import 'package:myttmi/core/ui/page_skeleton.dart';

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

  /// Antes era un destello celeste en el corte; se quitó (recargaba la
  /// transición). Queda para no tocar a quien lo usa.
  static Widget glowOverlay(Animation<double> glowAnim) => const SizedBox.shrink();
}

/// Transición de navegación: la pantalla nueva entra subiendo un poco,
/// desvaneciéndose y asentándose (escala 0.98 → 1) con una curva suave; la
/// de atrás se oscurece y se aleja apenas. Al volver, lo mismo al revés.
/// Se usa en TODAS las rutas con nombre (ver app_routes.dart).
class CyberPageRoute<T> extends PageRouteBuilder<T> {
  /// Mostrar un esqueleto de página completa hasta que la pantalla termine
  /// de traer sus datos (ver LoadingCurtain). false en pantallas sin datos
  /// del servidor (login, splash).
  final bool waitForData;

  // La transición parte al instante (antes esperaba hasta ~0,35 s los
  // datos y se sentía como un retraso en cada toque): entra el esqueleto
  // de página completa y, cuando llegan los datos, la pantalla entera.
  CyberPageRoute({required WidgetBuilder builder, super.settings, this.waitForData = true})
      : super(
          transitionDuration: const Duration(milliseconds: 170),
          reverseTransitionDuration: const Duration(milliseconds: 140),
          pageBuilder: (context, animation, secondaryAnimation) =>
              waitForData ? LoadingCurtain(child: builder(context)) : builder(context),
          // Liviana: solo fundido + un leve desplazamiento de la que entra. La
          // de atrás queda quieta (antes se escalaba y se le aplicaba un
          // Opacity a toda la pantalla, que obliga a pintarla en una capa
          // aparte en cada cuadro — lo más caro de la transición).
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
            return FadeTransition(
              opacity: enter,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(enter),
                child: child,
              ),
            );
          },
        );
}
