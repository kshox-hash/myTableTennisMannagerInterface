import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";

/// Cenizas blancas: motas chicas y suaves que suben lento con vaivén, copos
/// alargados que giran, aparecen y se apagan con fundido. [near] = capa de
/// adelante: pocas, más grandes y desenfocadas.
class AshField extends StatefulWidget {
  final int count;
  final bool near;
  const AshField({super.key, required this.count, required this.near, this.opacity = 1});

  /// Multiplica la opacidad de todas las partículas (1 = como en el login).
  final double opacity;

  @override
  State<AshField> createState() => _AshFieldState();
}

class _Ash {
  double x, y, size, speed, sway, phase, alpha, rot, spin, life, age, stretch;
  bool mote;
  _Ash(this.x, this.y, this.size, this.speed, this.sway, this.phase, this.alpha, this.rot, this.spin, this.life,
      this.age, this.stretch, this.mote);
}

class _AshFieldState extends State<AshField> with SingleTickerProviderStateMixin {
  final _rnd = math.Random();
  late final List<_Ash> _ps;
  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ps = List.generate(widget.count, (_) => _spawn(initial: true));
    _ticker = createTicker(_tick)..start();
  }

  _Ash _spawn({bool initial = false}) {
    final near = widget.near;
    // Más hacia el centro (donde está el jugador).
    final x = (_rnd.nextDouble() + _rnd.nextDouble() + _rnd.nextDouble()) / 3 * 1.2 - 0.1;
    final life = 9 + _rnd.nextDouble() * 9;
    return _Ash(
      x,
      initial ? 0.15 + _rnd.nextDouble() * 0.95 : 0.9 + _rnd.nextDouble() * 0.25,
      near ? 5 + _rnd.nextDouble() * 6 : 1.0 + _rnd.nextDouble() * 2.4,
      (near ? 0.035 : 0.014) + _rnd.nextDouble() * (near ? 0.025 : 0.016),
      0.012 + _rnd.nextDouble() * 0.03,
      _rnd.nextDouble() * math.pi * 2,
      near ? 0.15 + _rnd.nextDouble() * 0.2 : 0.25 + _rnd.nextDouble() * 0.4,
      _rnd.nextDouble() * math.pi,
      (_rnd.nextDouble() - 0.5) * 1.6,
      life,
      initial ? _rnd.nextDouble() * life : 0,
      1.6 + _rnd.nextDouble() * 1.6,
      true, // solo círculos (sin copos alargados)
    );
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 0.0 : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    final t = now.inMicroseconds / 1e6;
    for (var i = 0; i < _ps.length; i++) {
      final p = _ps[i];
      p.age += dt;
      p.y -= p.speed * dt;
      p.x += (0.004 + 0.006 * math.sin(t * 0.21 + p.phase)) * dt;
      p.rot += p.spin * dt;
      if (p.y < -0.06 || p.age > p.life) _ps[i] = _spawn();
    }
    _time.value = t;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _AshPainter(_ps, _time, widget.near, widget.opacity), size: Size.infinite);
}

class _AshPainter extends CustomPainter {
  final List<_Ash> ps;
  final ValueNotifier<double> time;
  final bool near;
  final double opacity;
  _AshPainter(this.ps, this.time, this.near, this.opacity) : super(repaint: time);

  static const _core = Color(0xFFFFFFFF);
  static const _mid = Color(0xFFE4ECF5);
  static const _edge = Color(0xFFB8C7D9);
  static const _ash = Color(0xFFDDE3EA);

  double _smooth(double e0, double e1, double v) {
    final x = ((v - e0) / (e1 - e0)).clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final paint = Paint()..isAntiAlias = true;
    final flake = Paint()
      ..isAntiAlias = true
      ..maskFilter = near ? const MaskFilter.blur(BlurStyle.normal, 3) : const MaskFilter.blur(BlurStyle.normal, 0.6);
    for (final p in ps) {
      final sway = math.sin(t * 0.55 + p.phase) * p.sway + math.sin(t * 1.3 + p.phase * 2) * p.sway * 0.35;
      final pos = Offset((p.x + sway) * size.width, p.y * size.height);
      final born = _smooth(0, 1.6, p.age);
      final dies = 1 - _smooth(p.life - 2.5, p.life, p.age);
      final high = _smooth(-0.05, 0.25, p.y);
      final a = (p.alpha * born * dies * high * opacity).clamp(0.0, 1.0);
      if (a < 0.01) continue;
      if (p.mote) {
        final breathe = 0.85 + 0.15 * math.sin(t * 2.2 + p.phase * 3);
        final r = p.size * (near ? 1.6 : 1.5) * breathe;
        paint.shader = RadialGradient(
          colors: [
            _core.withValues(alpha: a * 0.7),
            _mid.withValues(alpha: a * 0.35),
            _edge.withValues(alpha: a * 0.08),
            _edge.withValues(alpha: 0),
          ],
          stops: const [0, 0.35, 0.7, 1],
        ).createShader(Rect.fromCircle(center: pos, radius: r));
        canvas.drawCircle(pos, r, paint);
      } else {
        flake.color = _ash.withValues(alpha: a * 0.45);
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(p.rot);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: p.size * p.stretch, height: p.size * 0.7), flake);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AshPainter old) => false;
}
