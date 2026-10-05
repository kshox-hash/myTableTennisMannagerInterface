import "dart:math" as math;

import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";

/// Turquesa de gráficos y estadísticas (solo ahí; no en botones ni textos).
const statAqua = Color(0xFF22E3D0);

/// Medidor circular con brillo (estilo FIFA): arco de fondo tenue, arco de
/// avance en color con un halo suave y el valor al centro.
/// [open] = arco abierto abajo (mini medidor); si no, anillo completo.
class StatGauge extends StatelessWidget {
  final double fraction; // 0..1
  final String value;
  final String? caption; // texto chico bajo el número (dentro)
  final String? label; // etiqueta en mayúsculas debajo del medidor
  final double size;
  final double stroke;
  final Color color;
  final bool open;
  final double valueSize;

  const StatGauge({
    super.key,
    required this.fraction,
    required this.value,
    this.caption,
    this.label,
    this.size = 64,
    this.stroke = 5,
    this.color = statAqua,
    this.open = true,
    this.valueSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final gauge = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(fraction.clamp(0.0, 1.0), color, stroke, open),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: open ? size * 0.06 : 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: TextStyle(fontFamily: AppTypography.body, fontSize: valueSize, height: 1.05, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
                if (caption != null)
                  Text(caption!, style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, color: AppColors.scorifyTextMuted)),
              ],
            ),
          ),
        ),
      ),
    );
    if (label == null) return gauge;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        gauge,
        const SizedBox(height: 2),
        Text(label!.toUpperCase(),
            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1, color: AppColors.scorifyTextMuted)),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final double stroke;
  final bool open;
  _GaugePainter(this.value, this.color, this.stroke, this.open);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(stroke, stroke, size.width - stroke * 2, size.height - stroke * 2);
    // Abierto: 270° empezando abajo a la izquierda; cerrado: desde arriba.
    final start = open ? math.pi * 0.75 : -math.pi / 2;
    final total = open ? math.pi * 1.5 : math.pi * 2;
    canvas.drawArc(rect, start, total, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.08));
    if (value <= 0) return;
    final sweep = total * value;
    // Halo: el mismo arco, más ancho y difuminado.
    canvas.drawArc(rect, start, sweep, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.2
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.22)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.7));
    canvas.drawArc(rect, start, sweep, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value || old.color != color;
}
