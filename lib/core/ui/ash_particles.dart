import "dart:math" as math;

import "package:flutter/material.dart";

/// Cenizas blancas para el login: puntos chicos y sólidos (sin brillo ni
/// desenfoque, que en círculos grandes se veía feo), de distintos tamaños y
/// opacidades, que suben lento con un leve vaivén y se apagan al llegar
/// arriba. Se dibujan con un solo CustomPainter.
class AshParticles extends StatefulWidget {
  final int count;
  final Color color;
  /// Más grandes y opacas, para que se noten sobre fondos claros.
  final bool strong;
  /// Semilla propia: dos capas (detrás y delante del jugador) no repiten posiciones.
  final int seed;
  const AshParticles({super.key, this.count = 45, this.color = Colors.white, this.strong = false, this.seed = 7});

  @override
  State<AshParticles> createState() => _AshParticlesState();
}

class _Ash {
  double x; // 0..1 del ancho
  double y; // 0..1 del alto
  final double r; // radio en px
  final double speed; // fracción del alto por segundo
  final double alpha; // opacidad máxima
  final double swayAmp; // px
  final double swayFreq; // ciclos por segundo
  final double phase;
  _Ash(this.x, this.y, this.r, this.speed, this.alpha, this.swayAmp, this.swayFreq, this.phase);
}

class _AshParticlesState extends State<AshParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final math.Random _rnd = math.Random(widget.seed);
  late final List<_Ash> _ashes;
  Duration _last = Duration.zero;
  double _time = 0;

  _Ash _spawn({bool anywhere = true}) => _Ash(
        _rnd.nextDouble(),
        anywhere ? _rnd.nextDouble() : 1.02 + _rnd.nextDouble() * 0.1,
        (0.6 + math.pow(_rnd.nextDouble(), 2.2) * 1.2) * (widget.strong ? 1.5 : 1), // casi todas chicas
        0.012 + _rnd.nextDouble() * 0.022,
        widget.strong ? 0.6 + _rnd.nextDouble() * 0.4 : 0.18 + _rnd.nextDouble() * 0.42,
        4 + _rnd.nextDouble() * 10,
        0.05 + _rnd.nextDouble() * 0.12,
        _rnd.nextDouble() * math.pi * 2,
      );

  @override
  void initState() {
    super.initState();
    _ashes = [for (var i = 0; i < widget.count; i++) _spawn()];
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)
      ..forward();
  }

  void _tick() {
    final now = _ticker.lastElapsedDuration ?? Duration.zero;
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    _time += dt;
    for (var i = 0; i < _ashes.length; i++) {
      final a = _ashes[i];
      a.y -= a.speed * dt;
      if (a.y < -0.05) _ashes[i] = _spawn(anywhere: false);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(painter: _AshPainter(_ashes, _time, widget.color), size: Size.infinite),
      ),
    );
  }
}

class _AshPainter extends CustomPainter {
  final List<_Ash> ashes;
  final double time;
  final Color color;
  _AshPainter(this.ashes, this.time, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    for (final a in ashes) {
      // Se apagan de a poco al subir (arriba casi transparentes) y entran suave abajo.
      final fadeTop = (a.y / 0.35).clamp(0.0, 1.0);
      final fadeBottom = ((1.05 - a.y) / 0.1).clamp(0.0, 1.0);
      final alpha = a.alpha * fadeTop * fadeBottom;
      if (alpha <= 0.01) continue;
      final dx = math.sin(time * a.swayFreq * 2 * math.pi + a.phase) * a.swayAmp;
      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(a.x * size.width + dx, a.y * size.height), a.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AshPainter old) => true;
}
