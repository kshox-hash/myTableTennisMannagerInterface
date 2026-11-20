import "package:myttmi/core/ui/motion.dart";
import 'package:myttmi/core/ui/card_border.dart';
import 'package:myttmi/core/ui/panel_style.dart';
import 'package:flutter/material.dart';
import 'package:myttmi/core/constants/app_colors.dart';

enum GlassCardVariant { normal, elevated }

/// Tarjeta estándar del sistema "Marcador" — esquinas redondeadas con un
/// degradé diagonal (negro verdoso a negro puro), el mismo lenguaje
/// "moderno" que se definió para el home, aplicado a toda la app en vez
/// de quedar solo ahí. Reemplaza el estilo anterior de esquinas cortadas
/// en diagonal.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final GlassCardVariant variant;

  /// Ya no se usa (venía del corte diagonal anterior) — se deja para no
  /// romper a los call sites existentes que todavía lo pasan.
  final double cut;

  final Color? fillColor;
  final Color? borderColor;

  /// Foto de fondo opcional (asset), con un scrim oscuro/verde encima para
  /// que el contenido siga siendo legible.
  final ImageProvider? backgroundImage;
  final Alignment backgroundAlignment;

  /// Zoom de la foto desde el borde izquierdo (>1 corre al sujeto a la derecha).
  final double backgroundScale;

  /// Reemplaza el scrim por defecto (se pintan en orden, uno encima de otro).
  final List<Gradient>? scrims;

  /// De borde a borde: sin esquinas redondeadas ni filete de tarjeta.
  final bool square;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.variant = GlassCardVariant.normal,
    this.cut = 18,
    this.fillColor,
    this.borderColor,
    this.backgroundImage,
    this.backgroundAlignment = Alignment.center,
    this.backgroundScale = 1,
    this.scrims,
    this.square = false,
  });

  static const _radius = Panel.radius;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      child: child,
    );

    final Widget fill;
    if (backgroundImage != null) {
      fill = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: Transform.scale(
              scale: backgroundScale,
              alignment: Alignment.topLeft,
              child: Image(
                image: backgroundImage!,
                fit: BoxFit.cover,
                alignment: backgroundAlignment,
              ),
            ),
          ),
          if (scrims != null)
            for (final g in scrims!) Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: g)))
          else
          // Scrim: oscurece la foto de abajo hacia arriba para que el texto
          // siga siendo legible sin importar qué tan clara sea la imagen.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.scorifyBg.withOpacity(0.30),
                    AppColors.scorifyBg.withOpacity(0.92),
                  ],
                ),
              ),
            ),
          ),
          content,
        ],
      );
    } else {
      fill = content;
    }

    // Tocable: se hunde apenas al presionar, como los botones.
    final box = Container(
      decoration: BoxDecoration(
        borderRadius: square ? null : BorderRadius.circular(_radius),
        border: borderColor == null ? null : Border.all(color: borderColor!), // el filete lo pinta CardBorder
        color: fillColor,
        gradient: (fillColor == null && backgroundImage == null)
            ? AppColors.cardGradient
            : null,
        // Sin sombra: plano, como las tarjetas del landing.
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: onTap == null ? fill : InkWell(onTap: onTap, child: fill),
      ),
    );
    return PressScale(enabled: onTap != null, child: square ? box : CardBorder(radius: _radius, child: box));
  }
}
