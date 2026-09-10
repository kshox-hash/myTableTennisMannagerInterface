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
  });

  static const _radius = 16.0;

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
            child: Image(
              image: backgroundImage!,
              fit: BoxFit.cover,
              alignment: backgroundAlignment,
            ),
          ),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: borderColor ?? AppColors.scorifyCardBorder),
        color: fillColor,
        gradient: (fillColor == null && backgroundImage == null)
            ? AppColors.cardGradient
            : null,
        boxShadow: variant == GlassCardVariant.elevated
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: onTap == null ? fill : InkWell(onTap: onTap, child: fill),
      ),
    );
  }
}
