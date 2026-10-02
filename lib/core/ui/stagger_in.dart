import "package:flutter/material.dart";

/// Entrada en cascada: cada bloque aparece subiendo un poco y
/// desvaneciéndose, uno tras otro (el primero de inmediato, cada siguiente
/// 60 ms después). Se anima una sola vez, al aparecer en pantalla; no en
/// cada recarga.
class StaggerIn extends StatefulWidget {
  final int index;
  final Widget child;
  const StaggerIn({super.key, required this.index, required this.child});

  static const _step = Duration(milliseconds: 60);
  static const _maxDelayed = 8; // después del 8.º bloque ya no se espera más
  static const _duration = Duration(milliseconds: 520);

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: StaggerIn._duration);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    final i = widget.index.clamp(0, StaggerIn._maxDelayed);
    Future.delayed(StaggerIn._step * i, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(offset: Offset(0, 22 * (1 - _t.value)), child: child),
      ),
    );
  }
}

/// Envuelve los bloques de una lista/columna con [StaggerIn] en orden. Los
/// separadores (SizedBox vacíos) quedan igual y los Expanded/Flexible se
/// animan por dentro, para no romper el layout.
List<Widget> staggerChildren(List<Widget> children) {
  var i = 0;
  return [
    for (final w in children)
      if (w is SizedBox && w.child == null)
        w
      else if (w is Expanded)
        Expanded(flex: w.flex, child: StaggerIn(index: i++, child: w.child))
      else if (w is Flexible)
        Flexible(flex: w.flex, fit: w.fit, child: StaggerIn(index: i++, child: w.child))
      else
        StaggerIn(index: i++, child: w),
  ];
}
