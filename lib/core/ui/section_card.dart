import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/card_border.dart";

/// Tarjeta con título: ícono y nombre de la sección en mayúsculas de color ("SETS", "ÚLTIMOS PARTIDOS"),
/// opcionalmente con un ícono y una acción a la derecha ("Ver historial").
/// Se usa en toda la app para que las tarjetas con título se vean iguales.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final IconData? icon;
  final Color? titleColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Fondo; por defecto el degradado tenue de tarjeta.
  final Gradient? gradient;

  /// El contenido ocupa todo el alto que le den a la tarjeta (centrado).
  final bool fill;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.icon,
    this.titleColor,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.gradient,
    this.fill = false,
  });

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    // Mismo estilo de título que el Inicio: ícono + mayúsculas de color,
    // dentro de la tarjeta (sin franja), y la acción a la derecha.
    final color = titleColor ?? AppColors.scorifyMint;
    final header = Padding(
      padding: EdgeInsets.fromLTRB(16, trailing == null ? 14 : 8, trailing == null ? 16 : 6, 0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.body,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                color: color,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
    final body = Padding(padding: padding, child: child);
    return CardBorder(
      radius: _radius,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(gradient: gradient ?? AppColors.cardGradient),
            child: InkWell(
              onTap: onTap,
              child: Column(
                mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  if (fill) Expanded(child: Center(child: body)) else body,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Filas de una lista dentro de una tarjeta, separadas por una línea fina
/// (en vez de una tarjeta por fila).
List<Widget> dividedRows(Iterable<Widget> rows) {
  final out = <Widget>[];
  for (final r in rows) {
    if (out.isNotEmpty) out.add(const Divider(height: 1, thickness: 1, color: Color(0x14FFFFFF)));
    out.add(r);
  }
  return out;
}
