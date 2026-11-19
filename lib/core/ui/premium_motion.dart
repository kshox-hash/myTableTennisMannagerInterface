import "package:flutter/material.dart";

/// Punto de "en vivo" que late suave (crece y se apaga en loop).
class LiveDot extends StatefulWidget {
  final Color color;
  final double size;
  const LiveDot({super.key, this.color = const Color(0xFFFF5C5C), this.size = 7});

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 2.4,
      height: s * 2.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_c.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              // Onda que se expande y se desvanece.
              Container(
                width: s * (1 + 1.4 * t),
                height: s * (1 + 1.4 * t),
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: 0.45 * (1 - t))),
              ),
              Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
            ],
          );
        },
      ),
    );
  }
}

/// Número que "cuenta" de 0 a su valor al aparecer (marcadores, contadores).
class CountUpText extends StatelessWidget {
  final int value;
  final TextStyle style;
  final TextAlign? textAlign;
  final Duration duration;
  const CountUpText(this.value,
      {super.key, required this.style, this.textAlign, this.duration = const Duration(milliseconds: 700)});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: const Cubic(0.22, 1, 0.36, 1),
      builder: (context, v, _) => Text("${v.round()}", style: style, textAlign: textAlign),
    );
  }
}
