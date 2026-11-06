import "package:flutter/material.dart";

/// Efectos compartidos de la app — sutiles y baratos (sin desenfoque ni
/// animaciones en loop), para que se sienta pulida sin perder fluidez.

/// Etiqueta de la transición compartida de la foto de un jugador en un
/// partido: la misma en la tarjeta del Inicio y en el detalle del partido,
/// así la foto "vuela" de una pantalla a la otra.
String matchAvatarHeroTag(String matchId, String userId) => "match-avatar-$matchId-$userId";

/// Envuelve [child] en un Hero solo si hay etiqueta (sin partido o sin
/// jugador no hay transición).
Widget maybeHero(String? tag, Widget child) => tag == null
    ? child
    : Hero(
        tag: tag,
        // Durante el vuelo, sin el Material de fondo que a veces pinta un
        // rectángulo: solo la foto.
        flightShuttleBuilder: (_, __, ___, ____, toContext) => (toContext.widget as Hero).child,
        child: child,
      );

/// Número (o texto corto, p. ej. un marcador) que al cambiar entra
/// deslizándose desde abajo mientras el anterior sale hacia arriba, en vez de
/// cambiar de golpe. Ideal para resultados en vivo.
class AnimatedNumber extends StatelessWidget {
  final String value;
  final TextStyle? style;
  final TextAlign? textAlign;
  const AnimatedNumber(this.value, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(value);
        final offset = Tween<Offset>(
          begin: Offset(0, incoming ? 0.6 : -0.6),
          end: Offset.zero,
        ).animate(animation);
        return ClipRect(
          child: SlideTransition(position: offset, child: FadeTransition(opacity: animation, child: child)),
        );
      },
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [...previous, if (current != null) current]),
      child: Text(value, key: ValueKey(value), style: style, textAlign: textAlign),
    );
  }
}

/// Se hunde apenas al presionar (escala 0.98) y vuelve al soltar — el mismo
/// gesto que ya tienen los botones, para todas las tarjetas tocables. No
/// cambia el tamaño en el layout (solo el dibujo), así que no mueve nada.
class PressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const PressScale({super.key, required this.child, this.enabled = true});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (widget.enabled && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
